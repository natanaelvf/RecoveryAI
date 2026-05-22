import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/contractor_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/usage_bar.dart';

/// Profile screen — account info, language switch, logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final c = ref.watch(contractorProvider).contractor;
    final themePref = ref.watch(themePreferenceProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.accentPrimary,
                        colors.accentPrimary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      c.initials,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colors.textInverse,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  c.contactName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  c.contactEmail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  c.businessName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.accentPrimary,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tier + SMS
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.settingsTier.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.accentSuccess.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${c.tier.toUpperCase()} • ${c.tierPrice}/mo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.accentSuccess,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.settingsSmsUsage.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Text(
                  l10n.settingsSmsUsedOf(c.smsUsedThisMonth, c.monthlySMSCap),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                UsageBar(
                  percent: c.smsUsagePercent,
                  warning: c.smsUsagePercent > 0.8,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // App info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.language,
                  label: l10n.profileLanguage,
                  value: Localizations.localeOf(context).languageCode == 'fi'
                      ? 'Suomi'
                      : 'English',
                ),
                const Divider(),
                _InfoTile(
                  icon: Icons.brightness_6_rounded,
                  label: 'Theme',
                  value: themePref == ThemePreference.system
                      ? 'System'
                      : themePref == ThemePreference.dark
                          ? 'Dark'
                          : 'Light',
                ),
                const Divider(),
                _InfoTile(
                  icon: Icons.info_outline,
                  label: l10n.profileVersion,
                  value: '0.1.0',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.profileLogout),
                    content: Text(l10n.profileLogoutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authProvider).signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentDanger,
                        ),
                        child: Text(l10n.profileLogout),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.logout, color: colors.accentDanger),
              label: Text(
                l10n.profileLogout,
                style: TextStyle(color: colors.accentDanger),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.accentDanger),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
