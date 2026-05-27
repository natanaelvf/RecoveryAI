import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Request, Response } from 'express';
import router from '../routes/webhooks/twilio-voice';
import { lookupContractorByTwilioNumber } from '../services/twilio';
import { findOrCreateLead } from '../services/deduplication';
import { initiateConsentSms } from '../services/sms-state-machine';
import { sendPushNotification } from '../services/notifications';
import { LeadStatus, Contractor, Lead, Urgency } from '../types';

// ---------------------------------------------------------------------------
// Hoisted Mocks
// ---------------------------------------------------------------------------
const {
  mockSupabaseFrom,
  mockSendSms,
  mockSendPushNotification,
  mockLookupContractor,
  mockFindOrCreateLead,
  mockInitiateConsentSms,
} = vi.hoisted(() => ({
  mockSupabaseFrom: vi.fn(),
  mockSendSms: vi.fn(),
  mockSendPushNotification: vi.fn(),
  mockLookupContractor: vi.fn(),
  mockFindOrCreateLead: vi.fn(),
  mockInitiateConsentSms: vi.fn(),
}));

vi.mock('../config/supabase', () => ({
  supabase: { from: mockSupabaseFrom },
}));

vi.mock('../services/twilio', () => ({
  sendSms: mockSendSms,
  lookupContractorByTwilioNumber: mockLookupContractor,
}));

vi.mock('../services/notifications', () => ({
  sendPushNotification: mockSendPushNotification,
}));

vi.mock('../services/deduplication', () => ({
  findOrCreateLead: mockFindOrCreateLead,
}));

vi.mock('../services/sms-state-machine', () => ({
  initiateConsentSms: mockInitiateConsentSms,
}));

// Helpers to extract route callbacks from Express router
function getRouteHandler(path: string, method: 'post' | 'get' = 'post') {
  const layer = router.stack.find(
    (s) => s.route && s.route.path === path && s.route.methods[method]
  );
  if (!layer) throw new Error(`Route ${method.toUpperCase()} ${path} not found`);
  return layer.route.stack[0].handle;
}

function makeContractor(overrides: Partial<Contractor> = {}): Contractor {
  return {
    id: 'contractor-001',
    business_name: 'Unmissed plumbing',
    contact_name: 'Matti',
    contact_email: 'matti@unmissed.io',
    contact_phone: '+358501234567',
    twilio_phone_number: '+358800123456',
    number_setup_type: 'forwarding',
    calendly_url: 'https://calendly.com/unmissed-plumbing',
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
    locale: 'fi',
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
    locale: 'fi',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

function mockRes() {
  const res: Partial<Response> = {};
  res.type = vi.fn().mockReturnThis();
  res.send = vi.fn().mockReturnThis();
  res.status = vi.fn().mockReturnThis();
  return res as Response;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
describe('Integration: Multilingual Voice IVR Routing', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should redirect Portuguese callers directly to Portuguese voicemail', async () => {
    const contractor = makeContractor();
    const lead = makeLead({ caller_phone: '+351912345678', locale: 'pt' });

    mockLookupContractor.mockResolvedValue(contractor);
    mockFindOrCreateLead.mockResolvedValue({ lead, isNew: true });

    // Mock Supabase leads update
    const updateChain = {
      eq: vi.fn().mockResolvedValue({ data: null, error: null }),
    };
    mockSupabaseFrom.mockImplementation((table: string) => {
      if (table === 'leads') {
        return { update: vi.fn().mockReturnValue(updateChain) };
      }
      return {};
    });

    const handler = getRouteHandler('/');
    const req = {
      body: { From: '+351912345678', To: '+358800123456' },
      headers: {},
      get: () => 'localhost:3000',
    } as unknown as Request;
    const res = mockRes();

    await handler(req, res);

    expect(res.type).toHaveBeenCalledWith('text/xml');
    expect(res.send).toHaveBeenCalledWith(
      expect.stringContaining('voicemail-pt')
    );
  });

  it('should redirect Finnish/other callers to IVR language menu on forwarding setup', async () => {
    const contractor = makeContractor({ number_setup_type: 'forwarding' });
    const lead = makeLead({ caller_phone: '+358401112222' });

    mockLookupContractor.mockResolvedValue(contractor);
    mockFindOrCreateLead.mockResolvedValue({ lead, isNew: true });

    const handler = getRouteHandler('/');
    const req = {
      body: { From: '+358401112222', To: '+358800123456' },
      headers: {},
      get: () => 'localhost:3000',
    } as unknown as Request;
    const res = mockRes();

    await handler(req, res);

    expect(res.type).toHaveBeenCalledWith('text/xml');
    expect(res.send).toHaveBeenCalledWith(
      expect.stringContaining('ivr-menu')
    );
  });

  it('should play bilingual prompts in the IVR menu', async () => {
    const handler = getRouteHandler('/ivr-menu');
    const req = {
      query: { contractorId: 'contractor-001', leadId: 'lead-001', isNew: 'true' },
      headers: {},
      get: () => 'localhost:3000',
    } as unknown as Request;
    const res = mockRes();

    await handler(req, res);

    expect(res.type).toHaveBeenCalledWith('text/xml');
    expect(res.send).toHaveBeenCalledWith(
      expect.stringContaining('ivr_menu.mp3')
    );
    expect(res.send).toHaveBeenCalledWith(
      expect.stringContaining('Paina 1 englanniksi')
    );
  });

  it('should process IVR selection and route to English voicemail if 1 is pressed', async () => {
    const handler = getRouteHandler('/ivr-gather');
    const req = {
      body: { Digits: '1' },
      query: { contractorId: 'contractor-001', leadId: 'lead-001', isNew: 'true' },
      headers: {},
      get: () => 'localhost:3000',
    } as unknown as Request;
    const res = mockRes();

    // Mock Supabase leads update for locale
    const eqMock = vi.fn().mockResolvedValue({ data: null, error: null });
    mockSupabaseFrom.mockImplementation((table: string) => {
      if (table === 'leads') {
        return {
          update: vi.fn().mockReturnValue({ eq: eqMock }),
        };
      }
      return {};
    });

    await handler(req, res);

    expect(eqMock).toHaveBeenCalledWith('id', 'lead-001');
    expect(res.send).toHaveBeenCalledWith(
      expect.stringContaining('voicemail-en')
    );
  });

  it('should trigger initiateConsentSms in call-status callback if lead is still marked missed', async () => {
    const contractor = makeContractor();
    const lead = makeLead({ status: LeadStatus.Missed, caller_phone: '+358401112222' });

    mockLookupContractor.mockResolvedValue(contractor);

    // Mock Supabase lead selection
    const singleMock = vi.fn().mockResolvedValue({ data: lead, error: null });
    const limitMock = vi.fn().mockReturnValue({ single: singleMock });
    const orderMock = vi.fn().mockReturnValue({ limit: limitMock });
    const gteMock = vi.fn().mockReturnValue({ order: orderMock });
    const eqMock2 = vi.fn().mockReturnValue({ gte: gteMock });
    const eqMock1 = vi.fn().mockReturnValue({ eq: eqMock2 });

    mockSupabaseFrom.mockImplementation((table: string) => {
      if (table === 'leads') {
        return { select: vi.fn().mockReturnValue({ eq: eqMock1 }) };
      }
      return {};
    });

    const handler = getRouteHandler('/call-status');
    const req = {
      body: { CallStatus: 'completed', From: '+358401112222', To: '+358800123456' },
    } as unknown as Request;
    const res = mockRes();

    await handler(req, res);

    expect(mockInitiateConsentSms).toHaveBeenCalledWith(lead, contractor);
    expect(mockSendPushNotification).toHaveBeenCalledWith(
      contractor.id,
      'Missed Call',
      expect.stringContaining('+358401112222'),
      expect.any(Object)
    );
  });
});
