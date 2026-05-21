import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/stats_provider.dart';
import '../providers/leads_provider.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';
import '../widgets/stat_card.dart';
import '../widgets/revenue_chart.dart';

/// Dashboard screen — stats, chart, and recent wins.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(statsProvider);
    final revenueData = ref.watch(revenueDataProvider);
    final allLeads = ref.watch(leadsProvider).leads;

    final recentWins = allLeads
        .where((l) =>
            l.status == LeadStatus.completed ||
            l.status == LeadStatus.followedUp)
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats grid — 2x2
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                label: l10n.dashboardRecoveredRevenue,
                targetValue: stats.recoveredRevenue,
                prefix: '€',
                trend: '23% ${l10n.dashboardTrendUp}',
                emoji: '💰',
                accentColor: AppColors.accentSuccess,
              ),
              StatCard(
                label: l10n.dashboardLeadsRecovered,
                targetValue: stats.leadsRecovered.toDouble(),
                trend: '12% ${l10n.dashboardTrendUp}',
                emoji: '📞',
                accentColor: AppColors.accentPrimary,
              ),
              StatCard(
                label: l10n.dashboardRecoveryRate,
                targetValue: stats.recoveryRate.toDouble(),
                suffix: '%',
                trend: '5% ${l10n.dashboardTrendUp}',
                emoji: '📈',
                accentColor: AppColors.accentInfo,
              ),
              StatCard(
                label: l10n.dashboardAvgResponseTime,
                targetValue: 12,
                suffix: ' min',
                trend: '3min ${l10n.dashboardTrendUp}',
                trendUp: false,
                emoji: '⚡',
                accentColor: AppColors.accentDanger,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Revenue chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardRevenueChartTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                RevenueChart(data: revenueData),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recent wins
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.dashboardRecentWins,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const Divider(height: 1),
                if (recentWins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            l10n.dashboardNoWinsYet,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentWins.map((lead) => _WinItem(lead: lead)),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _WinItem extends StatelessWidget {
  final Lead lead;

  const _WinItem({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lead.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '€${(lead.estimatedValue ?? 350).toInt()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.accentSuccess,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 12),
          if (lead.satisfactionScore != null)
            Text(
              '${'★' * lead.satisfactionScore!}${'☆' * (5 - lead.satisfactionScore!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accentPrimary,
              ),
            )
          else
            const Text('—', style: TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
