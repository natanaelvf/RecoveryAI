import rateLimit from 'express-rate-limit';

/**
 * Rate limiter for API routes.
 * 100 requests per 15 minutes per IP.
 */
export const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,    // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false,     // Disable `X-RateLimit-*` headers
  message: { error: 'Too many requests, please try again later.' },
});

/**
 * Rate limiter for webhook routes (Twilio, Calendly).
 * Higher limit since these are server-to-server calls.
 * 500 requests per 15 minutes per IP.
 */
export const webhookRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 500,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many webhook requests.' },
});
