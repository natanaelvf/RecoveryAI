import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/activity_event.dart';
import '../models/lead.dart';
import '../widgets/month_calendar.dart';
import 'leads_provider.dart';

/// Dashboard stats derived from leads.
final statsProvider = Provider<DashboardStats>((ref) {
  final leads = ref.watch(leadsProvider).leads;
  return computeStats(leads);
});

/// Display month for the calendar — defaults to current month.
final displayMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Calendar day data — collected leads and booking revenue per day for the display month.
final calendarDayDataProvider = Provider<Map<DateTime, CalendarDayData>>((ref) {
  final leads = ref.watch(leadsProvider).leads;
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
  final leads = ref.watch(leadsProvider).leads;
  return computePipelineCounts(leads);
});

/// Selected time range for the revenue chart.
final timeRangeProvider = StateProvider<String>((ref) => '30d');

/// Activity events — mock data for now.
final activityEventsProvider = Provider<List<ActivityEvent>>((ref) {
  return generateMockActivityEvents();
});

/// Selected calendar date — defaults to today.
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Calendar event counts — how many bookings per day in the visible range.
final calendarEventCountsProvider = Provider<Map<DateTime, int>>((ref) {
  final leads = ref.watch(leadsProvider).leads;
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
  final leads = ref.watch(leadsProvider).leads;
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
  final leads = ref.watch(leadsProvider).leads;
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

/// SMS usage from mock contractor data.
final smsUsageProvider = Provider<({int used, int cap})>((ref) {
  return (used: mockContractor.smsUsedThisMonth, cap: mockContractor.monthlySMSCap);
});

/// All leads associated with a calendar date — created on that date OR booked for that date.
final leadsForCalendarDateProvider =
    Provider.family<List<Lead>, DateTime>((ref, date) {
  final leads = ref.watch(leadsProvider).leads;
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
