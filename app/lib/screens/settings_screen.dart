import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import '../providers/contractor_provider.dart';
import '../providers/theme_provider.dart';
import '../models/contractor.dart';
import '../theme/app_colors.dart';
import '../widgets/day_toggle_row.dart';
import '../widgets/usage_bar.dart';

/// Settings screen — business info, working hours, recovery settings, account, theme.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _businessNameController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _urgentThresholdController;
  late TextEditingController _normalThresholdController;
  late TextEditingController _defaultValueController;
  late TextEditingController _calendlyController;
  late List<int> _workingDays;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Controllers will be initialized when contractor data is available.
    _businessNameController = TextEditingController();
    _contactNameController = TextEditingController();
    _contactEmailController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _urgentThresholdController = TextEditingController();
    _normalThresholdController = TextEditingController();
    _defaultValueController = TextEditingController();
    _calendlyController = TextEditingController();
    _workingDays = [1, 2, 3, 4, 5];
    _startTime = const TimeOfDay(hour: 8, minute: 0);
    _endTime = const TimeOfDay(hour: 18, minute: 0);
  }

  void _initFromContractor(Contractor c) {
    if (_initialized) return;
    _initialized = true;
    _businessNameController.text = c.businessName;
    _contactNameController.text = c.contactName;
    _contactEmailController.text = c.contactEmail;
    _contactPhoneController.text = c.contactPhone;
    _urgentThresholdController.text = c.urgencyThresholdUrgentMin.toString();
    _normalThresholdController.text = c.urgencyThresholdNormalMin.toString();
    _defaultValueController.text =
        c.defaultJobValue?.toInt().toString() ?? '350';
    _calendlyController.text = c.calendlyUrl ?? '';
    _workingDays = List.from(c.workingDays);

    final startParts = c.workingHoursStart.split(':');
    _startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );
    final endParts = c.workingHoursEnd.split(':');
    _endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _urgentThresholdController.dispose();
    _normalThresholdController.dispose();
    _defaultValueController.dispose();
    _calendlyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(contractorProvider.notifier).updateSettings({
        'business_name': _businessNameController.text,
        'contact_name': _contactNameController.text,
        'contact_email': _contactEmailController.text,
        'contact_phone': _contactPhoneController.text,
        'working_days': _workingDays,
        'working_hours_start':
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'working_hours_end':
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'urgency_threshold_urgent_min':
            int.tryParse(_urgentThresholdController.text) ?? 60,
        'urgency_threshold_normal_min':
            int.tryParse(_normalThresholdController.text) ?? 1440,
        'default_job_value':
            double.tryParse(_defaultValueController.text) ?? 350,
        'calendly_url': _calendlyController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.toastSettingsSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final contractorAsync = ref.watch(contractorProvider);
    final themePref = ref.watch(themePreferenceProvider);

    return contractorAsync.when(
      loading:
          () => Scaffold(
            backgroundColor: colors.bgBase,
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Scaffold(
            backgroundColor: colors.bgBase,
            body: Center(child: Text('Error loading settings: $e')),
          ),
      data: (c) {
        _initFromContractor(c);
        final smsPercent = c.smsUsagePercent;
        final smsWarning = smsPercent > 0.8;

        final dayLabels = [
          l10n.dayMon,
          l10n.dayTue,
          l10n.dayWed,
          l10n.dayThu,
          l10n.dayFri,
          l10n.daySat,
          l10n.daySun,
        ];

        return Scaffold(
          backgroundColor: colors.bgBase,
          appBar: AppBar(
            title: Text(l10n.settingsTitle),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(l10n.settingsSave),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme selector
              _SectionHeader(title: 'APPEARANCE'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THEME',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ThemeOption(
                          icon: Icons.brightness_auto,
                          label: 'System',
                          isSelected: themePref == ThemePreference.system,
                          onTap:
                              () =>
                                  ref
                                      .read(themePreferenceProvider.notifier)
                                      .state = ThemePreference.system,
                        ),
                        const SizedBox(width: 8),
                        _ThemeOption(
                          icon: Icons.dark_mode_rounded,
                          label: 'Dark',
                          isSelected: themePref == ThemePreference.dark,
                          onTap:
                              () =>
                                  ref
                                      .read(themePreferenceProvider.notifier)
                                      .state = ThemePreference.dark,
                        ),
                        const SizedBox(width: 8),
                        _ThemeOption(
                          icon: Icons.light_mode_rounded,
                          label: 'Light',
                          isSelected: themePref == ThemePreference.light,
                          onTap:
                              () =>
                                  ref
                                      .read(themePreferenceProvider.notifier)
                                      .state = ThemePreference.light,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Business Info
              _SectionHeader(title: l10n.settingsBusinessInfo),
              const SizedBox(height: 8),
              _FormField(
                label: l10n.settingsBusinessName,
                controller: _businessNameController,
              ),
              _FormField(
                label: l10n.settingsContactName,
                controller: _contactNameController,
              ),
              _FormField(
                label: l10n.settingsContactEmail,
                controller: _contactEmailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _FormField(
                label: l10n.settingsContactPhone,
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Working Hours
              _SectionHeader(title: l10n.settingsWorkingHours),
              const SizedBox(height: 8),
              Text(
                l10n.settingsWorkingDays.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              DayToggleRow(
                selectedDays: _workingDays,
                dayLabels: dayLabels,
                onChanged: (days) => setState(() => _workingDays = days),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerField(
                      label: l10n.settingsStartTime,
                      time: _startTime,
                      onChanged: (t) => setState(() => _startTime = t),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerField(
                      label: l10n.settingsEndTime,
                      time: _endTime,
                      onChanged: (t) => setState(() => _endTime = t),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recovery Settings
              _SectionHeader(title: l10n.settingsRecovery),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      label: l10n.settingsUrgentThreshold,
                      controller: _urgentThresholdController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      label: l10n.settingsNormalThreshold,
                      controller: _normalThresholdController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      label: l10n.settingsDefaultJobValue,
                      controller: _defaultValueController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      label: l10n.settingsCalendlyUrl,
                      controller: _calendlyController,
                      keyboardType: TextInputType.url,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account
              _SectionHeader(title: l10n.settingsAccount),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier
                    Text(
                      l10n.settingsTier.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accentSuccess.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c.tier.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.accentSuccess,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${c.tierPrice}/mo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SMS usage
                    Text(
                      l10n.settingsSmsUsage.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.settingsSmsUsedOf(
                        c.smsUsedThisMonth,
                        c.monthlySMSCap,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    UsageBar(percent: smsPercent, warning: smsWarning),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          TextField(controller: controller, keyboardType: keyboardType),
        ],
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerField({
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
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 6),
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
            child: Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

/// Theme option button — used in the theme selector.
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimaryMuted : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? colors.accentPrimary : colors.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? colors.accentPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
