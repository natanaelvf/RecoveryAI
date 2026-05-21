import 'dart:math';
import '../models/contractor.dart';
import '../models/lead.dart';
import '../models/message.dart';

/// Mock data — direct port of frontend/src/data/mock.js
/// Same Finnish contractor, 12 leads, and SMS conversations.

// ── Helpers ──────────────────────────────────────────
DateTime _daysAgo(int days, [int hours = 0, int mins = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days, hours, mins);
}

DateTime _hoursAgo(int hours) =>
    DateTime.now().subtract(Duration(hours: hours));

DateTime _minsAgo(int mins) =>
    DateTime.now().subtract(Duration(minutes: mins));

// ── Contractor ───────────────────────────────────────
final mockContractor = Contractor(
  id: 'c1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6',
  businessName: 'Virtanen LVI Oy',
  contactName: 'Jukka Virtanen',
  contactEmail: 'jukka@virtanenlvi.fi',
  contactPhone: '+358 40 555 1234',
  twilioPhoneNumber: '+358 9 1234 5678',
  numberSetupType: 'forwarding',
  calendlyUrl: 'https://calendly.com/virtanenlvi/callback',
  tradeType: 'plumber',
  defaultJobValue: 350,
  urgencyThresholdUrgentMin: 60,
  urgencyThresholdNormalMin: 1440,
  workingHoursStart: '08:00',
  workingHoursEnd: '18:00',
  workingDays: [1, 2, 3, 4, 5],
  afterHoursEmergencyPolicy:
      'Putkirikot ja vesivahingot — soita heti. Muu kiireetön työ odottaa aamuun.',
  timezone: 'Europe/Helsinki',
  tier: 'growth',
  monthlySMSCap: 150,
  smsUsedThisMonth: 87,
  createdAt: _daysAgo(60),
  updatedAt: DateTime.now(),
);

// ── Leads ────────────────────────────────────────────
final List<Lead> mockLeads = [
  Lead(
    id: 'lead-001',
    contractorId: mockContractor.id,
    callerPhone: '+358 50 123 4567',
    callerName: 'Mikko Korhonen',
    issueDescription:
        'Keittiön tiskialtaan alla vuotaa putki, vesi valuu kaappiin.',
    urgency: Urgency.high,
    status: LeadStatus.qualifying,
    consentGiven: true,
    consentGivenAt: _hoursAgo(2),
    callCount: 2,
    estimatedValue: 280,
    calledDuringAfterHours: false,
    createdAt: _hoursAgo(2),
    updatedAt: _hoursAgo(1),
  ),
  Lead(
    id: 'lead-002',
    contractorId: mockContractor.id,
    callerPhone: '+358 44 987 6543',
    callerName: 'Anna Laine',
    issueDescription:
        'Kylpyhuoneen lattialämmitys ei toimi. Termostaatti näyttää virhettä.',
    urgency: Urgency.medium,
    status: LeadStatus.booked,
    consentGiven: true,
    consentGivenAt: _daysAgo(1, 14, 30),
    bookingTime: _daysAgo(-1, 10, 0),
    callCount: 1,
    estimatedValue: 450,
    calledDuringAfterHours: false,
    createdAt: _daysAgo(1, 14, 0),
    updatedAt: _daysAgo(1, 15, 0),
  ),
  Lead(
    id: 'lead-003',
    contractorId: mockContractor.id,
    callerPhone: '+358 40 111 2222',
    callerName: 'Pekka Mäkinen',
    issueDescription:
        'WC-istuin vuotaa jatkuvasti. Vettä valuu lattialle.',
    urgency: Urgency.emergency,
    status: LeadStatus.missed,
    consentGiven: false,
    callCount: 3,
    calledDuringAfterHours: true,
    createdAt: _minsAgo(15),
    updatedAt: _minsAgo(15),
  ),
  Lead(
    id: 'lead-004',
    contractorId: mockContractor.id,
    callerPhone: '+358 50 333 4444',
    callerName: 'Liisa Virtanen',
    issueDescription:
        'Haluaisin tarjouksen koko talon putkisaneerauksesta.',
    urgency: Urgency.low,
    status: LeadStatus.bookingSent,
    consentGiven: true,
    consentGivenAt: _daysAgo(2, 11, 0),
    callCount: 1,
    estimatedValue: 2200,
    calledDuringAfterHours: false,
    createdAt: _daysAgo(2, 10, 30),
    updatedAt: _daysAgo(2, 12, 0),
  ),
  Lead(
    id: 'lead-005',
    contractorId: mockContractor.id,
    callerPhone: '+358 44 555 6666',
    callerName: 'Heikki Järvinen',
    issueDescription: 'Pesukoneen hana tippuu. Ei kiire mutta ärsyttää.',
    urgency: Urgency.low,
    status: LeadStatus.completed,
    consentGiven: true,
    consentGivenAt: _daysAgo(5, 9, 0),
    bookingTime: _daysAgo(3, 14, 0),
    callCount: 1,
    estimatedValue: 150,
    satisfactionScore: 5,
    satisfactionFeedback: 'Erinomainen palvelu! Nopea ja ammattimainen.',
    calledDuringAfterHours: false,
    createdAt: _daysAgo(5, 8, 45),
    updatedAt: _daysAgo(2, 16, 0),
  ),
  Lead(
    id: 'lead-006',
    contractorId: mockContractor.id,
    callerPhone: '+358 50 777 8888',
    callerName: 'Sanna Koivisto',
    issueDescription:
        'Vesipatterien ilmaus koko talossa (rivitalo, 4 patteria).',
    urgency: Urgency.medium,
    status: LeadStatus.completed,
    consentGiven: true,
    consentGivenAt: _daysAgo(7, 13, 0),
    bookingTime: _daysAgo(5, 9, 0),
    callCount: 1,
    estimatedValue: 200,
    satisfactionScore: 4,
    satisfactionFeedback: 'Hyvin meni, kiitos!',
    calledDuringAfterHours: false,
    createdAt: _daysAgo(7, 12, 30),
    updatedAt: _daysAgo(4, 10, 0),
  ),
  Lead(
    id: 'lead-007',
    contractorId: mockContractor.id,
    callerPhone: '+358 44 999 0000',
    urgency: Urgency.unknown,
    status: LeadStatus.consentSent,
    consentGiven: false,
    callCount: 1,
    calledDuringAfterHours: false,
    createdAt: _hoursAgo(1),
    updatedAt: _hoursAgo(1),
  ),
  Lead(
    id: 'lead-008',
    contractorId: mockContractor.id,
    callerPhone: '+358 40 222 3333',
    callerName: 'Timo Lahtinen',
    issueDescription:
        'Kuumavesivaraaja ei lämmitä. Vain kylmää vettä tulee.',
    urgency: Urgency.high,
    status: LeadStatus.dnrAlert,
    consentGiven: true,
    consentGivenAt: _daysAgo(1, 10, 0),
    callCount: 2,
    estimatedValue: 800,
    dnrAlertSent: true,
    dnrAlertSentAt: _daysAgo(1, 11, 30),
    calledDuringAfterHours: false,
    createdAt: _daysAgo(1, 9, 45),
    updatedAt: _daysAgo(1, 11, 30),
  ),
  Lead(
    id: 'lead-009',
    contractorId: mockContractor.id,
    callerPhone: '+358 50 444 5555',
    callerName: 'Maria Heikkinen',
    urgency: Urgency.unknown,
    status: LeadStatus.noConsent,
    consentGiven: false,
    callCount: 1,
    calledDuringAfterHours: true,
    createdAt: _daysAgo(3, 22, 15),
    updatedAt: _daysAgo(3, 22, 45),
  ),
  Lead(
    id: 'lead-010',
    contractorId: mockContractor.id,
    callerPhone: '+358 44 666 7777',
    callerName: 'Antti Salonen',
    issueDescription:
        'Kellariin tulee vettä sadekelillä. Tarvitsen viemäritarkastuksen.',
    urgency: Urgency.medium,
    status: LeadStatus.completed,
    consentGiven: true,
    consentGivenAt: _daysAgo(10, 11, 0),
    bookingTime: _daysAgo(8, 13, 0),
    callCount: 1,
    estimatedValue: 650,
    satisfactionScore: 5,
    satisfactionFeedback: 'Todella perusteellinen työ. Suosittelen!',
    calledDuringAfterHours: false,
    createdAt: _daysAgo(10, 10, 30),
    updatedAt: _daysAgo(7, 14, 0),
  ),
  Lead(
    id: 'lead-011',
    contractorId: mockContractor.id,
    callerPhone: '+358 40 888 9999',
    callerName: 'Eeva Nieminen',
    issueDescription:
        'Astianpesukoneen liitäntä vuotaa. Koneen alla kosteutta.',
    urgency: Urgency.high,
    status: LeadStatus.booked,
    consentGiven: true,
    consentGivenAt: _hoursAgo(5),
    bookingTime: _daysAgo(-2, 9, 0),
    callCount: 1,
    estimatedValue: 300,
    calledDuringAfterHours: false,
    createdAt: _hoursAgo(6),
    updatedAt: _hoursAgo(4),
  ),
  Lead(
    id: 'lead-012',
    contractorId: mockContractor.id,
    callerPhone: '+358 50 101 2020',
    callerName: 'Ville Koskinen',
    issueDescription:
        'Sauna kiuas ei toimi. Kytkimet ok mutta ei lämpene.',
    urgency: Urgency.low,
    status: LeadStatus.followedUp,
    consentGiven: true,
    consentGivenAt: _daysAgo(14, 15, 0),
    bookingTime: _daysAgo(12, 10, 0),
    callCount: 1,
    estimatedValue: 400,
    satisfactionScore: 3,
    satisfactionFeedback: 'Työ ok, mutta aikataulu myöhästyi tunnin.',
    calledDuringAfterHours: false,
    createdAt: _daysAgo(14, 14, 30),
    updatedAt: _daysAgo(10, 12, 0),
  ),
];

// ── Messages (SMS conversations per lead) ────────────
final Map<String, List<Message>> mockMessages = {
  'lead-001': [
    Message(id: 'm001-1', leadId: 'lead-001', direction: MessageDirection.outbound, body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Voimme järjestää sinulle takaisinsoiton. Vastaa KYLLÄ jos haluat, tai STOP lopettaaksesi.', sentAt: _hoursAgo(2)),
    Message(id: 'm001-2', leadId: 'lead-001', direction: MessageDirection.inbound, body: 'KYLLÄ', sentAt: _hoursAgo(2).add(const Duration(minutes: 3))),
    Message(id: 'm001-3', leadId: 'lead-001', direction: MessageDirection.outbound, body: 'Kiitos! Mikä ongelma sinulla on? (esim. vuotava putki, rikkinäinen hana)', sentAt: _hoursAgo(2).add(const Duration(minutes: 4))),
    Message(id: 'm001-4', leadId: 'lead-001', direction: MessageDirection.inbound, body: 'Keittiön tiskialtaan alla vuotaa putki, vesi valuu kaappiin', sentAt: _hoursAgo(2).add(const Duration(minutes: 8))),
    Message(id: 'm001-5', leadId: 'lead-001', direction: MessageDirection.outbound, body: 'Ymmärrän. Kuinka kiireellinen tämä on?\n1 — Hätätapaus (tulva, turvallisuusriski)\n2 — Kiireellinen (tänään/huomenna)\n3 — Tällä viikolla\n4 — Ei kiire, haluan tarjouksen', sentAt: _hoursAgo(2).add(const Duration(minutes: 9))),
  ],
  'lead-002': [
    Message(id: 'm002-1', leadId: 'lead-002', direction: MessageDirection.outbound, body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Voimme järjestää sinulle takaisinsoiton. Vastaa KYLLÄ jos haluat, tai STOP lopettaaksesi.', sentAt: _daysAgo(1, 14, 5)),
    Message(id: 'm002-2', leadId: 'lead-002', direction: MessageDirection.inbound, body: 'Kyllä kiitos', sentAt: _daysAgo(1, 14, 30)),
    Message(id: 'm002-3', leadId: 'lead-002', direction: MessageDirection.outbound, body: 'Kiitos! Mikä ongelma sinulla on?', sentAt: _daysAgo(1, 14, 31)),
    Message(id: 'm002-4', leadId: 'lead-002', direction: MessageDirection.inbound, body: 'Kylpyhuoneen lattialämmitys ei toimi. Termostaatti näyttää virhettä E3.', sentAt: _daysAgo(1, 14, 38)),
    Message(id: 'm002-5', leadId: 'lead-002', direction: MessageDirection.outbound, body: 'Kuinka kiireellinen?\n1 — Hätä\n2 — Kiireellinen\n3 — Tällä viikolla\n4 — Ei kiire', sentAt: _daysAgo(1, 14, 39)),
    Message(id: 'm002-6', leadId: 'lead-002', direction: MessageDirection.inbound, body: '3', sentAt: _daysAgo(1, 14, 42)),
    Message(id: 'm002-7', leadId: 'lead-002', direction: MessageDirection.outbound, body: 'Selvä. Mikä on nimesi? Tässä linkki ajanvaraukseen: https://calendly.com/virtanenlvi/callback', sentAt: _daysAgo(1, 14, 43)),
    Message(id: 'm002-8', leadId: 'lead-002', direction: MessageDirection.inbound, body: 'Anna Laine', sentAt: _daysAgo(1, 14, 50)),
    Message(id: 'm002-9', leadId: 'lead-002', direction: MessageDirection.outbound, body: 'Aika varattu! Virtanen LVI soittaa sinulle huomenna klo 10:00. Kiitos Anna!', sentAt: _daysAgo(1, 15, 0)),
  ],
  'lead-003': [],
  'lead-004': [
    Message(id: 'm004-1', leadId: 'lead-004', direction: MessageDirection.outbound, body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ järjestääksesi takaisinsoiton.', sentAt: _daysAgo(2, 10, 35)),
    Message(id: 'm004-2', leadId: 'lead-004', direction: MessageDirection.inbound, body: 'Kyllä', sentAt: _daysAgo(2, 10, 50)),
    Message(id: 'm004-3', leadId: 'lead-004', direction: MessageDirection.outbound, body: 'Mikä ongelma?', sentAt: _daysAgo(2, 10, 51)),
    Message(id: 'm004-4', leadId: 'lead-004', direction: MessageDirection.inbound, body: 'Haluaisin tarjouksen koko talon putkisaneerauksesta. 1970-luvun rivitalo.', sentAt: _daysAgo(2, 11, 5)),
    Message(id: 'm004-5', leadId: 'lead-004', direction: MessageDirection.outbound, body: 'Kuinka kiireellinen?\n1 — Hätä\n2 — Kiireellinen\n3 — Tällä viikolla\n4 — Ei kiire', sentAt: _daysAgo(2, 11, 6)),
    Message(id: 'm004-6', leadId: 'lead-004', direction: MessageDirection.inbound, body: '4', sentAt: _daysAgo(2, 11, 15)),
    Message(id: 'm004-7', leadId: 'lead-004', direction: MessageDirection.outbound, body: 'Nimesi? Ja varaa aika täältä: https://calendly.com/virtanenlvi/callback', sentAt: _daysAgo(2, 11, 16)),
    Message(id: 'm004-8', leadId: 'lead-004', direction: MessageDirection.inbound, body: 'Liisa Virtanen', sentAt: _daysAgo(2, 12, 0)),
  ],
  'lead-005': [
    Message(id: 'm005-1', leadId: 'lead-005', direction: MessageDirection.outbound, body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ.', sentAt: _daysAgo(5, 8, 50)),
    Message(id: 'm005-2', leadId: 'lead-005', direction: MessageDirection.inbound, body: 'KYLLÄ', sentAt: _daysAgo(5, 9, 0)),
    Message(id: 'm005-3', leadId: 'lead-005', direction: MessageDirection.outbound, body: 'Mikä ongelma?', sentAt: _daysAgo(5, 9, 1)),
    Message(id: 'm005-4', leadId: 'lead-005', direction: MessageDirection.inbound, body: 'Pesukoneen hana tippuu', sentAt: _daysAgo(5, 9, 10)),
    Message(id: 'm005-5', leadId: 'lead-005', direction: MessageDirection.outbound, body: 'Kiireellisyys?\n1-4', sentAt: _daysAgo(5, 9, 11)),
    Message(id: 'm005-6', leadId: 'lead-005', direction: MessageDirection.inbound, body: '4', sentAt: _daysAgo(5, 9, 20)),
    Message(id: 'm005-7', leadId: 'lead-005', direction: MessageDirection.outbound, body: 'Varaa aika: https://calendly.com/virtanenlvi/callback', sentAt: _daysAgo(5, 9, 21)),
    Message(id: 'm005-8', leadId: 'lead-005', direction: MessageDirection.inbound, body: 'Heikki Järvinen', sentAt: _daysAgo(5, 9, 35)),
    Message(id: 'm005-9', leadId: 'lead-005', direction: MessageDirection.outbound, body: 'Varattu! Soitamme pe klo 14:00.', sentAt: _daysAgo(4, 10, 0)),
    Message(id: 'm005-10', leadId: 'lead-005', direction: MessageDirection.outbound, body: 'Hei Heikki, miten palvelu meni? Vastaa 1-5 (1=huono, 5=erinomainen).', sentAt: _daysAgo(2, 10, 0)),
    Message(id: 'm005-11', leadId: 'lead-005', direction: MessageDirection.inbound, body: '5 Erinomainen palvelu! Nopea ja ammattimainen.', sentAt: _daysAgo(2, 12, 0)),
  ],
  'lead-007': [
    Message(id: 'm007-1', leadId: 'lead-007', direction: MessageDirection.outbound, body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ järjestääksesi takaisinsoiton, tai STOP lopettaaksesi.', sentAt: _hoursAgo(1)),
  ],
  'lead-008': [
    Message(id: 'm008-1', leadId: 'lead-008', direction: MessageDirection.outbound, body: 'Hei, yritit tavoittaa Virtanen LVI:tä. Vastaa KYLLÄ.', sentAt: _daysAgo(1, 9, 50)),
    Message(id: 'm008-2', leadId: 'lead-008', direction: MessageDirection.inbound, body: 'Kyllä', sentAt: _daysAgo(1, 10, 0)),
    Message(id: 'm008-3', leadId: 'lead-008', direction: MessageDirection.outbound, body: 'Mikä ongelma?', sentAt: _daysAgo(1, 10, 1)),
    Message(id: 'm008-4', leadId: 'lead-008', direction: MessageDirection.inbound, body: 'Kuumavesivaraaja ei lämmitä. Vain kylmää tulee.', sentAt: _daysAgo(1, 10, 15)),
    Message(id: 'm008-5', leadId: 'lead-008', direction: MessageDirection.outbound, body: 'Kiireellisyys?\n1 — Hätä\n2 — Kiireellinen\n3 — Tällä viikolla\n4 — Ei kiire', sentAt: _daysAgo(1, 10, 16)),
    Message(id: 'm008-6', leadId: 'lead-008', direction: MessageDirection.inbound, body: '2', sentAt: _daysAgo(1, 10, 20)),
    Message(id: 'm008-7', leadId: 'lead-008', direction: MessageDirection.outbound, body: 'Nimesi? Varaa aika: https://calendly.com/virtanenlvi/callback', sentAt: _daysAgo(1, 10, 21)),
    Message(id: 'm008-8', leadId: 'lead-008', direction: MessageDirection.inbound, body: 'Timo Lahtinen', sentAt: _daysAgo(1, 10, 30)),
  ],
};

// ── Revenue chart data (last 30 days) ────────────────
class RevenueDay {
  final DateTime date;
  final String label;
  final int missed;
  final int recovered;
  final double revenue;

  const RevenueDay({
    required this.date,
    required this.label,
    required this.missed,
    required this.recovered,
    required this.revenue,
  });
}

List<RevenueDay> generateRevenueData() {
  final rng = Random(42); // Seeded for consistency
  final data = <RevenueDay>[];

  for (int i = 29; i >= 0; i--) {
    final d = DateTime.now().subtract(Duration(days: i));
    final isWeekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
    final missed = isWeekend ? rng.nextInt(2) : rng.nextInt(4) + 1;
    final recovered = (missed * (0.5 + rng.nextDouble() * 0.35)).floor();
    final revenue = recovered * (150.0 + rng.nextInt(500));

    data.add(RevenueDay(
      date: d,
      label: '${d.day}.${d.month}.',
      missed: missed,
      recovered: recovered,
      revenue: revenue,
    ));
  }
  return data;
}

// ── Computed stats ───────────────────────────────────
class DashboardStats {
  final double recoveredRevenue;
  final int leadsRecovered;
  final int recoveryRate;
  final String avgResponseTime;

  const DashboardStats({
    required this.recoveredRevenue,
    required this.leadsRecovered,
    required this.recoveryRate,
    required this.avgResponseTime,
  });
}

DashboardStats computeStats(List<Lead> leads) {
  final completedLeads = leads
      .where((l) => l.status == LeadStatus.completed || l.status == LeadStatus.followedUp)
      .toList();
  final totalRecoverable =
      leads.where((l) => l.status != LeadStatus.noConsent).length;
  final recoveredCount = leads
      .where((l) =>
          l.status == LeadStatus.booked ||
          l.status == LeadStatus.completed ||
          l.status == LeadStatus.followedUp)
      .length;

  final recoveredRevenue = completedLeads.fold<double>(
    0,
    (sum, l) => sum + (l.estimatedValue ?? mockContractor.defaultJobValue ?? 350),
  );
  final recoveryRate = totalRecoverable > 0
      ? ((recoveredCount / totalRecoverable) * 100).round()
      : 0;

  return DashboardStats(
    recoveredRevenue: recoveredRevenue,
    leadsRecovered: recoveredCount,
    recoveryRate: recoveryRate,
    avgResponseTime: '12 min',
  );
}
