import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { REGION } from './config';
import { notifyAdmins } from './telegram';
import type { AppointmentDoc, SettingsDoc } from './types';

const db = getFirestore();

/** Uzbekistan is a fixed UTC+5 offset year-round (no DST), and every
 * `appointmentTime` in this app is chosen by a barber/client thinking in
 * shop-local time. Cloud Functions run in an arbitrary (usually UTC)
 * runtime timezone, so day boundaries and "which hour is this" must be
 * computed by hand against UTC rather than via `Date#getHours()`. */
const SHOP_UTC_OFFSET_HOURS = 5;

function localHourStartUtcMs(year: number, month: number, day: number, hour: number): number {
  return Date.UTC(year, month - 1, day, 0, 0, 0) - SHOP_UTC_OFFSET_HOURS * 3_600_000 + hour * 3_600_000;
}

function localHourOf(date: Date): number {
  return (date.getUTCHours() + SHOP_UTC_OFFSET_HOURS) % 24;
}

async function getScheduleHours(): Promise<{ startHour: number; endHour: number }> {
  const snap = await db.collection('settings').doc('global').get();
  const data = snap.data() as (SettingsDoc & { scheduleStartHour?: number; scheduleEndHour?: number }) | undefined;
  const startHour = data?.scheduleStartHour ?? 6;
  const endHour = data?.scheduleEndHour ?? 20;
  return { startHour, endHour: endHour > startHour ? endHour : startHour + 1 };
}

interface DaySlotsRequest {
  year?: number;
  month?: number;
  day?: number;
}

/**
 * Public (unauthenticated) read of one day's free/busy hourly slots, for
 * the client-facing booking screen. Never exposes any client's name/phone -
 * only which hours are already taken - so it's safe to leave open to
 * anyone, unlike the `appointments` collection itself (locked to signed-in
 * barbers by firestore.rules).
 */
export const getPublicDaySlots = onCall({ region: REGION }, async (request) => {
  const { year, month, day } = (request.data ?? {}) as DaySlotsRequest;
  if (!year || !month || !day) {
    throw new HttpsError('invalid-argument', 'Sana noto\'g\'ri.');
  }

  const { startHour, endHour } = await getScheduleHours();
  const dayStartMs = localHourStartUtcMs(year, month, day, 0);
  const dayEndMs = dayStartMs + 24 * 3_600_000;

  const snapshot = await db
    .collection('appointments')
    .where('appointmentTime', '>=', Timestamp.fromMillis(dayStartMs))
    .where('appointmentTime', '<', Timestamp.fromMillis(dayEndMs))
    .get();

  const busyHours = new Set<number>();
  snapshot.docs.forEach((doc) => {
    const data = doc.data() as AppointmentDoc;
    if (data.status === 'cancelled') return;
    busyHours.add(localHourOf(data.appointmentTime.toDate()));
  });

  const nowMs = Date.now();
  const slots = [];
  for (let hour = startHour; hour < endHour; hour++) {
    slots.push({
      hour,
      isFree: !busyHours.has(hour),
      isPast: localHourStartUtcMs(year, month, day, hour) <= nowMs,
    });
  }

  return { startHour, endHour, slots };
});

interface CreateBookingRequest {
  year?: number;
  month?: number;
  day?: number;
  hour?: number;
  clientName?: string;
  clientPhone?: string;
}

/**
 * Public (unauthenticated) write that lets a client book themselves into
 * an open hourly slot from the booking screen. Goes through Admin SDK
 * (this function) rather than a direct Firestore write because
 * firestore.rules requires an authenticated barber for `appointments`
 * creates - there is no client-side path for an anonymous booking.
 *
 * Re-checks slot availability inside a transaction (a client's read of
 * `getPublicDaySlots` can be stale by the time they submit) and reuses the
 * exact `AppointmentDoc` shape the rest of the backend expects, so the
 * existing `onAppointmentCreated` trigger (SMS reminder scheduling,
 * `clients/{phone}` aggregate) picks it up with no special-casing.
 */
export const createPublicBooking = onCall({ region: REGION }, async (request) => {
  const { year, month, day, hour, clientName, clientPhone } = (request.data ?? {}) as CreateBookingRequest;
  if (!year || !month || !day || hour === undefined || hour === null) {
    throw new HttpsError('invalid-argument', 'Sana yoki vaqt noto\'g\'ri.');
  }

  const name = (clientName ?? '').trim();
  const phoneDigits = (clientPhone ?? '').replace(/\D/g, '');
  if (name.length < 2) {
    throw new HttpsError('invalid-argument', 'Ismingizni kiriting.');
  }
  const nineDigits = phoneDigits.length === 12 && phoneDigits.startsWith('998') ? phoneDigits.slice(3) : phoneDigits;
  if (nineDigits.length !== 9) {
    throw new HttpsError('invalid-argument', 'Telefon raqamingizni to\'g\'ri kiriting.');
  }
  const phone = `+998${nineDigits}`;

  const { startHour, endHour } = await getScheduleHours();
  if (hour < startHour || hour >= endHour) {
    throw new HttpsError('out-of-range', 'Bu vaqt ish jadvalidan tashqarida.');
  }

  const slotStartMs = localHourStartUtcMs(year, month, day, hour);
  if (slotStartMs <= Date.now()) {
    throw new HttpsError('failed-precondition', 'Bu vaqt allaqachon o\'tib ketgan.');
  }

  const appointmentsRef = db.collection('appointments');
  const hourQuery = appointmentsRef
    .where('appointmentTime', '>=', Timestamp.fromMillis(slotStartMs))
    .where('appointmentTime', '<', Timestamp.fromMillis(slotStartMs + 3_600_000));

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(hourQuery);
      const taken = snap.docs.some((d) => (d.data() as AppointmentDoc).status !== 'cancelled');
      if (taken) {
        throw new HttpsError('already-exists', 'Bu vaqt band qilindi. Boshqa vaqtni tanlang.');
      }

      const ref = appointmentsRef.doc();
      const doc: Omit<AppointmentDoc, 'createdAt' | 'updatedAt'> & { createdAt: FieldValue; updatedAt: FieldValue } = {
        clientPhone: phone,
        clientName: name,
        serviceType: null,
        barberId: 'public',
        appointmentTime: Timestamp.fromMillis(slotStartMs),
        status: 'scheduled',
        sendSms: true,
        smsSent: false,
        smsSentAt: null,
        smsStatus: null,
        reminderTaskName: null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: 'public',
      };
      tx.set(ref, doc);
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', 'Band qilishda xatolik yuz berdi.');
  }

  const dateLabel = `${String(day).padStart(2, '0')}.${String(month).padStart(2, '0')}.${year}`;
  const timeLabel = `${String(hour).padStart(2, '0')}:00`;
  await notifyAdmins(`🆕 Yangi band qilish!\n👤 ${name}\n📞 ${phone}\n📅 ${dateLabel}, ${timeLabel}`);

  return { success: true };
});
