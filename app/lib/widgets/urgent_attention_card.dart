import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';

/// Attention-needed card showing leads that require immediate action.
/// Tapping navigates to the lead detail.
class UrgentAttentionCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onTap;

  const UrgentAttentionCard({super.key, required this.lead, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reason = _reasonText;
    final icon = _reasonIcon;
    final accentColor = _reasonColor(colors);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.callerName ?? lead.callerPhone,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 11,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Time
            Text(
              _relativeTime(lead.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: colors.textTertiary,
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  String get _reasonText {
    switch (lead.status) {
      case LeadStatus.missed:
        return lead.urgency == Urgency.emergency
            ? '🚨 EMERGENCY — Not contacted!'
            : 'Missed — waiting for consent';
      case LeadStatus.dnrAlert:
        return '⚠️ Did Not Respond — follow up needed';
      case LeadStatus.consentSent:
        return '📨 Consent sent — awaiting reply';
      default:
        return 'Needs attention';
    }
  }

  IconData get _reasonIcon {
    switch (lead.status) {
      case LeadStatus.missed:
        return lead.urgency == Urgency.emergency
            ? Icons.warning_amber_rounded
            : Icons.phone_missed_rounded;
      case LeadStatus.dnrAlert:
        return Icons.notification_important_rounded;
      case LeadStatus.consentSent:
        return Icons.schedule_send_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Color _reasonColor(AppColors colors) {
    switch (lead.status) {
      case LeadStatus.missed:
        return lead.urgency == Urgency.emergency
            ? colors.urgencyEmergency
            : colors.accentDanger;
      case LeadStatus.dnrAlert:
        return colors.accentPrimary;
      case LeadStatus.consentSent:
        return colors.accentInfo;
      default:
        return colors.textTertiary;
    }
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
