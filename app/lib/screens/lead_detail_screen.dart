import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/leads_provider.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';
import '../models/message.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/pipeline_indicator.dart';
import '../widgets/urgency_badge.dart';
import '../widgets/status_badge.dart';
import '../widgets/conversation_bubble.dart';

/// Lead detail screen — info card, conversation thread, action buttons.
class LeadDetailScreen extends ConsumerWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final lead = ref.watch(leadByIdProvider(leadId));
    final messagesAsync = ref.watch(messagesProvider(leadId));

    if (lead == null) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(title: const Text('Lead')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❓', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Lead not found',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final canComplete = [
      LeadStatus.booked,
      LeadStatus.qualifying,
      LeadStatus.qualifyingIssue,
      LeadStatus.qualifyingUrgency,
      LeadStatus.qualifyingName,
      LeadStatus.bookingSent,
      LeadStatus.dnrAlert,
    ].contains(lead.status);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(lead.displayName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Lead info card
          _InfoCard(lead: lead, l10n: l10n, leadId: leadId),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (canComplete)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(leadsProvider.notifier).markComplete(leadId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.toastLeadCompleted)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(l10n.leadDetailMarkComplete),
                  ),
                ),
              if (canComplete) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final phone = lead.callerPhone.replaceAll(' ', '');
                    launchUrl(Uri.parse('tel:$phone'));
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(l10n.leadDetailCallLead),
                ),
              ),
            ],
          ),

          // Issue
          if (lead.issueDescription != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: l10n.leadDetailIssue,
              child: Text(
                lead.issueDescription!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ],

          // Costs section
          const SizedBox(height: 12),
          _CostsCard(lead: lead, leadId: leadId),

          // Satisfaction feedback
          if (lead.satisfactionFeedback != null) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: l10n.leadDetailFeedback,
              child: Text(
                '"${lead.satisfactionFeedback}"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],

          // Conversation
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.leadDetailConversation,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const Divider(height: 1),
                if (messagesAsync is AsyncLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (messagesAsync is AsyncError)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('Failed to load messages',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  )
                else if (messagesAsync.valueOrNull?.isEmpty ?? true)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(l10n.leadDetailNoMessages,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _ConversationThread(messages: messagesAsync.value!),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Lead info card with pipeline, key details, and badges.
class _InfoCard extends ConsumerWidget {
  final Lead lead;
  final AppLocalizations l10n;
  final String leadId;

  const _InfoCard({required this.lead, required this.l10n, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.leadDetailLeadInfo,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          PipelineIndicator(status: lead.status),
          const SizedBox(height: 14),
          _InfoRow(label: l10n.leadDetailPhone, value: lead.callerPhone, isMono: true),
          _InfoRow(
            label: l10n.leadDetailStatus,
            child: StatusBadge(status: lead.status),
          ),
          _InfoRow(
            label: l10n.leadDetailUrgency,
            child: UrgencyBadge(urgency: lead.urgency),
          ),
          _InfoRow(label: l10n.leadDetailCreated, value: app_date.formatDate(lead.createdAt)),
          if (lead.bookingTime != null)
            _InfoRow(label: l10n.leadDetailBookingTime, value: app_date.formatDate(lead.bookingTime)),
          // Tappable estimated value row
          _InfoRow(
            label: l10n.leadDetailEstimatedValue,
            child: GestureDetector(
              onTap: () => _showEditValueDialog(context, ref),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lead.estimatedValue != null ? '€${lead.estimatedValue!.toInt()}' : '—',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.accentSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          _InfoRow(
            label: l10n.leadDetailCallCount,
            value: '${lead.callCount}${lead.callCount > 1 ? ' 🔥' : ''}',
          ),
          if (lead.satisfactionScore != null)
            _InfoRow(
              label: l10n.leadDetailSatisfaction,
              value: '${'★' * lead.satisfactionScore!}${'☆' * (5 - lead.satisfactionScore!)}',
              valueColor: colors.accentPrimary,
            ),
          if (lead.calledDuringAfterHours)
            _InfoRow(
              label: l10n.leadDetailAfterHours,
              value: 'Yes',
              valueColor: colors.accentDanger,
            ),
        ],
      ),
    );
  }

  void _showEditValueDialog(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final controller = TextEditingController(
      text: lead.estimatedValue?.toInt().toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.euro_rounded, size: 20, color: colors.accentSuccess),
            const SizedBox(width: 8),
            const Text('Edit Expected Revenue'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '€ ',
            hintText: '0',
            filled: true,
            fillColor: colors.bgElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0) {
                Navigator.of(ctx).pop();
                try {
                  await ref.read(leadsProvider.notifier).updateEstimatedValue(leadId, value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Revenue updated')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Job costs card — shows individual costs and a total, with add button.
class _CostsCard extends ConsumerWidget {
  final Lead lead;
  final String leadId;

  const _CostsCard({required this.lead, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Costs', style: Theme.of(context).textTheme.headlineMedium),
              GestureDetector(
                onTap: () => _showAddCostDialog(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentPrimaryMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: colors.accentPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Add Cost',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (lead.costs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No costs recorded yet',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            ...lead.costs.map((cost) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '🧾',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cost.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatCostDate(cost.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '€${cost.amount.toStringAsFixed(cost.amount == cost.amount.roundToDouble() ? 0 : 2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.accentDanger,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 6),
            Divider(color: colors.borderSubtle, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Costs',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                ),
                Text(
                  '€${lead.totalCosts.toStringAsFixed(lead.totalCosts == lead.totalCosts.roundToDouble() ? 0 : 2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.accentDanger,
                  ),
                ),
              ],
            ),
          ],

          // Revenue vs Costs summary (only when both exist)
          if (lead.estimatedValue != null && lead.costs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: colors.borderSubtle, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Revenue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                ),
                Text(
                  '€${(lead.estimatedValue! - lead.totalCosts).toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: (lead.estimatedValue! - lead.totalCosts) >= 0
                        ? colors.accentSuccess
                        : colors.accentDanger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatCostDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showAddCostDialog(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Text('🧾', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Text('Add Cost'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Materials, Labour, Travel',
                filled: true,
                fillColor: colors.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '€ ',
                hintText: '0',
                filled: true,
                fillColor: colors.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final desc = descController.text.trim();
              final amount = double.tryParse(amountController.text);
              if (desc.isNotEmpty && amount != null && amount > 0) {
                Navigator.of(ctx).pop();
                try {
                  await ref.read(leadsProvider.notifier).addCost(leadId, desc, amount);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cost added')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final bool isMono;
  final Widget? child;

  const _InfoRow({
    required this.label,
    this.value,
    this.valueColor,
    this.isMono = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Expanded(
            child: child ??
                Text(
                  value ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: isMono ? 'monospace' : null,
                        color: valueColor,
                      ),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ConversationThread extends StatelessWidget {
  final List<Message> messages;

  const _ConversationThread({required this.messages});

  @override
  Widget build(BuildContext context) {
    String? lastDate;
    return Column(
      children: messages.map((msg) {
        final dateStr =
            '${msg.sentAt.day}.${msg.sentAt.month}.${msg.sentAt.year}';
        final showDate = dateStr != lastDate;
        lastDate = dateStr;

        return ConversationBubble(
          message: msg,
          showDate: showDate,
          dateLabel: dateStr,
        );
      }).toList(),
    );
  }
}
