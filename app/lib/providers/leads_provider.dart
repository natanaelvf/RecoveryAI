import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_event.dart';
import '../models/lead.dart';
import '../models/message.dart';
import '../services/api_service.dart';

final _api = ApiService();

// ---------------------------------------------------------------------------
// Activity feed — remains local (client-generated from mutations).
// Will be wired to Realtime events in a later phase.
// ---------------------------------------------------------------------------

class ActivityNotifier extends ChangeNotifier {
  final List<ActivityEvent> _events = [];

  List<ActivityEvent> get events => _events;

  void addEvent(ActivityEvent event) {
    _events.insert(0, event); // newest first
    if (_events.length > 50) _events.removeLast(); // cap at 50
    notifyListeners();
  }
}

final activityNotifierProvider =
    ChangeNotifierProvider<ActivityNotifier>((ref) {
  return ActivityNotifier();
});

/// Activity events — derived from the dynamic notifier.
final activityEventsProvider = Provider<List<ActivityEvent>>((ref) {
  return ref.watch(activityNotifierProvider).events;
});

// ---------------------------------------------------------------------------
// Leads provider — async, Supabase-backed + Realtime
// ---------------------------------------------------------------------------

class LeadsNotifier extends AsyncNotifier<List<Lead>> {
  RealtimeChannel? _realtimeChannel;

  @override
  Future<List<Lead>> build() async {
    // Fetch all leads on init.
    final leads = await _api.fetchAllLeads();

    // Subscribe to Realtime for live updates.
    _setupRealtime();

    // Clean up Realtime on dispose.
    ref.onDispose(() {
      if (_realtimeChannel != null) {
        _api.unsubscribe(_realtimeChannel!);
        _realtimeChannel = null;
      }
    });

    return leads;
  }

  void _setupRealtime() {
    _realtimeChannel = _api.subscribeToLeads(
      onInsert: (newRecord) {
        final currentLeads = state.valueOrNull;
        if (currentLeads == null) return;

        try {
          final newLead = Lead.fromJson(newRecord);
          state = AsyncData([newLead, ...currentLeads]);

          // Push activity event for new lead.
          ref.read(activityNotifierProvider).addEvent(ActivityEvent(
            type: ActivityType.newLead,
            description: 'New lead: ${newLead.displayName}',
            timestamp: DateTime.now(),
            leadId: newLead.id,
          ));
        } catch (e) {
          debugPrint('[realtime] Failed to parse inserted lead: $e');
        }
      },
      onUpdate: (newRecord) {
        final currentLeads = state.valueOrNull;
        if (currentLeads == null) return;

        try {
          final updatedLead = Lead.fromJson(newRecord);
          final updatedList = currentLeads.map((l) {
            return l.id == updatedLead.id ? updatedLead : l;
          }).toList();
          state = AsyncData(updatedList);
        } catch (e) {
          debugPrint('[realtime] Failed to parse updated lead: $e');
        }
      },
      onDelete: (oldRecord) {
        final currentLeads = state.valueOrNull;
        if (currentLeads == null) return;

        final deletedId = oldRecord['id'] as String?;
        if (deletedId != null) {
          final updatedList =
              currentLeads.where((l) => l.id != deletedId).toList();
          state = AsyncData(updatedList);
        }
      },
    );
  }

  /// Mark a lead as completed. Schedules satisfaction follow-up via Supabase.
  Future<void> markComplete(String leadId) async {
    try {
      final updatedLead = await _api.markLeadComplete(leadId);

      // Update local state immediately.
      final currentLeads = state.valueOrNull ?? [];
      state = AsyncData(currentLeads.map((l) {
        return l.id == leadId ? updatedLead : l;
      }).toList());

      // Push activity event.
      ref.read(activityNotifierProvider).addEvent(ActivityEvent(
        type: ActivityType.leadCompleted,
        description: 'Lead completed: ${updatedLead.displayName}',
        timestamp: DateTime.now(),
        leadId: leadId,
      ));
    } catch (e) {
      debugPrint('Failed to mark lead complete: $e');
      rethrow;
    }
  }

  /// Update the estimated value (expected revenue) for a lead.
  Future<void> updateEstimatedValue(String leadId, double newValue) async {
    try {
      final updatedLead = await _api.updateLead(
        leadId,
        {'estimated_value': newValue},
      );

      final currentLeads = state.valueOrNull ?? [];
      final oldLead = currentLeads.firstWhere(
        (l) => l.id == leadId,
        orElse: () => updatedLead,
      );

      state = AsyncData(currentLeads.map((l) {
        return l.id == leadId ? updatedLead : l;
      }).toList());

      // Push activity event.
      ref.read(activityNotifierProvider).addEvent(ActivityEvent(
        type: ActivityType.revenueUpdated,
        description: oldLead.estimatedValue != null
            ? 'Revenue updated: ${updatedLead.displayName} — €${oldLead.estimatedValue!.toInt()} → €${newValue.toInt()}'
            : 'Revenue set: ${updatedLead.displayName} — €${newValue.toInt()}',
        timestamp: DateTime.now(),
        leadId: leadId,
      ));
    } catch (e) {
      debugPrint('Failed to update estimated value: $e');
      rethrow;
    }
  }

  /// Add a cost entry to a lead.
  Future<void> addCost(
      String leadId, String description, double amount) async {
    try {
      await _api.addCost(leadId, description, amount);

      // Re-fetch the lead to get updated costs list.
      // (The lead model holds costs locally; we update via re-fetch.)
      final costs = await _api.fetchJobCosts(leadId);
      final currentLeads = state.valueOrNull ?? [];
      state = AsyncData(currentLeads.map((l) {
        if (l.id == leadId) {
          return l.copyWith(costs: costs, updatedAt: DateTime.now());
        }
        return l;
      }).toList());

      // Push activity event.
      final lead = currentLeads.firstWhere((l) => l.id == leadId);
      ref.read(activityNotifierProvider).addEvent(ActivityEvent(
        type: ActivityType.costAdded,
        description:
            'Cost added: ${lead.displayName} — €${amount.toInt()} ($description)',
        timestamp: DateTime.now(),
        leadId: leadId,
      ));
    } catch (e) {
      debugPrint('Failed to add cost: $e');
      rethrow;
    }
  }

  /// Add a lead manually.
  Future<void> addLead({
    required String phone,
    String? name,
    String? description,
    String urgency = 'unknown',
    double? estimatedValue,
  }) async {
    try {
      final newLead = await _api.addLeadManually(
        phone: phone,
        name: name,
        description: description,
        urgency: urgency,
        estimatedValue: estimatedValue,
      );

      // Prepend to local state (Realtime will also fire, but we update
      // optimistically to avoid delay).
      final currentLeads = state.valueOrNull ?? [];
      // Avoid duplicates if Realtime fires first.
      if (!currentLeads.any((l) => l.id == newLead.id)) {
        state = AsyncData([newLead, ...currentLeads]);
      }
    } catch (e) {
      debugPrint('Failed to add lead: $e');
      rethrow;
    }
  }

  /// Force refresh all leads from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.fetchAllLeads());
  }

  /// GDPR delete a lead.
  Future<void> deleteLeadGdpr(String leadId) async {
    try {
      await _api.deleteLeadGdpr(leadId);

      // Remove from local state.
      final currentLeads = state.valueOrNull ?? [];
      state =
          AsyncData(currentLeads.where((l) => l.id != leadId).toList());
    } catch (e) {
      debugPrint('Failed to delete lead: $e');
      rethrow;
    }
  }
}

final leadsProvider =
    AsyncNotifierProvider<LeadsNotifier, List<Lead>>(LeadsNotifier.new);

// ---------------------------------------------------------------------------
// Derived providers — same logic as before, but read from async source
// ---------------------------------------------------------------------------

/// Current status filter selection.
final statusFilterProvider = StateProvider<String>((ref) => 'all');

/// Current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered + sorted leads derived provider.
/// Returns an empty list while loading.
final filteredLeadsProvider = Provider<List<Lead>>((ref) {
  final allLeadsAsync = ref.watch(leadsProvider);
  final allLeads = allLeadsAsync.valueOrNull ?? [];
  final filter = ref.watch(statusFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  var filtered = List<Lead>.from(allLeads);

  // Sort by created_at descending (newest first)
  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Status filter
  if (filter != 'all') {
    filtered =
        filtered.where((l) => l.status.filterCategory == filter).toList();
  }

  // Search filter
  if (query.isNotEmpty) {
    filtered = filtered.where((l) {
      final nameMatch =
          l.callerName?.toLowerCase().contains(query) ?? false;
      final phoneMatch = l.callerPhone
          .replaceAll(' ', '')
          .contains(query.replaceAll(' ', ''));
      return nameMatch || phoneMatch;
    }).toList();
  }

  return filtered;
});

/// Lead by ID — returns null while loading or if not found.
final leadByIdProvider = Provider.family<Lead?, String>((ref, id) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];
  try {
    return leads.firstWhere((l) => l.id == id);
  } catch (_) {
    return null;
  }
});

/// Messages for a specific lead — fetched from Supabase.
final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, leadId) async {
  return _api.fetchMessages(leadId);
});

/// Job costs for a specific lead — fetched from Supabase.
final jobCostsProvider =
    FutureProvider.family<List<JobCost>, String>((ref, leadId) async {
  return _api.fetchJobCosts(leadId);
});

/// Lead counts per filter category.
final leadCountsProvider = Provider<Map<String, int>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final leads = leadsAsync.valueOrNull ?? [];

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
