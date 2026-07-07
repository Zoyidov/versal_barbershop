import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { REGION } from './config';
import { cancelReminderTask, scheduleReminderTask, taskSecret } from './taskQueue';
import type { AppointmentDoc, SettingsDoc } from './types';

const db = getFirestore();

/**
 * When the barber changes the global reminder window in Settings, every
 * already-scheduled, not-yet-sent, future appointment needs its Cloud Task
 * re-timed - otherwise only appointments booked *after* the change would
 * respect the new window, which would silently violate the "dynamically
 * respected" requirement for this setting.
 *
 * This is a full re-scan rather than an incremental update, which is fine
 * for a single-shop appointment volume; if this were to scale to many
 * thousands of pending appointments, this loop would need to be paginated.
 */
export const onGlobalSettingsUpdated = onDocumentUpdated(
  { document: 'settings/global', region: REGION, secrets: [taskSecret] },
  async (event) => {
    const before = event.data?.before.data() as SettingsDoc | undefined;
    const after = event.data?.after.data() as SettingsDoc | undefined;
    if (!before || !after) return;
    if (before.reminderWindowMinutes === after.reminderWindowMinutes) return;

    const newWindowMinutes = after.reminderWindowMinutes;
    const now = Timestamp.now();

    const pending = await db
      .collection('appointments')
      .where('status', '==', 'scheduled')
      .where('smsSent', '==', false)
      .where('sendSms', '==', true)
      .where('appointmentTime', '>', now)
      .get();

    logger.info(`Reminder window changed to ${newWindowMinutes}m - rescheduling ${pending.size} pending reminder(s).`);

    await Promise.all(
      pending.docs.map(async (doc) => {
        const appointment = doc.data() as AppointmentDoc;
        try {
          await cancelReminderTask(appointment.reminderTaskName);
          const scheduled = new Date(appointment.appointmentTime.toMillis() - newWindowMinutes * 60_000);
          const scheduleTime = scheduled.getTime() < Date.now() ? new Date() : scheduled;
          const taskName = await scheduleReminderTask(doc.id, scheduleTime);
          await doc.ref.update({ reminderTaskName: taskName });
        } catch (error) {
          logger.error('Failed to reschedule reminder after settings change', { appointmentId: doc.id, error });
        }
      }),
    );
  },
);
