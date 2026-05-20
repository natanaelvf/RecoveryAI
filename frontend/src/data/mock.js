/**
 * Mock Data — Realistic Finnish contractor + leads
 * Designed to show all pipeline states and demonstrate the full UI
 */

// ── Contractor ──────────────────────────────────────────
export const contractor = {
  id: 'c1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6',
  business_name: 'Virtanen LVI Oy',
  contact_name: 'Jukka Virtanen',
  contact_email: 'jukka@virtanenlvi.fi',
  contact_phone: '+358 40 555 1234',
  twilio_phone_number: '+358 9 1234 5678',
  number_setup_type: 'forwarding',
  calendly_url: 'https://calendly.com/virtanenlvi/callback',
  trade_type: 'plumber',
  default_job_value: 350,
  urgency_threshold_urgent_min: 60,
  urgency_threshold_normal_min: 1440,
  working_hours_start: '08:00',
  working_hours_end: '18:00',
  working_days: [1, 2, 3, 4, 5],
  after_hours_emergency_policy: 'Putkirikot ja vesivahingot — soita heti. Muu kiireetön työ odottaa aamuun.',
  timezone: 'Europe/Helsinki',
  tier: 'growth',
  monthly_sms_cap: 150,
  sms_used_this_month: 87,
};

// Helper — generate dates relative to now
function daysAgo(days, hours = 0, mins = 0) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  d.setHours(hours, mins, 0, 0);
  return d.toISOString();
}

function hoursAgo(hours) {
  const d = new Date();
  d.setHours(d.getHours() - hours);
  return d.toISOString();
}

function minsAgo(mins) {
  const d = new Date();
  d.setMinutes(d.getMinutes() - mins);
  return d.toISOString();
}

// ── Leads ───────────────────────────────────────────────
export const leads = [
  {
    id: 'lead-001',
    contractor_id: contractor.id,
    caller_phone: '+358 50 123 4567',
    caller_name: 'Mikko Korhonen',
    issue_description: 'Keittiön tiskialtaan alla vuotaa putki, vesi valuu kaappiin.',
    urgency: 'high',
    status: 'qualifying',
    consent_given: true,
    consent_given_at: hoursAgo(2),
    call_count: 2,
    estimated_value: 280,
    called_during_after_hours: false,
    created_at: hoursAgo(2),
    updated_at: hoursAgo(1),
  },
  {
    id: 'lead-002',
    contractor_id: contractor.id,
    caller_phone: '+358 44 987 6543',
    caller_name: 'Anna Laine',
    issue_description: 'Kylpyhuoneen lattialämmitys ei toimi. Termostaatti näyttää virhettä.',
    urgency: 'medium',
    status: 'booked',
    consent_given: true,
    consent_given_at: daysAgo(1, 14, 30),
    booking_time: daysAgo(-1, 10, 0), // tomorrow 10am
    call_count: 1,
    estimated_value: 450,
    called_during_after_hours: false,
    created_at: daysAgo(1, 14, 0),
    updated_at: daysAgo(1, 15, 0),
  },
  {
    id: 'lead-003',
    contractor_id: contractor.id,
    caller_phone: '+358 40 111 2222',
    caller_name: 'Pekka Mäkinen',
    issue_description: 'WC-istuin vuotaa jatkuvasti. Vettä valuu lattialle.',
    urgency: 'emergency',
    status: 'missed',
    consent_given: false,
    call_count: 3,
    estimated_value: null,
    called_during_after_hours: true,
    created_at: minsAgo(15),
    updated_at: minsAgo(15),
  },
  {
    id: 'lead-004',
    contractor_id: contractor.id,
    caller_phone: '+358 50 333 4444',
    caller_name: 'Liisa Virtanen',
    issue_description: 'Haluaisin tarjouksen koko talon putkisaneerauksesta.',
    urgency: 'low',
    status: 'booking_sent',
    consent_given: true,
    consent_given_at: daysAgo(2, 11, 0),
    call_count: 1,
    estimated_value: 2200,
    called_during_after_hours: false,
    created_at: daysAgo(2, 10, 30),
    updated_at: daysAgo(2, 12, 0),
  },
  {
    id: 'lead-005',
    contractor_id: contractor.id,
    caller_phone: '+358 44 555 6666',
    caller_name: 'Heikki Järvinen',
    issue_description: 'Pesukoneen hana tippuu. Ei kiire mutta ärsyttää.',
    urgency: 'low',
    status: 'completed',
    consent_given: true,
    consent_given_at: daysAgo(5, 9, 0),
    booking_time: daysAgo(3, 14, 0),
    call_count: 1,
    estimated_value: 150,
    satisfaction_score: 5,
    satisfaction_feedback: 'Erinomainen palvelu! Nopea ja ammattimainen.',
    called_during_after_hours: false,
    created_at: daysAgo(5, 8, 45),
    updated_at: daysAgo(2, 16, 0),
  },
  {
    id: 'lead-006',
    contractor_id: contractor.id,
    caller_phone: '+358 50 777 8888',
    caller_name: 'Sanna Koivisto',
    issue_description: 'Vesipatterien ilmaus koko talossa (rivitalo, 4 patteria).',
    urgency: 'medium',
    status: 'completed',
    consent_given: true,
    consent_given_at: daysAgo(7, 13, 0),
    booking_time: daysAgo(5, 9, 0),
    call_count: 1,
    estimated_value: 200,
    satisfaction_score: 4,
    satisfaction_feedback: 'Hyvin meni, kiitos!',
    called_during_after_hours: false,
    created_at: daysAgo(7, 12, 30),
    updated_at: daysAgo(4, 10, 0),
  },
  {
    id: 'lead-007',
    contractor_id: contractor.id,
    caller_phone: '+358 44 999 0000',
    caller_name: null,
    issue_description: null,
    urgency: 'unknown',
    status: 'consent_sent',
    consent_given: false,
    call_count: 1,
    estimated_value: null,
    called_during_after_hours: false,
    created_at: hoursAgo(1),
    updated_at: hoursAgo(1),
  },
  {
    id: 'lead-008',
    contractor_id: contractor.id,
    caller_phone: '+358 40 222 3333',
    caller_name: 'Timo Lahtinen',
    issue_description: 'Kuumavesivaraaja ei lämmitä. Vain kylmää vettä tulee.',
    urgency: 'high',
    status: 'dnr_alert',
    consent_given: true,
    consent_given_at: daysAgo(1, 10, 0),
    call_count: 2,
    estimated_value: 800,
    dnr_alert_sent: true,
    dnr_alert_sent_at: daysAgo(1, 11, 30),
    called_during_after_hours: false,
    created_at: daysAgo(1, 9, 45),
    updated_at: daysAgo(1, 11, 30),
  },
  {
    id: 'lead-009',
    contractor_id: contractor.id,
    caller_phone: '+358 50 444 5555',
    caller_name: 'Maria Heikkinen',
    issue_description: null,
    urgency: 'unknown',
    status: 'no_consent',
    consent_given: false,
    call_count: 1,
    estimated_value: null,
    called_during_after_hours: true,
    created_at: daysAgo(3, 22, 15),
    updated_at: daysAgo(3, 22, 45),
  },
  {
    id: 'lead-010',
    contractor_id: contractor.id,
    caller_phone: '+358 44 666 7777',
    caller_name: 'Antti Salonen',
    issue_description: 'Kellariin tulee vettä sadekelillä. Tarvitsen viemäritarkastuksen.',
    urgency: 'medium',
    status: 'completed',
    consent_given: true,
    consent_given_at: daysAgo(10, 11, 0),
    booking_time: daysAgo(8, 13, 0),
    call_count: 1,
    estimated_value: 650,
    satisfaction_score: 5,
    satisfaction_feedback: 'Todella perusteellinen työ. Suosittelen!',
    called_during_after_hours: false,
    created_at: daysAgo(10, 10, 30),
    updated_at: daysAgo(7, 14, 0),
  },
  {
    id: 'lead-011',
    contractor_id: contractor.id,
    caller_phone: '+358 40 888 9999',
    caller_name: 'Eeva Nieminen',
    issue_description: 'Astianpesukoneen liitäntä vuotaa. Koneen alla kosteutta.',
    urgency: 'high',
    status: 'booked',
    consent_given: true,
    consent_given_at: hoursAgo(5),
    booking_time: daysAgo(-2, 9, 0), // 2 days from now
    call_count: 1,
    estimated_value: 300,
    called_during_after_hours: false,
    created_at: hoursAgo(6),
    updated_at: hoursAgo(4),
  },
  {
    id: 'lead-012',
    contractor_id: contractor.id,
    caller_phone: '+358 50 101 2020',
    caller_name: 'Ville Koskinen',
    issue_description: 'Sauna kiuas ei toimi. Kytkimet ok mutta ei lämpene.',
    urgency: 'low',
    status: 'followed_up',
    consent_given: true,
    consent_given_at: daysAgo(14, 15, 0),
    booking_time: daysAgo(12, 10, 0),
    call_count: 1,
    estimated_value: 400,
    satisfaction_score: 3,
    satisfaction_feedback: 'Työ ok, mutta aikataulu myöhästyi tunnin.',
    called_during_after_hours: false,
    created_at: daysAgo(14, 14, 30),
    updated_at: daysAgo(10, 12, 0),
  },
];

// ── Messages (SMS conversations per lead) ───────────────
export const messages = {
  'lead-001': [
    { id: 'm001-1', direction: 'outbound', body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Voimme järjestää sinulle takaisinsoiton. Vastaa KYLLÄ jos haluat, tai STOP lopettaaksesi.', sent_at: hoursAgo(2) },
    { id: 'm001-2', direction: 'inbound', body: 'KYLLÄ', sent_at: new Date(new Date(hoursAgo(2)).getTime() + 3 * 60000).toISOString() },
    { id: 'm001-3', direction: 'outbound', body: 'Kiitos! Mikä ongelma sinulla on? (esim. vuotava putki, rikkinäinen hana)', sent_at: new Date(new Date(hoursAgo(2)).getTime() + 4 * 60000).toISOString() },
    { id: 'm001-4', direction: 'inbound', body: 'Keittiön tiskialtaan alla vuotaa putki, vesi valuu kaappiin', sent_at: new Date(new Date(hoursAgo(2)).getTime() + 8 * 60000).toISOString() },
    { id: 'm001-5', direction: 'outbound', body: 'Ymmärrän. Kuinka kiireellinen tämä on?\n1 — Hätätapaus (tulva, turvallisuusriski)\n2 — Kiireellinen (tänään/huomenna)\n3 — Tällä viikolla\n4 — Ei kiire, haluan tarjouksen', sent_at: new Date(new Date(hoursAgo(2)).getTime() + 9 * 60000).toISOString() },
  ],
  'lead-002': [
    { id: 'm002-1', direction: 'outbound', body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Voimme järjestää sinulle takaisinsoiton. Vastaa KYLLÄ jos haluat, tai STOP lopettaaksesi.', sent_at: daysAgo(1, 14, 5) },
    { id: 'm002-2', direction: 'inbound', body: 'Kyllä kiitos', sent_at: daysAgo(1, 14, 30) },
    { id: 'm002-3', direction: 'outbound', body: 'Kiitos! Mikä ongelma sinulla on?', sent_at: daysAgo(1, 14, 31) },
    { id: 'm002-4', direction: 'inbound', body: 'Kylpyhuoneen lattialämmitys ei toimi. Termostaatti näyttää virhettä E3.', sent_at: daysAgo(1, 14, 38) },
    { id: 'm002-5', direction: 'outbound', body: 'Kuinka kiireellinen?\n1 — Hätä\n2 — Kiireellinen\n3 — Tällä viikolla\n4 — Ei kiire', sent_at: daysAgo(1, 14, 39) },
    { id: 'm002-6', direction: 'inbound', body: '3', sent_at: daysAgo(1, 14, 42) },
    { id: 'm002-7', direction: 'outbound', body: 'Selvä. Mikä on nimesi? Tässä linkki ajanvaraukseen: https://calendly.com/virtanenlvi/callback', sent_at: daysAgo(1, 14, 43) },
    { id: 'm002-8', direction: 'inbound', body: 'Anna Laine', sent_at: daysAgo(1, 14, 50) },
    { id: 'm002-9', direction: 'outbound', body: 'Aika varattu! Virtanen LVI soittaa sinulle huomenna klo 10:00. Kiitos Anna!', sent_at: daysAgo(1, 15, 0) },
  ],
  'lead-003': [],
  'lead-004': [
    { id: 'm004-1', direction: 'outbound', body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ järjestääksesi takaisinsoiton.', sent_at: daysAgo(2, 10, 35) },
    { id: 'm004-2', direction: 'inbound', body: 'Kyllä', sent_at: daysAgo(2, 10, 50) },
    { id: 'm004-3', direction: 'outbound', body: 'Mikä ongelma?', sent_at: daysAgo(2, 10, 51) },
    { id: 'm004-4', direction: 'inbound', body: 'Haluaisin tarjouksen koko talon putkisaneerauksesta. 1970-luvun rivitalo.', sent_at: daysAgo(2, 11, 5) },
    { id: 'm004-5', direction: 'outbound', body: 'Kuinka kiireellinen?\n1 — Hätä\n2 — Kiireellinen\n3 — Tällä viikolla\n4 — Ei kiire', sent_at: daysAgo(2, 11, 6) },
    { id: 'm004-6', direction: 'inbound', body: '4', sent_at: daysAgo(2, 11, 15) },
    { id: 'm004-7', direction: 'outbound', body: 'Nimesi? Ja varaa aika täältä: https://calendly.com/virtanenlvi/callback', sent_at: daysAgo(2, 11, 16) },
    { id: 'm004-8', direction: 'inbound', body: 'Liisa Virtanen', sent_at: daysAgo(2, 12, 0) },
  ],
  'lead-005': [
    { id: 'm005-1', direction: 'outbound', body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ.', sent_at: daysAgo(5, 8, 50) },
    { id: 'm005-2', direction: 'inbound', body: 'KYLLÄ', sent_at: daysAgo(5, 9, 0) },
    { id: 'm005-3', direction: 'outbound', body: 'Mikä ongelma?', sent_at: daysAgo(5, 9, 1) },
    { id: 'm005-4', direction: 'inbound', body: 'Pesukoneen hana tippuu', sent_at: daysAgo(5, 9, 10) },
    { id: 'm005-5', direction: 'outbound', body: 'Kiireellisyys?\n1-4', sent_at: daysAgo(5, 9, 11) },
    { id: 'm005-6', direction: 'inbound', body: '4', sent_at: daysAgo(5, 9, 20) },
    { id: 'm005-7', direction: 'outbound', body: 'Varaa aika: https://calendly.com/virtanenlvi/callback', sent_at: daysAgo(5, 9, 21) },
    { id: 'm005-8', direction: 'inbound', body: 'Heikki Järvinen', sent_at: daysAgo(5, 9, 35) },
    { id: 'm005-9', direction: 'outbound', body: 'Varattu! Soitamme pe klo 14:00.', sent_at: daysAgo(4, 10, 0) },
    { id: 'm005-10', direction: 'outbound', body: 'Hei Heikki, miten palvelu meni? Vastaa 1-5 (1=huono, 5=erinomainen).', sent_at: daysAgo(2, 10, 0) },
    { id: 'm005-11', direction: 'inbound', body: '5 Erinomainen palvelu! Nopea ja ammattimainen.', sent_at: daysAgo(2, 12, 0) },
  ],
  'lead-007': [
    { id: 'm007-1', direction: 'outbound', body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ järjestääksesi takaisinsoiton, tai STOP lopettaaksesi.', sent_at: hoursAgo(1) },
  ],
  'lead-008': [
    { id: 'm008-1', direction: 'outbound', body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ.', sent_at: daysAgo(1, 9, 50) },
    { id: 'm008-2', direction: 'inbound', body: 'Kyllä', sent_at: daysAgo(1, 10, 0) },
    { id: 'm008-3', direction: 'outbound', body: 'Mikä ongelma?', sent_at: daysAgo(1, 10, 1) },
    { id: 'm008-4', direction: 'inbound', body: 'Kuumavesivaraaja ei lämmitä. Vain kylmää tulee.', sent_at: daysAgo(1, 10, 15) },
    { id: 'm008-5', direction: 'outbound', body: 'Kiireellisyys?\n1 — Hätä\n2 — Kiireellinen\n3 — Tällä viikolla\n4 — Ei kiire', sent_at: daysAgo(1, 10, 16) },
    { id: 'm008-6', direction: 'inbound', body: '2', sent_at: daysAgo(1, 10, 20) },
    { id: 'm008-7', direction: 'outbound', body: 'Nimesi? Varaa aika: https://calendly.com/virtanenlvi/callback', sent_at: daysAgo(1, 10, 21) },
    { id: 'm008-8', direction: 'inbound', body: 'Timo Lahtinen', sent_at: daysAgo(1, 10, 30) },
  ],
};

// ── Revenue chart data (last 30 days) ───────────────────
export function generateRevenueData() {
  const data = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dayOfWeek = d.getDay();
    // Weekends have less activity
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
    const missed = isWeekend ? Math.floor(Math.random() * 2) : Math.floor(Math.random() * 4) + 1;
    const recovered = Math.floor(missed * (0.5 + Math.random() * 0.35));
    const revenue = recovered * (150 + Math.floor(Math.random() * 500));

    data.push({
      date: d.toISOString().split('T')[0],
      label: d.toLocaleDateString('fi-FI', { day: 'numeric', month: 'short' }),
      missed,
      recovered,
      revenue,
    });
  }
  return data;
}

// ── Computed stats ──────────────────────────────────────
export function getStats() {
  const completedLeads = leads.filter(l => ['completed', 'followed_up'].includes(l.status));
  const totalRecoverable = leads.filter(l => l.status !== 'no_consent').length;
  const recoveredCount = leads.filter(l => ['booked', 'completed', 'followed_up'].includes(l.status)).length;

  const recoveredRevenue = completedLeads.reduce((sum, l) => sum + (l.estimated_value || contractor.default_job_value), 0);
  const recoveryRate = totalRecoverable > 0 ? Math.round((recoveredCount / totalRecoverable) * 100) : 0;

  return {
    recoveredRevenue,
    leadsRecovered: recoveredCount,
    recoveryRate,
    avgResponseTime: '12 min',
  };
}
