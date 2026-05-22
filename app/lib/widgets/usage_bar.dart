import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// SMS usage progress bar — matches the web prototype's usage-bar.
class UsageBar extends StatelessWidget {
  final double percent; // 0.0 to 1.0
  final bool warning;

  const UsageBar({
    super.key,
    required this.percent,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: colors.bgInput,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percent.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: warning
                  ? [colors.accentDanger, colors.accentPrimary]
                  : [colors.accentPrimary, colors.accentSuccess],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
