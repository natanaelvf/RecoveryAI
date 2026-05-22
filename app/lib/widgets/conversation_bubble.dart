import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/message.dart';
import '../utils/date_utils.dart' as app_date;

/// SMS conversation bubble — WhatsApp-style message display.
class ConversationBubble extends StatelessWidget {
  final Message message;
  final bool showDate;
  final String? dateLabel;

  const ConversationBubble({
    super.key,
    required this.message,
    this.showDate = false,
    this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        // Date separator
        if (showDate && dateLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              dateLabel!,
              style: TextStyle(
                fontSize: 11,
                color: colors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Bubble
        Align(
          alignment: message.isOutbound
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: message.isOutbound
                  ? colors.accentPrimary.withValues(alpha: 0.12)
                  : colors.bgElevated,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(message.isOutbound ? 12 : 2),
                bottomRight: Radius.circular(message.isOutbound ? 2 : 12),
              ),
              border: Border.all(
                color: message.isOutbound
                    ? colors.accentPrimary.withValues(alpha: 0.2)
                    : colors.borderSubtle,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.body,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: message.isOutbound
                        ? colors.textPrimary
                        : colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      app_date.formatTime(message.sentAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textTertiary,
                      ),
                    ),
                    if (message.isOutbound) ...[
                      const SizedBox(width: 4),
                      Text(
                        '✓✓',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.accentSuccess,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
