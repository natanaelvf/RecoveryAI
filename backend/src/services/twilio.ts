import Twilio from 'twilio';
import { env } from '../config/env';
import { supabase } from '../config/supabase';
import { Contractor } from '../types';

const twilioClient = Twilio(env.twilioAccountSid, env.twilioAuthToken);

const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 500;

/**
 * Check if a Twilio error is transient and worth retrying.
 */
function isTransientError(err: unknown): boolean {
  if (err && typeof err === 'object' && 'status' in err) {
    const status = (err as { status: number }).status;
    return status === 429 || status >= 500;
  }
  return false;
}

/**
 * Sleep for the given number of milliseconds.
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Send an SMS via Twilio with cap enforcement and retry logic.
 * Throws 'SMS_CAP_REACHED' if the contractor has exceeded their monthly limit.
 */
export async function sendSms(
  to: string,
  from: string,
  body: string
): Promise<string> {
  // Look up contractor by Twilio number to check SMS cap
  const { data: contractor } = await supabase
    .from('contractors')
    .select('id, sms_used_this_month, monthly_sms_cap')
    .eq('twilio_phone_number', from)
    .single();

  if (contractor && contractor.sms_used_this_month >= contractor.monthly_sms_cap) {
    console.warn(
      `[twilio] SMS cap reached for contractor ${contractor.id}: ${contractor.sms_used_this_month}/${contractor.monthly_sms_cap}`
    );
    throw new Error('SMS_CAP_REACHED');
  }

  // Send with retry on transient errors
  let lastError: unknown;
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      const message = await twilioClient.messages.create({ to, from, body });

      // Increment SMS counter after successful send
      if (contractor) {
        await supabase
          .from('contractors')
          .update({
            sms_used_this_month: contractor.sms_used_this_month + 1,
          })
          .eq('id', contractor.id);
      }

      return message.sid;
    } catch (err) {
      lastError = err;
      if (attempt < MAX_RETRIES && isTransientError(err)) {
        const delay = RETRY_DELAY_MS * Math.pow(2, attempt);
        console.warn(`[twilio] Transient error on attempt ${attempt + 1}, retrying in ${delay}ms...`);
        await sleep(delay);
      } else {
        break;
      }
    }
  }

  throw lastError;
}

/**
 * Look up the contractor who owns a given Twilio phone number.
 */
export async function lookupContractorByTwilioNumber(
  phoneNumber: string
): Promise<Contractor | null> {
  const { data, error } = await supabase
    .from('contractors')
    .select('*')
    .eq('twilio_phone_number', phoneNumber)
    .single();

  if (error || !data) {
    return null;
  }

  return data as Contractor;
}

