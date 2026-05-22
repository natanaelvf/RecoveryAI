import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/activity_event.dart';

/// Scrollable activity feed showing recent events.
/// Each event is tappable — navigates to the related lead.
class ActivityFeed extends StatelessWidget {
  final List<ActivityEvent> events;
  final int maxVisible;
  final ValueChanged<ActivityEvent>? onEventTap;

  const ActivityFeed({
    super.key,
    required this.events,
    this.maxVisible = 10,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final visibleEvents = events.take(maxVisible).toList();

    if (visibleEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Text('📭', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: visibleEvents.map((event) {
        final hasTap = onEventTap != null && event.leadId != null;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasTap ? () => onEventTap!(event) : null,
            splashColor: colors.accentPrimaryMuted,
            highlightColor: colors.accentPrimaryMuted.withValues(alpha: 0.3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Text(event.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),

                  // Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _eventSubtext(event),
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Relative time
                  Text(
                    _relativeTime(event.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textTertiary,
                    ),
                  ),

                  // Chevron for tappable rows
                  if (hasTap) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _eventSubtext(ActivityEvent event) {
    switch (event.type) {
      case ActivityType.newLead:
        return 'Tap to view lead details';
      case ActivityType.smsSent:
        return 'View conversation';
      case ActivityType.bookingConfirmed:
        return 'View booking details';
      case ActivityType.dnrAlert:
        return 'Requires attention';
      case ActivityType.leadCompleted:
        return 'View completed lead';
      case ActivityType.satisfactionReceived:
        return 'View feedback';
    }
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}.${timestamp.month}';
  }
}
