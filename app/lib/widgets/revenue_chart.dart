import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';

/// Revenue bar chart — last 30 days, using fl_chart.
/// Matches the web prototype's canvas-drawn chart.
class RevenueChart extends StatelessWidget {
  final List<RevenueDay> data;

  const RevenueChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final maxRevenue = data.fold<double>(
      100,
      (max, d) => d.revenue > max ? d.revenue : max,
    );

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: maxRevenue * 1.1,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < data.length && (idx % 5 == 0 || idx == data.length - 1)) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data[idx].label,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textTertiary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.bgElevated,
              tooltipRoundedRadius: 6,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = data[group.x.toInt()];
                return BarTooltipItem(
                  '${day.label}\n€${day.revenue.toInt()}',
                  TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(data.length, (i) {
            final d = data[i];
            final hasRecovery = d.recovered > 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.revenue > 0 ? d.revenue : maxRevenue * 0.02,
                  width: 6,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                  gradient: hasRecovery
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.accentPrimary,
                            colors.accentPrimary.withValues(alpha: 0.4),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.bgElevated.withValues(alpha: 0.8),
                            colors.bgElevated.withValues(alpha: 0.3),
                          ],
                        ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}
