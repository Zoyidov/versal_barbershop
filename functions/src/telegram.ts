import { defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { errorMessage } from './util';

/**
 * ============================================================================
 * TELEGRAM ADMIN NOTIFICATIONS
 * ============================================================================
 * Fired whenever a client books themselves in through the public booking
 * screen, so the shop finds out immediately without needing the app open.
 * Both the bot token and the admin chat ID list live in `functions/.env`
 * (added by the shop owner, not committed) - swap either without touching
 * code, then `cd functions && npm run deploy`.
 *
 * `TELEGRAM_ADMIN_CHAT_IDS` is a comma-separated list of Telegram numeric
 * chat IDs (there can be more than one admin/barber watching the bot).
 * ============================================================================
 */

export const telegramBotToken = defineString('TELEGRAM_BOT_TOKEN', { default: '' });
export const telegramAdminChatIds = defineString('TELEGRAM_ADMIN_CHAT_IDS', { default: '' });

/** Best-effort notify - logs and swallows failures so a Telegram outage
 * never blocks (or rolls back) a booking that already succeeded. */
export async function notifyAdmins(text: string): Promise<void> {
  const token = telegramBotToken.value();
  const chatIds = telegramAdminChatIds
    .value()
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);

  if (!token || chatIds.length === 0) {
    logger.warn('Telegram bot sozlanmagan (TELEGRAM_BOT_TOKEN / TELEGRAM_ADMIN_CHAT_IDS bo\'sh) - xabar yuborilmadi');
    return;
  }

  await Promise.all(
    chatIds.map(async (chatId) => {
      try {
        const response = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ chat_id: chatId, text }),
        });
        if (!response.ok) {
          logger.error('Telegram xabari yuborilmadi', { chatId, status: response.status, body: await response.text() });
        }
      } catch (error) {
        logger.error('Telegram xabarini yuborishda xatolik', { chatId, reason: errorMessage(error) });
      }
    }),
  );
}
