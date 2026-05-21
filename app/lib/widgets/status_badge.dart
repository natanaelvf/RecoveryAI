import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';

/// Status badge with animated dot — shows current lead status.
class StatusBadge extends StatelessWidget {
  final LeadStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _label(l10n),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (status) {
      case LeadStatus.missed:
      case LeadStatus.consentSent:
      case LeadStatus.dnrAlert:
        return AppColors.statusMissed;
      case LeadStatus.optedIn:
      case LeadStatus.qualifying:
      case LeadStatus.bookingSent:
        return AppColors.statusActive;
      case LeadStatus.booked:
        return AppColors.statusBooked;
      case LeadStatus.completed:
      case LeadStatus.followedUp:
        return AppColors.statusCompleted;
      case LeadStatus.noConsent:
        return AppColors.statusNoConsent;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (status) {
      case LeadStatus.missed: return l10n.statusMissed;
      case LeadStatus.consentSent: return l10n.statusConsentSent;
      case LeadStatus.optedIn: return l10n.statusOptedIn;
      case LeadStatus.qualifying: return l10n.statusQualifying;
      case LeadStatus.bookingSent: return l10n.statusBookingSent;
      case LeadStatus.booked: return l10n.statusBooked;
      case LeadStatus.completed: return l10n.statusCompleted;
      case LeadStatus.followedUp: return l10n.statusFollowedUp;
      case LeadStatus.dnrAlert: return l10n.statusDnrAlert;
      case LeadStatus.noConsent: return l10n.statusNoConsent;
    }
  }
}
