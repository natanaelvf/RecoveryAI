import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../providers/leads_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/lead_card.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/add_lead_sheet.dart';

/// Leads list screen — search, filter chips, lead cards, and FAB for adding leads.
class LeadsScreen extends ConsumerWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final leads = ref.watch(filteredLeadsProvider);
    final counts = ref.watch(leadCountsProvider);
    final selectedFilter = ref.watch(statusFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final filterLabels = [
      l10n.leadsFilterAll,
      l10n.leadsFilterMissed,
      l10n.leadsFilterContacted,
      l10n.leadsFilterBooked,
      l10n.leadsFilterCompleted,
    ];

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(l10n.leadsTitle),
      ),
      // ── FAB for manual lead input ──────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: colors.bgSurface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => AddLeadSheet(
              onSubmit: ({
                required String phone,
                String? name,
                String? description,
                String urgency = 'medium',
                double? estimatedValue,
              }) {
                ref.read(leadsProvider).addLead(
                      phone: phone,
                      name: name,
                      description: description,
                      urgency: urgency,
                      estimatedValue: estimatedValue,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lead added: $phone'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: l10n.leadsSearchPlaceholder,
                prefixIcon: Icon(Icons.search, color: colors.textTertiary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterChipBar(
              counts: counts,
              selected: selectedFilter,
              labels: filterLabels,
              onSelected: (key) =>
                  ref.read(statusFilterProvider.notifier).state = key,
            ),
          ),
          const SizedBox(height: 8),

          // Leads list
          Expanded(
            child: leads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          searchQuery.isNotEmpty || selectedFilter != 'all'
                              ? l10n.leadsNoResults
                              : l10n.leadsEmptyTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.leadsEmptyDesc,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: leads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lead = leads[index];
                      return LeadCard(
                        lead: lead,
                        onTap: () => context.push('/leads/${lead.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
