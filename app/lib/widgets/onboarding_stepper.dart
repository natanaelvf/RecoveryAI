import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Horizontal step progress indicator with animated fill bar.
class OnboardingStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const OnboardingStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        // Step indicators
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector line
              final stepBefore = index ~/ 2;
              final isDone = stepBefore < currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDone ? colors.accentPrimary : colors.borderSubtle,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }

            // Step circle
            final stepIdx = index ~/ 2;
            final isDone = stepIdx < currentStep;
            final isCurrent = stepIdx == currentStep;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: isCurrent ? 36 : 28,
              height: isCurrent ? 36 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? colors.accentPrimary
                    : isCurrent
                        ? colors.accentPrimaryMuted
                        : colors.bgElevated,
                border: Border.all(
                  color: isDone || isCurrent
                      ? colors.accentPrimary
                      : colors.borderSubtle,
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: colors.accentPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? Icon(Icons.check_rounded,
                        size: 16, color: colors.textInverse)
                    : Text(
                        '${stepIdx + 1}',
                        style: TextStyle(
                          fontSize: isCurrent ? 14 : 12,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? colors.accentPrimary
                              : colors.textTertiary,
                        ),
                      ),
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        // Current step label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            currentStep < stepLabels.length ? stepLabels[currentStep] : '',
            key: ValueKey(currentStep),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
