import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/day_toggle_row.dart';

/// Step 4: Schedule & Preferences — working days, hours, thresholds, job value.
class StepSchedulePreferences extends ConsumerStatefulWidget {
  const StepSchedulePreferences({super.key});

  @override
  ConsumerState<StepSchedulePreferences> createState() =>
      _StepSchedulePreferencesState();
}

class _StepSchedulePreferencesState
    extends ConsumerState<StepSchedulePreferences> {
  late TextEditingController _urgentCtrl;
  late TextEditingController _normalCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _calendlyCtrl;

  @override
  void initState() {
    super.initState();
    final ob = ref.read(onboardingProvider);
    _urgentCtrl =
        TextEditingController(text: ob.urgencyThresholdUrgentMin.toString());
    _normalCtrl =
        TextEditingController(text: ob.urgencyThresholdNormalMin.toString());
    _valueCtrl =
        TextEditingController(text: ob.defaultJobValue.toInt().toString());
    _calendlyCtrl = TextEditingController(text: ob.calendlyUrl);
  }

  @override
  void dispose() {
    _urgentCtrl.dispose();
    _normalCtrl.dispose();
    _valueCtrl.dispose();
    _calendlyCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    final ob = ref.read(onboardingProvider);
    ob.urgencyThresholdUrgentMin = int.tryParse(_urgentCtrl.text) ?? 60;
    ob.urgencyThresholdNormalMin = int.tryParse(_normalCtrl.text) ?? 1440;
    ob.defaultJobValue = double.tryParse(_valueCtrl.text) ?? 350;
    ob.calendlyUrl = _calendlyCtrl.text;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    ob.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onboarding = ref.watch(onboardingProvider);

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Parse start/end times
    final startParts = onboarding.workingHoursStart.split(':');
    final startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );
    final endParts = onboarding.workingHoursEnd.split(':');
    final endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏰', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Schedule & preferences',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Set your working hours and recovery thresholds.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),

          const SizedBox(height: 28),

          // Working days
          Text('WORKING DAYS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          DayToggleRow(
            selectedDays: onboarding.workingDays,
            dayLabels: dayLabels,
            onChanged: (days) {
              onboarding.workingDays = days;
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              onboarding.notifyListeners();
            },
          ),

          const SizedBox(height: 24),

          // Working hours
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'START TIME',
                  time: startTime,
                  onChanged: (t) {
                    onboarding.workingHoursStart =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                    onboarding.notifyListeners();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeField(
                  label: 'END TIME',
                  time: endTime,
                  onChanged: (t) {
                    onboarding.workingHoursEnd =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                    onboarding.notifyListeners();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Thresholds
          Text(
            'URGENCY THRESHOLDS',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Urgent (min)',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _urgentCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _sync(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Normal (min)',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _normalCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _sync(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Default job value
          Text(
            'DEFAULT JOB VALUE',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valueCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => _sync(),
            decoration: const InputDecoration(
              prefixText: '€ ',
              hintText: '350',
            ),
          ),

          const SizedBox(height: 24),

          // Calendly URL
          Text(
            'CALENDLY URL (OPTIONAL)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _calendlyCtrl,
            keyboardType: TextInputType.url,
            onChanged: (_) => _sync(),
            decoration: const InputDecoration(
              hintText: 'https://calendly.com/your-business',
              prefixIcon: Icon(Icons.link, size: 20),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeField({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bgInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: colors.textTertiary),
                const SizedBox(width: 8),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
