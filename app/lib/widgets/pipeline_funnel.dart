import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pipeline funnel visualization — horizontal bars showing lead flow.
/// Tapping a stage triggers the onStageTap callback for navigation.
class PipelineFunnel extends StatefulWidget {
  final Map<String, int> stageCounts;
  final ValueChanged<String>? onStageTap;

  const PipelineFunnel({
    super.key,
    required this.stageCounts,
    this.onStageTap,
  });

  @override
  State<PipelineFunnel> createState() => _PipelineFunnelState();
}

class _PipelineFunnelState extends State<PipelineFunnel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    final stages = _buildStages(colors);
    final maxCount = stages.fold<int>(
      1,
      (max, s) => s.count > max ? s.count : max,
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          children: stages.map((stage) {
            final fraction =
                (stage.count / maxCount * _animation.value).clamp(0.1, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: widget.onStageTap != null
                    ? () => widget.onStageTap!(stage.key)
                    : null,
                child: Row(
                  children: [
                    // Stage label
                    SizedBox(
                      width: 80,
                      child: Text(
                        stage.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    // Bar
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              // Track
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: colors.bgElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              // Fill
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 28,
                                width: constraints.maxWidth * fraction,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      stage.color,
                                      stage.color.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          stage.color.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${stage.count}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textInverse,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<_Stage> _buildStages(AppColors colors) {
    return [
      _Stage('missed', 'Missed', widget.stageCounts['missed'] ?? 0,
          colors.accentDanger),
      _Stage('contacted', 'Contacted', widget.stageCounts['contacted'] ?? 0,
          colors.accentPrimary),
      _Stage('booked', 'Booked', widget.stageCounts['booked'] ?? 0,
          colors.accentSuccess),
      _Stage('completed', 'Completed', widget.stageCounts['completed'] ?? 0,
          colors.accentInfo),
    ];
  }
}

class _Stage {
  final String key;
  final String label;
  final int count;
  final Color color;
  const _Stage(this.key, this.label, this.count, this.color);
}
