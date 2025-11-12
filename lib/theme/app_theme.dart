// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

// --- App Color Palette ---
const Color softBlue = Color(0xFFA7C7E7);
const Color mintGreen = Color(0xFFA8D5BA);
const Color mutedNeutralLight = Color(0xFFF5F7F8);
const Color mutedNeutralMid = Color(0xFFE0E0E0);
const Color mutedNeutralDark = Color(0xFF4A6572);

// --- Light Theme Definition ---
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.light,
  scaffoldBackgroundColor: mutedNeutralLight,
  colorScheme: const ColorScheme.light(
    primary: softBlue,
    secondary: mintGreen,
    surface: Colors.white,
    onSurface: mutedNeutralDark,
    error: Colors.redAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: mutedNeutralDark),
    titleTextStyle: TextStyle(
        color: mutedNeutralDark, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    color: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: mutedNeutralDark),
    bodyMedium: TextStyle(color: mutedNeutralDark),
    titleLarge: TextStyle(color: mutedNeutralDark, fontWeight: FontWeight.bold),
    headlineSmall:
        TextStyle(color: mutedNeutralDark, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: mutedNeutralDark,
      backgroundColor: mintGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      elevation: 3,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: mutedNeutralDark,
      side: const BorderSide(color: mutedNeutralDark, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: softBlue, width: 2),
    ),
  ),
);

// --- Enhanced Dark Theme Definition ---
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  scaffoldBackgroundColor:
      const Color(0xFF121212), // Material Design standard dark background
  colorScheme: const ColorScheme.dark(
    primary: softBlue,
    secondary: mintGreen,
    surface: Color(0xFF1E1E1E), // Color for card backgrounds
    onSurface: Color(0xFFEAEAEA),
    error: Colors.redAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFFEAEAEA)),
    titleTextStyle: TextStyle(
        color: Color(0xFFEAEAEA), fontSize: 20, fontWeight: FontWeight.bold),
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    color: const Color(0xFF1E1E1E), // This ensures all cards are dark
  ),
  // Updated text theme for better visibility
  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: Color(0xFFEAEAEA)),
    bodyMedium: TextStyle(
        color: const Color(0xFFEAEAEA)
            .withOpacity(0.8)), // Subtler color for less important text
    titleLarge:
        const TextStyle(color: Color(0xFFEAEAEA), fontWeight: FontWeight.bold),
    headlineSmall:
        const TextStyle(color: Color(0xFFEAEAEA), fontWeight: FontWeight.bold),
  ),
  // ListTile theme for better contrast on cards
  listTileTheme: ListTileThemeData(
    iconColor: mintGreen,
    textColor: const Color(0xFFEAEAEA).withOpacity(0.9),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black, // Dark text on light green button
      backgroundColor: mintGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      elevation: 3,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: mutedNeutralMid, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2A2A2A),
    hintStyle: TextStyle(color: Colors.grey.shade600), // Hint text color
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: softBlue, width: 2),
    ),
  ),
);
