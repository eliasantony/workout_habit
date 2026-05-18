import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0EA5E9); // Clear water blue
  static const Color primaryContainerColor = Color(0xFFE0F2FE); // Light blue
  static const Color secondaryColor = Color(0xFF14B8A6); // Fresh aqua/mint
  static const Color accentColor = Color(0xFFF97316); // Warm orange for streaks
  static const Color backgroundColor = Color(0xFFF8FAFC); // Very light blue/off-white
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFEF5350);

  // Dark Mode Colors - Pixel Weather Inspired
  static const Color primaryColorDark = Color(0xFF7CB9FF); // Bright, vibrant blue
  static const Color backgroundColorDark = Color(0xFF0B0E14); // Deep charcoal/black
  static const Color surfaceColorDark = Color(0xFF171C26); // Slightly lighter surface
  static const Color secondaryTextColorDark = Color(0xFF9DA3AE); // Improved contrast gray

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryContainerColor,
        onPrimaryContainer: primaryColor,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceColor,
        error: errorColor,
        outlineVariant: Colors.blue.withValues(alpha: 0.1),
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.blue.withValues(alpha: 0.05)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColorDark,
        onPrimary: backgroundColorDark,
        primaryContainer: surfaceColorDark,
        onPrimaryContainer: primaryColorDark,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceColorDark,
        onSurface: Colors.white,
        onSurfaceVariant: secondaryTextColorDark,
        error: errorColor,
        outline: Colors.white.withValues(alpha: 0.1),
        outlineVariant: Colors.white.withValues(alpha: 0.05),
      ),
      scaffoldBackgroundColor: backgroundColorDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColorDark),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: backgroundColorDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColorDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorDark,
          foregroundColor: backgroundColorDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColorDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: primaryColorDark,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: secondaryTextColorDark,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
        ),
        bodySmall: TextStyle(
          color: secondaryTextColorDark,
        ),
        labelSmall: TextStyle(
          color: secondaryTextColorDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

}
