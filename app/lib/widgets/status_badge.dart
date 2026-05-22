import 'package:flutter/material.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../models/lead.dart';

/// Status badge with animated dot — shows current lead status.
class StatusBadge extends StatelessWidget {
  final LeadStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final color = _getColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _label(l10n),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(AppColors colors) {
    switch (status) {
      case LeadStatus.missed:
      case LeadStatus.consentSent:
      case LeadStatus.dnrAlert:
        return colors.statusMissed;
      case LeadStatus.optedIn:
      case LeadStatus.qualifying:
      case LeadStatus.qualifyingIssue:
      case LeadStatus.qualifyingUrgency:
      case LeadStatus.qualifyingName:
      case LeadStatus.bookingSent:
        return colors.statusActive;
      case LeadStatus.booked:
        return colors.statusBooked;
      case LeadStatus.completed:
      case LeadStatus.followedUp:
        return colors.statusCompleted;
      case LeadStatus.noConsent:
        return colors.statusNoConsent;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (status) {
      case LeadStatus.missed: return l10n.statusMissed;
      case LeadStatus.consentSent: return l10n.statusConsentSent;
      case LeadStatus.optedIn: return l10n.statusOptedIn;
      case LeadStatus.qualifying: return l10n.statusQualifying;
      case LeadStatus.qualifyingIssue: return l10n.statusQualifying;
      case LeadStatus.qualifyingUrgency: return l10n.statusQualifying;
      case LeadStatus.qualifyingName: return l10n.statusQualifying;
      case LeadStatus.bookingSent: return l10n.statusBookingSent;
      case LeadStatus.booked: return l10n.statusBooked;
      case LeadStatus.completed: return l10n.statusCompleted;
      case LeadStatus.followedUp: return l10n.statusFollowedUp;
      case LeadStatus.dnrAlert: return l10n.statusDnrAlert;
      case LeadStatus.noConsent: return l10n.statusNoConsent;
    }
  }
}
