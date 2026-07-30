import { getMessaging } from 'firebase-admin/messaging';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import type { UserDoc } from './types';
import { errorMessage } from './util';

const db = getFirestore();

interface PushPayload {
  title: string;
  body: string;
  /** Extra fields the Flutter side can read off the message (e.g. to
   * decide where to navigate on tap). Values must be strings - FCM's
   * `data` payload doesn't support other types. */
  data?: Record<string, string>;
  /** iOS badge count for this notification. Android has no equivalent
   * API here - most launchers derive their badge dot from the tray's
   * active notification count instead, which the OS handles on its own. */
  badge?: number;
}

/**
 * Sends a push notification to every device token registered for one
 * user (`users/{uid}.fcmTokens`). Best-effort: logs and swallows failures
 * so a push outage never blocks (or rolls back) the action that
 * triggered it - a booking, an approval, an SMS-limit top-up all already
 * succeeded in Firestore by the time this runs.
 */
export async function sendPushToUser(uid: string, payload: PushPayload): Promise<void> {
  const snap = await db.collection('users').doc(uid).get();
  const user = snap.data() as UserDoc | undefined;
  const tokens = user?.fcmTokens ?? [];
  if (tokens.length === 0) return;
  await sendToTokens(uid, tokens, payload);
}

/** Sends to every admin account's registered devices - used for events
 * only an admin acts on (a new registration pending approval). */
export async function sendPushToAdmins(payload: PushPayload): Promise<void> {
  const snapshot = await db.collection('users').where('role', '==', 'admin').get();
  await Promise.all(
    snapshot.docs.map((doc) => {
      const tokens = (doc.data() as UserDoc).fcmTokens ?? [];
      if (tokens.length === 0) return Promise.resolve();
      return sendToTokens(doc.id, tokens, payload);
    }),
  );
}

async function sendToTokens(uid: string, tokens: string[], payload: PushPayload): Promise<void> {
  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
      android: { priority: 'high', notification: { channelId: 'versal_default' } },
      apns: { payload: { aps: { badge: payload.badge ?? 1, sound: 'default' } } },
    });

    // A token FCM reports as unregistered/invalid is a dead device install
    // (uninstalled app, expired token, etc) - keep `fcmTokens` from growing
    // stale forever instead of re-attempting it on every future push.
    const deadTokens = response.responses
      .map((r, i) => ({ r, token: tokens[i] }))
      .filter(
        ({ r }) =>
          !r.success &&
          (r.error?.code === 'messaging/registration-token-not-registered' ||
            r.error?.code === 'messaging/invalid-registration-token'),
      )
      .map(({ token }) => token);

    if (deadTokens.length > 0) {
      await db
        .collection('users')
        .doc(uid)
        .update({ fcmTokens: FieldValue.arrayRemove(...deadTokens) });
    }
  } catch (error) {
    logger.error('Push xabarini yuborishda xatolik', { uid, reason: errorMessage(error) });
  }
}
