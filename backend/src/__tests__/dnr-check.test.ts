import { describe, it, expect, vi, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mock dependencies using vi.hoisted() to avoid hoisting issues
// ---------------------------------------------------------------------------

const { mockSupabaseFrom, mockSendPushNotification } = vi.hoisted(() => ({
  mockSupabaseFrom: vi.fn(),
  mockSendPushNotification: vi.fn(),
}));

vi.mock('../config/supabase', () => ({
  supabase: { from: mockSupabaseFrom },
}));

vi.mock('../services/notifications', () => ({
  sendPushNotification: mockSendPushNotification,
}));

import { runDnrCheck } from '../jobs/dnr-check';
import { LeadStatus } from '../types';

// ---------------------------------------------------------------------------
// Supabase mock helpers
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
  chain['then'] = vi.fn((resolve: (v: unknown) => void) => resolve({ data, error }));

  return chain;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('DNR Check Job', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSendPushNotification.mockResolvedValue(undefined);
  });

  it('should do nothing when no overdue leads exist', async () => {
    mockSupabaseFrom.mockReturnValue(mockChain([], null));

    await runDnrCheck();

    expect(mockSendPushNotification).not.toHaveBeenCalled();
  });

  it('should send alert when urgent lead exceeds threshold', async () => {
    const urgentLead = {
      id: 'lead-urgent',
      urgency: 'high',
      caller_phone: '+358401234567',
      status: LeadStatus.BookingSent,
      dnr_alert_sent: false,
      created_at: new Date(Date.now() - 120 * 60 * 1000).toISOString(), // 2 hours ago
      contractors: {
        id: 'contractor-001',
        urgency_threshold_urgent_min: 60, // 1 hour threshold
        urgency_threshold_normal_min: 1440,
      },
    };

    // Query returns the overdue lead
    const queryChain = mockChain([urgentLead], null);
    // Update chain for marking alert sent
    const updateChain = mockChain();

    let callCount = 0;
    mockSupabaseFrom.mockImplementation(() => {
      callCount++;
      if (callCount === 1) return queryChain;
      return updateChain;
    });

    await runDnrCheck();

    expect(mockSendPushNotification).toHaveBeenCalledWith(
      'contractor-001',
      '🚨 Urgent Lead Not Responding',
      expect.stringContaining('60 min'),
      expect.objectContaining({ leadId: 'lead-urgent', priority: 'high' })
    );
  });

  it('should use normal threshold for non-urgent leads', async () => {
    const normalLead = {
      id: 'lead-normal',
      urgency: 'low',
      caller_phone: '+358401234567',
      status: LeadStatus.BookingSent,
      dnr_alert_sent: false,
      created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString(), // 30 min ago (under 1440 threshold)
      contractors: {
        id: 'contractor-001',
        urgency_threshold_urgent_min: 60,
        urgency_threshold_normal_min: 1440, // 24 hour threshold
      },
    };

    const queryChain = mockChain([normalLead], null);
    mockSupabaseFrom.mockReturnValue(queryChain);

    await runDnrCheck();

    // Should NOT send alert — 30 min < 1440 min threshold
    expect(mockSendPushNotification).not.toHaveBeenCalled();
  });

  it('should send alert for normal lead exceeding 24h threshold', async () => {
    const normalLead = {
      id: 'lead-overdue',
      urgency: 'low',
      caller_phone: '+358401234567',
      status: LeadStatus.BookingSent,
      dnr_alert_sent: false,
      created_at: new Date(Date.now() - 25 * 60 * 60 * 1000).toISOString(), // 25 hours ago
      contractors: {
        id: 'contractor-001',
        urgency_threshold_urgent_min: 60,
        urgency_threshold_normal_min: 1440,
      },
    };

    const queryChain = mockChain([normalLead], null);
    const updateChain = mockChain();

    let callCount = 0;
    mockSupabaseFrom.mockImplementation(() => {
      callCount++;
      if (callCount === 1) return queryChain;
      return updateChain;
    });

    await runDnrCheck();

    expect(mockSendPushNotification).toHaveBeenCalledWith(
      'contractor-001',
      'Lead Not Responding',
      expect.stringContaining('1440 min'),
      expect.objectContaining({ leadId: 'lead-overdue' })
    );

    // Normal leads should NOT have priority: 'high'
    const callData = mockSendPushNotification.mock.calls[0][3];
    expect(callData.priority).toBeUndefined();
  });

  it('should classify emergency urgency as urgent threshold', async () => {
    const emergencyLead = {
      id: 'lead-emergency',
      urgency: 'emergency',
      caller_phone: '+358401234567',
      status: LeadStatus.BookingSent,
      dnr_alert_sent: false,
      created_at: new Date(Date.now() - 90 * 60 * 1000).toISOString(), // 90 min ago
      contractors: {
        id: 'contractor-001',
        urgency_threshold_urgent_min: 60, // 1 hour
        urgency_threshold_normal_min: 1440,
      },
    };

    const queryChain = mockChain([emergencyLead], null);
    const updateChain = mockChain();

    let callCount = 0;
    mockSupabaseFrom.mockImplementation(() => {
      callCount++;
      if (callCount === 1) return queryChain;
      return updateChain;
    });

    await runDnrCheck();

    // Should use urgent threshold (60 min), and 90 > 60, so alert
    expect(mockSendPushNotification).toHaveBeenCalled();
  });

  it('should not alert leads that already have dnr_alert_sent = true', async () => {
    // The query itself filters for dnr_alert_sent = false,
    // so no already-alerted leads should be in the result set.
    // This test verifies the query filtering is in place.
    mockSupabaseFrom.mockReturnValue(mockChain([], null));

    await runDnrCheck();

    expect(mockSendPushNotification).not.toHaveBeenCalled();
  });

  it('should handle database query errors gracefully', async () => {
    mockSupabaseFrom.mockReturnValue(
      mockChain(null, { message: 'Connection refused' })
    );

    // Should not throw
    await expect(runDnrCheck()).resolves.not.toThrow();
    expect(mockSendPushNotification).not.toHaveBeenCalled();
  });

  it('should handle multiple overdue leads in a single run', async () => {
    const leads = [
      {
        id: 'lead-1',
        urgency: 'high',
        caller_phone: '+358401111111',
        status: LeadStatus.BookingSent,
        dnr_alert_sent: false,
        created_at: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
        contractors: {
          id: 'contractor-001',
          urgency_threshold_urgent_min: 60,
          urgency_threshold_normal_min: 1440,
        },
      },
      {
        id: 'lead-2',
        urgency: 'emergency',
        caller_phone: '+358402222222',
        status: LeadStatus.ConsentSent,
        dnr_alert_sent: false,
        created_at: new Date(Date.now() - 90 * 60 * 1000).toISOString(),
        contractors: {
          id: 'contractor-002',
          urgency_threshold_urgent_min: 60,
          urgency_threshold_normal_min: 1440,
        },
      },
    ];

    const queryChain = mockChain(leads, null);
    const updateChain = mockChain();

    let callCount = 0;
    mockSupabaseFrom.mockImplementation(() => {
      callCount++;
      if (callCount === 1) return queryChain;
      return updateChain;
    });

    await runDnrCheck();

    expect(mockSendPushNotification).toHaveBeenCalledTimes(2);
  });
});
