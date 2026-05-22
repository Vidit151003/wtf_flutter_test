import 'package:flutter/material.dart';

// ─── Spacing system (8pt base) ───────────────────────────────────────────────
const double kSpacing2 = 2.0;
const double kSpacing4 = 4.0;
const double kSpacing8 = 8.0;
const double kSpacing12 = 12.0;
const double kSpacing16 = 16.0;
const double kSpacing20 = 20.0;
const double kSpacing24 = 24.0;
const double kSpacing32 = 32.0;

// ─── Shared semantic colours ─────────────────────────────────────────────────
const Color kColorSuccess = Color(0xFF12B76A);
const Color kColorWarning = Color(0xFFF79009);
const Color kColorError = Color(0xFFD92D20);

// ─── Trainer palette ─────────────────────────────────────────────────────────
const Color kTrainerPrimary = Color(0xFFE50914);
const Color kTrainerPrimaryDark = Color(0xFFC2070F);
const Color kTrainerBackground = Color(0xFFFFFFFF);
const Color kTrainerSurface = Color(0xFFF9F9F9);
const Color kTrainerOnPrimary = Color(0xFFFFFFFF);
const Color kTrainerNeutral100 = Color(0xFFF2F2F2);
const Color kTrainerNeutral300 = Color(0xFFD4D4D4);
const Color kTrainerNeutral500 = Color(0xFF737373);
const Color kTrainerNeutral700 = Color(0xFF404040);
const Color kTrainerNeutral900 = Color(0xFF171717);

// ─── Guru palette ────────────────────────────────────────────────────────────
const Color kGuruPrimary = Color(0xFF1769E0);
const Color kGuruPrimaryDark = Color(0xFF1257BC);
const Color kGuruBackground = Color(0xFFFFFFFF);
const Color kGuruSurface = Color(0xFFF5F8FF);
const Color kGuruOnPrimary = Color(0xFFFFFFFF);
const Color kGuruNeutral100 = Color(0xFFF0F2F5);
const Color kGuruNeutral300 = Color(0xFFCDD5E0);
const Color kGuruNeutral500 = Color(0xFF6B7A99);
const Color kGuruNeutral700 = Color(0xFF374561);
const Color kGuruNeutral900 = Color(0xFF0D1B3E);

// ─── Typography ──────────────────────────────────────────────────────────────
TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      color: primaryText,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: primaryText,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: primaryText,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: primaryText,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: primaryText,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: primaryText,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: secondaryText,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: primaryText,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: primaryText,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: secondaryText,
    ),
  );
}

// ─── Trainer ThemeData ────────────────────────────────────────────────────────
ThemeData getTrainerTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: kTrainerPrimary,
    onPrimary: kTrainerOnPrimary,
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF410002),
    secondary: Color(0xFF775652),
    onSecondary: kTrainerOnPrimary,
    secondaryContainer: Color(0xFFFFDAD6),
    onSecondaryContainer: Color(0xFF2C1512),
    tertiary: Color(0xFF755B2E),
    onTertiary: kTrainerOnPrimary,
    tertiaryContainer: Color(0xFFFFDEA7),
    onTertiaryContainer: Color(0xFF271900),
    error: kColorError,
    onError: kTrainerOnPrimary,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: kTrainerSurface,
    onSurface: kTrainerNeutral900,
    surfaceContainerHighest: kTrainerNeutral100,
    onSurfaceVariant: kTrainerNeutral700,
    outline: kTrainerNeutral300,
    outlineVariant: kTrainerNeutral100,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: kTrainerNeutral900,
    onInverseSurface: kTrainerNeutral100,
    inversePrimary: Color(0xFFFFB4AB),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kTrainerBackground,
    textTheme: _buildTextTheme(kTrainerNeutral900, kTrainerNeutral500),
    appBarTheme: const AppBarTheme(
      backgroundColor: kTrainerBackground,
      foregroundColor: kTrainerNeutral900,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kTrainerNeutral900,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kTrainerPrimary,
        foregroundColor: kTrainerOnPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTrainerPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: kTrainerPrimary, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kTrainerNeutral100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kTrainerNeutral300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kTrainerPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kColorError, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: kSpacing16, vertical: kSpacing16),
    ),
    cardTheme: CardThemeData(
      color: kTrainerSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kTrainerNeutral100),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kTrainerNeutral100,
      thickness: 1,
    ),
    extensions: const [],
  );
}

// ─── Guru ThemeData ───────────────────────────────────────────────────────────
ThemeData getGuruTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: kGuruPrimary,
    onPrimary: kGuruOnPrimary,
    primaryContainer: Color(0xFFD8E6FF),
    onPrimaryContainer: Color(0xFF001C48),
    secondary: Color(0xFF555F71),
    onSecondary: kGuruOnPrimary,
    secondaryContainer: Color(0xFFD9E3F8),
    onSecondaryContainer: Color(0xFF121C2B),
    tertiary: Color(0xFF6D5E78),
    onTertiary: kGuruOnPrimary,
    tertiaryContainer: Color(0xFFF5DAFF),
    onTertiaryContainer: Color(0xFF271731),
    error: kColorError,
    onError: kGuruOnPrimary,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: kGuruSurface,
    onSurface: kGuruNeutral900,
    surfaceContainerHighest: kGuruNeutral100,
    onSurfaceVariant: kGuruNeutral700,
    outline: kGuruNeutral300,
    outlineVariant: kGuruNeutral100,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: kGuruNeutral900,
    onInverseSurface: kGuruNeutral100,
    inversePrimary: Color(0xFFADC6FF),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kGuruBackground,
    textTheme: _buildTextTheme(kGuruNeutral900, kGuruNeutral500),
    appBarTheme: const AppBarTheme(
      backgroundColor: kGuruBackground,
      foregroundColor: kGuruNeutral900,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kGuruNeutral900,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGuruPrimary,
        foregroundColor: kGuruOnPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kGuruPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: kGuruPrimary, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kGuruNeutral100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGuruNeutral300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGuruPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kColorError, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: kSpacing16, vertical: kSpacing16),
    ),
    cardTheme: CardThemeData(
      color: kGuruSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kGuruNeutral100),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kGuruNeutral100,
      thickness: 1,
    ),
    extensions: const [],
  );
}
