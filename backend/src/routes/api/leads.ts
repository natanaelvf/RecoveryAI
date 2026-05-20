import { Router, Request, Response } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { supabase } from '../../config/supabase';
import { LeadStatus } from '../../types';

const router = Router();

router.use(authMiddleware);

/**
 * GET / — List leads for the authenticated contractor.
 * Query params: status, page (1-based), limit (default 20)
 */
router.get('/', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;
  const status = req.query.status as string | undefined;
  const page = Math.max(1, parseInt(req.query.page as string, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit as string, 10) || 20));
  const offset = (page - 1) * limit;

  try {
    let query = supabase
      .from('leads')
      .select('*', { count: 'exact' })
      .eq('contractor_id', contractorId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (status) {
      query = query.eq('status', status);
    }

    const { data, count, error } = await query;

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json({
      leads: data,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch leads' });
  }
});

/**
 * GET /:id — Get a single lead with its messages.
 */
router.get('/:id', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;
  const leadId = req.params.id;

  try {
    const { data: lead, error: leadError } = await supabase
      .from('leads')
      .select('*')
      .eq('id', leadId)
      .eq('contractor_id', contractorId)
      .single();

    if (leadError || !lead) {
      res.status(404).json({ error: 'Lead not found' });
      return;
    }

    const { data: messages } = await supabase
      .from('messages')
      .select('*')
      .eq('lead_id', leadId)
      .order('sent_at', { ascending: true });

    res.json({ lead, messages: messages || [] });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch lead' });
  }
});

/**
 * PATCH /:id — Update lead fields (status, estimated_value, notes).
 * Handles mark-complete logic: schedules satisfaction follow-up.
 */
router.patch('/:id', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;
  const leadId = req.params.id;
  const { status, estimated_value } = req.body as {
    status?: LeadStatus;
    estimated_value?: number;
  };

  try {
    // Verify ownership
    const { data: existing, error: findError } = await supabase
      .from('leads')
      .select('id, status')
      .eq('id', leadId)
      .eq('contractor_id', contractorId)
      .single();

    if (findError || !existing) {
      res.status(404).json({ error: 'Lead not found' });
      return;
    }

    const updates: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };

    if (status !== undefined) updates.status = status;
    if (estimated_value !== undefined) updates.estimated_value = estimated_value;

    const { data: updated, error: updateError } = await supabase
      .from('leads')
      .update(updates)
      .eq('id', leadId)
      .select('*')
      .single();

    if (updateError) {
      res.status(500).json({ error: updateError.message });
      return;
    }

    // If marking as completed, schedule satisfaction follow-up in 24h
    if (status === LeadStatus.Completed) {
      const followupTime = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
      await supabase.from('scheduled_tasks').insert({
        lead_id: leadId,
        task_type: 'satisfaction_followup',
        execute_at: followupTime,
        executed: false,
      });
    }

    res.json({ lead: updated });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update lead' });
  }
});

/**
 * DELETE /:id/gdpr — Full GDPR deletion of a lead and all related data.
 */
router.delete('/:id/gdpr', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;
  const leadId = req.params.id;

  try {
    // Verify ownership
    const { data: lead, error } = await supabase
      .from('leads')
      .select('id')
      .eq('id', leadId)
      .eq('contractor_id', contractorId)
      .single();

    if (error || !lead) {
      res.status(404).json({ error: 'Lead not found' });
      return;
    }

    // Delete messages
    await supabase.from('messages').delete().eq('lead_id', leadId);

    // Delete scheduled tasks
    await supabase.from('scheduled_tasks').delete().eq('lead_id', leadId);

    // Delete the lead
    await supabase.from('leads').delete().eq('id', leadId);

    res.json({ deleted: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete lead data' });
  }
});

export default router;
