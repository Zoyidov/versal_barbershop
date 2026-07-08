import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { REGION, DEFAULT_REMINDER_WINDOW_MINUTES } from './config';
import { cancelReminderTask, scheduleReminderTask, taskSecret } from './taskQueue';
import type { AppointmentDoc, SettingsDoc } from './types';

const db = getFirestore();

async function getReminderWindowMinutes(): Promise<number> {
  const snap = await db.collection('settings').doc('global').get();
  const data = snap.data() as SettingsDoc | undefined;
  return data?.reminderWindowMinutes ?? DEFAULT_REMINDER_WINDOW_MINUTES;
}

function computeScheduleTime(appointmentTime: Date, reminderWindowMinutes: number): Date {
  const scheduled = new Date(appointmentTime.getTime() - reminderWindowMinutes * 60_000);
  const now = new Date();
  // Never schedule a Cloud Task in the past - if the reminder window has
  // already elapsed by the time the appointment was booked, fire almost
  // immediately instead.
  return scheduled.getTime() < now.getTime() ? now : scheduled;
}

/**
 * Keeps `clients/{phone}` (the lifetime aggregate used by the statistics
 * screen and the smart-alert banner) in sync whenever a new appointment is
 * booked. Runs in a transaction so concurrent bookings for the same phone
 * number never race each other's counters.
 */
async function upsertClientOnCreate(phone: string, name: string | null): Promise<void> {
  const ref = db.collection('clients').doc(phone);
  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists) {
      tx.set(ref, {
        phoneNumber: phone,
        lastName: name,
        totalVisits: 1,
        totalCancellations: 0,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      const existingName = (doc.data() as { lastName?: string | null }).lastName ?? null;
      tx.update(ref, {
        lastName: name ?? existingName,
        totalVisits: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
}

/**
 * Fires once per new appointment document:
 *  1. Updates the client's lifetime aggregate.
 *  2. If the barber left "send reminder SMS" on, schedules a Cloud Task
 *     that will hit `sendSmsReminderTask` at (appointmentTime - reminder
 *     window), reading the window from `settings/global` at *creation*
 *     time. `onGlobalSettingsUpdated` (settingsTriggers.ts) keeps this in
 *     sync retroactively if the window changes later.
 */
export const onAppointmentCreated = onDocumentCreated(
  { document: 'appointments/{appointmentId}', region: REGION, secrets: [taskSecret] },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const appointment = snap.data() as AppointmentDoc;
    const appointmentId = event.params.appointmentId;

    await upsertClientOnCreate(appointment.clientPhone, appointment.clientName);

    if (!appointment.sendSms || appointment.status !== 'scheduled') return;

    try {
      const reminderWindowMinutes = await getReminderWindowMinutes();
      const scheduleTime = computeScheduleTime(appointment.appointmentTime.toDate(), reminderWindowMinutes);
      const taskName = await scheduleReminderTask(appointmentId, scheduleTime);
      await snap.ref.update({ reminderTaskName: taskName });
    } catch (error) {
      logger.error('Failed to schedule SMS reminder task on create', { appointmentId, error });
    }
  },
);

/**
 * Fires on every edit to an existing appointment. Handles three cases:
 *  - Cancellation: moves the client's counters from visits to
 *    cancellations and cancels any pending reminder task.
 *  - Time or SMS-toggle changes on a still-scheduled, not-yet-sent
 *    appointment: cancels the old task (if any) and schedules a fresh one.
 *  - Everything else (name/service edits, already-sent reminders): no-op.
 */
export const onAppointmentUpdated = onDocumentUpdated(
  { document: 'appointments/{appointmentId}', region: REGION, secrets: [taskSecret] },
  async (event) => {
    const before = event.data?.before.data() as AppointmentDoc | undefined;
    const after = event.data?.after.data() as AppointmentDoc | undefined;
    if (!before || !after || !event.data) return;

    const ref = event.data.after.ref;
    const appointmentId = event.params.appointmentId;

    if (before.status === 'scheduled' && after.status === 'cancelled') {
      await db.runTransaction(async (tx) => {
        const clientRef = db.collection('clients').doc(after.clientPhone);
        const clientDoc = await tx.get(clientRef);
        if (clientDoc.exists) {
          tx.update(clientRef, {
            totalVisits: FieldValue.increment(-1),
            totalCancellations: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          });
        } else {
          // Client aggregate is missing (phone format drift, manual doc
          // deletion, etc.) - tx.update() on a nonexistent doc throws
          // NOT_FOUND, which used to abort this whole handler *before* it
          // reached cancelReminderTask() below, leaving the Cloud Task
          // alive to fire a stale reminder later.
          tx.set(clientRef, {
            phoneNumber: after.clientPhone,
            lastName: after.clientName,
            totalVisits: 0,
            totalCancellations: 1,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
      });

      try {
        await cancelReminderTask(after.reminderTaskName);
      } catch (error) {
        logger.error('Failed to cancel reminder task on cancellation', { appointmentId, error });
      }
      if (after.reminderTaskName) {
        await ref.update({ reminderTaskName: null });
      }
      return;
    }

    // Only a still-scheduled, not-yet-sent appointment can need its
    // reminder rescheduled.
    if (after.status !== 'scheduled' || after.smsSent) return;

    const timeChanged = before.appointmentTime.toMillis() !== after.appointmentTime.toMillis();
    const turnedOff = before.sendSms && !after.sendSms;
    const turnedOn = !before.sendSms && after.sendSms;

    if (turnedOff) {
      try {
        await cancelReminderTask(after.reminderTaskName);
      } catch (error) {
        logger.error('Failed to cancel reminder task after SMS toggled off', { appointmentId, error });
      }
      if (after.reminderTaskName) await ref.update({ reminderTaskName: null });
      return;
    }

    if (!after.sendSms) return;

    const needsReschedule = timeChanged || turnedOn;
    if (!needsReschedule) return;

    try {
      await cancelReminderTask(after.reminderTaskName);
      const reminderWindowMinutes = await getReminderWindowMinutes();
      const scheduleTime = computeScheduleTime(after.appointmentTime.toDate(), reminderWindowMinutes);
      const taskName = await scheduleReminderTask(appointmentId, scheduleTime);
      await ref.update({ reminderTaskName: taskName });
    } catch (error) {
      logger.error('Failed to reschedule SMS reminder task', { appointmentId, error });
    }
  },
);
