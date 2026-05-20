import Twilio from 'twilio';
import { env } from '../config/env';
import { supabase } from '../config/supabase';
import { Contractor } from '../types';

const twilioClient = Twilio(env.twilioAccountSid, env.twilioAuthToken);

/**
 * Send an SMS via Twilio.
 */
export async function sendSms(
  to: string,
  from: string,
  body: string
): Promise<string> {
  const message = await twilioClient.messages.create({ to, from, body });
  return message.sid;
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
