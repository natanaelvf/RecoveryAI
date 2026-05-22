import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';

/// Step 2: Contact Details — name, email, phone.
class StepContactDetails extends ConsumerStatefulWidget {
  const StepContactDetails({super.key});

  @override
  ConsumerState<StepContactDetails> createState() => _StepContactDetailsState();
}

class _StepContactDetailsState extends ConsumerState<StepContactDetails> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final ob = ref.read(onboardingProvider);
    _nameCtrl = TextEditingController(text: ob.contactName);
    _emailCtrl = TextEditingController(text: ob.contactEmail);
    _phoneCtrl = TextEditingController(text: ob.contactPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    final ob = ref.read(onboardingProvider);
    ob.contactName = _nameCtrl.text;
    ob.contactEmail = _emailCtrl.text;
    ob.contactPhone = _phoneCtrl.text;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    ob.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // Watch to stay reactive
    ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👤', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Your contact details',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'How customers and the system can reach you.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),

          const SizedBox(height: 32),

          // Name
          Text('FULL NAME', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => _sync(),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Jukka Virtanen',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),

          const SizedBox(height: 20),

          // Email
          Text('EMAIL', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            onChanged: (_) => _sync(),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'e.g. jukka@virtanenlvi.fi',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),

          const SizedBox(height: 20),

          // Phone
          Text('PHONE NUMBER', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            onChanged: (_) => _sync(),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'e.g. +358 40 123 4567',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),

          const SizedBox(height: 16),

          // Helper text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfoMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.accentInfo.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.accentInfo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This phone number is for account contact only. Missed call forwarding is set up in the next step.',
                    style: TextStyle(fontSize: 12, color: colors.accentInfo, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
