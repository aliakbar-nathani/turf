import 'package:flutter/material.dart';

class AppTheme {
  // Main colors
  static const Color primaryColor = Color(0xFF2E7D32);  // Green color to represent turf/field
  static const Color secondaryColor = Color(0xFF1565C0); // Blue for accents
  static const Color accentColor = Color(0xFFFF8F00);   // Orange for call-to-actions
  
  // Background colors
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Colors.white;
  
  // Success/Error colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color infoColor = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  static ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: scaffoldBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}