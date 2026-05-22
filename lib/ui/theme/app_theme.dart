import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Markalama renkleri
  static const _purple = Color(0xFF382469); // koyu mor (light primary)
  static const _purpleAccent = Color(0xFF8762FF); // ana vurgu
  static const _purpleLight = Color(0xFFB39DFF); // dark için aydınlık

  // Light yüzeyler
  static const _scaffoldLight = Colors.white;
  static const _surfaceContainerLight = Color(0xFFEDE7FF);
  static const _inactiveLight = Color(0xFFF0F7FF);

  // Dark yüzeyler
  static const _scaffoldDark = Color(0xFF0F0B1E);
  static const _surfaceDark = Color(0xFF1E1A2E);
  static const _surfaceContainerDark = Color(0xFF2A2540);
  static const _inactiveDark = Color(0xFF3A2F55);

  static final ThemeData light = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _purple,
      secondary: _purpleAccent,
      error: Color(0xFFE53935),
      surface: Colors.white,
      surfaceContainerHighest: _surfaceContainerLight,
      onSurface: Colors.black,
    ),
    primaryColor: _purple,
    indicatorColor: _purple,
    scaffoldBackgroundColor: _scaffoldLight,
    canvasColor: Colors.white,
    cardColor: Colors.white,
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
    unselectedWidgetColor: _inactiveLight,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.black,
    ),
    fontFamily: 'Comfortaa',
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: _purple,
        fontWeight: FontWeight.bold,
        fontSize: 60.0,
      ),
      headlineMedium: const TextStyle(
        color: _purple,
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
      ),
      bodyLarge: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w400,
        fontSize: 20.0,
      ),
      bodyMedium: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
      ),
      bodySmall: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: _purple,
      selectionHandleColor: _purple,
      selectionColor: Color(0x1F382469),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _purpleLight,
      secondary: _purpleAccent,
      error: Color(0xFFFF6B6B),
      surface: _surfaceDark,
      surfaceContainerHighest: _surfaceContainerDark,
      onSurface: Colors.white,
    ),
    primaryColor: _purpleLight,
    indicatorColor: _purpleAccent,
    scaffoldBackgroundColor: _scaffoldDark,
    canvasColor: _surfaceDark,
    cardColor: _surfaceDark,
    dialogTheme: const DialogThemeData(backgroundColor: _surfaceDark),
    unselectedWidgetColor: _inactiveDark,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _surfaceDark,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceDark,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
    ),
    fontFamily: 'Comfortaa',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: _purpleLight,
        fontWeight: FontWeight.bold,
        fontSize: 60.0,
      ),
      headlineMedium: TextStyle(
        color: _purpleLight,
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w400,
        fontSize: 20.0,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
      ),
      bodySmall: TextStyle(
        color: Color(0xB3FFFFFF), // %70 beyaz
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _purpleLight,
      selectionHandleColor: _purpleLight,
      selectionColor: _purpleLight.withValues(alpha: 0.3),
    ),
  );
}
