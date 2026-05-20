import { Router, Request, Response } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { supabase } from '../../config/supabase';

const router = Router();

router.use(authMiddleware);

/** Fields allowed to be updated via PATCH /settings */
const UPDATABLE_FIELDS = [
  'business_name',
  'contact_name',
  'contact_email',
  'contact_phone',
  'calendly_url',
  'trade_type',
  'default_job_value',
  'urgency_threshold_urgent_min',
  'urgency_threshold_normal_min',
  'working_hours_start',
  'working_hours_end',
  'working_days',
  'after_hours_emergency_policy',
  'after_hours_ring',
  'timezone',
] as const;

/**
 * GET /settings — Return the authenticated contractor's settings.
 */
router.get('/settings', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;

  try {
    const { data, error } = await supabase
      .from('contractors')
      .select('*')
      .eq('id', contractorId)
      .single();

    if (error || !data) {
      res.status(404).json({ error: 'Contractor not found' });
      return;
    }

    res.json({ contractor: data });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch settings' });
  }
});

/**
 * PATCH /settings — Update contractor settings.
 * Only whitelisted fields are accepted.
 */
router.patch('/settings', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;
  const body = req.body as Record<string, unknown>;

  // Filter to only allowed fields
  const updates: Record<string, unknown> = {};
  for (const field of UPDATABLE_FIELDS) {
    if (body[field] !== undefined) {
      updates[field] = body[field];
    }
  }

  if (Object.keys(updates).length === 0) {
    res.status(400).json({ error: 'No valid fields to update' });
    return;
  }

  updates.updated_at = new Date().toISOString();

  try {
    const { data, error } = await supabase
      .from('contractors')
      .update(updates)
      .eq('id', contractorId)
      .select('*')
      .single();

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json({ contractor: data });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

export default router;
