import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trade_type_picker.dart';

/// Step 1: Business Info — business name + trade type.
class StepBusinessInfo extends ConsumerWidget {
  const StepBusinessInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final onboarding = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('🏢', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Tell us about your business',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'We\'ll use this to personalize your recovery experience.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),

          const SizedBox(height: 32),

          // Business name
          Text(
            'BUSINESS NAME',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) {
              onboarding.businessName = value;
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              onboarding.notifyListeners();
            },
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: onboarding.businessName,
                selection: TextSelection.collapsed(
                    offset: onboarding.businessName.length),
              ),
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. Virtanen LVI Oy',
            ),
          ),

          const SizedBox(height: 28),

          // Trade type
          Text(
            'YOUR TRADE',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          TradeTypePicker(
            selected: onboarding.tradeType,
            onSelected: (value) {
              onboarding.tradeType = value;
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              onboarding.notifyListeners();
            },
          ),
        ],
      ),
    );
  }
}
