import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead.dart';
import '../widgets/month_calendar.dart';
import 'contractor_provider.dart';
import 'leads_provider.dart';

// ---------------------------------------------------------------------------
// Stats model
// ---------------------------------------------------------------------------

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

DashboardStats _computeStats(List<Lead> leads, double defaultJobValue) {
  final completedLeads = leads
      .where(
          (l) => l.status == LeadStatus.completed || l.status == LeadStatus.followedUp)
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
    (sum, l) => sum + (l.estimatedValue ?? defaultJobValue),
  );
  final recoveryRate = totalRecoverable > 0
      ? ((recoveredCount / totalRecoverable) * 100).round()
      : 0;

  return DashboardStats(
    recoveredRevenue: recoveredRevenue,
    leadsRecovered: recoveredCount,
    recoveryRate: recoveryRate,
    avgResponseTime: '—', // TODO: compute from real message timestamps
  );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Dashboard stats derived from leads and contractor's default job value.
final statsProvider = Provider<DashboardStats>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final contractorAsync = ref.watch(contractorProvider);

  final leads = leadsAsync.valueOrNull ?? [];
  final defaultJobValue = contractorAsync.valueOrNull?.defaultJobValue ?? 350;

  return _computeStats(leads, defaultJobValue);
});

/// Display month for the calendar — defaults to current month.
final displayMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Calendar day data — collected leads and booking revenue per day for the display month.
final calendarDayDataProvider = Provider<Map<DateTime, CalendarDayData>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];
  final displayMonth = ref.watch(displayMonthProvider);
  final data = <DateTime, CalendarDayData>{};

  final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
  final lastDay = DateTime(displayMonth.year, displayMonth.month + 1, 0);

  // Initialize all days in the month
  for (var d = firstDay; !d.isAfter(lastDay); d = d.add(const Duration(days: 1))) {
    final dateOnly = DateTime(d.year, d.month, d.day);
    data[dateOnly] = CalendarDayData(date: dateOnly);
  }

  for (final lead in leads) {
    // Collected leads: count leads created on each day that have progressed
    // past missed status (opted-in, qualifying, booked, completed, etc.)
    final createdDate = DateTime(lead.createdAt.year, lead.createdAt.month, lead.createdAt.day);
    if (data.containsKey(createdDate) && _isCollectedLead(lead)) {
      final existing = data[createdDate]!;
      data[createdDate] = CalendarDayData(
        date: createdDate,
        collectedLeads: existing.collectedLeads + 1,
        bookingRevenue: existing.bookingRevenue,
      );
    }

    // Booking revenue: for future bookings, put the revenue on the booking day
    if (lead.bookingTime != null && lead.estimatedValue != null) {
      final bookingDate = DateTime(
        lead.bookingTime!.year,
        lead.bookingTime!.month,
        lead.bookingTime!.day,
      );
      if (data.containsKey(bookingDate)) {
        final existing = data[bookingDate]!;
        data[bookingDate] = CalendarDayData(
          date: bookingDate,
          collectedLeads: existing.collectedLeads,
          bookingRevenue: existing.bookingRevenue + lead.estimatedValue!,
        );
      }
    }
  }

  return data;
});

/// Whether a lead counts as "collected" (progressed beyond initial missed state).
bool _isCollectedLead(Lead lead) {
  switch (lead.status) {
    case LeadStatus.optedIn:
    case LeadStatus.qualifying:
    case LeadStatus.qualifyingIssue:
    case LeadStatus.qualifyingUrgency:
    case LeadStatus.qualifyingName:
    case LeadStatus.bookingSent:
    case LeadStatus.booked:
    case LeadStatus.completed:
    case LeadStatus.followedUp:
      return true;
    case LeadStatus.missed:
    case LeadStatus.consentSent:
    case LeadStatus.dnrAlert:
    case LeadStatus.noConsent:
      return false;
  }
}

/// Pipeline counts — derived from leads by status stage.
final pipelineCountsProvider = Provider<Map<String, int>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];

  int missed = 0;
  int contacted = 0;
  int booked = 0;
  int completed = 0;

  for (final lead in leads) {
    switch (lead.status) {
      case LeadStatus.missed:
      case LeadStatus.consentSent:
      case LeadStatus.dnrAlert:
      case LeadStatus.noConsent:
        missed++;
        break;
      case LeadStatus.optedIn:
      case LeadStatus.qualifying:
      case LeadStatus.qualifyingIssue:
      case LeadStatus.qualifyingUrgency:
      case LeadStatus.qualifyingName:
      case LeadStatus.bookingSent:
        contacted++;
        break;
      case LeadStatus.booked:
        booked++;
        break;
      case LeadStatus.completed:
      case LeadStatus.followedUp:
        completed++;
        break;
    }
  }

  return {
    'missed': missed,
    'contacted': contacted,
    'booked': booked,
    'completed': completed,
  };
})
;

/// Selected time range for the revenue chart.
final timeRangeProvider = StateProvider<String>((ref) => '30d');

/// Selected calendar date — defaults to today.
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Calendar event counts — how many bookings per day in the visible range.
final calendarEventCountsProvider = Provider<Map<DateTime, int>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];
  final counts = <DateTime, int>{};

  for (final lead in leads) {
    if (lead.bookingTime != null) {
      final dateOnly = DateTime(
        lead.bookingTime!.year,
        lead.bookingTime!.month,
        lead.bookingTime!.day,
      );
      counts[dateOnly] = (counts[dateOnly] ?? 0) + 1;
    }
  }

  return counts;
});

/// Scheduled leads for a specific date.
final scheduledLeadsForDateProvider =
    Provider.family<List<Lead>, DateTime>((ref, date) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];
  final dateOnly = DateTime(date.year, date.month, date.day);

  return leads
      .where((l) {
        if (l.bookingTime == null) return false;
        final bookingDate = DateTime(
          l.bookingTime!.year,
          l.bookingTime!.month,
          l.bookingTime!.day,
        );
        return bookingDate == dateOnly;
      })
      .toList()
    ..sort((a, b) => a.bookingTime!.compareTo(b.bookingTime!));
});

/// Leads needing urgent attention — missed + DNR + consent pending.
final urgentLeadsProvider = Provider<List<Lead>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];

  return leads
      .where((l) =>
          l.status == LeadStatus.missed ||
          l.status == LeadStatus.dnrAlert ||
          l.status == LeadStatus.consentSent)
      .toList()
    ..sort((a, b) {
      // Emergency first, then by recency
      final aWeight = a.urgency == Urgency.emergency ? 0 : 1;
      final bWeight = b.urgency == Urgency.emergency ? 0 : 1;
      if (aWeight != bWeight) return aWeight.compareTo(bWeight);
      return b.createdAt.compareTo(a.createdAt);
    });
});

/// SMS usage from the contractor provider.
final smsUsageProvider = Provider<({int used, int cap})>((ref) {
  final contractorAsync = ref.watch(contractorProvider);
  final contractor = contractorAsync.valueOrNull;
  return (
    used: contractor?.smsUsedThisMonth ?? 0,
    cap: contractor?.monthlySMSCap ?? 50,
  );
});

/// All leads associated with a calendar date — created on that date OR booked for that date.
final leadsForCalendarDateProvider =
    Provider.family<List<Lead>, DateTime>((ref, date) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];
  final dateOnly = DateTime(date.year, date.month, date.day);

  return leads.where((l) {
    final createdDate = DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day);
    if (createdDate == dateOnly) return true;

    if (l.bookingTime != null) {
      final bookingDate = DateTime(
        l.bookingTime!.year,
        l.bookingTime!.month,
        l.bookingTime!.day,
      );
      if (bookingDate == dateOnly) return true;
    }
    return false;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
