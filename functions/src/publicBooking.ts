import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { REGION } from './config';
import { sendPushToUser } from './notifications';
import { notifyAdmins } from './telegram';
import type { AppointmentDoc, SettingsDoc, UserDoc } from './types';

const db = getFirestore();

/** True for any account a client is allowed to book - a barber, or an
 * admin who also personally takes clients (the original pre-multi-barber
 * account, still attributed most of the shop's history - see
 * scripts/setAdmin.js). Every other role (none currently exist) is not
 * bookable. */
function isBookableRole(role: string): boolean {
  return role === 'barber' || role === 'admin';
}

/** Confirms `barberId` is an account an anonymous client is actually
 * allowed to book - a barber or admin, approved and not disabled - so
 * this never trusts a client-supplied uid at face value. Returns the doc
 * so callers that already need it (createPublicBooking) don't re-fetch.
 *
 * Deliberately does NOT check `smsLimit` here: that field only meters the
 * automated reminder SMS (see reserveSmsCredit in smsReminderTask.ts,
 * which already degrades gracefully - `smsStatus: 'limit_exceeded'` -
 * without touching the appointment itself). Gating real customer bookings
 * on it too was tried and reverted: with every barber still at their
 * default `smsLimit: 0` before an admin tops them up, it made the entire
 * public booking page (and every barber in it) disappear behind a
 * confusing "no barbers available" error - see chat history. */
async function requireBookableBarber(barberId: string): Promise<UserDoc> {
  const snap = await db.collection('users').doc(barberId).get();
  const user = snap.data() as UserDoc | undefined;
  if (!user || !isBookableRole(user.role) || !user.approved || !user.active) {
    throw new HttpsError('failed-precondition', 'Bu sartarosh hozircha mavjud emas.');
  }
  return user;
}

/**
 * Public (unauthenticated) read of the barbers/admin clients can pick
 * from. Only ever exposes `uid`/`name` - never phone/password/role/limit
 * fields, which is why this goes through Admin SDK (the `users`
 * collection itself is locked to self-reads by firestore.rules).
 *
 * No `where('role', ...)` filter here (role can't be queried as
 * "barber or admin" in one equality where) - the doc count is small
 * enough (one shop's staff) that filtering the two roles in memory is
 * simpler than two merged queries.
 */
export const getPublicBarbers = onCall({ region: REGION }, async () => {
  const snapshot = await db.collection('users').where('approved', '==', true).where('active', '==', true).get();

  const barbers = snapshot.docs
    .map((doc) => ({ uid: doc.id, user: doc.data() as UserDoc }))
    .filter(({ user }) => isBookableRole(user.role))
    // The admin is usually the shop owner personally cutting hair, so
    // they're listed first; everyone else keeps Firestore's return order.
    .sort((a, b) => (a.user.role === 'admin' ? 0 : 1) - (b.user.role === 'admin' ? 0 : 1))
    .map(({ uid, user }) => ({ uid, name: user.name }));

  return { barbers };
});

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

/** Prefers the barber's own working hours (`users/{barberId}`) and falls
 * back to the shop-wide default (`settings/global`) when the barber hasn't
 * set personal hours yet, so per-barber schedules work without forcing a
 * migration for every existing account. */
async function getScheduleHours(barber?: UserDoc): Promise<{ startHour: number; endHour: number }> {
  let startHour = barber?.scheduleStartHour;
  let endHour = barber?.scheduleEndHour;

  if (startHour === undefined || endHour === undefined) {
    const snap = await db.collection('settings').doc('global').get();
    const data = snap.data() as (SettingsDoc & { scheduleStartHour?: number; scheduleEndHour?: number }) | undefined;
    startHour ??= data?.scheduleStartHour ?? 6;
    endHour ??= data?.scheduleEndHour ?? 20;
  }

  return { startHour, endHour: endHour > startHour ? endHour : startHour + 1 };
}

interface DaySlotsRequest {
  year?: number;
  month?: number;
  day?: number;
  barberId?: string;
}

/**
 * Public (unauthenticated) read of one day's free/busy hourly slots for a
 * specific barber, for the client-facing booking screen. Never exposes any
 * client's name/phone - only which hours are already taken - so it's safe
 * to leave open to anyone, unlike the `appointments` collection itself
 * (locked to signed-in barbers by firestore.rules).
 */
export const getPublicDaySlots = onCall({ region: REGION }, async (request) => {
  const { year, month, day, barberId } = (request.data ?? {}) as DaySlotsRequest;
  if (!year || !month || !day || !barberId) {
    throw new HttpsError('invalid-argument', 'Sana yoki sartarosh noto\'g\'ri.');
  }
  const barber = await requireBookableBarber(barberId);

  const { startHour, endHour } = await getScheduleHours(barber);
  const dayStartMs = localHourStartUtcMs(year, month, day, 0);
  const dayEndMs = dayStartMs + 24 * 3_600_000;

  const snapshot = await db
    .collection('appointments')
    .where('barberId', '==', barberId)
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
  barberId?: string;
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
  const { year, month, day, hour, clientName, clientPhone, barberId } = (request.data ?? {}) as CreateBookingRequest;
  if (!year || !month || !day || hour === undefined || hour === null || !barberId) {
    throw new HttpsError('invalid-argument', 'Sana, vaqt yoki sartarosh noto\'g\'ri.');
  }
  const barber = await requireBookableBarber(barberId);

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

  const { startHour, endHour } = await getScheduleHours(barber);
  if (hour < startHour || hour >= endHour) {
    throw new HttpsError('out-of-range', 'Bu vaqt ish jadvalidan tashqarida.');
  }

  const slotStartMs = localHourStartUtcMs(year, month, day, hour);
  if (slotStartMs <= Date.now()) {
    throw new HttpsError('failed-precondition', 'Bu vaqt allaqachon o\'tib ketgan.');
  }

  const appointmentsRef = db.collection('appointments');
  const hourQuery = appointmentsRef
    .where('barberId', '==', barberId)
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
        barberId,
        appointmentTime: Timestamp.fromMillis(slotStartMs),
        status: 'scheduled',
        sendSms: true,
        smsSent: false,
        smsSentAt: null,
        smsStatus: null,
        reminderTaskName: null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: barberId,
      };
      tx.set(ref, doc);
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', 'Band qilishda xatolik yuz berdi.');
  }

  const dateLabel = `${String(day).padStart(2, '0')}.${String(month).padStart(2, '0')}.${year}`;
  const timeLabel = `${String(hour).padStart(2, '0')}:00`;
  await Promise.all([
    notifyAdmins(`🆕 Yangi band qilish!\n👤 ${name}\n📞 ${phone}\n📅 ${dateLabel}, ${timeLabel}`),
    sendPushToUser(barberId, {
      title: 'Yangi band qilish!',
      body: `${name} - ${dateLabel}, ${timeLabel}`,
      data: { type: 'booking', barberId },
    }),
  ]);

  return { success: true };
});
