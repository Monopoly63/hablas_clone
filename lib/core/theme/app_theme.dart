import 'package:flutter/material.dart';

/// Hablas Studio Theme Configuration
/// OLED Deep Black base with Liquid Electric Cyan / Cobalt Blue accent system
class AppTheme {
  // ─── Brand Colors ───────────────────────────────────────────────────
  static const Color oledBlack = Color(0xFF050505);
  static const Color surfaceDark = Color(0xFF0D0D12);
  static const Color surfaceDark60 = Color(0x990D0D12); // 60% opacity

  // ─── Accent Palette ─────────────────────────────────────────────────
  static const Color liquidCyan = Color(0xFF00F2FE);
  static const Color cobaltBlue = Color(0xFF4FACFE);
  static const Color neonEmerald = Color(0xFF00FF87);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color warmAmber = Color(0xFFFFBE0B);

  // ─── Glass Opacity Layers ───────────────────────────────────────────
  static const Color glassFill = Color(0x1AFFFFFF);  // 10% white fill
  static const Color glassFillSubtle = Color(0x0AFFFFFF); // 4% white fill
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white border
  static const Color glassShadow = Color(0x10000000); // 6% black shadow
  static const Color glassShadowDeep = Color(0x20000000); // 12% black shadow

  // ─── Status Colors ──────────────────────────────────────────────────
  static const Color statusRunning = neonEmerald;
  static const Color statusIdle = cobaltBlue;
  static const Color statusSleeping = Color(0xFF666680);
  static const Color statusError = neonPink;

  // ─── Gradient Definitions ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [liquidCyan, cobaltBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonEmerald, liquidCyan],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [neonPink, Color(0xFFFF4D6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Text Styles ────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFFE0E0E0),
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFFAAAAAA),
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Color(0xFF888888),
  );

  static const TextStyle accentLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: liquidCyan,
  );

  // ─── Build ThemeData ────────────────────────────────────────────────
  static ThemeData buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: oledBlack,
      colorScheme: const ColorScheme.dark(
        primary: liquidCyan,
        secondary: neonEmerald,
        surface: surfaceDark,
        error: neonPink,
        onPrimary: oledBlack,
        onSecondary: oledBlack,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0x00000000),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: heading2,
        iconTheme: IconThemeData(color: liquidCyan, size: 24),
      ),
      cardTheme: CardThemeData(
        color: glassFillSubtle,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: glassBorder, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: surfaceDark60,
        foregroundColor: liquidCyan,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: glassBorder, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
        contentTextStyle: body,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x15FFFFFF),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFCCCCCC),
        size: 24,
      ),
      textTheme: TextTheme(
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: bodySmall,
        labelLarge: accentLabel,
        labelSmall: caption,
      ),
    );
  }
}
