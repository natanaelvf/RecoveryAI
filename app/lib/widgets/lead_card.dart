import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final isEmergency = lead.urgency == Urgency.emergency;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          // Use Border.all (uniform) so borderRadius is allowed.
          // The left accent colour is rendered as a Positioned strip inside.
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: isEmergency
              ? [
                  BoxShadow(
                    color: AppColors.accentDanger.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        // ClipRRect keeps the left strip clipped to the card's rounded corners.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              // Coloured left accent strip (3 px wide)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: _leftBorderColor),
              ),
              // Card content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(7),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 17, // 14 base + 3 for the accent strip
                      right: 14,
                      top: 14,
                      bottom: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: phone + time ago
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lead.callerPhone,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                            ),
                            Text(
                              app_date.timeAgo(context, lead.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
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
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPrimaryMuted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '📞 ${l10n.leadsCalledTimes(lead.callCount)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accentPrimary,
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
            ],
          ),
        ),
      ),
    );
  }

  Color get _leftBorderColor {
    switch (lead.status) {
      case LeadStatus.missed:
      case LeadStatus.consentSent:
      case LeadStatus.dnrAlert:
        return AppColors.accentDanger;
      case LeadStatus.optedIn:
      case LeadStatus.qualifying:
      case LeadStatus.bookingSent:
        return AppColors.accentPrimary;
      case LeadStatus.booked:
        return AppColors.accentSuccess;
      case LeadStatus.completed:
      case LeadStatus.followedUp:
        return AppColors.accentInfo;
      case LeadStatus.noConsent:
        return AppColors.textTertiary;
    }
  }
}
