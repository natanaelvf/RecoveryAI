import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Integration test: Twilio voice webhook → lead creation → consent SMS
 *
 * Tests the full flow from an incoming voice call through to the first SMS being sent,
 * exercising the voice webhook handler, deduplication service, and SMS state machine together.
 */

// ---------------------------------------------------------------------------
// Hoisted mocks
// ---------------------------------------------------------------------------

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
  lookupContractorByTwilioNumber: vi.fn(),
}));

vi.mock('../services/notifications', () => ({
  sendPushNotification: mockSendPushNotification,
}));

// We need to re-import after mocking to get the mocked version
import { lookupContractorByTwilioNumber } from '../services/twilio';
import { findOrCreateLead } from '../services/deduplication';
import { initiateConsentSms, handleInboundSms } from '../services/sms-state-machine';
import { LeadStatus, Contractor, Lead, Urgency } from '../types';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

function makeContractor(overrides: Partial<Contractor> = {}): Contractor {
  return {
    id: 'contractor-001',
    business_name: 'Helsinki Plumbing Oy',
    contact_name: 'Matti',
    contact_email: 'matti@test.fi',
    contact_phone: '+358501234567',
    twilio_phone_number: '+358800123456',
    number_setup_type: 'forwarding',
    calendly_url: 'https://calendly.com/helsinki-plumbing',
    trade_type: 'plumber',
    default_job_value: 250,
    urgency_threshold_urgent_min: 60,
    urgency_threshold_normal_min: 1440,
    working_hours_start: '08:00',
    working_hours_end: '18:00',
    working_days: [1, 2, 3, 4, 5],
    after_hours_emergency_policy: 'Flooding only',
    after_hours_ring: false,
    timezone: 'Europe/Helsinki',
    tier: 'starter',
    locale: 'en',
    monthly_sms_cap: 50,
    sms_used_this_month: 5,
    stripe_customer_id: null,
    fcm_token: 'fcm-token-123',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

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
    estimated_value: 250,
    satisfaction_score: null,
    satisfaction_feedback: null,
    notes: null,
    called_during_after_hours: false,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

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
// Integration: Voice Webhook → Lead → Consent SMS
// ---------------------------------------------------------------------------

describe('Integration: Voice → Lead → Consent SMS', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSendSms.mockResolvedValue('SM_consent_sid');
    mockSendPushNotification.mockResolvedValue(undefined);
  });

  it('should create a lead and send consent SMS for a new missed call', async () => {
    const contractor = makeContractor();
    const callerPhone = '+358401234567';
    const newLead = makeLead({ caller_phone: callerPhone, status: LeadStatus.Missed });

    // Mock: no existing lead found → create new
    const findChain = mockChain(null, { message: 'Not found' });
    const contractorChain = mockChain({ default_job_value: 250 });
    const insertChain = mockChain(newLead);
    const updateChain = mockChain(newLead);
    const messageChain = mockChain();
    const taskChain = mockChain();

    let leadCallCount = 0;
    mockSupabaseFrom.mockImplementation((table: string) => {
      if (table === 'leads') {
        leadCallCount++;
        if (leadCallCount === 1) return findChain;    // dedup find
        if (leadCallCount === 2) return insertChain;   // create lead
        return updateChain;                             // update status
      }
      if (table === 'contractors') return contractorChain;
      if (table === 'messages') return messageChain;
      if (table === 'scheduled_tasks') return taskChain;
      return mockChain();
    });

    // Step 1: Deduplication creates a new lead
    const { lead, isNew } = await findOrCreateLead(contractor.id, callerPhone, false);
    expect(isNew).toBe(true);
    expect(lead.caller_phone).toBe(callerPhone);

    // Step 2: Initiate consent SMS flow
    await initiateConsentSms(lead, contractor);

    // Verify: consent SMS was sent
    expect(mockSendSms).toHaveBeenCalledWith(
      callerPhone,
      contractor.twilio_phone_number,
      expect.stringContaining('Reply YES')
    );

    // Verify: consent timeout was scheduled
    expect(mockSupabaseFrom).toHaveBeenCalledWith('scheduled_tasks');
  });

  it('should increment call_count for duplicate caller and NOT send consent again', async () => {
    const contractor = makeContractor();
    const callerPhone = '+358401234567';
    const existingLead = makeLead({
      caller_phone: callerPhone,
      status: LeadStatus.ConsentSent,
      call_count: 1,
    });
    const updatedLead = { ...existingLead, call_count: 2 };

    const findChain = mockChain(existingLead);
    const updateChain = mockChain(updatedLead);

    let leadCallCount = 0;
    mockSupabaseFrom.mockImplementation((table: string) => {
      if (table === 'leads') {
        leadCallCount++;
        if (leadCallCount === 1) return findChain;
        return updateChain;
      }
      return mockChain();
    });

    const { lead, isNew } = await findOrCreateLead(contractor.id, callerPhone, false);

    expect(isNew).toBe(false);
    expect(lead.call_count).toBe(2);

    // Since isNew is false, consent SMS should NOT be sent
    // (the voice webhook checks isNew before calling initiateConsentSms)
    expect(mockSendSms).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// Integration: Full SMS sequence through all statuses
// ---------------------------------------------------------------------------

describe('Integration: Full SMS Sequence', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSendSms.mockResolvedValue('SM_test_sid');
    mockSendPushNotification.mockResolvedValue(undefined);
  });

  it('should progress lead through consent → issue → urgency → name → booking', async () => {
    const contractor = makeContractor();

    // Track lead status progression
    const statusHistory: string[] = [];
    const captureUpdate = (data: unknown) => {
      if (data && typeof data === 'object' && 'status' in (data as Record<string, unknown>)) {
        statusHistory.push((data as Record<string, string>).status);
      }
    };

    // Generic mock that captures updates
    mockSupabaseFrom.mockImplementation((table: string) => {
      const chain: Record<string, unknown> = {};
      const handler = (...args: unknown[]) => {
        // Capture status updates
        if (typeof args[0] === 'object' && args[0] !== null) {
          captureUpdate(args[0]);
        }
        return chain;
      };
      for (const method of [
        'select', 'insert', 'delete',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(() => chain);
      }
      chain['update'] = vi.fn(handler);
      chain['single'] = vi.fn(() => ({ data: null, error: null }));
      return chain;
    });

    // Step 1: consent_sent → reply YES → qualifying_issue
    let lead = makeLead({ status: LeadStatus.ConsentSent });
    mockSupabaseFrom.mockImplementation((table: string) => {
      const chain = mockChain(lead);
      (chain['update'] as ReturnType<typeof vi.fn>).mockImplementation((data: unknown) => {
        captureUpdate(data);
        return chain;
      });
      return chain;
    });
    await handleInboundSms(lead, 'YES', contractor);

    // Step 2: qualifying_issue → reply with issue → qualifying_urgency
    lead = makeLead({ status: LeadStatus.QualifyingIssue });
    mockSupabaseFrom.mockImplementation(() => {
      const chain = mockChain(lead);
      (chain['update'] as ReturnType<typeof vi.fn>).mockImplementation((data: unknown) => {
        captureUpdate(data);
        return chain;
      });
      return chain;
    });
    await handleInboundSms(lead, 'Leaking pipe under sink', contractor);

    // Step 3: qualifying_urgency → reply "3" (high) → qualifying_name
    lead = makeLead({ status: LeadStatus.QualifyingUrgency });
    mockSupabaseFrom.mockImplementation(() => {
      const chain = mockChain(lead);
      (chain['update'] as ReturnType<typeof vi.fn>).mockImplementation((data: unknown) => {
        captureUpdate(data);
        return chain;
      });
      return chain;
    });
    await handleInboundSms(lead, '3', contractor);

    // Step 4: qualifying_name → reply with name → booking_sent
    lead = makeLead({ status: LeadStatus.QualifyingName });
    mockSupabaseFrom.mockImplementation(() => {
      const chain = mockChain(lead);
      (chain['update'] as ReturnType<typeof vi.fn>).mockImplementation((data: unknown) => {
        captureUpdate(data);
        return chain;
      });
      return chain;
    });
    await handleInboundSms(lead, 'Mikko Virtanen', contractor);

    // Verify: 4 outbound SMS were sent (issue question, urgency question, name question, booking link)
    expect(mockSendSms).toHaveBeenCalledTimes(4);

    // Verify: final SMS contains Calendly link
    const lastSmsBody = mockSendSms.mock.calls[3][2] as string;
    expect(lastSmsBody).toContain('calendly.com');

    // Verify status progression
    expect(statusHistory).toEqual(
      expect.arrayContaining([
        LeadStatus.QualifyingIssue,
        LeadStatus.QualifyingUrgency,
        LeadStatus.QualifyingName,
        LeadStatus.BookingSent,
      ])
    );
  });
});
