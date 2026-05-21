import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Horizontal scrollable filter chip bar — matches the web prototype's filter pills.
class FilterChipBar extends StatelessWidget {
  final Map<String, int> counts;
  final String selected;
  final List<String> labels;
  final ValueChanged<String> onSelected;

  const FilterChipBar({
    super.key,
    required this.counts,
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = _keys[index];
          final label = labels[index];
          final count = counts[key] ?? 0;
          final isActive = selected == key;

          return GestureDetector(
            onTap: () => onSelected(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accentPrimaryMuted
                    : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.accentPrimary.withValues(alpha: 0.4)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.accentPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? AppColors.accentPrimary.withValues(alpha: 0.7)
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> get _keys =>
      ['all', 'missed', 'contacted', 'booked', 'completed'];
}
