import type { Timestamp } from 'firebase-admin/firestore';

export type AppointmentStatus = 'scheduled' | 'cancelled' | 'completed';
export type SmsStatus = 'sent' | 'failed' | 'limit_exceeded' | null;

/** Mirrors `appointments/{id}` — keep in sync with the Dart AppointmentModel. */
export interface AppointmentDoc {
  clientPhone: string;
  clientName: string | null;
  serviceType: string | null;
  barberId: string;
  appointmentTime: Timestamp;
  status: AppointmentStatus;
  sendSms: boolean;
  smsSent: boolean;
  smsSentAt: Timestamp | null;
  smsStatus: SmsStatus;
  reminderTaskName: string | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}

/** Mirrors `clients/{phoneNumber}` — lifetime aggregate per client. */
export interface ClientDoc {
  phoneNumber: string;
  lastName: string | null;
  totalVisits: number;
  totalCancellations: number;
  updatedAt: Timestamp;
}

/** Mirrors `settings/global` — shop-wide configuration.
 * `scheduleStartHour`/`scheduleEndHour` are written directly by the Flutter
 * client (`settings_remote_data_source.dart`) and read here only by
 * `publicBooking.ts` - optional because older docs may predate them. */
export interface SettingsDoc {
  reminderWindowMinutes: number;
  shopName: string;
  scheduleStartHour?: number;
  scheduleEndHour?: number;
}

/** Mirrors `users/{uid}` — barber accounts. Never sent to the client. */
export interface UserDoc {
  phoneNumber: string;
  passwordHash: string;
  passwordSalt: string;
  name: string;
  role: string;
  active: boolean;
  /** Set by an admin via `approveBarber`. New registrations start `false`. */
  approved: boolean;
  /** Remaining SMS credits; decremented on each successful send. Ignored for `role === 'admin'`.
   * Also gates new bookings: a barber (never an admin) with `smsLimit <= 0` cannot be booked into,
   * client-side or via `createPublicBooking` - see firestore.rules and publicBooking.ts. */
  smsLimit: number;
  /** This barber's own working hours, shown/edited from their profile and used instead of
   * `settings/global`'s shop-wide `scheduleStartHour`/`scheduleEndHour` once set. Optional because
   * most barbers predate this field and fall back to the shop default until they set their own. */
  scheduleStartHour?: number;
  scheduleEndHour?: number;
  /** FCM device tokens this account is signed in on (one app install can
   * register several over time - old device, new device, reinstall - so
   * this is a list, pruned by notifications.ts whenever FCM reports a
   * token as dead). Written by the client via `fcmTokens` self-update
   * (see firestore.rules); read only by notifications.ts. */
  fcmTokens?: string[];
  createdAt?: Timestamp;
}
