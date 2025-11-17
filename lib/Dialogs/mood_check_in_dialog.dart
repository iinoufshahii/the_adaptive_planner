import 'dart:ui';

import 'package:adaptive_planner/Widgets/Responsive_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Service/mood_service.dart';

/// Stateful widget for mood and energy level check-in dialog.
/// Allows users to log their current mood and energy state in a beautiful glassmorphic dialog.
class MoodCheckInDialog extends StatefulWidget {
  /// Optional callback triggered when user dismisses dialog without logging mood
  final VoidCallback? onDismissed;

  /// Optional callback triggered when mood is successfully logged
  final VoidCallback? onCompleted;

  const MoodCheckInDialog({
    super.key,
    this.onDismissed,
    this.onCompleted,
  });

  @override
  State<MoodCheckInDialog> createState() => _MoodCheckInDialogState();
}

/// State for MoodCheckInDialog managing mood and energy selection, submission.
class _MoodCheckInDialogState extends State<MoodCheckInDialog> {
  /// Flag to prevent multiple submissions while request is in flight
  bool _isSubmitting = false;

  /// Currently selected mood ('Happy', 'Neutral', 'Sad', etc.) or null if not selected
  String? _selectedMood;

  /// Currently selected energy level ('High', 'Medium', 'Low') or null if not selected
  String? _selectedEnergyLevel;

  /// Static list of mood options with emoji, label, and color for UI display
  static const List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😊', 'mood': 'Happy', 'color': Colors.green},
    {'emoji': '😐', 'mood': 'Neutral', 'color': Colors.blue},
    {'emoji': '😔', 'mood': 'Sad', 'color': Colors.indigo},
    {'emoji': '😠', 'mood': 'Angry', 'color': Colors.red},
    {'emoji': '😩', 'mood': 'Stressed', 'color': Colors.orange},
    {'emoji': '🧘', 'mood': 'Calm', 'color': Colors.teal},
  ];

  /// Static list of energy level options with emoji, label, and color for UI display
  static const List<Map<String, dynamic>> _energyOptions = [
    {'emoji': '⚡', 'level': 'High', 'color': Colors.orange},
    {'emoji': '🔋', 'level': 'Medium', 'color': Colors.blue},
    {'emoji': '🪫', 'level': 'Low', 'color': Colors.grey},
  ];

  /// Method: Updates selected mood and rebuilds UI via setState.
  /// [mood] parameter: mood name to select ('Happy', 'Neutral', etc.)
  void _selectMood(String mood) {
    setState(() => _selectedMood = mood); // Update state and trigger rebuild
  }

  /// Method: Updates selected energy level and rebuilds UI via setState.
  /// [energyLevel] parameter: energy level name to select ('High', 'Medium', 'Low')
  void _selectEnergyLevel(String energyLevel) {
    setState(() =>
        _selectedEnergyLevel = energyLevel); // Update state and trigger rebuild
  }

  /// Async method: Submits mood check-in to Firestore via MoodService.
  /// Validates selections, prevents double-submission, shows success/error feedback.
  Future<void> _submitMoodCheckIn() async {
    // Guard: if already submitting, prevent multiple concurrent requests
    if (_isSubmitting) return;

    // Extract current selections
    final mood = _selectedMood;
    final energy = _selectedEnergyLevel;

    // Validation: ensure both mood and energy are selected before submission
    if (mood == null || energy == null) return;

    // Set submitting flag to prevent multiple submissions
    setState(() => _isSubmitting = true);

    // Get current authenticated user
    final user = FirebaseAuth.instance.currentUser;

    // Conditional: verify user is authenticated before saving
    if (user != null && mounted) {
      try {
        // Call MoodService to add mood check-in to Firestore
        await context.read<MoodService>().addMood(
              mood.toLowerCase(), // Convert to lowercase for storage consistency
              energy
                  .toLowerCase(), // Convert to lowercase for storage consistency
            );

        // Check if widget still mounted before updating state (prevents memory leaks)
        if (mounted) {
          Navigator.of(context).pop(); // Close the dialog
          widget.onCompleted?.call(); // Trigger completion callback if provided

          // Show success SnackBar message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mood logged: $mood ($energy energy)'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Error handling: reset submitting flag and show error message
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to log mood: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Method: Closes dialog and triggers dismissal callback.
  void _dismiss() {
    Navigator.of(context).pop();
    widget.onDismissed?.call(); // Trigger dismissal callback if provided
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    // Responsive dimensions
    final dialogPadding = isMobile
        ? 20.0
        : isTablet
            ? 24.0
            : 28.0;
    final headerFontSize = isMobile
        ? 20.0
        : isTablet
            ? 22.0
            : 24.0;
    final subtitleFontSize = isMobile
        ? 13.0
        : isTablet
            ? 14.0
            : 15.0;
    final sectionTitleFontSize = isMobile
        ? 15.0
        : isTablet
            ? 16.0
            : 18.0;
    final gridSpacing = isMobile ? 10.0 : 12.0;
    final gridChildAspectRatio = isMobile ? 0.95 : 1.0;
    final moodGridCrossAxisCount = isMobile
        ? 3
        : isTablet
            ? 4
            : 6;
    final maxDialogWidth = isMobile
        ? 320.0
        : isTablet
            ? 500.0
            : 600.0;
    final buttonHeight = isMobile
        ? 48.0
        : isTablet
            ? 52.0
            : 56.0;
    final buttonFontSize = isMobile
        ? 15.0
        : isTablet
            ? 16.0
            : 18.0;

    // Dialog with glassmorphic design using BackdropFilter and gradient
    return Dialog(
      backgroundColor:
          Colors.transparent, // Transparent background for custom styling
      elevation: 0, // No default shadow (custom shadows in decoration)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        // BackdropFilter: creates frosted glass blur effect behind dialog
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(maxWidth: maxDialogWidth),
            decoration: BoxDecoration(
              // Gradient: creates depth with semi-transparent blue overlay
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.brightness == Brightness.dark
                    ? [
                        const Color.fromARGB(255, 45, 85, 120)
                            .withValues(alpha: 0.95),
                        const Color.fromARGB(255, 35, 65, 100)
                            .withValues(alpha: 0.85),
                        const Color.fromARGB(255, 40, 75, 115)
                            .withValues(alpha: 0.75),
                      ]
                    : [
                        const Color.fromARGB(255, 224, 247, 255)
                            .withValues(alpha: 0.95),
                        const Color.fromARGB(255, 180, 235, 255)
                            .withValues(alpha: 0.85),
                        const Color.fromARGB(255, 255, 255, 255)
                            .withValues(alpha: 0.75),
                      ],
                stops: const [0.0, 0.5, 1.0], // Gradient distribution
              ),
              borderRadius: BorderRadius.circular(28),
              // Border: subtle white edge defines glass boundary
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.9),
                width: 2,
              ),
              // Multiple layered shadows: creates 3D depth effect
              boxShadow: [
                // Deep shadow for main depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 3,
                ),
                // Medium shadow for additional depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                // Subtle inner shadow for depth
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? const Color.fromARGB(255, 100, 180, 220)
                          .withValues(alpha: 0.2)
                      : const Color.fromARGB(255, 68, 205, 255)
                          .withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                  spreadRadius: -2,
                ),
                // Highlight shadow for glass effect
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? const Color.fromARGB(255, 70, 160, 200)
                          .withValues(alpha: 0.15)
                      : const Color.fromARGB(255, 90, 194, 255)
                          .withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(-4, -4),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(dialogPadding),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Column only takes needed space
                children: [
                  // ==================== HEADER SECTION ====================
                  // Header with title and dismiss button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Expanded title text
                      Expanded(
                        child: Text(
                          'How are you feeling?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontSize: headerFontSize,
                          ),
                        ),
                      ),
                      // Dismiss/close button
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : _dismiss, // Disable while submitting
                        icon: Icon(Icons.close,
                            color: theme.colorScheme.onSurface),
                        style: IconButton.styleFrom(
                          backgroundColor: theme
                              .colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.8),
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Subtitle/description text
                  Text(
                    'Track your daily mood to help personalize your experience',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.8),
                      fontSize: subtitleFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ==================== MOOD SELECTION SECTION ====================
                  // Label for mood selection
                  Text(
                    'Select your mood',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontSize: sectionTitleFontSize,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid of mood options (3 columns)
                  GridView.builder(
                    shrinkWrap: true, // Only use needed space
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable scrolling
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          moodGridCrossAxisCount, // Responsive columns
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: gridSpacing,
                      childAspectRatio:
                          gridChildAspectRatio, // Responsive aspect
                    ),
                    itemCount: _moodOptions.length,
                    itemBuilder: (context, index) {
                      final option = _moodOptions[index];
                      // Check if this mood is currently selected
                      final isSelected = _selectedMood == option['mood'];
                      // Disable interactions while submitting
                      final isEnabled = !_isSubmitting;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          // Only allow tap if not submitting
                          onTap: isEnabled
                              ? () => _selectMood(option['mood'])
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              // Conditional: thicker border and colored if selected
                              border: Border.all(
                                color: isSelected
                                    ? option[
                                        'color'] // Use mood color if selected
                                    : theme.colorScheme.outline.withValues(
                                        alpha: 0.4), // Gray if unselected
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              // Gradient background
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        option['color'].withValues(alpha: 0.15),
                                        option['color'].withValues(alpha: 0.08),
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        theme
                                            .colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.6),
                                        theme
                                            .colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                      ],
                                    ),
                              // Conditional: shadow only when selected
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: option['color']
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Emoji display - responsive size
                                Text(
                                  option['emoji'],
                                  style: TextStyle(
                                      fontSize: isMobile
                                          ? 32
                                          : isTablet
                                              ? 36
                                              : 40),
                                ),
                                const SizedBox(height: 6),
                                // Mood label text
                                Text(
                                  option['mood'],
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    // Conditional: use mood color if selected, gray if disabled
                                    color: isSelected
                                        ? option['color']
                                        : (isEnabled
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5)),
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile
                                        ? 12
                                        : isTablet
                                            ? 13
                                            : 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ==================== ENERGY LEVEL SECTION ====================
                  // Label for energy level selection
                  Text(
                    'Select your energy level',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontSize: sectionTitleFontSize,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row of energy level options (map loop: creates 3 energy buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _energyOptions.map((option) {
                      // Check if this energy level is currently selected
                      final isSelected =
                          _selectedEnergyLevel == option['level'];
                      // Disable interactions while submitting
                      final isEnabled = !_isSubmitting;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              // Only allow tap if not submitting
                              onTap: isEnabled
                                  ? () => _selectEnergyLevel(option['level'])
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: isMobile
                                        ? 16
                                        : isTablet
                                            ? 18
                                            : 20),
                                decoration: BoxDecoration(
                                  // Conditional: thicker border and colored if selected
                                  border: Border.all(
                                    color: isSelected
                                        ? option[
                                            'color'] // Use energy color if selected
                                        : theme.colorScheme.outline
                                            .withValues(alpha: 0.4),
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  // Gradient background
                                  gradient: isSelected
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            option['color']
                                                .withValues(alpha: 0.15),
                                            option['color']
                                                .withValues(alpha: 0.08),
                                          ],
                                        )
                                      : LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            theme.colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.6),
                                            theme.colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.3),
                                          ],
                                        ),
                                  // Conditional: shadow only when selected
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: option['color']
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Emoji display - responsive size
                                    Text(
                                      option['emoji'],
                                      style: TextStyle(
                                          fontSize: isMobile
                                              ? 24
                                              : isTablet
                                                  ? 26
                                                  : 28),
                                    ),
                                    const SizedBox(height: 6),
                                    // Energy level label text
                                    Text(
                                      option['level'],
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        // Conditional: use energy color if selected, gray if disabled
                                        color: isSelected
                                            ? option['color']
                                            : (isEnabled
                                                ? theme.colorScheme.onSurface
                                                : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.5)),
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile
                                            ? 12
                                            : isTablet
                                                ? 13
                                                : 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(), // toList() converts map iterator to List widget
                  ),

                  const SizedBox(height: 32),

                  // ==================== ACTION BUTTONS ====================
                  // Submit button (log mood) - FilledButton with conditional enabled state
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      // Button enabled only if both mood and energy selected and not submitting
                      onPressed: (_selectedMood != null &&
                              _selectedEnergyLevel != null &&
                              !_isSubmitting)
                          ? _submitMoodCheckIn
                          : null,
                      style: FilledButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: buttonHeight / 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      // Conditional: show spinner while submitting, text otherwise
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Log Mood',
                              style: TextStyle(fontSize: buttonFontSize),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip button (dismiss without logging) - TextButton with optional submit behavior
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : _dismiss, // Disable while submitting
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: buttonFontSize -
                            2, // Slightly smaller than action button
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HELPER FUNCTION ====================
/// Helper function to show the mood check-in dialog.
/// Displays the MoodCheckInDialog with optional callbacks for completion/dismissal.
/// [barrierDismissible] is set to false to require explicit button interaction.
Future<void> showMoodCheckInDialog(
  BuildContext context, {
  VoidCallback? onDismissed,
  VoidCallback? onCompleted,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // Require explicit action to close
    builder: (context) => MoodCheckInDialog(
      onDismissed: onDismissed,
      onCompleted: onCompleted,
    ),
  );
}
