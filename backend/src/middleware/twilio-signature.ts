import { Request, Response, NextFunction } from 'express';
import Twilio from 'twilio';
import { env } from '../config/env';

/**
 * Express middleware that validates the X-Twilio-Signature header.
 * Rejects requests with invalid signatures with 403.
 *
 * This ensures only genuine Twilio requests reach the voice/SMS webhooks.
 */
export function twilioSignatureMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const signature = req.headers['x-twilio-signature'] as string;

  if (!signature) {
    console.warn('[twilio-auth] Missing X-Twilio-Signature header');
    res.status(403).json({ error: 'Missing Twilio signature' });
    return;
  }

  // Build the full URL that Twilio used when signing
  const protocol = req.headers['x-forwarded-proto'] || req.protocol;
  const host = req.headers['host'] || '';
  const url = `${protocol}://${host}${req.originalUrl}`;

  const isValid = Twilio.validateRequest(
    env.twilioAuthToken,
    signature,
    url,
    req.body || {}
  );

  if (!isValid) {
    console.warn(`[twilio-auth] Invalid signature for ${req.originalUrl}`);
    res.status(403).json({ error: 'Invalid Twilio signature' });
    return;
  }

  next();
}
