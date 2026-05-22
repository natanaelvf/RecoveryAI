import 'package:flutter/material.dart';

/// Design tokens as a ThemeExtension — supports both dark and light themes.
/// Access via `Theme.of(context).extension<AppColors>()!` or `AppColors.of(context)`.
class AppColors extends ThemeExtension<AppColors> {
  // ── Backgrounds ──────────────────────────
  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;
  final Color bgInput;
  final Color bgOverlay;

  // ── Accents ──────────────────────────────
  final Color accentPrimary;
  final Color accentPrimaryHover;
  final Color accentPrimaryMuted;
  final Color accentPrimaryGlow;
  final Color accentSuccess;
  final Color accentSuccessMuted;
  final Color accentDanger;
  final Color accentDangerMuted;
  final Color accentInfo;
  final Color accentInfoMuted;

  // ── Text ─────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;

  // ── Borders ──────────────────────────────
  final Color borderSubtle;
  final Color borderHover;
  final Color borderFocus;

  // ── Urgency Colors ───────────────────────
  final Color urgencyEmergency;
  final Color urgencyHigh;
  final Color urgencyMedium;
  final Color urgencyLow;
  final Color urgencyUnknown;

  // ── Status Colors ────────────────────────
  final Color statusMissed;
  final Color statusActive;
  final Color statusBooked;
  final Color statusCompleted;
  final Color statusDnr;
  final Color statusNoConsent;

  const AppColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgInput,
    required this.bgOverlay,
    required this.accentPrimary,
    required this.accentPrimaryHover,
    required this.accentPrimaryMuted,
    required this.accentPrimaryGlow,
    required this.accentSuccess,
    required this.accentSuccessMuted,
    required this.accentDanger,
    required this.accentDangerMuted,
    required this.accentInfo,
    required this.accentInfoMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.borderSubtle,
    required this.borderHover,
    required this.borderFocus,
    required this.urgencyEmergency,
    required this.urgencyHigh,
    required this.urgencyMedium,
    required this.urgencyLow,
    required this.urgencyUnknown,
    required this.statusMissed,
    required this.statusActive,
    required this.statusBooked,
    required this.statusCompleted,
    required this.statusDnr,
    required this.statusNoConsent,
  });

  /// Convenience accessor from BuildContext.
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  // ════════════════════════════════════════════
  // DARK PALETTE — "Industrial Precision"
  // ════════════════════════════════════════════
  static const dark = AppColors(
    bgBase: Color(0xFF0F1419),
    bgSurface: Color(0xFF1A2332),
    bgElevated: Color(0xFF243044),
    bgInput: Color(0xFF141C27),
    bgOverlay: Color(0x99000000),

    accentPrimary: Color(0xFFF59E0B),
    accentPrimaryHover: Color(0xFFFB923C),
    accentPrimaryMuted: Color(0x26F59E0B),
    accentPrimaryGlow: Color(0x4DF59E0B),
    accentSuccess: Color(0xFF10B981),
    accentSuccessMuted: Color(0x2610B981),
    accentDanger: Color(0xFFF43F5E),
    accentDangerMuted: Color(0x26F43F5E),
    accentInfo: Color(0xFF3B82F6),
    accentInfoMuted: Color(0x263B82F6),

    textPrimary: Color(0xFFE8ECF1),
    textSecondary: Color(0xFF8899AA),
    textTertiary: Color(0xFF556677),
    textInverse: Color(0xFF0F1419),

    borderSubtle: Color(0xFF1E2D3D),
    borderHover: Color(0xFF2A3E52),
    borderFocus: Color(0x66F59E0B),

    urgencyEmergency: Color(0xFFEF4444),
    urgencyHigh: Color(0xFFF59E0B),
    urgencyMedium: Color(0xFF3B82F6),
    urgencyLow: Color(0xFF10B981),
    urgencyUnknown: Color(0xFF556677),

    statusMissed: Color(0xFFF43F5E),
    statusActive: Color(0xFFF59E0B),
    statusBooked: Color(0xFF10B981),
    statusCompleted: Color(0xFF3B82F6),
    statusDnr: Color(0xFFF43F5E),
    statusNoConsent: Color(0xFF556677),
  );

  // ════════════════════════════════════════════
  // LIGHT PALETTE — "Clean Professional"
  // ════════════════════════════════════════════
  static const light = AppColors(
    bgBase: Color(0xFFF5F7FA),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFF0F2F5),
    bgInput: Color(0xFFF5F6F8),
    bgOverlay: Color(0x4D000000),

    accentPrimary: Color(0xFFD97706),
    accentPrimaryHover: Color(0xFFB45309),
    accentPrimaryMuted: Color(0x1AD97706),
    accentPrimaryGlow: Color(0x33D97706),
    accentSuccess: Color(0xFF059669),
    accentSuccessMuted: Color(0x1A059669),
    accentDanger: Color(0xFFE11D48),
    accentDangerMuted: Color(0x1AE11D48),
    accentInfo: Color(0xFF2563EB),
    accentInfoMuted: Color(0x1A2563EB),

    textPrimary: Color(0xFF1A1D21),
    textSecondary: Color(0xFF5F6B7A),
    textTertiary: Color(0xFF9BA5B0),
    textInverse: Color(0xFFFFFFFF),

    borderSubtle: Color(0xFFE2E5E9),
    borderHover: Color(0xFFCDD2D8),
    borderFocus: Color(0x66D97706),

    urgencyEmergency: Color(0xFFDC2626),
    urgencyHigh: Color(0xFFD97706),
    urgencyMedium: Color(0xFF2563EB),
    urgencyLow: Color(0xFF059669),
    urgencyUnknown: Color(0xFF9BA5B0),

    statusMissed: Color(0xFFE11D48),
    statusActive: Color(0xFFD97706),
    statusBooked: Color(0xFF059669),
    statusCompleted: Color(0xFF2563EB),
    statusDnr: Color(0xFFE11D48),
    statusNoConsent: Color(0xFF9BA5B0),
  );

  @override
  AppColors copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? bgElevated,
    Color? bgInput,
    Color? bgOverlay,
    Color? accentPrimary,
    Color? accentPrimaryHover,
    Color? accentPrimaryMuted,
    Color? accentPrimaryGlow,
    Color? accentSuccess,
    Color? accentSuccessMuted,
    Color? accentDanger,
    Color? accentDangerMuted,
    Color? accentInfo,
    Color? accentInfoMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? borderSubtle,
    Color? borderHover,
    Color? borderFocus,
    Color? urgencyEmergency,
    Color? urgencyHigh,
    Color? urgencyMedium,
    Color? urgencyLow,
    Color? urgencyUnknown,
    Color? statusMissed,
    Color? statusActive,
    Color? statusBooked,
    Color? statusCompleted,
    Color? statusDnr,
    Color? statusNoConsent,
  }) {
    return AppColors(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      bgInput: bgInput ?? this.bgInput,
      bgOverlay: bgOverlay ?? this.bgOverlay,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentPrimaryHover: accentPrimaryHover ?? this.accentPrimaryHover,
      accentPrimaryMuted: accentPrimaryMuted ?? this.accentPrimaryMuted,
      accentPrimaryGlow: accentPrimaryGlow ?? this.accentPrimaryGlow,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentSuccessMuted: accentSuccessMuted ?? this.accentSuccessMuted,
      accentDanger: accentDanger ?? this.accentDanger,
      accentDangerMuted: accentDangerMuted ?? this.accentDangerMuted,
      accentInfo: accentInfo ?? this.accentInfo,
      accentInfoMuted: accentInfoMuted ?? this.accentInfoMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderHover: borderHover ?? this.borderHover,
      borderFocus: borderFocus ?? this.borderFocus,
      urgencyEmergency: urgencyEmergency ?? this.urgencyEmergency,
      urgencyHigh: urgencyHigh ?? this.urgencyHigh,
      urgencyMedium: urgencyMedium ?? this.urgencyMedium,
      urgencyLow: urgencyLow ?? this.urgencyLow,
      urgencyUnknown: urgencyUnknown ?? this.urgencyUnknown,
      statusMissed: statusMissed ?? this.statusMissed,
      statusActive: statusActive ?? this.statusActive,
      statusBooked: statusBooked ?? this.statusBooked,
      statusCompleted: statusCompleted ?? this.statusCompleted,
      statusDnr: statusDnr ?? this.statusDnr,
      statusNoConsent: statusNoConsent ?? this.statusNoConsent,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgInput: Color.lerp(bgInput, other.bgInput, t)!,
      bgOverlay: Color.lerp(bgOverlay, other.bgOverlay, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentPrimaryHover: Color.lerp(accentPrimaryHover, other.accentPrimaryHover, t)!,
      accentPrimaryMuted: Color.lerp(accentPrimaryMuted, other.accentPrimaryMuted, t)!,
      accentPrimaryGlow: Color.lerp(accentPrimaryGlow, other.accentPrimaryGlow, t)!,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t)!,
      accentSuccessMuted: Color.lerp(accentSuccessMuted, other.accentSuccessMuted, t)!,
      accentDanger: Color.lerp(accentDanger, other.accentDanger, t)!,
      accentDangerMuted: Color.lerp(accentDangerMuted, other.accentDangerMuted, t)!,
      accentInfo: Color.lerp(accentInfo, other.accentInfo, t)!,
      accentInfoMuted: Color.lerp(accentInfoMuted, other.accentInfoMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderHover: Color.lerp(borderHover, other.borderHover, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      urgencyEmergency: Color.lerp(urgencyEmergency, other.urgencyEmergency, t)!,
      urgencyHigh: Color.lerp(urgencyHigh, other.urgencyHigh, t)!,
      urgencyMedium: Color.lerp(urgencyMedium, other.urgencyMedium, t)!,
      urgencyLow: Color.lerp(urgencyLow, other.urgencyLow, t)!,
      urgencyUnknown: Color.lerp(urgencyUnknown, other.urgencyUnknown, t)!,
      statusMissed: Color.lerp(statusMissed, other.statusMissed, t)!,
      statusActive: Color.lerp(statusActive, other.statusActive, t)!,
      statusBooked: Color.lerp(statusBooked, other.statusBooked, t)!,
      statusCompleted: Color.lerp(statusCompleted, other.statusCompleted, t)!,
      statusDnr: Color.lerp(statusDnr, other.statusDnr, t)!,
      statusNoConsent: Color.lerp(statusNoConsent, other.statusNoConsent, t)!,
    );
  }
}
