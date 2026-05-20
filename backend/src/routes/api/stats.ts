import { Router, Request, Response } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { supabase } from '../../config/supabase';
import { LeadStatus } from '../../types';

const router = Router();

router.use(authMiddleware);

/**
 * GET / — Return stats for the current month:
 * - recovered: leads that reached 'booked' or 'completed'
 * - totalValue: sum of estimated_value for recovered leads
 * - responseRate: percentage of non-'missed' and non-'no_consent' leads
 */
router.get('/', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;

  try {
    // Start of current month
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

    // All leads this month
    const { data: allLeads, error: allError } = await supabase
      .from('leads')
      .select('id, status, estimated_value')
      .eq('contractor_id', contractorId)
      .gte('created_at', monthStart);

    if (allError) {
      res.status(500).json({ error: allError.message });
      return;
    }

    const leads = allLeads || [];
    const total = leads.length;

    const recoveredStatuses: string[] = [
      LeadStatus.Booked,
      LeadStatus.Completed,
    ];

    const recovered = leads.filter((l) => recoveredStatuses.includes(l.status));
    const recoveredCount = recovered.length;
    const totalValue = recovered.reduce(
      (sum, l) => sum + (l.estimated_value || 0),
      0
    );

    const engaged = leads.filter(
      (l) => l.status !== LeadStatus.Missed && l.status !== LeadStatus.NoConsent
    );
    const responseRate = total > 0 ? Math.round((engaged.length / total) * 100) : 0;

    res.json({
      month: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
      recovered: recoveredCount,
      totalValue,
      responseRate,
      totalLeads: total,
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to compute stats' });
  }
});

export default router;
