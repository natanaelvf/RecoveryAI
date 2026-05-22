import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Horizontal week strip calendar — shows 7 days centered on today.
/// Days with events get dot indicators below the date.
class WeekStripCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, int> eventCounts; // date (dateOnly) → count
  final ValueChanged<DateTime> onDateSelected;

  const WeekStripCalendar({
    super.key,
    required this.selectedDate,
    required this.eventCounts,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Show 7 days: 2 past, today, 4 future
    final startDate = today.subtract(const Duration(days: 2));
    final days = List.generate(7, (i) => startDate.add(Duration(days: i)));

    return Row(
      children: days.map((date) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final isToday = dateOnly == today;
        final isSelected = dateOnly == DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final count = eventCounts[dateOnly] ?? 0;
        final isPast = dateOnly.isBefore(today);

        return Expanded(
          child: GestureDetector(
            onTap: () => onDateSelected(dateOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentPrimaryMuted
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.4))
                    : null,
              ),
              child: Column(
                children: [
                  // Day name
                  Text(
                    _dayName(date.weekday),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPast
                          ? colors.textTertiary.withValues(alpha: 0.6)
                          : colors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Date number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday && !isSelected
                          ? colors.accentPrimary
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isToday && !isSelected
                              ? colors.textInverse
                              : isSelected
                                  ? colors.accentPrimary
                                  : isPast
                                      ? colors.textTertiary
                                      : colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Event dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      count.clamp(0, 3),
                      (i) => Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colors.accentPrimary
                              : colors.accentSuccess,
                        ),
                      ),
                    ),
                  ),
                  if (count == 0) const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case 1: return 'MON';
      case 2: return 'TUE';
      case 3: return 'WED';
      case 4: return 'THU';
      case 5: return 'FRI';
      case 6: return 'SAT';
      case 7: return 'SUN';
      default: return '';
    }
  }
}
