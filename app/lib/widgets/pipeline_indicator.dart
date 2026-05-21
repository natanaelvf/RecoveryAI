import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';

/// 5-step pipeline indicator showing lead progression.
/// Matches frontend/src/views/leads.js renderPipeline().
class PipelineIndicator extends StatelessWidget {
  final LeadStatus status;
  final double dotSize;
  final double connectorHeight;

  const PipelineIndicator({
    super.key,
    required this.status,
    this.dotSize = 10,
    this.connectorHeight = 2,
  });

  @override
  Widget build(BuildContext context) {
    final currentStage = status.pipelineStage;
    const stageCount = 5;

    return Row(
      children: List.generate(stageCount * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector
          final stageIdx = index ~/ 2;
          final isDone = stageIdx < currentStage;
          return Expanded(
            child: Container(
              height: connectorHeight,
              color: isDone ? AppColors.accentSuccess : AppColors.borderSubtle,
            ),
          );
        }

        // Dot
        final stageIdx = index ~/ 2;
        final isDone = stageIdx < currentStage;
        final isCurrent = stageIdx == currentStage;
        final isMissed = stageIdx == 0 && currentStage == 0;

        Color color;
        if (isDone) {
          color = AppColors.accentSuccess;
        } else if (isCurrent && isMissed) {
          color = AppColors.accentDanger;
        } else if (isCurrent) {
          color = AppColors.accentPrimary;
        } else {
          color = AppColors.borderSubtle;
        }

        return Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: isCurrent
                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                : null,
          ),
        );
      }),
    );
  }
}
