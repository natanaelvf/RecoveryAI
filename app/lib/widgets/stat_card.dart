import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated stat card matching the web prototype's stat-card component.
/// Counts up from 0 on first build.
class StatCard extends StatefulWidget {
  final String label;
  final double targetValue;
  final String prefix;
  final String suffix;
  final String trend;
  final bool trendUp;
  final String emoji;
  final Color accentColor;

  const StatCard({
    super.key,
    required this.label,
    required this.targetValue,
    this.prefix = '',
    this.suffix = '',
    this.trend = '',
    this.trendUp = true,
    this.emoji = '📊',
    required this.accentColor,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: label + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Animated value
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final current =
                  (widget.targetValue * _animation.value).round();
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.prefix}${_formatNumber(current)}${widget.suffix}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 28,
                  ),
                  maxLines: 1,
                ),
              );
            },
          ),
          const Spacer(),

          // Trend
          if (widget.trend.isNotEmpty)
            Text(
              '${widget.trendUp ? '↑' : '↓'} ${widget.trend}',
              style: TextStyle(
                fontSize: 12,
                color: widget.trendUp
                    ? colors.accentSuccess
                    : colors.accentDanger,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      // Finnish thousands separator (space)
      final str = value.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) {
          buffer.write('\u00A0'); // non-breaking space
        }
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return value.toString();
  }
}
