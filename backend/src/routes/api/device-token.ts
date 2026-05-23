import { Router, Request, Response } from 'express';
import { supabase } from '../../config/supabase';

const router = Router();

/**
 * POST /api/device-token
 *
 * Register or update the contractor's FCM device token.
 * Called by the Flutter app after login and on token refresh.
 *
 * Body: { token: string }
 * Auth: Bearer token (Supabase JWT) — handled by authMiddleware
 */
router.post('/device-token', async (req: Request, res: Response) => {
  const contractorId = req.contractorId;
  if (!contractorId) {
    res.status(401).json({ error: 'Not authenticated' });
    return;
  }

  const { token } = req.body as { token?: string };

  if (!token || typeof token !== 'string' || token.trim().length === 0) {
    res.status(400).json({ error: 'Missing or invalid "token" in request body' });
    return;
  }

  try {
    const { error } = await supabase
      .from('contractors')
      .update({
        fcm_token: token.trim(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', contractorId);

    if (error) {
      console.error(`[api] Failed to update FCM token for ${contractorId}:`, error.message);
      res.status(500).json({ error: 'Failed to update device token' });
      return;
    }

    console.log(`[api] FCM token updated for contractor ${contractorId}`);
    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('[api] Device token update error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * DELETE /api/device-token
 *
 * Clear the contractor's FCM device token (e.g. on logout).
 */
router.delete('/device-token', async (req: Request, res: Response) => {
  const contractorId = req.contractorId;
  if (!contractorId) {
    res.status(401).json({ error: 'Not authenticated' });
    return;
  }

  try {
    await supabase
      .from('contractors')
      .update({
        fcm_token: null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', contractorId);

    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('[api] Device token clear error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
