import type { Timestamp } from 'firebase-admin/firestore';

export type AppointmentStatus = 'scheduled' | 'cancelled' | 'completed';
export type SmsStatus = 'sent' | 'failed' | null;

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

/** Mirrors `settings/global` — shop-wide configuration. */
export interface SettingsDoc {
  reminderWindowMinutes: number;
  shopName: string;
}

/** Mirrors `users/{uid}` — barber accounts. Never sent to the client. */
export interface UserDoc {
  phoneNumber: string;
  passwordHash: string;
  passwordSalt: string;
  name: string;
  role: string;
  active: boolean;
}
