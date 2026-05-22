import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';

/// A single scheduled appointment card — shows time, name, urgency, and issue.
class ScheduleCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onTap;

  const ScheduleCard({super.key, required this.lead, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final time = lead.bookingTime;
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            // Time column
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.accentPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info column
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
                  if (lead.issueDescription != null)
                    Text(
                      lead.issueDescription!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Value badge
            if (lead.estimatedValue != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentSuccessMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '€${lead.estimatedValue!.toInt()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.accentSuccess,
                  ),
                ),
              ),

            const SizedBox(width: 6),

            // Urgency dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _urgencyColor(lead.urgency, colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _urgencyColor(Urgency urgency, AppColors colors) {
    switch (urgency) {
      case Urgency.emergency: return colors.urgencyEmergency;
      case Urgency.high: return colors.urgencyHigh;
      case Urgency.medium: return colors.urgencyMedium;
      case Urgency.low: return colors.urgencyLow;
      case Urgency.unknown: return colors.urgencyUnknown;
    }
  }
}
