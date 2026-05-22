import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Data for a single calendar day.
class CalendarDayData {
  final DateTime date;
  final int collectedLeads; // leads collected (opted-in, qualified, booked, completed, etc.)
  final double bookingRevenue; // future booking revenue for this day

  const CalendarDayData({
    required this.date,
    this.collectedLeads = 0,
    this.bookingRevenue = 0,
  });
}

/// Full month calendar — replaces the revenue chart.
/// Shows green dots for days with collected leads and booking revenue for future days.
class MonthCalendar extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime selectedDate;
  final Map<DateTime, CalendarDayData> dayData;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthCalendar({
    super.key,
    required this.displayMonth,
    required this.selectedDate,
    required this.dayData,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Month header
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Calculate grid
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastDayOfMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final daysInMonth = lastDayOfMonth.day;

    // Offset: how many blank cells before the 1st
    final leadingBlanks = startWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // ── Month navigation ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onPreviousMonth,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_left_rounded, size: 20, color: colors.textSecondary),
              ),
            ),
            Text(
              '${monthNames[displayMonth.month - 1]} ${displayMonth.year}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    letterSpacing: 0.3,
                  ),
            ),
            GestureDetector(
              onTap: onNextMonth,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded, size: 20, color: colors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Weekday headers ──
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // ── Day cells grid ──
        ...List.generate(rows, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - leadingBlanks + 1;

                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 48));
                }

                final date = DateTime(displayMonth.year, displayMonth.month, dayNum);
                final dateOnly = DateTime(date.year, date.month, date.day);
                final isToday = dateOnly == today;
                final isSelected = dateOnly == DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                final data = dayData[dateOnly];
                final hasCollectedLeads = (data?.collectedLeads ?? 0) > 0;
                final bookingRev = data?.bookingRevenue ?? 0;
                final isFuture = dateOnly.isAfter(today);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDateSelected(dateOnly),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.accentPrimaryMuted
                            : isToday
                                ? colors.bgElevated
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.5), width: 1.5)
                            : isToday
                                ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Day number
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? colors.accentPrimary
                                  : isToday
                                      ? colors.accentPrimary
                                      : dateOnly.isBefore(today)
                                          ? colors.textTertiary
                                          : colors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Indicators row
                          SizedBox(
                            height: 14,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Green dot for collected leads
                                if (hasCollectedLeads)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.accentSuccess,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.accentSuccess.withValues(alpha: 0.4),
                                          blurRadius: 4,
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                // Revenue indicator for future bookings
                                if (isFuture && bookingRev > 0)
                                  Text(
                                    '€${bookingRev.toInt()}',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                      color: colors.accentSuccess.withValues(alpha: 0.9),
                                    ),
                                  ),
                                // Revenue for past/today completed bookings
                                if (!isFuture && bookingRev > 0 && !hasCollectedLeads)
                                  Text(
                                    '€${bookingRev.toInt()}',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                      color: colors.accentInfo.withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),

        const SizedBox(height: 12),

        // ── Legend ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: colors.accentSuccess, label: 'Leads collected'),
            const SizedBox(width: 16),
            _LegendItem(color: colors.accentSuccess.withValues(alpha: 0.9), label: 'Booking revenue', isText: true),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isText;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isText)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          )
        else
          Text(
            '€',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
