/**
 * Central configuration constants shared across the backend. Keeping the
 * region/queue names here means every trigger and the Cloud Tasks client
 * agree on the same deployment target without repeating string literals.
 */

/** Region every function and the Cloud Tasks queue are deployed to. Must
 * match the region the Flutter app targets via
 * `FirebaseFunctions.instanceFor(region: ...)`. */
export const REGION = 'us-central1';

/** Cloud Tasks queue location. Cloud Tasks queues are regional, so this
 * matches REGION here, but is kept separate in case they ever diverge. */
export const TASKS_LOCATION = 'us-central1';

/** Name of the Cloud Tasks queue used for SMS reminders. Must be created
 * once via `gcloud tasks queues create sms-reminders --location=us-central1`
 * before first deploy (see the setup guide). */
export const TASKS_QUEUE_NAME = 'sms-reminders';

/** Fallback reminder window when `settings/global` has no value set yet. */
export const DEFAULT_REMINDER_WINDOW_MINUTES = 40;
