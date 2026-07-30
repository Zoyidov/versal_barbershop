import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { REGION } from './config';
import { requireAdmin } from './auth';
import { fetchSmsBalance, SmsGatewayError } from './smsGateway';

/**
 * Callable wrapper around devsms.uz's balance endpoint so the Flutter app
 * can show the shop's remaining SMS balance in Settings without ever
 * holding the devsms.uz bearer token itself. Admin-only: this is the shop's
 * shared prepaid balance, not any one barber's own `smsLimit`, so regular
 * barbers must never see it (enforced here, not just hidden in the UI).
 */
export const getSmsBalance = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);

  try {
    return await fetchSmsBalance();
  } catch (error) {
    if (error instanceof SmsGatewayError) {
      throw new HttpsError('unavailable', error.message);
    }
    throw new HttpsError('internal', 'SMS balansini olishda xatolik yuz berdi.');
  }
});
