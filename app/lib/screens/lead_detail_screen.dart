import 'package:flutter/material.dart';
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
    final messages = ref.watch(messagesProvider(leadId));

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
          _InfoCard(lead: lead, l10n: l10n),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (canComplete)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(leadsProvider).markComplete(leadId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.toastLeadCompleted)),
                      );
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
                if (messages.isEmpty)
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
                    child: _ConversationThread(messages: messages),
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
class _InfoCard extends StatelessWidget {
  final Lead lead;
  final AppLocalizations l10n;

  const _InfoCard({required this.lead, required this.l10n});

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
          _InfoRow(
            label: l10n.leadDetailEstimatedValue,
            value: lead.estimatedValue != null ? '€${lead.estimatedValue!.toInt()}' : '—',
            valueColor: colors.accentSuccess,
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
