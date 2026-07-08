import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { REGION } from './config';
import { fetchSmsBalance, SmsGatewayError } from './smsGateway';

/**
 * Callable wrapper around devsms.uz's balance endpoint so the Flutter app
 * can show the shop's remaining SMS balance in Settings without ever
 * holding the devsms.uz bearer token itself.
 */
export const getSmsBalance = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sessiya muddati tugagan. Iltimos, qayta kiring.');
  }

  try {
    return await fetchSmsBalance();
  } catch (error) {
    if (error instanceof SmsGatewayError) {
      throw new HttpsError('unavailable', error.message);
    }
    throw new HttpsError('internal', 'SMS balansini olishda xatolik yuz berdi.');
  }
});
