import * as admin from 'firebase-admin';
import { env } from '../config/env';
import { supabase } from '../config/supabase';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const serviceAccount = require(env.firebaseServiceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

/**
 * Send a push notification to a contractor's device(s) via Firebase Cloud Messaging.
 */
export async function sendPushNotification(
  contractorId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  // TODO: Look up the contractor's FCM token(s) from a `devices` table or contractor record
  const { data: contractor, error } = await supabase
    .from('contractors')
    .select('id')
    .eq('id', contractorId)
    .single();

  if (error || !contractor) {
    console.error(`Contractor ${contractorId} not found for push notification`);
    return;
  }

  // TODO: Replace with actual FCM token lookup
  const fcmToken: string | null = null; // placeholder

  if (!fcmToken) {
    console.warn(`No FCM token found for contractor ${contractorId}, skipping push`);
    return;
  }

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: data || {},
    });
  } catch (err) {
    console.error(`Failed to send push notification to contractor ${contractorId}:`, err);
  }
}
