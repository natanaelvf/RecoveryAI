import * as admin from 'firebase-admin';
import { env } from '../config/env';
import { supabase } from '../config/supabase';

// ---------------------------------------------------------------------------
// Firebase Admin SDK — graceful initialization
// If the service account file is missing, push notifications are disabled
// but the rest of the backend continues to work.
// ---------------------------------------------------------------------------

let firebaseInitialized = false;

try {
  if (!admin.apps.length && env.firebaseServiceAccountPath) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const serviceAccount = require(env.firebaseServiceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseInitialized = true;
    console.log('[fcm] Firebase Admin SDK initialized');
  } else if (admin.apps.length) {
    firebaseInitialized = true;
  }
} catch (err) {
  console.warn(
    `[fcm] Firebase not initialized — push notifications disabled. ` +
    `Reason: ${err instanceof Error ? err.message : String(err)}`
  );
}

/**
 * Send a push notification to a contractor's device(s) via Firebase Cloud Messaging.
 *
 * Reads the contractor's FCM token from the `fcm_token` column.
 * If Firebase is not initialized or no token is stored, logs a warning and returns.
 */
export async function sendPushNotification(
  contractorId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  if (!firebaseInitialized) {
    console.warn(`[fcm] Skipping push for contractor ${contractorId} — Firebase not initialized`);
    return;
  }

  // Look up the contractor's FCM token
  const { data: contractor, error } = await supabase
    .from('contractors')
    .select('id, fcm_token')
    .eq('id', contractorId)
    .single();

  if (error || !contractor) {
    console.error(`[fcm] Contractor ${contractorId} not found for push notification`);
    return;
  }

  const fcmToken: string | null = contractor.fcm_token || null;

  if (!fcmToken) {
    console.warn(`[fcm] No FCM token for contractor ${contractorId}, skipping push`);
    return;
  }

  try {
    // Determine if this is an urgent/emergency notification
    const isUrgent = data?.priority === 'high';

    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: data || {},
      android: {
        priority: 'high',
        notification: isUrgent
          ? {
              // Urgent channel: louder alarm-style sound, bypasses DND
              channelId: 'urgent_leads',
              sound: 'urgent_alarm',
              defaultVibrateTimings: false,
              vibrateTimingsMillis: ['0', '500', '200', '500', '200', '500', '200', '500'],
              notificationCount: 1,
            }
          : {
              channelId: 'leads',
              sound: 'default',
            },
      },
    });
    console.log(`[fcm] Push sent to contractor ${contractorId}: "${title}" (urgent=${isUrgent})`);
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);

    // If the token is invalid/expired, clear it from the database
    if (
      errorMsg.includes('messaging/registration-token-not-registered') ||
      errorMsg.includes('messaging/invalid-registration-token')
    ) {
      console.warn(`[fcm] Stale token for contractor ${contractorId}, clearing`);
      await supabase
        .from('contractors')
        .update({ fcm_token: null })
        .eq('id', contractorId);
    }

    console.error(`[fcm] Failed to send push to contractor ${contractorId}:`, errorMsg);
  }
}
