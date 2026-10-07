import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color corporateBlue = Color(0xFF00529B);
  static const Color corporateYellow = Color(0xFFFFC000);
  static const Color corporateLightBlue = Color(0xFFC4D5E5);
  static const Color darkBackground = Color(0xFF090B0F);
  static const Color darkSurface = Color(0xFF14181E);
  static const Color darkSurfaceRaised = Color(0xFF1B2129);
  static const Color darkText = Color(0xFFF4F7FB);
  static const Color darkMuted = Color(0xFFAAB4C3);
  static const Color darkBorder = Color(0xFF303844);

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
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xFFD8E8F7),
      indicatorColor: Colors.white,
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
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: corporateBlue,
    scaffoldBackgroundColor: darkBackground,
    canvasColor: darkSurface,
    cardColor: darkSurface,
    dividerColor: darkBorder,
    iconTheme: const IconThemeData(color: darkMuted),
    cardTheme: const CardThemeData(
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: corporateBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF66B2FF),
      onPrimary: const Color(0xFF001D35),
      secondary: corporateYellow,
      onSecondary: Colors.black,
      surface: darkSurface,
      onSurface: darkText,
      onSurfaceVariant: darkMuted,
      outline: darkBorder,
      outlineVariant: darkBorder,
      surfaceContainerLow: Color(0xFF11151A),
      surfaceContainer: darkSurface,
      surfaceContainerHigh: darkSurfaceRaised,
      surfaceContainerHighest: Color(0xFF232A34),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: darkText,
      displayColor: darkText,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: darkSurfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder),
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
      backgroundColor: darkSurface,
      elevation: 0,
      foregroundColor: darkText,
      surfaceTintColor: Colors.transparent,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: Color(0xFF66B2FF),
      unselectedItemColor: darkMuted,
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
      fillColor: darkSurfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkBorder),
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
    tabBarTheme: const TabBarThemeData(
      labelColor: darkText,
      unselectedLabelColor: darkMuted,
      indicatorColor: Color(0xFF66B2FF),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: darkText,
      iconColor: darkMuted,
      subtitleTextStyle: TextStyle(color: darkMuted),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: darkSurfaceRaised,
      surfaceTintColor: Colors.transparent,
      textStyle: const TextStyle(color: darkText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurfaceRaised,
      modalBackgroundColor: darkSurfaceRaised,
      surfaceTintColor: Colors.transparent,
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(darkSurfaceRaised),
      dataRowColor: WidgetStatePropertyAll(darkSurface),
      headingTextStyle: TextStyle(color: darkText, fontWeight: FontWeight.w700),
      dataTextStyle: TextStyle(color: darkText),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText,
        side: const BorderSide(color: darkBorder),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF252C36),
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Color(0xFF8CC8FF),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
