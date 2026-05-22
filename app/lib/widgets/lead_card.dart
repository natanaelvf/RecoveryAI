import 'package:flutter/material.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';
import '../utils/date_utils.dart' as app_date;
import 'pipeline_indicator.dart';
import 'urgency_badge.dart';
import 'status_badge.dart';

/// Lead card — matches the web prototype's lead-card component.
/// Shows phone, name, issue, urgency/status badges, call count, and pipeline.
class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onTap;

  const LeadCard({super.key, required this.lead, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final isEmergency = lead.urgency == Urgency.emergency;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: isEmergency
                ? [
                    BoxShadow(
                      color: colors.accentDanger.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Colored left accent strip
              Container(
                width: 3,
                color: _leftBorderColor(colors),
              ),
              // Card content
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: phone + time ago
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lead.callerPhone,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      color: colors.textTertiary,
                                      fontSize: 12,
                                    ),
                              ),
                              Text(
                                app_date.timeAgo(context, lead.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textTertiary,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),

                          // Name
                          if (lead.callerName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              lead.callerName!,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Issue
                          const SizedBox(height: 6),
                          Text(
                            lead.issueDescription != null
                                ? '"${lead.issueDescription}"'
                                : l10n.waitingForResponse,
                            style: TextStyle(
                              fontSize: 13,
                              color: lead.issueDescription != null
                                  ? colors.textSecondary
                                  : colors.textTertiary,
                              fontStyle: lead.issueDescription == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          // Footer: urgency + status + call count
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              UrgencyBadge(urgency: lead.urgency),
                              StatusBadge(status: lead.status),
                              if (lead.callCount > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.accentPrimaryMuted,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '📞 ${l10n.leadsCalledTimes(lead.callCount)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.accentPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Pipeline
                          PipelineIndicator(status: lead.status),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _leftBorderColor(AppColors colors) {
    switch (lead.status) {
      case LeadStatus.missed:
      case LeadStatus.consentSent:
      case LeadStatus.dnrAlert:
        return colors.accentDanger;
      case LeadStatus.optedIn:
      case LeadStatus.qualifying:
      case LeadStatus.qualifyingIssue:
      case LeadStatus.qualifyingUrgency:
      case LeadStatus.qualifyingName:
      case LeadStatus.bookingSent:
        return colors.accentPrimary;
      case LeadStatus.booked:
        return colors.accentSuccess;
      case LeadStatus.completed:
      case LeadStatus.followedUp:
        return colors.accentInfo;
      case LeadStatus.noConsent:
        return colors.textTertiary;
    }
  }
}
