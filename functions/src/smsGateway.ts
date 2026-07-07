import { defineString } from 'firebase-functions/params';

/**
 * ============================================================================
 * devsms.uz INTEGRATION POINT
 * ============================================================================
 * This is the *only* file in the backend that talks to the devsms.uz SMS
 * gateway (https://devsms.uz/api/send_sms.php). Every caller only depends
 * on `sendReminderSms`'s signature, so if devsms.uz's contract ever changes
 * again, this is the one file that needs updating.
 *
 * The token and the SMS wording both live in `functions/.env` (see that
 * file) so you can swap either one yourself - new token, newly-approved
 * template - without touching any code. Just edit `.env` and redeploy:
 *   cd functions && npm run deploy
 * ============================================================================
 */

export const devsmsApiUrl = defineString('DEVSMS_API_URL', {
  default: 'https://devsms.uz/api/send_sms.php',
});

export const devsmsApiToken = defineString('DEVSMS_API_TOKEN');

export const devsmsSmsTemplate = defineString('DEVSMS_SMS_TEMPLATE', {
  default: 'Assalomu alaykum{name}! Eslatma: bugun soat {time} da sartaroshxonada uchrashuvingiz bor. Kutib qolamiz!',
});

export class SmsGatewayError extends Error {}

interface DevSmsResponse {
  success: boolean;
  message?: string;
  data?: {
    sms_id?: number;
    request_id?: string;
    status?: string;
  };
}

export async function sendReminderSms(phoneNumber: string, message: string): Promise<void> {
  const url = devsmsApiUrl.value();

  // devsms.uz expects a bare national/international number with no leading
  // "+" (e.g. 998901234567), while the rest of the app stores phone numbers
  // as +998XXXXXXXXX (E.164) - strip the plus only at this boundary.
  const phone = phoneNumber.replace(/^\+/, '');

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${devsmsApiToken.value()}`,
    },
    body: JSON.stringify({
      phone,
      message,
    }),
  });

  const rawBody = await response.text();
  let parsed: DevSmsResponse | null = null;
  try {
    parsed = JSON.parse(rawBody) as DevSmsResponse;
  } catch {
    // Fall through - parsed stays null, handled below.
  }

  if (!response.ok || !parsed || !parsed.success) {
    const detail = parsed?.message ?? rawBody;
    throw new SmsGatewayError(`devsms.uz request failed (HTTP ${response.status}): ${detail}`);
  }
}
