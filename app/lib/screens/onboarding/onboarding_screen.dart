import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/contractor_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/onboarding_stepper.dart';
import 'step_business_info.dart';
import 'step_contact_details.dart';
import 'step_phone_setup.dart';
import 'step_schedule_preferences.dart';

/// Onboarding wizard — 4-step animated flow.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _successController;
  late Animation<double> _successScale;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleComplete() async {
    final onboardingNotifier = ref.read(onboardingProvider);

    // Validate the current (final) step before saving.
    if (!onboardingNotifier.canAdvance) {
      final error = onboardingNotifier.currentStepError ?? 'Please fill in all required fields.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final contractorNotifier = ref.read(contractorProvider.notifier);
    final success = await onboardingNotifier.complete(contractorNotifier);

    if (!mounted) return;

    if (success) {
      // Only show success animation AFTER the save succeeds.
      setState(() => _showSuccess = true);
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(onboardingNotifier.error ?? 'Failed to save. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Advance to the next step with validation.
  void _handleNext() {
    final onboarding = ref.read(onboardingProvider);
    if (!onboarding.canAdvance) {
      final error = onboarding.currentStepError ?? 'Please fill in all required fields.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _goToStep(onboarding.currentStep + 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onboarding = ref.watch(onboardingProvider);
    final currentStep = onboarding.currentStep;

    if (_showSuccess) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        body: Center(
          child: ScaleTransition(
            scale: _successScale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accentSuccess,
                    boxShadow: [
                      BoxShadow(
                        color: colors.accentSuccess.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: colors.textInverse,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'You\'re all set!',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Taking you to your dashboard...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with stepper
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                children: [
                  // Logo + Skip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.accentPrimaryMuted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.phone_missed_rounded,
                              color: colors.accentPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RecoveryAI',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final onboarding = ref.read(onboardingProvider);
                          // Check minimum required fields for skip
                          if (onboarding.businessName.trim().isEmpty ||
                              onboarding.phoneNumber.trim().isEmpty) {
                            final shouldContinue = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Required fields missing'),
                                content: const Text(
                                  'At minimum, your business name and phone number are required to use RecoveryAI. '
                                  'Please fill these in before continuing.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (shouldContinue != true && context.mounted) return;
                          }
                          // Save whatever is filled and proceed.
                          final contractorNotifier = ref.read(contractorProvider.notifier);
                          await onboarding.complete(contractorNotifier);
                          if (context.mounted) context.go('/dashboard');
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Step indicator
                  OnboardingStepper(
                    currentStep: currentStep,
                    totalSteps: 4,
                    stepLabels: const [
                      'Business Info',
                      'Contact Details',
                      'Phone Setup',
                      'Preferences',
                    ],
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  ref.read(onboardingProvider).goToStep(page);
                },
                children: const [
                  StepBusinessInfo(),
                  StepContactDetails(),
                  StepPhoneSetup(),
                  StepSchedulePreferences(),
                ],
              ),
            ),

            // Bottom nav buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border(
                  top: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  // Back
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _goToStep(currentStep - 1);
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),

                  const SizedBox(width: 12),

                  // Next / Complete
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onboarding.isSaving
                          ? null
                          : () {
                              if (currentStep < 3) {
                                _handleNext();
                              } else {
                                _handleComplete();
                              }
                            },
                      icon: onboarding.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              currentStep < 3
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_rounded,
                              size: 18,
                            ),
                      label: Text(
                        onboarding.isSaving
                            ? 'Saving...'
                            : (currentStep < 3 ? 'Continue' : 'Complete Setup'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
