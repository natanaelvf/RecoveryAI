import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Visual trade type picker — grid of tappable cards with emoji icons.
class TradeTypePicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const TradeTypePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _trades = [
    _Trade('plumber', '🔧', 'Plumber'),
    _Trade('hvac', '❄️', 'HVAC'),
    _Trade('electrician', '⚡', 'Electrician'),
    _Trade('roofer', '🏠', 'Roofer'),
    _Trade('other', '🔨', 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _trades.map((trade) {
        final isActive = selected == trade.value;
        return GestureDetector(
          onTap: () => onSelected(trade.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 78) / 3, // 3 per row with padding
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isActive ? colors.accentPrimaryMuted : colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? colors.accentPrimary : colors.borderSubtle,
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colors.accentPrimary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  trade.emoji,
                  style: TextStyle(fontSize: isActive ? 30 : 26),
                ),
                const SizedBox(height: 6),
                Text(
                  trade.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? colors.accentPrimary
                        : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Trade {
  final String value;
  final String emoji;
  final String label;
  const _Trade(this.value, this.emoji, this.label);
}
