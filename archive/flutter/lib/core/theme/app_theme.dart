import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Template Design Tokens
  static const Color primaryGreen = Color(0xFF2F7F3F);
  static const Color ctaOrange = Color(0xFFFF6B35);
  static const Color creamBg = Color(0xFFFFF8E7);
  static const Color creamBgAlt = Color(0xFFFDFAF3);
  static const Color brownText = Color(0xFF6B4E3D);
  static const Color brownTextLight = Color(0xFF8B6F47);
  static const Color darkBg = Color(0xFF141E16);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFC62828);
  static const Color warningColor = Color(0xFFE65100);
  static const Color infoColor = Color(0xFF1976D2);

  // Backward compatibility aliases
  static const Color primaryColor = primaryGreen;
  static const Color secondaryColor = ctaOrange;
  static const Color backgroundColor = creamBg;
  static const Color surfaceColor = Colors.white;
  static const Color accentColor = primaryGreen;
  static const Color primaryLightColor = successGreen;
  static const Color secondaryLightColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF2E7D32);

  // High contrast theme colors
  static const Color highContrastPrimary = Color(0xFF000000);
  static const Color highContrastSecondary = Color(0xFF4A4A4A);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  static const Color highContrastSurface = Color(0xFFF5F5F5);

  // Text contrast optimized colors
  static const Color textPrimary = brownText;
  static const Color textSecondary = brownTextLight;
  static const Color textTertiary = Color(0xFF999999);

  static TextTheme _plusJakartaSansTextTheme(TextTheme base) {
    return GoogleFonts.plusJakartaSansTextTheme(base);
  }

  static ThemeData getLightTheme({bool highContrast = false}) {
    final colorScheme = highContrast ? _highContrastLightScheme : _standardLightScheme;

    final baseTextTheme = _getAccessibleTextTheme(colorScheme);
    final textTheme = _plusJakartaSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: creamBg,
      iconTheme: const IconThemeData(
        color: brownText,
        size: 24.0,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: brownText,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: brownText,
        ),
        iconTheme: const IconThemeData(
          color: brownText,
          size: 24,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        selectedItemColor: primaryGreen,
        unselectedItemColor: brownText.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade100,
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 2,
          shadowColor: primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: errorColor,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: brownText.withValues(alpha: 0.4),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: brownText.withValues(alpha: 0.7),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: errorColor,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryGreen,
        disabledColor: Colors.grey.shade200,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: brownText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ctaOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        shape: CircleBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: primaryGreen.withValues(alpha: 0.1),
        circularTrackColor: primaryGreen.withValues(alpha: 0.1),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGreen;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen.withValues(alpha: 0.3);
          }
          return Colors.grey.shade300;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: primaryGreen.withValues(alpha: 0.1),
        thumbColor: primaryGreen,
        overlayColor: primaryGreen.withValues(alpha: 0.1),
      ),
      dividerTheme: DividerThemeData(
        color: brownText.withValues(alpha: 0.05),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => getLightTheme();

  static ThemeData getDarkTheme({bool highContrast = false}) {
    final colorScheme = highContrast ? _highContrastDarkScheme : _standardDarkScheme;

    final baseTextTheme = _getAccessibleTextTheme(colorScheme);
    final textTheme = _plusJakartaSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: darkBg,
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24.0,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1A2B1E).withValues(alpha: 0.95),
        selectedItemColor: primaryGreen,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A2B1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(48, 48),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2B1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A2B1E),
        selectedColor: primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ctaOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: primaryGreen.withValues(alpha: 0.1),
        circularTrackColor: primaryGreen.withValues(alpha: 0.1),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGreen;
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen.withValues(alpha: 0.3);
          }
          return Colors.grey.shade700;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: primaryGreen.withValues(alpha: 0.2),
        thumbColor: primaryGreen,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.05),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => getDarkTheme();

  // Color schemes
  static final ColorScheme _standardLightScheme = ColorScheme.light(
    primary: primaryGreen,
    onPrimary: Colors.white,
    primaryContainer: primaryGreen.withValues(alpha: 0.1),
    onPrimaryContainer: primaryGreen,
    secondary: ctaOrange,
    onSecondary: Colors.white,
    secondaryContainer: ctaOrange.withValues(alpha: 0.1),
    onSecondaryContainer: ctaOrange,
    tertiary: brownText,
    surface: creamBg,
    onSurface: brownText,
    onSurfaceVariant: brownTextLight,
    outline: brownText.withValues(alpha: 0.2),
    error: errorColor,
    onError: Colors.white,
  );

  static final ColorScheme _standardDarkScheme = ColorScheme.dark(
    primary: primaryGreen,
    onPrimary: Colors.white,
    primaryContainer: primaryGreen.withValues(alpha: 0.2),
    onPrimaryContainer: const Color(0xFFA5D6A7),
    secondary: ctaOrange,
    onSecondary: Colors.white,
    secondaryContainer: ctaOrange.withValues(alpha: 0.2),
    onSecondaryContainer: const Color(0xFFFFAB91),
    surface: darkBg,
    onSurface: const Color(0xFFE0E0E0),
    onSurfaceVariant: const Color(0xFFBDBDBD),
    outline: Colors.white.withValues(alpha: 0.2),
    error: const Color(0xFFEF9A9A),
    onError: Colors.black,
  );

  static final ColorScheme _highContrastLightScheme = ColorScheme.light(
    primary: highContrastPrimary,
    secondary: highContrastSecondary,
    surface: highContrastBackground,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
    error: Colors.red.shade800,
    onError: Colors.white,
  );

  static final ColorScheme _highContrastDarkScheme = ColorScheme.dark(
    primary: Colors.white,
    secondary: Colors.grey.shade300,
    surface: Colors.black,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    error: Colors.red.shade300,
    onError: Colors.black,
  );

  static TextTheme _getAccessibleTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colorScheme.onSurface,
        height: 1.45,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
        height: 1.33,
      ),
    );
  }

  static ThemeData getTheme({
    required Brightness brightness,
    required bool highContrast,
  }) {
    return brightness == Brightness.light
        ? getLightTheme(highContrast: highContrast)
        : getDarkTheme(highContrast: highContrast);
  }
}
