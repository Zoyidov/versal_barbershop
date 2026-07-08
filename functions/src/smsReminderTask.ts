import { onRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { REGION } from './config';
import { taskSecret } from './taskQueue';
import { devsmsSmsTemplate, sendReminderSms } from './smsGateway';
import type { AppointmentDoc } from './types';
import { errorMessage } from './util';

const db = getFirestore();

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
      logger.error('Failed to send SMS reminder', { appointmentId, message: errorMessage(error), error });
      await ref.update({ smsStatus: 'failed', reminderTaskName: null });
      // Non-2xx tells Cloud Tasks to retry according to the queue's retry
      // policy instead of silently swallowing a failed delivery.
      res.status(500).send(`Failed to send SMS: ${errorMessage(error)}`);
    }
  },
);
