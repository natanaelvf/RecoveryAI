import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Segmented time range selector — 7d / 30d / 90d.
class TimeRangeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _ranges = ['7d', '30d', '90d'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _ranges.map((range) {
          final isActive = selected == range;
          return GestureDetector(
            onTap: () => onChanged(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? colors.accentPrimaryMuted : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isActive
                    ? Border.all(
                        color: colors.accentPrimary.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Text(
                range,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? colors.accentPrimary : colors.textTertiary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
