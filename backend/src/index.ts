import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cron from 'node-cron';
import { env } from './config/env';

// --- Route imports ---
import twilioVoiceWebhook from './routes/webhooks/twilio-voice';
import twilioSmsWebhook from './routes/webhooks/twilio-sms';
import calendlyWebhook from './routes/webhooks/calendly';
import deviceTokenRoute from './routes/api/device-token';

// --- Middleware imports ---
import { twilioSignatureMiddleware } from './middleware/twilio-signature';
import { authMiddleware } from './middleware/auth';
import { apiRateLimiter, webhookRateLimiter } from './middleware/rate-limit';

// --- Cron job imports ---
import { runDnrCheck } from './jobs/dnr-check';
import { runSatisfactionFollowup } from './jobs/satisfaction-followup';
import { runDataRetention } from './jobs/data-retention';
import { runConsentTimeout } from './jobs/consent-timeout';
import { runSmsReset } from './jobs/sms-reset';

const app = express();

// Trust Fly.io's reverse proxy so express-rate-limit reads the correct client IP
// from X-Forwarded-For instead of throwing ERR_ERL_UNEXPECTED_X_FORWARDED_FOR.
app.set('trust proxy', 1);

// --- Middleware ---
app.use(helmet());

// Fix #9: Restrict CORS to specific origins (mobile app doesn't need CORS,
// but keep it ready for a future web dashboard)
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || false, // Disabled by default; set CORS_ORIGIN env var for web dashboard
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Parse JSON with raw body capture for webhook signature verification.
// The verify callback stores the raw buffer on req.rawBody so that
// Calendly signature verification uses the exact original payload.
app.use(
  express.json({
    verify: (req: express.Request, _res, buf) => {
      (req as express.Request & { rawBody?: string }).rawBody = buf.toString('utf-8');
    },
  })
);
app.use(express.urlencoded({ extended: true })); // Twilio sends form-encoded

// --- Static files (for voicemails) ---
app.use('/audio', express.static('public/audio'));

// --- Health check ---
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// --- API routes (authenticated + rate limited) ---
app.use('/api', apiRateLimiter, authMiddleware, deviceTokenRoute);

// --- Webhook routes (validated by signature + rate limited) ---
// Fix #7: Apply Twilio signature validation to Twilio webhook routes
app.use('/webhooks/twilio-voice', webhookRateLimiter, twilioSignatureMiddleware, twilioVoiceWebhook);
app.use('/webhooks/twilio-sms', webhookRateLimiter, twilioSignatureMiddleware, twilioSmsWebhook);
app.use('/webhooks/calendly', webhookRateLimiter, calendlyWebhook);

// --- Cron jobs ---
// DNR check: every 15 minutes
cron.schedule('*/15 * * * *', () => {
  runDnrCheck().catch((err) => console.error('[cron] DNR check error:', err));
});

// Satisfaction follow-up: every 30 minutes
cron.schedule('*/30 * * * *', () => {
  runSatisfactionFollowup().catch((err) =>
    console.error('[cron] Satisfaction followup error:', err)
  );
});

// Consent timeout: every 5 minutes (fix #20)
cron.schedule('*/5 * * * *', () => {
  runConsentTimeout().catch((err) =>
    console.error('[cron] Consent timeout error:', err)
  );
});

// Data retention: daily at 3:00 AM
cron.schedule('0 3 * * *', () => {
  runDataRetention().catch((err) =>
    console.error('[cron] Data retention error:', err)
  );
});

// Monthly SMS reset: 1st of each month at midnight
cron.schedule('0 0 1 * *', () => {
  runSmsReset().catch((err) =>
    console.error('[cron] SMS reset error:', err)
  );
});

// --- Start server ---
app.listen(env.port, () => {
  console.log(`🚀 Server running on port ${env.port}`);
  console.log(`   Health check: http://localhost:${env.port}/health`);
});

export default app;
