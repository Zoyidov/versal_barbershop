import { onRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { REGION } from './config';
import { taskSecret } from './taskQueue';
import { devsmsSmsTemplate, sendReminderSms } from './smsGateway';
import type { AppointmentDoc, UserDoc } from './types';
import { errorMessage } from './util';

const db = getFirestore();

/**
 * Reserves one SMS credit off `users/{barberId}.smsLimit` before actually
 * sending, so two reminders firing at once can't both pass a stale check.
 * `role === 'admin'` accounts are unmetered - reserving there is a no-op.
 * Returns `false` (and reserves nothing) when the barber is out of credit.
 */
async function reserveSmsCredit(barberId: string): Promise<boolean> {
  const barberRef = db.collection('users').doc(barberId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(barberRef);
    const barber = snap.data() as UserDoc | undefined;
    if (!barber || barber.role === 'admin') return true;
    if ((barber.smsLimit ?? 0) <= 0) return false;
    tx.update(barberRef, { smsLimit: FieldValue.increment(-1) });
    return true;
  });
}

/** Returns a reserved credit after a send attempt fails, so a delivery
 * failure never permanently costs the barber a credit. */
async function refundSmsCredit(barberId: string): Promise<void> {
  const barberRef = db.collection('users').doc(barberId);
  const snap = await barberRef.get();
  const barber = snap.data() as UserDoc | undefined;
  if (!barber || barber.role === 'admin') return;
  await barberRef.update({ smsLimit: FieldValue.increment(1) });
}

/**
 * Fills in `{time}` in the template configured in `functions/.env`
 * (DEVSMS_SMS_TEMPLATE). Edit that one value whenever a newly-approved
 * devsms.uz template needs to go live - no code change needed.
 *
 * devsms.uz's moderator approves a template by its exact sentence
 * structure (e.g. "Bugun soat 14:30 da ...") and masks whatever appears in
 * that spot, so every real message must keep the same shape as the
 * approved sample - only the time actually varies per appointment.
 */
function buildReminderMessage(appointment: AppointmentDoc): string {
  const time = appointment.appointmentTime.toDate().toLocaleTimeString('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
    timeZone: 'Asia/Tashkent',
  });

  return devsmsSmsTemplate.value().replace('{time}', time);
}

/**
 * HTTP endpoint invoked exclusively by the Cloud Tasks queue (never by the
 * Flutter app). This is the function that actually calls devsms.uz - and
 * because it's driven purely by Cloud Tasks' own scheduler, it fires
 * whether or not the app, or the barber's phone, is on at that moment.
 *
 * Authenticated with a shared secret header rather than IAM/OIDC to keep
 * first-time deploy simple; every task enqueued by taskQueue.ts carries the
 * same secret via the `X-Task-Secret` header.
 */
export const sendSmsReminderTask = onRequest(
  { region: REGION, secrets: [taskSecret] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    if (req.get('X-Task-Secret') !== taskSecret.value()) {
      logger.warn('Rejected sendSmsReminderTask request with invalid or missing task secret.');
      res.status(401).send('Unauthorized');
      return;
    }

    const appointmentId = (req.body as { appointmentId?: string } | undefined)?.appointmentId;
    if (!appointmentId) {
      res.status(400).send('Missing appointmentId in request body.');
      return;
    }

    const ref = db.collection('appointments').doc(appointmentId);
    const snap = await ref.get();

    if (!snap.exists) {
      // Nothing to send to; acknowledge so Cloud Tasks does not retry.
      res.status(200).send('Appointment no longer exists, skipping.');
      return;
    }

    const appointment = snap.data() as AppointmentDoc;

    // Re-validate at send time: the appointment may have been cancelled,
    // rescheduled, or had SMS turned off since this task was enqueued.
    if (appointment.status !== 'scheduled' || !appointment.sendSms || appointment.smsSent) {
      res.status(200).send('Reminder no longer applicable, skipping.');
      return;
    }

    const hasCredit = await reserveSmsCredit(appointment.barberId);
    if (!hasCredit) {
      await ref.update({ smsStatus: 'limit_exceeded', reminderTaskName: null });
      res.status(200).send('Barber has no SMS credit left, skipping.');
      return;
    }

    try {
      await sendReminderSms(appointment.clientPhone, buildReminderMessage(appointment));
      await ref.update({
        smsSent: true,
        smsSentAt: Timestamp.now(),
        smsStatus: 'sent',
        reminderTaskName: null,
      });
      res.status(200).send('SMS sent.');
    } catch (error) {
      // Cloud Functions' logger treats a `message` key in the metadata
      // object as reserved (it silently overwrites it with the logger
      // call's own stack trace), so the real reason must go under a
      // different key - `reason` - or it's lost from Cloud Logging entirely.
      logger.error('Failed to send SMS reminder', { appointmentId, reason: errorMessage(error) });
      await refundSmsCredit(appointment.barberId);
      await ref.update({ smsStatus: 'failed', reminderTaskName: null });
      // Non-2xx tells Cloud Tasks to retry according to the queue's retry
      // policy instead of silently swallowing a failed delivery.
      res.status(500).send(`Failed to send SMS: ${errorMessage(error)}`);
    }
  },
);
