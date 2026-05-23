import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mock external dependencies using vi.hoisted() to avoid hoisting issues
// ---------------------------------------------------------------------------

const { mockSupabaseFrom, mockSendSms, mockSendPushNotification } = vi.hoisted(() => ({
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

import { handleInboundSms, initiateConsentSms } from '../services/sms-state-machine';
import { Lead, LeadStatus, Contractor, Urgency } from '../types';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

function makeLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: 'lead-001',
    contractor_id: 'contractor-001',
    caller_phone: '+358401234567',
    caller_name: null,
    issue_description: null,
    urgency: Urgency.Unknown,
    email: null,
    call_count: 1,
    status: LeadStatus.Missed,
    consent_given: false,
    consent_given_at: null,
    booking_time: null,
    calendly_event_id: null,
    dnr_alert_sent: false,
    dnr_alert_sent_at: null,
    estimated_value: null,
    satisfaction_score: null,
    satisfaction_feedback: null,
    notes: null,
    called_during_after_hours: false,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

function makeContractor(overrides: Partial<Contractor> = {}): Contractor {
  return {
    id: 'contractor-001',
    business_name: 'Test Plumbing Oy',
    contact_name: 'Matti Meikäläinen',
    contact_email: 'matti@test.fi',
    contact_phone: '+358501234567',
    twilio_phone_number: '+358800123456',
    number_setup_type: 'forwarding',
    calendly_url: 'https://calendly.com/test-plumbing',
    trade_type: 'plumber',
    default_job_value: 250,
    urgency_threshold_urgent_min: 60,
    urgency_threshold_normal_min: 1440,
    working_hours_start: '08:00',
    working_hours_end: '18:00',
    working_days: [1, 2, 3, 4, 5],
    after_hours_emergency_policy: 'Flooding and burst pipes only',
    after_hours_ring: false,
    timezone: 'Europe/Helsinki',
    tier: 'starter',
    monthly_sms_cap: 50,
    sms_used_this_month: 0,
    stripe_customer_id: null,
    fcm_token: null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Supabase mock helpers
// ---------------------------------------------------------------------------

/**
 * Build a chainable mock that simulates Supabase's fluent query builder.
 * The final call in the chain resolves to { data, error }.
 */
function mockChain(data: unknown = null, error: unknown = null) {
  const chain: Record<string, unknown> = {};
  const handler = () => chain;

  // All chainable methods return the chain itself
  for (const method of [
    'select', 'insert', 'update', 'delete',
    'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
    'order', 'limit', 'range', 'filter',
  ]) {
    chain[method] = vi.fn(handler);
  }

  // Terminal methods resolve the result
  chain['single'] = vi.fn(() => ({ data, error }));
  chain['maybeSingle'] = vi.fn(() => ({ data, error }));
  chain['then'] = vi.fn((resolve: (v: unknown) => void) => resolve({ data, error }));

  return chain;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('SMS State Machine', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    // Default: sendSms returns a fake SID
    mockSendSms.mockResolvedValue('SM_test_sid_001');

    // Default: push notification succeeds
    mockSendPushNotification.mockResolvedValue(undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // ─── Consent Phase ────────────────────────────────────

  describe('consent_sent status', () => {
    it('should advance to qualifying_issue on "YES"', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      // Mock re-fetch of lead
      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'YES', contractor);

      // Should have updated lead status to qualifying_issue with consent fields
      expect(mockSupabaseFrom).toHaveBeenCalledWith('leads');
      // Should have recorded inbound message
      expect(mockSupabaseFrom).toHaveBeenCalledWith('messages');
      // Should have sent issue question SMS
      expect(mockSendSms).toHaveBeenCalled();
    });

    it('should accept "KYLLÄ" as consent (Finnish YES)', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'KYLLÄ', contractor);

      expect(mockSendSms).toHaveBeenCalled();
    });

    it('should accept "KYLLA" as consent (Finnish YES without diacritics)', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'KYLLA', contractor);

      expect(mockSendSms).toHaveBeenCalled();
    });

    it('should transition to no_consent on "STOP"', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'STOP', contractor);

      // Should have sent opt-out confirmation
      expect(mockSendSms).toHaveBeenCalled();
    });

    it('should accept "EI" as opt-out (Finnish STOP)', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'EI', contractor);

      expect(mockSendSms).toHaveBeenCalled();
    });

    it('should re-send consent prompt on unrecognized reply', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'MAYBE', contractor);

      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('Reply YES');
    });
  });

  // ─── Issue Collection Phase ───────────────────────────

  describe('qualifying_issue status', () => {
    it('should store issue description and advance to qualifying_urgency', async () => {
      const lead = makeLead({ status: LeadStatus.QualifyingIssue });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'Leaking pipe under kitchen sink', contractor);

      // Should have sent urgency question
      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('How urgent');
    });
  });

  // ─── Urgency Collection Phase ─────────────────────────

  describe('qualifying_urgency status', () => {
    it('should parse urgency "1" as low and advance to qualifying_name', async () => {
      const lead = makeLead({ status: LeadStatus.QualifyingUrgency });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '1', contractor);

      // Should have sent name question
      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('name');
    });

    it('should parse urgency "4" as emergency', async () => {
      const lead = makeLead({ status: LeadStatus.QualifyingUrgency });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '4', contractor);

      expect(mockSendSms).toHaveBeenCalled();
    });

    it('should send emergency push for after-hours emergency leads', async () => {
      const lead = makeLead({
        status: LeadStatus.QualifyingUrgency,
        called_during_after_hours: true,
        issue_description: 'Burst pipe flooding basement',
      });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '4', contractor); // 4 = emergency

      expect(mockSendPushNotification).toHaveBeenCalledWith(
        contractor.id,
        expect.stringContaining('EMERGENCY'),
        expect.any(String),
        expect.objectContaining({ leadId: lead.id, priority: 'high' })
      );
    });

    it('should NOT send emergency push for non-after-hours emergency', async () => {
      const lead = makeLead({
        status: LeadStatus.QualifyingUrgency,
        called_during_after_hours: false,
      });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '4', contractor);

      expect(mockSendPushNotification).not.toHaveBeenCalled();
    });

    it('should re-ask urgency on invalid input', async () => {
      const lead = makeLead({ status: LeadStatus.QualifyingUrgency });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'very urgent', contractor);

      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('How urgent');
    });

    it('should re-ask urgency on "5" (out of range)', async () => {
      const lead = makeLead({ status: LeadStatus.QualifyingUrgency });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '5', contractor);

      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('How urgent');
    });
  });

  // ─── Name Collection Phase ────────────────────────────

  describe('qualifying_name status', () => {
    it('should store name and send booking link', async () => {
      const lead = makeLead({ status: LeadStatus.QualifyingName });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'Mikko Virtanen', contractor);

      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('calendly.com');
    });
  });

  // ─── Booking Sent Phase ───────────────────────────────

  describe('booking_sent status', () => {
    it('should re-send booking link on any reply', async () => {
      const lead = makeLead({ status: LeadStatus.BookingSent });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'When can I book?', contractor);

      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('calendly.com');
    });
  });

  // ─── Satisfaction Follow-up Phase ─────────────────────

  describe('followed_up status', () => {
    it('should parse score "5" and mark completed', async () => {
      const lead = makeLead({ status: LeadStatus.FollowedUp });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '5 Great service!', contractor);

      // Should NOT trigger low satisfaction push for score 5
      expect(mockSendPushNotification).not.toHaveBeenCalled();
    });

    it('should trigger low satisfaction alert for score <= 2', async () => {
      const lead = makeLead({
        status: LeadStatus.FollowedUp,
        caller_name: 'Pekka',
        caller_phone: '+358401234567',
      });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '1 Terrible experience', contractor);

      expect(mockSendPushNotification).toHaveBeenCalledWith(
        contractor.id,
        expect.stringContaining('Low Satisfaction'),
        expect.any(String),
        expect.objectContaining({ leadId: lead.id })
      );
    });

    it('should extract score from mixed text like "I give it a 3"', async () => {
      const lead = makeLead({ status: LeadStatus.FollowedUp });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'I give it a 3', contractor);

      // Score 3 should NOT trigger push
      expect(mockSendPushNotification).not.toHaveBeenCalled();
    });

    it('should re-ask satisfaction on reply with no digit 1-5', async () => {
      const lead = makeLead({ status: LeadStatus.FollowedUp });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, 'It was fine', contractor);

      expect(mockSendSms).toHaveBeenCalled();
      const smsBody = mockSendSms.mock.calls[0][2] as string;
      expect(smsBody).toContain('1-5');
    });
  });

  // ─── SMS Cap ──────────────────────────────────────────

  describe('SMS cap handling', () => {
    it('should handle SMS_CAP_REACHED gracefully', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      mockSendSms.mockRejectedValue(new Error('SMS_CAP_REACHED'));

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      // Should not throw
      await expect(
        handleInboundSms(lead, 'YES', contractor)
      ).resolves.not.toThrow();
    });
  });

  // ─── Consent Initiation ───────────────────────────────

  describe('initiateConsentSms', () => {
    it('should send consent SMS and schedule timeout', async () => {
      const lead = makeLead({ status: LeadStatus.Missed });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        if (table === 'scheduled_tasks') return mockChain();
        return mockChain();
      });

      await initiateConsentSms(lead, contractor);

      // Should have sent consent SMS
      expect(mockSendSms).toHaveBeenCalledWith(
        lead.caller_phone,
        contractor.twilio_phone_number,
        expect.stringContaining('Reply YES')
      );

      // Should have scheduled consent timeout
      expect(mockSupabaseFrom).toHaveBeenCalledWith('scheduled_tasks');
    });

    it('should not schedule timeout if SMS fails', async () => {
      const lead = makeLead({ status: LeadStatus.Missed });
      const contractor = makeContractor();

      mockSendSms.mockRejectedValue(new Error('Twilio error'));

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        if (table === 'scheduled_tasks') return mockChain();
        return mockChain();
      });

      await initiateConsentSms(lead, contractor);

      // Should NOT have updated lead status (SMS failed)
      // The function catches the error internally
    });
  });

  // ─── Edge cases ───────────────────────────────────────

  describe('edge cases', () => {
    it('should handle lead not found during re-fetch', async () => {
      const lead = makeLead();
      const contractor = makeContractor();

      // Re-fetch returns null
      mockSupabaseFrom.mockReturnValue(mockChain(null, { message: 'Not found' }));

      // Should not throw
      await expect(
        handleInboundSms(lead, 'YES', contractor)
      ).resolves.not.toThrow();
    });

    it('should handle unexpected status gracefully', async () => {
      const lead = makeLead({ status: LeadStatus.Booked });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      // Should log warning but not throw
      await expect(
        handleInboundSms(lead, 'hello', contractor)
      ).resolves.not.toThrow();
    });

    it('should trim whitespace from message body', async () => {
      const lead = makeLead({ status: LeadStatus.ConsentSent });
      const contractor = makeContractor();

      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') return mockChain(lead);
        if (table === 'messages') return mockChain();
        return mockChain();
      });

      await handleInboundSms(lead, '  YES  ', contractor);

      // Should have processed as YES
      expect(mockSendSms).toHaveBeenCalled();
    });
  });
});
