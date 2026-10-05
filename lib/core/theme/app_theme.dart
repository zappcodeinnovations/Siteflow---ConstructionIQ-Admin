import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color corporateBlue = Color(0xFF00529B);
  static const Color corporateYellow = Color(0xFFFFC000);
  static const Color corporateLightBlue = Color(0xFFC4D5E5);

  static ThemeData lightTheme = ThemeData(
    primaryColor: corporateBlue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: corporateBlue),
    textTheme: GoogleFonts.interTextTheme(),

    appBarTheme: const AppBarTheme(
      backgroundColor: corporateBlue,
      elevation: 0,
      foregroundColor: Colors.white,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: corporateBlue,
      unselectedItemColor: Colors.grey,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: corporateYellow,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: corporateBlue, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: const TextStyle(
        color: Color(0xFF0F2C4A),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      contentTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: corporateBlue,
    scaffoldBackgroundColor: const Color(0xFF071C2D),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
    ), // Slightly lighter for cards
    colorScheme: ColorScheme.fromSeed(
      seedColor: corporateBlue,
      brightness: Brightness.dark,
    ).copyWith(surface: const Color(0xFF1E1E1E)),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF0F2C4A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: corporateBlue,
      elevation: 0,
      foregroundColor: Colors.white,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: corporateBlue,
      selectedItemColor: corporateYellow,
      unselectedItemColor: Colors.white54,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: corporateYellow,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF162A42),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white60),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
    ),
  );
}
