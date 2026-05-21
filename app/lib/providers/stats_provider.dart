import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import 'leads_provider.dart';

/// Dashboard stats derived from leads.
final statsProvider = Provider<DashboardStats>((ref) {
  final leads = ref.watch(leadsProvider).leads;
  return computeStats(leads);
});

/// Revenue chart data (30 days).
final revenueDataProvider = Provider<List<RevenueDay>>((ref) {
  return generateRevenueData();
});
