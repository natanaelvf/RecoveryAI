import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';

/// Urgency badge — colored chip showing urgency level.
class UrgencyBadge extends StatelessWidget {
  final Urgency urgency;

  const UrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bgColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label(l10n),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _bgColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (urgency) {
      case Urgency.emergency: return AppColors.urgencyEmergency;
      case Urgency.high: return AppColors.urgencyHigh;
      case Urgency.medium: return AppColors.urgencyMedium;
      case Urgency.low: return AppColors.urgencyLow;
      case Urgency.unknown: return AppColors.urgencyUnknown;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (urgency) {
      case Urgency.emergency: return l10n.urgencyEmergency;
      case Urgency.high: return l10n.urgencyHigh;
      case Urgency.medium: return l10n.urgencyMedium;
      case Urgency.low: return l10n.urgencyLow;
      case Urgency.unknown: return l10n.urgencyUnknown;
    }
  }
}
