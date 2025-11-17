/// Reusable card widgets for consistent UI design across the app.
/// Contains modular, theme-aware card components for journal entries, tasks, and other content.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Responsive_widget.dart';

// ==================== MOOD COLOR HELPERS ====================
/// Returns color for mood type (positive=green, negative=red, neutral=blue)
Color getMoodColor(String? mood) {
  switch (mood?.toLowerCase()) {
    case 'positive':
      return Colors.green;
    case 'negative':
      return Colors.red;
    case 'neutral':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

/// Returns gradient for mood type with appropriate color scheme
LinearGradient getMoodGradient(String? mood) {
  switch (mood?.toLowerCase()) {
    case 'positive':
      return LinearGradient(
        colors: [Colors.green.shade400, Colors.green.shade600],
      );
    case 'negative':
      return LinearGradient(
        colors: [Colors.red.shade400, Colors.red.shade600],
      );
    case 'neutral':
      return LinearGradient(
        colors: [Colors.blue.shade400, Colors.blue.shade600],
      );
    default:
      return LinearGradient(
        colors: [Colors.grey.shade400, Colors.grey.shade600],
      );
  }
}

// ==================== CARD CONTAINER ====================
/// Reusable glass-effect card container with theme-aware colors
/// Handles background, borders, and shadows for dark/light modes
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;
  final double? borderWidth;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? ResponsiveUtils.getCardBorderRadius(context);
    final bw = borderWidth ?? 1.5;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(br),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade900.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(br),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.2),
              width: bw,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ==================== HEADER CARD ====================
/// Header card displaying date and mood information
/// Used in journal entries and detail views
class HeaderCard extends StatelessWidget {
  final DateTime date;
  final String? mood;
  final bool showTime;

  const HeaderCard({
    super.key,
    required this.date,
    this.mood,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(
              ResponsiveUtils.getDefaultPadding(context).toDouble()),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade800.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(
                ResponsiveUtils.getCardBorderRadius(context).toDouble()),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(date),
                style: TextStyle(
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (showTime) ...[
                SizedBox(
                    height: ResponsiveUtils.getColumnSpacing(context) * 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time
                    Text(
                      DateFormat('h:mm a').format(date),
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getBodyFontSize(context) * 0.9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Mood Badge
                    if (mood != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getDefaultPadding(context) * 0.7,
                          vertical:
                              ResponsiveUtils.getColumnSpacing(context) * 0.4,
                        ),
                        decoration: BoxDecoration(
                          gradient: getMoodGradient(mood),
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getCardBorderRadius(context) *
                                  0.75),
                          boxShadow: [
                            BoxShadow(
                              color: getMoodColor(mood).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          mood!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize:
                                ResponsiveUtils.getBodyFontSize(context) * 0.85,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TEXT CONTENT CARD ====================
/// Card for displaying text content (journal entries, task descriptions)
/// Theme-aware with proper visibility in dark mode
class TextContentCard extends StatelessWidget {
  final String text;
  final String? title;
  final double? maxWidth;

  const TextContentCard({
    super.key,
    required this.text,
    this.title,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontSize: ResponsiveUtils.getTitleFontSize(context) * 0.7,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getColumnSpacing(context) * 0.75),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getCardBorderRadius(context).toDouble()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.all(
                  ResponsiveUtils.getDefaultPadding(context).toDouble()),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800.withValues(alpha: 0.8)
                    : Colors.grey.shade50.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getCardBorderRadius(context).toDouble()),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.shade700.withValues(alpha: 0.5)
                      : Colors.grey.shade200.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getBodyFontSize(context) * 0.95,
                  height: 1.8,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== SENTIMENT ANALYSIS CARD ====================
/// Card for displaying AI insights/suggestions
/// Gradient background with icon and text content
class SentimentCard extends StatelessWidget {
  final String text;
  final String? title;
  final Color gradientColor;
  final IconData? icon;

  const SentimentCard({
    super.key,
    required this.text,
    this.title,
    this.gradientColor = Colors.blue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadeColor = gradientColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontSize: ResponsiveUtils.getTitleFontSize(context) * 0.7,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getColumnSpacing(context) * 0.75),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getCardBorderRadius(context).toDouble()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.all(
                  ResponsiveUtils.getDefaultPadding(context).toDouble()),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          shadeColor.withValues(alpha: 0.15),
                          shadeColor.withValues(alpha: 0.08),
                        ]
                      : [
                          shadeColor.withValues(alpha: 0.1),
                          shadeColor.withValues(alpha: 0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getCardBorderRadius(context).toDouble()),
                border: Border.all(
                  color: shadeColor.withValues(alpha: isDark ? 0.4 : 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadeColor.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Row(
                      children: [
                        Container(
                          width: ResponsiveUtils.getIconSize(context) * 1.25,
                          height: ResponsiveUtils.getIconSize(context) * 1.25,
                          decoration: BoxDecoration(
                            color: shadeColor,
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getCardBorderRadius(context) *
                                    0.65),
                            boxShadow: [
                              BoxShadow(
                                color: shadeColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: ResponsiveUtils.getIconSize(context) * 0.7,
                          ),
                        ),
                        SizedBox(
                            width: ResponsiveUtils.getColumnSpacing(context) *
                                0.5),
                      ],
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getColumnSpacing(context) * 0.5),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context) * 0.9,
                      height: 1.7,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== ACTION ITEM CARD ====================
/// Card for displaying actionable steps or task items
/// Shows numbered item with text and theme-aware styling
class ActionItemCard extends StatelessWidget {
  final int index;
  final String text;
  final Color accentColor;

  const ActionItemCard({
    super.key,
    required this.index,
    required this.text,
    this.accentColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
          ResponsiveUtils.getCardBorderRadius(context).toDouble()),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.all(
              ResponsiveUtils.getDefaultPadding(context).toDouble()),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      accentColor.withValues(alpha: 0.15),
                      accentColor.withValues(alpha: 0.08),
                    ]
                  : [
                      accentColor.withValues(alpha: 0.08),
                      accentColor.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(
                ResponsiveUtils.getCardBorderRadius(context).toDouble()),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number Badge
              Container(
                width: ResponsiveUtils.getIconSize(context) * 1.1,
                height: ResponsiveUtils.getIconSize(context) * 1.1,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getCardBorderRadius(context) * 0.65),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getBodyFontSize(context) * 0.8,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getColumnSpacing(context) * 0.5),
              // Text Content
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context) * 0.95,
                    height: 1.6,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MOOD BADGE ====================
/// Standalone mood badge for displaying sentiment
class MoodBadge extends StatelessWidget {
  final String mood;
  final double? fontSize;

  const MoodBadge({
    super.key,
    required this.mood,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getDefaultPadding(context) * 0.5,
        vertical: ResponsiveUtils.getColumnSpacing(context) * 0.25,
      ),
      decoration: BoxDecoration(
        gradient: getMoodGradient(mood),
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getCardBorderRadius(context) * 0.8),
        boxShadow: [
          BoxShadow(
            color: getMoodColor(mood).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        mood,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize ?? ResponsiveUtils.getSmallFontSize(context),
        ),
      ),
    );
  }
}

// ==================== JOURNAL CARD ====================
/// Complete reusable journal entry card with modern glass effect.
/// Displays date, time, mood, and expandable AI suggestions.
/// Fully responsive and theme-aware for dark/light modes.
class JournalCard extends StatelessWidget {
  final DateTime date;
  final String? mood;
  final String? aiFeedback;
  final List<String>? actionableSteps;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const JournalCard({
    super.key,
    required this.date,
    this.mood,
    this.aiFeedback,
    this.actionableSteps,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPadding = ResponsiveUtils.getDefaultPadding(context);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getCardBorderRadius(context).toDouble()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: EdgeInsets.only(
                bottom: ResponsiveUtils.getColumnSpacing(context) * 0.75),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getCardBorderRadius(context).toDouble()),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date and mood
                Padding(
                  padding: EdgeInsets.all(defaultPadding * 0.6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(date),
                              style: TextStyle(
                                fontSize:
                                    ResponsiveUtils.getBodyFontSize(context) *
                                        0.9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(
                                height:
                                    ResponsiveUtils.getColumnSpacing(context) *
                                        0.2),
                            Text(
                              DateFormat('h:mm a').format(date),
                              style: TextStyle(
                                fontSize:
                                    ResponsiveUtils.getSmallFontSize(context) *
                                        0.85,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mood != null)
                        MoodBadge(
                            mood: mood!,
                            fontSize: ResponsiveUtils.getSmallFontSize(context))
                      else
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.grey.shade400),
                          ),
                        ),
                    ],
                  ),
                ),
                // AI Suggestions expansion section
                if (aiFeedback != null ||
                    (actionableSteps?.isNotEmpty ?? false))
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        'AI Suggestions',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getSmallFontSize(context),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      tilePadding: EdgeInsets.symmetric(
                          horizontal: defaultPadding * 0.6),
                      collapsedIconColor:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      iconColor:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            defaultPadding * 0.6,
                            0,
                            defaultPadding * 0.6,
                            defaultPadding * 0.6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (aiFeedback != null &&
                                  aiFeedback!.isNotEmpty) ...[
                                Text(
                                  'Suggestion',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: ResponsiveUtils.getSmallFontSize(
                                        context),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(
                                    height: ResponsiveUtils.getColumnSpacing(
                                            context) *
                                        0.5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.blue
                                                .withValues(alpha: 0.15)
                                            : Colors.blue
                                                .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.withValues(
                                              alpha: isDark ? 0.35 : 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        aiFeedback!,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.grey.shade800,
                                          fontSize:
                                              ResponsiveUtils.getSmallFontSize(
                                                  context),
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: ResponsiveUtils.getColumnSpacing(
                                            context) *
                                        0.75),
                              ],
                              if (actionableSteps != null &&
                                  actionableSteps!.isNotEmpty) ...[
                                Text(
                                  'Actionable Steps',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: ResponsiveUtils.getSmallFontSize(
                                        context),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(
                                    height: ResponsiveUtils.getColumnSpacing(
                                            context) *
                                        0.5),
                                ...actionableSteps!.asMap().entries.map((e) {
                                  int idx = e.key;
                                  String step = e.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom:
                                            ResponsiveUtils.getColumnSpacing(
                                                    context) *
                                                0.5),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.green.shade400,
                                                Colors.green.shade600,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.green.shade400
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${idx + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            width: ResponsiveUtils
                                                    .getColumnSpacing(context) *
                                                0.75),
                                        Expanded(
                                          child: Text(
                                            step,
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils
                                                  .getSmallFontSize(context),
                                              color: isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.8)
                                                  : Colors.grey.shade800,
                                              height: 1.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TASK CARD ====================
/// Modern reusable task card with glass effect and emotion-style status badges.
/// Displays task with checkbox, title, deadline, and emotion-like priority/energy/category indicators.
/// Includes expandable subtasks section with individual checkboxes.
/// Fully responsive and theme-aware for dark/light modes.
class TaskCard extends StatefulWidget {
  final String title;
  final DateTime deadline;
  final String priority; // 'high', 'medium', 'low'
  final String energy; // 'high', 'medium', 'low' or similar
  final String category;
  final bool isCompleted;
  final List<Map<String, dynamic>>?
      subtasks; // List of subtasks with id, title, isCompleted
  final Function(bool? value)? onCheckChange;
  final Function(String subtaskId, bool isCompleted)? onSubtaskCheckChange;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const TaskCard({
    super.key,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.energy,
    required this.category,
    required this.isCompleted,
    this.subtasks,
    this.onCheckChange,
    this.onSubtaskCheckChange,
    this.onTap,
    this.padding,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expandSubtasks = false;

  /// Convert task priority to emotion-like badge display
  String _priorityToEmotion(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Neutral';
    }
  }

  /// Convert energy level to emotion-like badge display
  String _energyToEmotion(String energy) {
    switch (energy.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'neutral';
    }
  }

  /// Get gradient color based on priority (emotion style)
  LinearGradient _getStatusGradient(String emotion) {
    switch (emotion) {
      case 'High':
        return LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        );
      case 'Medium':
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        );
      case 'Low':
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        );
      default:
        return LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPadding = ResponsiveUtils.getDefaultPadding(context);
    final smallFontSize = ResponsiveUtils.getSmallFontSize(context);
    final priorityEmotion = _priorityToEmotion(widget.priority);
    final energyEmotion = _energyToEmotion(widget.energy);

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getCardBorderRadius(context).toDouble()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: EdgeInsets.only(
                bottom: ResponsiveUtils.getColumnSpacing(context) * 0.5),
            decoration: BoxDecoration(
              color: widget.isCompleted
                  ? (isDark
                      ? Colors.grey.shade900.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.4))
                  : (isDark
                      ? Colors.grey.shade900.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9)),
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getCardBorderRadius(context).toDouble()),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: widget.padding ??
                  EdgeInsets.symmetric(
                    horizontal: defaultPadding,
                    vertical: ResponsiveUtils.getCardPadding(context) * 0.5,
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with checkbox and title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Checkbox(
                          value: widget.isCompleted,
                          onChanged: widget.onCheckChange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                            color: widget.isCompleted
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6)
                                : Theme.of(context).colorScheme.onSurface,
                            decoration: widget.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getColumnSpacing(context) * 0.4),
                  // Deadline
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: smallFontSize * 1.2,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('MMM dd, hh:mm a').format(widget.deadline),
                          style: TextStyle(
                              fontSize: smallFontSize * 0.85,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getColumnSpacing(context) * 0.6),
                  // Emotion-style status badges
                  Wrap(
                    spacing: ResponsiveUtils.getColumnSpacing(context) * 0.5,
                    runSpacing: ResponsiveUtils.getColumnSpacing(context) * 0.3,
                    children: [
                      // Priority badge (emotion style)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getColumnSpacing(context) * 0.6,
                          vertical:
                              ResponsiveUtils.getColumnSpacing(context) * 0.25,
                        ),
                        decoration: BoxDecoration(
                          gradient: _getStatusGradient(priorityEmotion),
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getCardBorderRadius(context) *
                                  0.8),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusGradient(priorityEmotion)
                                  .colors
                                  .first
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          priorityEmotion,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: smallFontSize,
                          ),
                        ),
                      ),
                      // Energy badge (emotion style)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getColumnSpacing(context) * 0.6,
                          vertical:
                              ResponsiveUtils.getColumnSpacing(context) * 0.25,
                        ),
                        decoration: BoxDecoration(
                          gradient: _getStatusGradient(energyEmotion),
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getCardBorderRadius(context) *
                                  0.8),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusGradient(energyEmotion)
                                  .colors
                                  .first
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          energyEmotion,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: smallFontSize,
                          ),
                        ),
                      ),
                      // Category badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getColumnSpacing(context) * 0.6,
                          vertical:
                              ResponsiveUtils.getColumnSpacing(context) * 0.25,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getCardBorderRadius(context) *
                                  0.8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.category.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: smallFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Subtasks section if available
                  if (widget.subtasks != null &&
                      widget.subtasks!.isNotEmpty) ...[
                    SizedBox(
                        height:
                            ResponsiveUtils.getColumnSpacing(context) * 0.6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _expandSubtasks = !_expandSubtasks),
                      child: Row(
                        children: [
                          Icon(
                            _expandSubtasks
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: smallFontSize * 1.2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(
                              width: ResponsiveUtils.getColumnSpacing(context) *
                                  0.3),
                          Expanded(
                            child: Text(
                              widget.subtasks!.every((s) =>
                                      (s['isCompleted'] as bool? ?? false))
                                  ? '✓ All Done'
                                  : 'Subtasks (${widget.subtasks!.where((s) => !(s['isCompleted'] as bool? ?? false)).length}/${widget.subtasks!.length})',
                              style: TextStyle(
                                fontSize: smallFontSize * 0.9,
                                fontWeight: FontWeight.w600,
                                color: widget.subtasks!.every((s) =>
                                        (s['isCompleted'] as bool? ?? false))
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_expandSubtasks) ...[
                      SizedBox(
                          height:
                              ResponsiveUtils.getColumnSpacing(context) * 0.4),
                      ...widget.subtasks!.map((subtask) {
                        final subtaskId = subtask['id'] as String;
                        final subtaskTitle = subtask['title'] as String;
                        final isSubtaskCompleted =
                            subtask['isCompleted'] as bool? ?? false;

                        return Padding(
                          padding: EdgeInsets.only(
                            left:
                                ResponsiveUtils.getColumnSpacing(context) * 0.8,
                            bottom:
                                ResponsiveUtils.getColumnSpacing(context) * 0.3,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: isSubtaskCompleted,
                                  onChanged: (value) {
                                    if (widget.onSubtaskCheckChange != null) {
                                      widget.onSubtaskCheckChange!(
                                          subtaskId, value ?? false);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  activeColor:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              SizedBox(
                                  width: ResponsiveUtils.getColumnSpacing(
                                          context) *
                                      0.5),
                              Expanded(
                                child: Text(
                                  subtaskTitle,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getSmallFontSize(
                                        context),
                                    color: isSubtaskCompleted
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    decoration: isSubtaskCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
