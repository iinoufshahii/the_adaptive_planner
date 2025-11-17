import 'package:flutter/material.dart';

// ==================== APP COLOR PALETTE ====================
/// Primary blue color - used for main UI elements and branding (#66B2D6)
const Color softBlue = Color(0xFF66B2D6);

/// Secondary light blue - used for accents and highlights (#FFFFFF)
const Color mintGreen = Color.fromARGB(255, 255, 255, 255);

/// Light neutral background color - used for dashboard backgrounds (#F0F8FF)
const Color mutedNeutralLight = Color(0xFFF0F8FF);

/// Mid-tone neutral color - used for secondary text and elements (#961E1E)
const Color mutedNeutralMid = Color.fromARGB(255, 150, 30, 30);

/// Dark neutral color - primary text color in light mode (#000000)
const Color mutedNeutralDark = Color.fromARGB(255, 0, 0, 0);

/// Deep aqua blue - alternative secondary color (#4694B0)
const Color deepAqua = Color(0xFF4694B0);

// ==================== REUSABLE CARD COLORS ====================
/// Card background color for light mode - white for clarity
const Color lightModeCardColor = Colors.white;

/// Card background color for dark mode - dark gray for visibility
const Color darkModeCardColor = Color(0xFF1E1E1E);

/// Background color for entire app in dark mode - darker than cards for contrast
const Color darkModeBackgroundColor = Color(0xFF121212);

/// Background color for entire app in light mode - soft white
const Color lightModeBackgroundColor = mutedNeutralLight;

// ==================== GLASS EFFECT DECORATIONS ====================
/// Modern glass effect decoration for navigation bar with gradient and blur support.
/// Applies frosted glass aesthetic with proper borders and shadows for visual depth.
/// [isDarkMode] determines color palette: darker colors for dark theme, lighter for light theme
BoxDecoration getGlassNavBarDecoration(BuildContext context, bool isDarkMode) {
  return BoxDecoration(
    // Gradient: semi-transparent white overlay creates glass effect
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDarkMode
          ? [
              Colors.white.withValues(alpha: 0.08), // Very subtle in dark mode
              Colors.white
                  .withValues(alpha: 0.05), // Even more subtle at bottom
            ]
          : [
              Colors.white.withValues(alpha: 0.85), // More opaque in light mode
              Colors.white.withValues(
                  alpha: 0.7), // Slightly more transparent at bottom
            ],
      stops: [0.0, 1.0], // Gradient starts at top, ends at bottom
    ),
    // Border radius: smooth rounded corners for nav bar top
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(30),
      topRight: Radius.circular(30),
    ),
    // Border: subtle white edge creates glass definition
    border: Border.all(
      color: Colors.white.withValues(alpha: isDarkMode ? 0.15 : 0.5),
      width: 1.5,
    ),
    // Box shadows: creates depth and 3D effect
    boxShadow: [
      // Deep shadow for main depth
      BoxShadow(
        color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.15),
        blurRadius: 40,
        offset: const Offset(0, -10), // Offset upward for nav bar position
        spreadRadius: 5,
      ),
      // Secondary shadow for additional depth
      BoxShadow(
        color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.08),
        blurRadius: 20,
        offset: const Offset(0, -5),
      ),
    ],
  );
}

/// Modern glass effect decoration for card widgets.
/// Creates frosted glass aesthetic with gradient, border, and layered shadows.
BoxDecoration getModernCardDecoration(BuildContext context) {
  return BoxDecoration(
    // Gradient: creates depth with semi-transparent white overlay
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.9), // Top-left: most opaque
        Colors.white.withValues(alpha: 0.7), // Middle: slightly transparent
        Colors.white
            .withValues(alpha: 0.85), // Bottom-right: between top and middle
      ],
      stops: [0.0, 0.5, 1.0], // Distribution of gradient stops
    ),
    borderRadius: BorderRadius.circular(24), // Rounded corners for modern look
    // Border: white edge defines glass boundary
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.7),
      width: 2.5,
    ),
    // Multiple shadows: creates layered depth effect
    boxShadow: [
      // Primary shadow: main depth effect
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 40,
        offset: const Offset(0, 20),
      ),
      // Secondary shadow: additional depth
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      // Tertiary shadow: subtle depth
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
      // Highlight shadow: creates light reflection for glass effect
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.6),
        blurRadius: 8,
        offset: const Offset(-2, -2), // Top-left light source
      ),
    ],
  );
}

/// Modern button decoration with gradient and shadow effects.
/// Creates a polished button appearance with blue-to-white gradient.
BoxDecoration getModernButtonDecoration() {
  return BoxDecoration(
    // Gradient: blue to white for modern look
    gradient: LinearGradient(
      colors: [softBlue, mintGreen],
    ),
    borderRadius: BorderRadius.circular(14),
    // Shadows: multiple layers create depth and elevation
    boxShadow: [
      // Primary shadow: main elevation effect
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 8),
      ),
      // Secondary shadow: additional depth
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      // Color shadow: adds blue tint for cohesion
      BoxShadow(
        color: softBlue.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ==================== LIGHT THEME DEFINITION ====================
/// Main light theme for the application following Material Design 3 principles.
/// Defines colors, typography, component styles, and overall light mode appearance.
final ThemeData appTheme = ThemeData(
  useMaterial3: true, // Enable Material Design 3 components
  fontFamily: 'Roboto', // Use Roboto as standard font
  brightness: Brightness.light, // Set to light mode
  scaffoldBackgroundColor: mutedNeutralLight, // Background for scaffolds
  colorScheme: const ColorScheme.light(
    primary: deepAqua, // Primary action color
    secondary: softBlue, // Secondary accent color
    surface: mutedNeutralLight, // Surface color for cards/containers
    onSurface: mutedNeutralDark, // Text color on surfaces
    error: Colors.redAccent, // Error color for validation
  ),
  // AppBar styling: transparent background for modern look
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0, // No shadow
    iconTheme: IconThemeData(color: mutedNeutralDark),
    titleTextStyle: TextStyle(
        color: mutedNeutralDark, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  // Card styling: rounded corners and elevation
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    color: lightModeCardColor,
  ),
  // Text theme: consistent typography throughout app
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: mutedNeutralDark),
    bodyMedium: TextStyle(color: mutedNeutralMid),
    titleLarge: TextStyle(color: mutedNeutralDark, fontWeight: FontWeight.bold),
    headlineSmall:
        TextStyle(color: mutedNeutralDark, fontWeight: FontWeight.bold),
  ),
  // Elevated button styling: primary action button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: deepAqua,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      elevation: 3,
    ),
  ),
  // Outlined button styling: secondary action button
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: mutedNeutralMid,
      side: const BorderSide(color: mutedNeutralMid, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  // Input field styling: text input and form fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: mutedNeutralLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(
          color: deepAqua, width: 2), // Blue highlight when focused
    ),
  ),
);

// ==================== DARK THEME DEFINITION ====================
/// Enhanced dark theme for the application following Material Design 3 principles.
/// Defines colors, typography, component styles optimized for dark mode visibility.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true, // Enable Material Design 3 components
  fontFamily: 'Roboto', // Use Roboto as standard font
  brightness: Brightness.dark, // Set to dark mode
  scaffoldBackgroundColor:
      const Color(0xFF121212), // Material Design standard dark background
  colorScheme: const ColorScheme.dark(
    primary: softBlue, // Primary action color - lighter in dark mode
    secondary: mintGreen, // Secondary accent color
    surface: Color(0xFF1E1E1E), // Color for card backgrounds
    onSurface: Color(0xFFEAEAEA), // Text color on surfaces - light gray
    error: Colors.redAccent, // Error color for validation
  ),
  // AppBar styling: transparent background for modern look
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0, // No shadow
    iconTheme: IconThemeData(color: Color(0xFFEAEAEA)),
    titleTextStyle: TextStyle(
        color: Color(0xFFEAEAEA), fontSize: 20, fontWeight: FontWeight.bold),
  ),
  // Card styling: dark background with elevation
  cardTheme: CardThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    color: darkModeCardColor, // Ensures all cards use dark color
  ),
  // Text theme: light colors optimized for dark backgrounds
  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: Color(0xFFEAEAEA)),
    bodyMedium: TextStyle(
        color: const Color(0xFFEAEAEA)
            .withValues(alpha: 0.8)), // Subtler color for secondary text
    titleLarge:
        const TextStyle(color: Color(0xFFEAEAEA), fontWeight: FontWeight.bold),
    headlineSmall:
        const TextStyle(color: Color(0xFFEAEAEA), fontWeight: FontWeight.bold),
  ),
  // ListTile theme for better contrast on dark cards
  listTileTheme: ListTileThemeData(
    iconColor: mintGreen, // Light color for icons
    textColor:
        const Color(0xFFEAEAEA).withValues(alpha: 0.9), // High contrast text
  ),
  // Elevated button styling: primary action button in dark mode
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
  // Outlined button styling: secondary action button in dark mode
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: mutedNeutralMid, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  // Input field styling: dark background for text inputs
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2A2A2A), // Slightly lighter than background
    hintStyle: TextStyle(color: Colors.grey.shade600), // Hint text in gray
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(
          color: softBlue, width: 2), // Blue highlight when focused
    ),
  ),
);
