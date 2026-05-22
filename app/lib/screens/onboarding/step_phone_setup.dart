import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';

/// Step 3: Phone Setup — how Twilio forwarding works + phone number input.
class StepPhoneSetup extends ConsumerStatefulWidget {
  const StepPhoneSetup({super.key});

  @override
  ConsumerState<StepPhoneSetup> createState() => _StepPhoneSetupState();
}

class _StepPhoneSetupState extends ConsumerState<StepPhoneSetup> {
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: ref.read(onboardingProvider).phoneNumber);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onboarding = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Phone setup',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Configure how missed calls are captured.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),

          const SizedBox(height: 24),

          // How it works card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW IT WORKS',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 14),
                _StepExplainer(
                  icon: Icons.phone_missed_rounded,
                  iconColor: colors.accentDanger,
                  title: 'Customer calls, you miss it',
                  subtitle: 'Life happens — busy on a job, driving, etc.',
                ),
                const SizedBox(height: 12),
                _StepExplainer(
                  icon: Icons.sms_rounded,
                  iconColor: colors.accentPrimary,
                  title: 'We send an SMS immediately',
                  subtitle: 'Asks the caller about their issue in your language.',
                ),
                const SizedBox(height: 12),
                _StepExplainer(
                  icon: Icons.calendar_today_rounded,
                  iconColor: colors.accentSuccess,
                  title: 'Lead qualified & booked',
                  subtitle: 'AI qualifies urgency and sends a booking link.',
                ),
                const SizedBox(height: 12),
                _StepExplainer(
                  icon: Icons.attach_money_rounded,
                  iconColor: colors.accentInfo,
                  title: 'You recover the revenue',
                  subtitle: 'Track recovered leads and satisfaction in-app.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Business phone number
          Text(
            'YOUR BUSINESS PHONE NUMBER',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              onboarding.phoneNumber = value;
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              onboarding.notifyListeners();
            },
            decoration: const InputDecoration(
              hintText: '+358 40 XXX XXXX',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),

          const SizedBox(height: 20),

          // Setup type
          Text(
            'SETUP TYPE',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          _SetupTypeOption(
            icon: Icons.call_merge_rounded,
            title: 'Forward to RecoveryAI',
            subtitle: 'Keep your number. We detect missed calls via forwarding.',
            isSelected: onboarding.numberSetupType == 'forwarding',
            onTap: () {
              onboarding.numberSetupType = 'forwarding';
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              onboarding.notifyListeners();
            },
          ),
          const SizedBox(height: 10),
          _SetupTypeOption(
            icon: Icons.add_call,
            title: 'Get a new number',
            subtitle: 'We provide a dedicated number for missed call recovery.',
            isSelected: onboarding.numberSetupType == 'new_number',
            onTap: () {
              onboarding.numberSetupType = 'new_number';
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              onboarding.notifyListeners();
            },
          ),
        ],
      ),
    );
  }
}

class _StepExplainer extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StepExplainer({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SetupTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimaryMuted : colors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentPrimary.withValues(alpha: 0.12)
                    : colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? colors.accentPrimary : colors.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colors.accentPrimary
                              : colors.textPrimary,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 22, color: colors.accentPrimary),
          ],
        ),
      ),
    );
  }
}
