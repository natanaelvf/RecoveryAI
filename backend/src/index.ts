import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cron from 'node-cron';
import { env } from './config/env';

// --- Route imports ---
import twilioVoiceWebhook from './routes/webhooks/twilio-voice';
import twilioSmsWebhook from './routes/webhooks/twilio-sms';
import calendlyWebhook from './routes/webhooks/calendly';
import leadsApi from './routes/api/leads';
import statsApi from './routes/api/stats';
import contractorApi from './routes/api/contractor';

// --- Cron job imports ---
import { runDnrCheck } from './jobs/dnr-check';
import { runSatisfactionFollowup } from './jobs/satisfaction-followup';
import { runDataRetention } from './jobs/data-retention';

const app = express();

// --- Middleware ---
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Twilio sends form-encoded

// --- Health check ---
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// --- Webhook routes (no auth — validated by signature/Twilio) ---
app.use('/webhooks/twilio-voice', twilioVoiceWebhook);
app.use('/webhooks/twilio-sms', twilioSmsWebhook);
app.use('/webhooks/calendly', calendlyWebhook);

// --- API routes (auth required) ---
app.use('/api/leads', leadsApi);
app.use('/api/stats', statsApi);
app.use('/api/contractor', contractorApi);

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

// Data retention: daily at 3:00 AM
cron.schedule('0 3 * * *', () => {
  runDataRetention().catch((err) =>
    console.error('[cron] Data retention error:', err)
  );
});

// --- Start server ---
app.listen(env.port, () => {
  console.log(`🚀 Server running on port ${env.port}`);
  console.log(`   Health check: http://localhost:${env.port}/health`);
});

export default app;
