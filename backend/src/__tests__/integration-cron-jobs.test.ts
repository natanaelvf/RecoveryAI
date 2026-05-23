import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Integration tests for cron jobs:
 * - Consent timeout → lead transitions to no_consent
 * - Satisfaction follow-up → SMS sent, response parsed
 */

const {
  mockSupabaseFrom,
  mockSendSms,
  mockSendPushNotification,
} = vi.hoisted(() => ({
  mockSupabaseFrom: vi.fn(),
  mockSendSms: vi.fn(),
  mockSendPushNotification: vi.fn(),
}));

vi.mock('../config/supabase', () => ({
  supabase: { from: mockSupabaseFrom },
}));

vi.mock('../services/twilio', () => ({
  sendSms: mockSendSms,
}));

vi.mock('../services/notifications', () => ({
  sendPushNotification: mockSendPushNotification,
}));

import { runConsentTimeout } from '../jobs/consent-timeout';
import { runSatisfactionFollowup } from '../jobs/satisfaction-followup';
import { LeadStatus } from '../types';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function mockChain(data: unknown = null, error: unknown = null) {
  const chain: Record<string, unknown> = {};
  const handler = () => chain;
  for (const method of [
    'select', 'insert', 'update', 'delete',
    'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
    'order', 'limit', 'range', 'filter',
  ]) {
    chain[method] = vi.fn(handler);
  }
  chain['single'] = vi.fn(() => ({ data, error }));
  return chain;
}

// ---------------------------------------------------------------------------
// Consent Timeout Tests
// ---------------------------------------------------------------------------

describe('Integration: Consent Timeout Cron', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should transition lead to no_consent when consent timeout expires', async () => {
    const overdueTask = {
      id: 'task-001',
      lead_id: 'lead-001',
      task_type: 'consent_timeout',
      execute_at: new Date(Date.now() - 5 * 60 * 1000).toISOString(), // 5 min ago
      executed: false,
      leads: {
        id: 'lead-001',
        status: LeadStatus.ConsentSent,
      },
    };

    // Track what gets updated
    const updatedLeadStatuses: string[] = [];
    const executedTaskIds: string[] = [];

    mockSupabaseFrom.mockImplementation((table: string) => {
      const chain: Record<string, unknown> = {};
      const handler = () => chain;
      for (const method of [
        'select', 'insert', 'delete',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(handler);
      }
      chain['update'] = vi.fn((data: Record<string, unknown>) => {
        if (table === 'leads' && data.status) {
          updatedLeadStatuses.push(data.status as string);
        }
        if (table === 'scheduled_tasks' && data.executed) {
          executedTaskIds.push('task-executed');
        }
        return chain;
      });
      chain['single'] = vi.fn(() => ({ data: [overdueTask], error: null }));
      // The query returns the array
      chain['lte'] = vi.fn(() => ({ data: [overdueTask], error: null }));
      return chain;
    });

    await runConsentTimeout();

    // Should have updated lead to no_consent
    expect(updatedLeadStatuses).toContain(LeadStatus.NoConsent);
    // Should have marked task as executed
    expect(executedTaskIds.length).toBeGreaterThan(0);
  });

  it('should NOT transition lead that already moved past consent_sent', async () => {
    const taskForAdvancedLead = {
      id: 'task-002',
      lead_id: 'lead-002',
      task_type: 'consent_timeout',
      execute_at: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
      executed: false,
      leads: {
        id: 'lead-002',
        status: LeadStatus.QualifyingIssue, // Already responded, moved past consent
      },
    };

    const updatedLeadStatuses: string[] = [];

    mockSupabaseFrom.mockImplementation((table: string) => {
      const chain: Record<string, unknown> = {};
      const handler = () => chain;
      for (const method of [
        'select', 'insert', 'delete',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(handler);
      }
      chain['update'] = vi.fn((data: Record<string, unknown>) => {
        if (table === 'leads' && data.status) {
          updatedLeadStatuses.push(data.status as string);
        }
        return chain;
      });
      chain['lte'] = vi.fn(() => ({ data: [taskForAdvancedLead], error: null }));
      return chain;
    });

    await runConsentTimeout();

    // Should NOT have changed lead status (it's already past consent_sent)
    expect(updatedLeadStatuses).not.toContain(LeadStatus.NoConsent);
  });

  it('should handle no overdue tasks gracefully', async () => {
    mockSupabaseFrom.mockImplementation(() => {
      const chain: Record<string, unknown> = {};
      const handler = () => chain;
      for (const method of [
        'select', 'insert', 'update', 'delete',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(handler);
      }
      chain['lte'] = vi.fn(() => ({ data: [], error: null }));
      return chain;
    });

    await expect(runConsentTimeout()).resolves.not.toThrow();
  });
});

// ---------------------------------------------------------------------------
// Satisfaction Follow-up Tests
// ---------------------------------------------------------------------------

describe('Integration: Satisfaction Follow-up Cron', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSendSms.mockResolvedValue('SM_satisfaction_sid');
  });

  it('should send satisfaction SMS for due follow-up tasks', async () => {
    const dueTask = {
      id: 'task-sat-001',
      lead_id: 'lead-001',
      task_type: 'satisfaction_followup',
      execute_at: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
      executed: false,
      leads: {
        id: 'lead-001',
        caller_phone: '+358401234567',
        caller_name: 'Mikko',
        status: LeadStatus.Completed,
        contractors: {
          id: 'contractor-001',
          business_name: 'Helsinki Plumbing Oy',
          twilio_phone_number: '+358800123456',
        },
      },
    };

    let smsSent = false;
    let taskMarkedExecuted = false;
    let leadStatusUpdated = false;

    mockSupabaseFrom.mockImplementation((table: string) => {
      const chain: Record<string, unknown> = {};
      const handler = () => chain;
      for (const method of [
        'select', 'insert', 'delete',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(handler);
      }
      chain['update'] = vi.fn((data: Record<string, unknown>) => {
        if (table === 'scheduled_tasks' && data.executed === true) {
          taskMarkedExecuted = true;
        }
        if (table === 'leads' && data.status === LeadStatus.FollowedUp) {
          leadStatusUpdated = true;
        }
        return chain;
      });
      chain['insert'] = vi.fn(() => chain); // message recording
      chain['lte'] = vi.fn(() => ({ data: [dueTask], error: null }));
      return chain;
    });

    await runSatisfactionFollowup();

    // Verify SMS was sent
    expect(mockSendSms).toHaveBeenCalledWith(
      '+358401234567',
      '+358800123456',
      expect.stringContaining('1-5')
    );

    // Verify task was marked as executed
    expect(taskMarkedExecuted).toBe(true);

    // Verify lead status was updated to followed_up
    expect(leadStatusUpdated).toBe(true);
  });

  it('should handle SMS failure without crashing the job', async () => {
    mockSendSms.mockRejectedValue(new Error('Twilio timeout'));

    const dueTask = {
      id: 'task-sat-002',
      lead_id: 'lead-002',
      task_type: 'satisfaction_followup',
      execute_at: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
      executed: false,
      leads: {
        id: 'lead-002',
        caller_phone: '+358402222222',
        status: LeadStatus.Completed,
        contractors: {
          id: 'contractor-001',
          business_name: 'Test Oy',
          twilio_phone_number: '+358800123456',
        },
      },
    };

    mockSupabaseFrom.mockImplementation(() => {
      const chain: Record<string, unknown> = {};
      const handler = () => chain;
      for (const method of [
        'select', 'insert', 'update', 'delete',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(handler);
      }
      chain['lte'] = vi.fn(() => ({ data: [dueTask], error: null }));
      return chain;
    });

    // Should not throw even though SMS failed
    await expect(runSatisfactionFollowup()).resolves.not.toThrow();
  });
});
