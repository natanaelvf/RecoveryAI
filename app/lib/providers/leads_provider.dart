import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/lead.dart';
import '../models/message.dart';

/// Leads state — manages the full leads list, filtering, and search.
class LeadsNotifier extends ChangeNotifier {
  final List<Lead> _leads = List.from(mockLeads);

  List<Lead> get leads => _leads;

  void markComplete(String leadId) {
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx != -1) {
      _leads[idx] = _leads[idx].copyWith(
        status: LeadStatus.completed,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }
}

final leadsProvider = ChangeNotifierProvider<LeadsNotifier>((ref) {
  return LeadsNotifier();
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
