import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App-wide ThemeData — dark ("Industrial Precision") and light ("Clean Professional").
/// Both themes share the same typography system but use their respective color palettes.
class AppTheme {
  AppTheme._();

  // ════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════
  static ThemeData get dark {
    const c = AppColors.dark;
    return _buildTheme(Brightness.dark, c);
  }

  // ════════════════════════════════════════════
  // LIGHT THEME
  // ════════════════════════════════════════════
  static ThemeData get light {
    const c = AppColors.light;
    return _buildTheme(Brightness.light, c);
  }

  static ThemeData _buildTheme(Brightness brightness, AppColors c) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.bgBase,
      canvasColor: c.bgSurface,

      extensions: <ThemeExtension<dynamic>>[c],

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.accentPrimary,
        onPrimary: c.textInverse,
        secondary: c.accentSuccess,
        onSecondary: c.textInverse,
        error: c.accentDanger,
        onError: c.textInverse,
        surface: c.bgSurface,
        onSurface: c.textPrimary,
      ),

      // ── Typography ─────────────────────────
      textTheme: _buildTextTheme(c),

      // ── AppBar ─────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgSurface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.archivoBlack(
          fontSize: 20,
          color: c.textPrimary,
          letterSpacing: -0.02,
        ),
      ),

      // ── Bottom Navigation ──────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bgSurface,
        selectedItemColor: c.accentPrimary,
        unselectedItemColor: c.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      // ── Card ───────────────────────────────
      cardTheme: CardThemeData(
        color: c.bgSurface,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: c.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accentPrimary,
          foregroundColor: c.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.borderSubtle),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ── Text Button ────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
        ),
      ),

      // ── Input Decoration ───────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.accentPrimary, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.textTertiary, fontSize: 14),
        labelStyle: TextStyle(
          fontFamily: GoogleFonts.barlowCondensed().fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.8,
          color: c.textTertiary,
        ),
      ),

      // ── Chip ───────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: c.bgElevated,
        selectedColor: c.accentPrimaryMuted,
        labelStyle: TextStyle(fontSize: 13, color: c.textSecondary),
        side: BorderSide(color: c.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Divider ────────────────────────────
      dividerTheme: DividerThemeData(
        color: c.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ───────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.bgElevated,
        contentTextStyle: TextStyle(color: c.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialog ─────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Bottom Sheet ───────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ── FloatingActionButton ───────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accentPrimary,
        foregroundColor: c.textInverse,
        elevation: isDark ? 4 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(AppColors c) {
    return TextTheme(
      // Display — Archivo Black
      displayLarge: GoogleFonts.archivoBlack(
        fontSize: 32,
        color: c.textPrimary,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.archivoBlack(
        fontSize: 28,
        color: c.textPrimary,
        letterSpacing: -0.3,
        height: 1.1,
      ),
      displaySmall: GoogleFonts.archivoBlack(
        fontSize: 24,
        color: c.textPrimary,
        letterSpacing: -0.2,
        height: 1.1,
      ),

      // Headlines — Barlow Condensed uppercase
      headlineLarge: GoogleFonts.barlowCondensed(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: c.textSecondary,
        letterSpacing: 0.8,
      ),
      headlineMedium: GoogleFonts.barlowCondensed(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: c.textSecondary,
        letterSpacing: 0.6,
      ),
      headlineSmall: GoogleFonts.barlowCondensed(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: c.textSecondary,
        letterSpacing: 0.5,
      ),

      // Title — DM Sans
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c.textSecondary,
      ),

      // Body — DM Sans
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        color: c.textPrimary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        color: c.textPrimary,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        color: c.textSecondary,
        height: 1.5,
      ),

      // Labels — DM Sans
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: c.textSecondary,
      ),
      labelSmall: GoogleFonts.barlowCondensed(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: c.textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}
