import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Day toggle row — 7 buttons for selecting working days (Mon-Sun).
class DayToggleRow extends StatelessWidget {
  final List<int> selectedDays;
  final List<String> dayLabels;
  final ValueChanged<List<int>> onChanged;

  const DayToggleRow({
    super.key,
    required this.selectedDays,
    required this.dayLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isActive = selectedDays.contains(dayNum);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 6 ? 6 : 0),
            child: GestureDetector(
              onTap: () {
                final newDays = List<int>.from(selectedDays);
                if (isActive) {
                  newDays.remove(dayNum);
                } else {
                  newDays.add(dayNum);
                  newDays.sort();
                }
                onChanged(newDays);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.accentPrimaryMuted
                      : colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? colors.accentPrimary.withValues(alpha: 0.4)
                        : colors.borderSubtle,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? colors.accentPrimary
                          : colors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
