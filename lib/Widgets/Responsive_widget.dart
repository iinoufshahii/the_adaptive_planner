import 'package:flutter/material.dart';

/// Utility class providing responsive design utilities for different device types.
/// Implements breakpoint-based scaling for fonts, spacing, and layout elements.
class ResponsiveUtils {
  // ==================== DEVICE BREAKPOINTS ====================
  /// Maximum width threshold for mobile devices (600 pixels)
  static const double mobileMaxWidth = 600;

  /// Maximum width threshold for tablet devices (1200 pixels)
  static const double tabletMaxWidth = 1200;

  // ==================== DEVICE TYPE DETECTION ====================
  /// Determines if current screen is mobile device (width < 600px).
  /// Used to apply mobile-specific styling and layouts.
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Determines if current screen is tablet device (600px ≤ width < 1200px).
  /// Used to apply tablet-optimized styling and layouts.
  static bool isTablet(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  /// Determines if current screen is web/desktop device (width ≥ 1200px).
  /// Used to apply web-optimized styling and layouts.
  static bool isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Get responsive maximum content width for centered layouts.
  /// Scales based on device: 1400 on web, infinite on tablet, infinite on mobile.
  static double getMaxContentWidth(BuildContext context) {
    if (isWeb(context)) return 1400.0; // Web: standard max width
    if (isTablet(context)) return double.infinity; // Tablet: use full width
    return double.infinity; // Mobile: use full width
  }

  /// Get responsive spacing scale factor for adapting all spacing values.
  /// Mobile: 1.0 (base), Tablet: 1.2x, Web: 1.5x
  static double getSpacingScale(BuildContext context) {
    if (isMobile(context)) return 1.0; // Mobile: no scaling
    if (isTablet(context)) return 1.2; // Tablet: 20% larger
    return 1.5; // Web: 50% larger
  }

  // ==================== CARD DIMENSIONS ====================
  /// Get responsive card maximum width based on device type.
  /// Mobile: 90% of screen, Tablet: 500px, Web: 600px
  static double getCardMaxWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth * 0.9; // Mobile: 90% of screen
    if (isTablet(context)) return 500.0; // Tablet: fixed 500px
    return 600.0; // Web: fixed 600px
  }

  // ==================== PADDING & MARGINS ====================
  /// Get responsive outer padding for page content.
  /// Mobile: 24px, Tablet: 32px, Web: 48px
  static double getOuterPadding(BuildContext context) {
    if (isMobile(context)) return 24.0; // Mobile: base padding
    if (isTablet(context)) return 32.0; // Tablet: larger padding
    return 48.0; // Web: large padding
  }

  /// Get responsive default padding for components and spacing.
  /// Mobile: 20px, Tablet: 24px, Web: 32px
  static double getDefaultPadding(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Get responsive padding for card contents.
  /// Mobile: 16px, Tablet: 20px, Web: 24px
  static double getCardPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    return 24.0;
  }

  /// Get responsive vertical spacing between major sections.
  /// Mobile: 24px, Tablet: 32px, Web: 40px
  static double getSectionSpacing(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 32.0;
    return 40.0;
  }

  /// Get responsive horizontal spacing between columns.
  /// Mobile: 12px, Tablet: 16px, Web: 20px
  static double getColumnSpacing(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  // ==================== BUTTON DIMENSIONS ====================
  /// Get responsive button height for consistent touch targets.
  /// Mobile: 50px, Tablet: 55px, Web: 60px
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) return 50.0;
    if (isTablet(context)) return 55.0;
    return 60.0;
  }

  /// Get responsive button maximum width to prevent excessive stretching.
  /// Mobile: 90% of screen, Tablet: 400px, Web: 500px
  static double getButtonMaxWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width * 0.9;
    if (isTablet(context)) return 400.0;
    return 500.0;
  }

  /// Get responsive vertical padding inside buttons.
  /// Mobile: 14px, Tablet: 16px, Web: 18px
  static double getButtonVerticalPadding(BuildContext context) {
    if (isMobile(context)) return 14.0;
    if (isTablet(context)) return 16.0;
    return 18.0;
  }

  // ==================== TYPOGRAPHY ====================
  /// Get responsive greeting/headline font size.
  /// Mobile: 24px, Tablet: 28px, Web: 32px
  static double getGreetingFontSize(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    return 32.0;
  }

  /// Get responsive title font size for section headers.
  /// Mobile: 20px, Tablet: 22px, Web: 24px
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 22.0;
    return 24.0;
  }

  /// Get responsive body text font size.
  /// Mobile: 16px, Tablet: 18px, Web: 20px
  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 18.0;
    return 20.0;
  }

  /// Get responsive small/caption font size.
  /// Mobile: 13px, Tablet: 14px, Web: 15px
  static double getSmallFontSize(BuildContext context) {
    if (isMobile(context)) return 13.0;
    if (isTablet(context)) return 14.0;
    return 15.0;
  }

  /// Get responsive subtitle font size.
  /// Mobile: 14px, Tablet: 16px, Web: 18px
  static double getSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) return 14.0;
    if (isTablet(context)) return 16.0;
    return 18.0;
  }

  /// Get responsive button text font size.
  /// Mobile: 16px, Tablet: 18px, Web: 20px
  static double getButtonFontSize(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 18.0;
    return 20.0;
  }

  /// Get responsive tab label font size.
  /// Mobile: 15px, Tablet: 16px, Web: 18px
  static double getTabFontSize(BuildContext context) {
    if (isMobile(context)) return 15.0;
    if (isTablet(context)) return 16.0;
    return 18.0;
  }

  /// Get responsive chip/tag font size.
  /// Mobile: 10px, Tablet: 11px, Web: 12px
  static double getChipFontSize(BuildContext context) {
    if (isMobile(context)) return 10.0;
    if (isTablet(context)) return 11.0;
    return 12.0;
  }

  // ==================== ICON SIZES ====================
  /// Get responsive standard icon size for UI elements.
  /// Mobile: 30px, Tablet: 35px, Web: 40px
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) return 30.0;
    if (isTablet(context)) return 35.0;
    return 40.0;
  }

  /// Get responsive large icon size for prominent visual elements.
  /// Mobile: 64px, Tablet: 80px, Web: 96px
  static double getLargeIconSize(BuildContext context) {
    if (isMobile(context)) return 64.0;
    if (isTablet(context)) return 80.0;
    return 96.0;
  }

  // ==================== GRID & LIST ====================
  /// Get responsive grid cross axis count for 2-4 column layouts.
  /// Mobile: 2 columns, Tablet: 3 columns, Web: 4 columns
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// Get responsive grid cross axis count for 1-3 column layouts.
  /// Mobile: 1 column, Tablet: 2 columns, Web: 3 columns
  static int getGridCrossAxisCount3(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Get responsive list item height for consistency.
  /// Mobile: 70px, Tablet: 80px, Web: 90px
  static double getListItemHeight(BuildContext context) {
    if (isMobile(context)) return 70.0;
    if (isTablet(context)) return 80.0;
    return 90.0;
  }

  // ==================== FORM DIMENSIONS ====================
  /// Get responsive form height for login/signup screens.
  /// Mobile: 450px, Tablet: 500px, Web: 550px
  static double getFormHeight(BuildContext context) {
    if (isMobile(context)) return 450.0;
    if (isTablet(context)) return 500.0;
    return 550.0;
  }

  /// Get responsive horizontal padding inside forms.
  /// Mobile: 20px, Tablet: 24px, Web: 28px
  static double getFormHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 24.0;
    return 28.0;
  }

  /// Get responsive vertical padding inside forms (consistent across devices).
  static double getFormVerticalPadding(BuildContext context) {
    return 16.0; // Same for all devices
  }

  /// Get responsive form padding as EdgeInsets for convenient use.
  static EdgeInsets getFormPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getFormHorizontalPadding(context),
      vertical: getFormVerticalPadding(context),
    );
  }

  // ==================== NAVIGATION & UI ====================
  /// Get responsive tab margin for horizontal spacing.
  /// Mobile: 16px, Tablet: 20px, Web: 24px
  static double getTabMargin(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    return 24.0;
  }

  /// Get responsive FAB bottom padding to account for nav bar height.
  /// Mobile: 80px, Tablet: 100px, Web: 120px
  static double getFabBottomPadding(BuildContext context) {
    if (isMobile(context)) return 80.0;
    if (isTablet(context)) return 100.0;
    return 120.0;
  }

  // ==================== BORDERS & STYLING ====================
  /// Get responsive card border radius for consistent rounding.
  /// Mobile: 16px, Tablet: 18px, Web: 20px
  static double getCardBorderRadius(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 18.0;
    return 20.0;
  }

  /// Get responsive divider height for visual separation.
  /// Mobile: 1.0px, Tablet: 1.2px, Web: 1.5px
  static double getDividerHeight(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.2;
    return 1.5;
  }

  // ==================== TEXT STYLES ====================
  /// Get responsive button text style with appropriate font size and letter spacing.
  static TextStyle getButtonTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: getButtonFontSize(context),
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 0.3,
    );
  }

  /// Get responsive tab label text style for tab bars.
  static TextStyle getTabLabelStyle(BuildContext context) {
    return TextStyle(
      fontSize: getTabFontSize(context),
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
    );
  }
}
