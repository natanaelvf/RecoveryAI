import { Router, Request, Response } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { supabase } from '../../config/supabase';
import { LeadStatus } from '../../types';

const router = Router();

router.use(authMiddleware);

/**
 * Compute stats for a set of leads.
 */
function computeLeadStats(leads: Array<{ id: string; status: string; estimated_value: number | null }>) {
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

  return { recoveredCount, totalValue, responseRate, totalLeads: total };
}

/**
 * GET / — Return stats for the current and previous month:
 * - recovered: leads that reached 'booked' or 'completed'
 * - totalValue: sum of estimated_value for recovered leads
 * - responseRate: percentage of non-'missed' and non-'no_consent' leads
 */
router.get('/', async (req: Request, res: Response) => {
  const contractorId = req.contractorId!;

  try {
    const now = new Date();

    // Current month boundaries
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
    const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1).toISOString();

    // Previous month boundaries
    const prevMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString();
    const prevMonthEnd = monthStart;

    // Current month leads
    const { data: currentLeads, error: currentError } = await supabase
      .from('leads')
      .select('id, status, estimated_value')
      .eq('contractor_id', contractorId)
      .gte('created_at', monthStart)
      .lt('created_at', monthEnd);

    if (currentError) {
      res.status(500).json({ error: currentError.message });
      return;
    }

    // Previous month leads
    const { data: prevLeads, error: prevError } = await supabase
      .from('leads')
      .select('id, status, estimated_value')
      .eq('contractor_id', contractorId)
      .gte('created_at', prevMonthStart)
      .lt('created_at', prevMonthEnd);

    if (prevError) {
      res.status(500).json({ error: prevError.message });
      return;
    }

    const current = computeLeadStats(currentLeads || []);
    const previous = computeLeadStats(prevLeads || []);

    const formatMonth = (d: Date) =>
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

    res.json({
      current: {
        month: formatMonth(now),
        ...current,
      },
      previous: {
        month: formatMonth(new Date(now.getFullYear(), now.getMonth() - 1, 1)),
        ...previous,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to compute stats' });
  }
});

export default router;

