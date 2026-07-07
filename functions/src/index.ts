import { initializeApp } from 'firebase-admin/app';

// Must run before any other module in this project calls getFirestore()/
// getAuth() at module-load time - every export below is require()'d (and
// therefore evaluated) only once its `export ... from` line is reached,
// which is after this call.
initializeApp();

export { loginWithPhonePassword } from './auth';
export { onAppointmentCreated, onAppointmentUpdated } from './appointmentTriggers';
export { onGlobalSettingsUpdated } from './settingsTriggers';
export { sendSmsReminderTask } from './smsReminderTask';
