import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/activity_event.dart';
import '../models/lead.dart';
import '../models/message.dart';

/// Dynamic activity event notifier — seeded with mock events,
/// new events are pushed when actions occur (complete, revenue edit, cost add).
class ActivityNotifier extends ChangeNotifier {
  final List<ActivityEvent> _events = List.from(generateMockActivityEvents());

  List<ActivityEvent> get events => _events;

  void addEvent(ActivityEvent event) {
    _events.insert(0, event); // newest first
    notifyListeners();
  }
}

final activityNotifierProvider = ChangeNotifierProvider<ActivityNotifier>((ref) {
  return ActivityNotifier();
});

/// Activity events — derived from the dynamic notifier.
final activityEventsProvider = Provider<List<ActivityEvent>>((ref) {
  return ref.watch(activityNotifierProvider).events;
});

/// Leads state — manages the full leads list, filtering, and search.
class LeadsNotifier extends ChangeNotifier {
  final List<Lead> _leads = List.from(mockLeads);

  /// Reference to the activity notifier for pushing events.
  final ActivityNotifier _activityNotifier;

  LeadsNotifier(this._activityNotifier);

  List<Lead> get leads => _leads;

  void markComplete(String leadId) {
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx != -1) {
      final lead = _leads[idx];
      _leads[idx] = lead.copyWith(
        status: LeadStatus.completed,
        updatedAt: DateTime.now(),
      );

      // Push activity event
      _activityNotifier.addEvent(ActivityEvent(
        type: ActivityType.leadCompleted,
        description: 'Lead completed: ${lead.displayName}',
        timestamp: DateTime.now(),
        leadId: leadId,
      ));

      notifyListeners();
    }
  }

  /// Update the estimated value (expected revenue) for a lead.
  void updateEstimatedValue(String leadId, double newValue) {
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx != -1) {
      final lead = _leads[idx];
      final oldValue = lead.estimatedValue;
      _leads[idx] = lead.copyWith(
        estimatedValue: newValue,
        updatedAt: DateTime.now(),
      );

      // Push activity event
      _activityNotifier.addEvent(ActivityEvent(
        type: ActivityType.revenueUpdated,
        description: oldValue != null
            ? 'Revenue updated: ${lead.displayName} — €${oldValue.toInt()} → €${newValue.toInt()}'
            : 'Revenue set: ${lead.displayName} — €${newValue.toInt()}',
        timestamp: DateTime.now(),
        leadId: leadId,
      ));

      notifyListeners();
    }
  }

  /// Add a cost entry to a lead (tracked separately from revenue).
  void addCost(String leadId, String description, double amount) {
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx != -1) {
      final lead = _leads[idx];
      final cost = JobCost(
        id: 'cost-${DateTime.now().millisecondsSinceEpoch}',
        description: description,
        amount: amount,
        createdAt: DateTime.now(),
      );
      _leads[idx] = lead.copyWith(
        costs: [...lead.costs, cost],
        updatedAt: DateTime.now(),
      );

      // Push activity event
      _activityNotifier.addEvent(ActivityEvent(
        type: ActivityType.costAdded,
        description: 'Cost added: ${lead.displayName} — €${amount.toInt()} ($description)',
        timestamp: DateTime.now(),
        leadId: leadId,
      ));

      notifyListeners();
    }
  }

  /// Add a lead manually — inserts at the top of the list.
  void addLead({
    required String phone,
    String? name,
    String? description,
    String urgency = 'medium',
    double? estimatedValue,
  }) {
    final id = 'lead-manual-${DateTime.now().millisecondsSinceEpoch}';
    final urgencyValue = _parseUrgency(urgency);

    _leads.insert(
      0,
      Lead(
        id: id,
        contractorId: mockContractor.id,
        callerPhone: phone,
        callerName: name,
        issueDescription: description,
        urgency: urgencyValue,
        status: LeadStatus.missed,
        consentGiven: false,
        callCount: 1,
        estimatedValue: estimatedValue,
        calledDuringAfterHours: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Urgency _parseUrgency(String value) {
    switch (value) {
      case 'emergency': return Urgency.emergency;
      case 'high': return Urgency.high;
      case 'medium': return Urgency.medium;
      case 'low': return Urgency.low;
      default: return Urgency.unknown;
    }
  }
}

final leadsProvider = ChangeNotifierProvider<LeadsNotifier>((ref) {
  final activityNotifier = ref.read(activityNotifierProvider);
  return LeadsNotifier(activityNotifier);
});

/// Current status filter selection.
final statusFilterProvider = StateProvider<String>((ref) => 'all');

/// Current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered + sorted leads derived provider.
final filteredLeadsProvider = Provider<List<Lead>>((ref) {
  final allLeads = ref.watch(leadsProvider).leads;
  final filter = ref.watch(statusFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  var filtered = List<Lead>.from(allLeads);

  // Sort by created_at descending (newest first)
  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Status filter
  if (filter != 'all') {
    filtered = filtered.where((l) => l.status.filterCategory == filter).toList();
  }

  // Search filter
  if (query.isNotEmpty) {
    filtered = filtered.where((l) {
      final nameMatch =
          l.callerName?.toLowerCase().contains(query) ?? false;
      final phoneMatch =
          l.callerPhone.replaceAll(' ', '').contains(query.replaceAll(' ', ''));
      return nameMatch || phoneMatch;
    }).toList();
  }

  return filtered;
});

/// Lead by ID.
final leadByIdProvider = Provider.family<Lead?, String>((ref, id) {
  final leads = ref.watch(leadsProvider).leads;
  try {
    return leads.firstWhere((l) => l.id == id);
  } catch (_) {
    return null;
  }
});

/// Messages for a specific lead.
final messagesProvider = Provider.family<List<Message>, String>((ref, leadId) {
  return mockMessages[leadId] ?? [];
});

/// Lead counts per filter category.
final leadCountsProvider = Provider<Map<String, int>>((ref) {
  final leads = ref.watch(leadsProvider).leads;
  final counts = <String, int>{
    'all': leads.length,
    'missed': 0,
    'contacted': 0,
    'booked': 0,
    'completed': 0,
  };

  for (final l in leads) {
    final cat = l.status.filterCategory;
    counts[cat] = (counts[cat] ?? 0) + 1;
  }

  return counts;
});
