import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Relative time formatting — matches frontend/src/views/leads.js timeAgo()
String timeAgo(BuildContext context, DateTime date) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
  return l10n.timeWeeksAgo((diff.inDays / 7).floor());
}

/// Format date for display (Finnish locale style)
String formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day}.${date.month}.${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

/// Format time only
String formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

/// Format date as day label (e.g., "21.5.")
String formatDayLabel(DateTime date) {
  return '${date.day}.${date.month}.';
}
