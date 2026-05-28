import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand colors (مستخرجة من شعار القوافل التعليمية) ──────────────────────
  static const brandRed    = Color(0xFFE52027); // الشخصية الحمراء فوق الشعار
  static const brandGold   = Color(0xFFAD8535); // الكتاب والنسر الذهبي
  static const brandBlack  = Color(0xFF1A1A1A); // الشخصيتان الجانبيتان
  static const brandCream  = Color(0xFFF9F6F0); // الخلفية الفاتحة المتناسقة

  // Cairo TextTheme – applied globally
  static TextTheme get _cairoTextTheme => GoogleFonts.cairoTextTheme();

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData light() {
    final cs = ColorScheme(
      brightness:        Brightness.light,
      primary:           brandRed,
      onPrimary:         Colors.white,
      primaryContainer:  const Color(0xFFFFDADB),
      onPrimaryContainer:const Color(0xFF8B0009),
      secondary:         brandGold,
      onSecondary:       Colors.white,
      secondaryContainer:const Color(0xFFF5E4BC),
      onSecondaryContainer: const Color(0xFF5C4500),
      tertiary:          brandBlack,
      onTertiary:        Colors.white,
      tertiaryContainer: const Color(0xFFE0E0E0),
      onTertiaryContainer: brandBlack,
      error:             const Color(0xFFBA1A1A),
      onError:           Colors.white,
      errorContainer:    const Color(0xFFFFDAD6),
      onErrorContainer:  const Color(0xFF410002),
      surface:           brandCream,
      onSurface:         brandBlack,
      surfaceContainerHighest: const Color(0xFFEDE8E1),
      outline:           const Color(0xFFADA89F),
      outlineVariant:    const Color(0xFFD6D0C8),
      shadow:            Colors.black,
      scrim:             Colors.black,
      inverseSurface:    const Color(0xFF32302C),
      onInverseSurface:  const Color(0xFFF5F0E8),
      inversePrimary:    const Color(0xFFFFB3B5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: brandCream,
      textTheme: _cairoTextTheme.apply(
        bodyColor:    brandBlack,
        displayColor: brandBlack,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEDE8E1)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandRed,
          side: const BorderSide(color: brandRed),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandRed,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandRed, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6D0C8)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: const Color(0xFF6B6560)),
        hintStyle: GoogleFonts.cairo(
            color: const Color(0xFF6B6560), fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5E4BC),
        selectedColor: brandRed,
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDE8E1),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandRed,
        linearTrackColor: Color(0xFFFFDADB),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: brandRed,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: brandBlack,
        ),
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final cs = ColorScheme(
      brightness:        Brightness.dark,
      primary:           const Color(0xFFFFB3B5),
      onPrimary:         const Color(0xFF680011),
      primaryContainer:  const Color(0xFF93000E),
      onPrimaryContainer:const Color(0xFFFFDADB),
      secondary:         const Color(0xFFDAC17E),
      onSecondary:       const Color(0xFF3A2900),
      secondaryContainer:const Color(0xFF543D00),
      onSecondaryContainer: const Color(0xFFF5E4BC),
      tertiary:          const Color(0xFFCCC8BF),
      onTertiary:        const Color(0xFF32302C),
      tertiaryContainer: const Color(0xFF484540),
      onTertiaryContainer: const Color(0xFFE8E4DB),
      error:             const Color(0xFFFFB4AB),
      onError:           const Color(0xFF690005),
      errorContainer:    const Color(0xFF93000A),
      onErrorContainer:  const Color(0xFFFFDAD6),
      surface:           const Color(0xFF1A1816),
      onSurface:         const Color(0xFFEDE8E1),
      surfaceContainerHighest: const Color(0xFF32302C),
      outline:           const Color(0xFF968F87),
      outlineVariant:    const Color(0xFF4A4741),
      shadow:            Colors.black,
      scrim:             Colors.black,
      inverseSurface:    const Color(0xFFEDE8E1),
      onInverseSurface:  const Color(0xFF32302C),
      inversePrimary:    brandRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF1A1816),
      textTheme: _cairoTextTheme.apply(
        bodyColor:    const Color(0xFFEDE8E1),
        displayColor: const Color(0xFFEDE8E1),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF1A1816),
        foregroundColor: const Color(0xFFEDE8E1),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFEDE8E1),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF252320),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3A3730)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252320),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB3B5), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A4741)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: const Color(0xFF968F87)),
        hintStyle: GoogleFonts.cairo(
            color: const Color(0xFF968F87), fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFFFB3B5),
      ),
    );
  }
}
