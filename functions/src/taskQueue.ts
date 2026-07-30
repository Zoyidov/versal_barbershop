import { CloudTasksClient } from '@google-cloud/tasks';
import { defineSecret } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { REGION, TASKS_LOCATION, TASKS_QUEUE_NAME } from './config';
import { errorMessage } from './util';

const tasksClient = new CloudTasksClient();

/**
 * Shared secret checked by `sendSmsReminderTask` on every incoming request.
 * This is what stops anyone who finds the function's URL from triggering
 * arbitrary SMS sends - only Cloud Tasks (which we configure with this same
 * secret as a header below) can call it successfully.
 *
 * Set with: firebase functions:secrets:set TASK_QUEUE_SECRET
 */
export const taskSecret = defineSecret('TASK_QUEUE_SECRET');

function currentProjectId(): string {
  const id = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT;
  if (!id) {
    throw new Error('Unable to resolve the current GCP project id from the function environment.');
  }
  return id;
}

/**
 * Deterministic invoke URL for a 2nd-gen ("v2") HTTPS Cloud Function.
 * Firebase documents this classic `cloudfunctions.net` URL format as stable
 * for 2nd-gen functions in addition to the auto-generated Cloud Run URL, so
 * we can compute it here without needing to look anything up post-deploy.
 */
function reminderTaskUrl(): string {
  return `https://${REGION}-${currentProjectId()}.cloudfunctions.net/sendSmsReminderTask`;
}

/**
 * Schedules a one-shot Cloud Task that will POST to `sendSmsReminderTask`
 * at (approximately) `scheduleTime`. This is what makes the reminder fire
 * even if the Flutter app - or the device it's on - is completely closed:
 * the task lives in Cloud Tasks infrastructure, independent of any client.
 *
 * Deliberately does not set an explicit task name: Cloud Tasks refuses to
 * reuse a name for up to an hour after a task with that name was deleted,
 * which would break the reschedule-on-edit flow. Letting Cloud Tasks
 * auto-generate a unique id sidesteps that entirely; we just persist the
 * returned name on the appointment doc for later cancellation.
 */
export async function scheduleReminderTask(appointmentId: string, scheduleTime: Date): Promise<string> {
  const parent = tasksClient.queuePath(currentProjectId(), TASKS_LOCATION, TASKS_QUEUE_NAME);
  const body = Buffer.from(JSON.stringify({ appointmentId })).toString('base64');

  const [response] = await tasksClient.createTask({
    parent,
    task: {
      httpRequest: {
        httpMethod: 'POST',
        url: reminderTaskUrl(),
        headers: {
          'Content-Type': 'application/json',
          'X-Task-Secret': taskSecret.value(),
        },
        body,
      },
      scheduleTime: { seconds: Math.floor(scheduleTime.getTime() / 1000) },
    },
  });

  if (!response.name) {
    throw new Error('Cloud Tasks did not return a task name for the newly created reminder task.');
  }
  return response.name;
}

/**
 * Cancels a previously scheduled reminder task. Safe to call with a task
 * that has already fired or was already deleted - Cloud Tasks returns
 * NOT_FOUND (gRPC code 5) in that case, which is treated as a no-op here
 * rather than an error, since "the task is gone" is exactly what we want.
 */
export async function cancelReminderTask(taskName: string | null | undefined): Promise<void> {
  if (!taskName) return;
  try {
    await tasksClient.deleteTask({ name: taskName });
  } catch (error) {
    const code = (error as { code?: number }).code;
    if (code === 5) return; // NOT_FOUND - already fired or already cancelled.
    logger.error('Failed to cancel reminder task', { taskName, reason: errorMessage(error) });
    throw error;
  }
}
