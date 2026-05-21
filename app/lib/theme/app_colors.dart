import 'package:flutter/material.dart';

/// Design tokens translated from the web prototype's CSS variables.
/// Source: frontend/src/styles/index.css :root block.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────
  static const bgBase = Color(0xFF0F1419);
  static const bgSurface = Color(0xFF1A2332);
  static const bgElevated = Color(0xFF243044);
  static const bgInput = Color(0xFF141C27);
  static const bgOverlay = Color(0x99000000);

  // ── Accents ──────────────────────────────
  static const accentPrimary = Color(0xFFF59E0B);
  static const accentPrimaryHover = Color(0xFFFB923C);
  static const accentPrimaryMuted = Color(0x26F59E0B);
  static const accentPrimaryGlow = Color(0x4DF59E0B);
  static const accentSuccess = Color(0xFF10B981);
  static const accentSuccessMuted = Color(0x2610B981);
  static const accentDanger = Color(0xFFF43F5E);
  static const accentDangerMuted = Color(0x26F43F5E);
  static const accentInfo = Color(0xFF3B82F6);
  static const accentInfoMuted = Color(0x263B82F6);

  // ── Text ─────────────────────────────────
  static const textPrimary = Color(0xFFE8ECF1);
  static const textSecondary = Color(0xFF8899AA);
  static const textTertiary = Color(0xFF556677);
  static const textInverse = Color(0xFF0F1419);

  // ── Borders ──────────────────────────────
  static const borderSubtle = Color(0xFF1E2D3D);
  static const borderHover = Color(0xFF2A3E52);
  static const borderFocus = Color(0x66F59E0B);

  // ── Urgency Colors ───────────────────────
  static const urgencyEmergency = Color(0xFFEF4444);
  static const urgencyHigh = Color(0xFFF59E0B);
  static const urgencyMedium = Color(0xFF3B82F6);
  static const urgencyLow = Color(0xFF10B981);
  static const urgencyUnknown = Color(0xFF556677);

  // ── Status Colors ────────────────────────
  static const statusMissed = Color(0xFFF43F5E);
  static const statusActive = Color(0xFFF59E0B);
  static const statusBooked = Color(0xFF10B981);
  static const statusCompleted = Color(0xFF3B82F6);
  static const statusDnr = Color(0xFFF43F5E);
  static const statusNoConsent = Color(0xFF556677);
}
