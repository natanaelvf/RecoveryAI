import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

/// Animated SMS usage gauge — circular arc indicator.
class SmsUsageGauge extends StatefulWidget {
  final int used;
  final int cap;

  const SmsUsageGauge({
    super.key,
    required this.used,
    required this.cap,
  });

  @override
  State<SmsUsageGauge> createState() => _SmsUsageGaugeState();
}

class _SmsUsageGaugeState extends State<SmsUsageGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    final percent = widget.cap > 0 ? widget.used / widget.cap : 0.0;
    final isWarning = percent > 0.8;
    final isDanger = percent > 0.95;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Row(
          children: [
            // Gauge
            SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: percent * _animation.value,
                  trackColor: colors.bgInput,
                  fillColor: isDanger
                      ? colors.accentDanger
                      : isWarning
                          ? colors.accentPrimary
                          : colors.accentSuccess,
                  glowColor: isDanger
                      ? colors.accentDanger.withValues(alpha: 0.3)
                      : isWarning
                          ? colors.accentPrimary.withValues(alpha: 0.3)
                          : colors.accentSuccess.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percent * _animation.value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDanger
                              ? colors.accentDanger
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.used} / ${widget.cap}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SMS this month',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  // Remaining
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isDanger
                              ? colors.accentDanger
                              : isWarning
                                  ? colors.accentPrimary
                                  : colors.accentSuccess)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.cap - widget.used} remaining',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDanger
                            ? colors.accentDanger
                            : isWarning
                                ? colors.accentPrimary
                                : colors.accentSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final Color glowColor;

  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 6.0;
    const startAngle = -math.pi * 0.75;
    const sweepRange = math.pi * 1.5;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRange,
      false,
      trackPaint,
    );

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Glow
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final fillSweep = sweepRange * progress.clamp(0, 1);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fillSweep,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fillSweep,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress ||
      old.fillColor != fillColor;
}
