/// App-wide reusable dialog system with Material Design 3 styling.
/// 
/// This file provides three customizable dialog components:
/// 1. FloatingBottomDialog: SnackBar-like notification (auto-dismisses in 1.5s)
/// 2. ConfirmationDialog: Modal confirmation prompt with Yes/No buttons
/// 3. AutoDismissDialog: Centered popup that auto-dismisses (1.5s)
/// 
/// All dialogs support [AppMessageType] for color-coded messaging (success, error, info, warning)
/// and follow Material Design 3 theming throughout the app.
library;

import 'package:flutter/material.dart';

/// Enum for categorizing messages with predefined icons, colors, and styling.
/// 
/// Values:
/// - [error]: Red color scheme for error states (Icons.error)
/// - [success]: Green/tertiary color for success states (Icons.check_circle)
/// - [info]: Blue/primary color for informational messages (Icons.info)
/// - [warning]: Orange/errorContainer color for warnings (Icons.warning_amber)
enum AppMessageType { error, success, info, warning }

/// Returns the appropriate icon for each message type.
/// 
/// - Success: check_circle
/// - Info: info  
/// - Warning: warning_amber
/// - Error: error
IconData _iconFor(AppMessageType type) {
  switch (type) {
    case AppMessageType.success:
      return Icons.check_circle;
    case AppMessageType.info:
      return Icons.info;
    case AppMessageType.warning:
      return Icons.warning_amber;
    case AppMessageType.error:
      return Icons.error;
  }
}

/// Returns the background color for each message type using Material Design 3 color scheme.
/// 
/// Uses theme's ColorScheme to ensure consistency with app theming:
/// - Success: tertiary (green-like)
/// - Info: primary (blue-like)
/// - Warning: errorContainer (orange-like)
/// - Error: error (red)
Color _colorFor(BuildContext context, AppMessageType type) {
  final scheme = Theme.of(context).colorScheme;
  switch (type) {
    case AppMessageType.success:
      return scheme.tertiary; // Using tertiary for success
    case AppMessageType.info:
      return scheme.primary;
    case AppMessageType.warning:
      return scheme.errorContainer;
    case AppMessageType.error:
      return scheme.error;
  }
}

/// Returns the text/icon color that contrasts well with each message type's background color.
/// 
/// Ensures proper contrast for accessibility and readability:
/// - Success: onTertiary
/// - Info: onPrimary
/// - Warning: onErrorContainer
/// - Error: onError
Color _onColorFor(BuildContext context, AppMessageType type) {
  final scheme = Theme.of(context).colorScheme;
  switch (type) {
    case AppMessageType.success:
      return scheme.onTertiary;
    case AppMessageType.info:
      return scheme.onPrimary;
    case AppMessageType.warning:
      return scheme.onErrorContainer;
    case AppMessageType.error:
      return scheme.onError;
  }
}

// ============================================================================
// DIALOG TYPE 1: Floating Bottom Message (1.5 sec, auto-dismiss)
// ============================================================================
/// Modern SnackBar-like notification that slides in from the bottom.
/// 
/// Features:
/// - Automatically dismisses after 1.5 seconds
/// - Smooth slide-in animation (100ms)
/// - Icon and message with color coding based on [AppMessageType]
/// - Auto-hides and calls [onDismiss] callback
/// - Non-blocking (doesn't interrupt user interaction)
/// 
/// Best for: Quick success, error, or info notifications
/// Example: "Email sent successfully", "Network error occurred"
class FloatingBottomDialog extends StatefulWidget {
  /// Message text to display
  final String message;
  
  /// Color scheme and icon based on message type
  final AppMessageType type;
  
  /// Duration before auto-dismissing (default: 1.5 seconds)
  final Duration duration;
  
  /// Optional callback when dialog is dismissed
  final VoidCallback? onDismiss;

  const FloatingBottomDialog({
    super.key,
    required this.message,
    this.type = AppMessageType.info,
    this.duration = const Duration(milliseconds: 1500),
    this.onDismiss,
  });

  @override
  State<FloatingBottomDialog> createState() => _FloatingBottomDialogState();
}

class _FloatingBottomDialogState extends State<FloatingBottomDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, widget.type);
    final onColor = _onColorFor(context, widget.type);
    final icon = _iconFor(widget.type);
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: onColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

/// Show floating bottom notification with optional callback.
/// 
/// Displays a non-blocking message that slides in from bottom and auto-dismisses.
/// Returns a Future that completes when dialog closes.
/// 
/// Parameters:
/// - [context]: BuildContext for navigation and theming
/// - [message]: Text to display in the notification
/// - [type]: Message type for color/icon (default: info)
/// - [duration]: Auto-dismiss timeout (default: 1.5 seconds)
/// - [onDismiss]: Optional callback when notification disappears
/// 
/// Example:
/// ```dart
/// await showFloatingBottomDialog(
///   context,
///   message: 'Task completed!',
///   type: AppMessageType.success,
/// );
/// ```
Future<void> showFloatingBottomDialog(
  BuildContext context, {
  required String message,
  AppMessageType type = AppMessageType.info,
  Duration duration = const Duration(milliseconds: 1500),
  VoidCallback? onDismiss,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, anim1, anim2) => FloatingBottomDialog(
      message: message,
      type: type,
      duration: duration,
      onDismiss: onDismiss,
    ),
  );
}

// ============================================================================
// DIALOG TYPE 2: Confirmation Popup Dialog (modal, requires user action)
// ============================================================================
/// Material Design 3 modal dialog for user confirmation/action.
/// 
/// Features:
/// - Blocks interaction with content below (modal)
/// - Customizable title, message, and button labels
/// - Custom button colors (default: red for confirmative actions)
/// - Returns bool: true if confirmed, false if cancelled
/// - Optional callbacks on confirm/cancel
/// 
/// Best for: Destructive actions like delete, important decisions
/// Example: "Delete this task permanently?", "Discard changes?"
class ConfirmationDialog extends StatelessWidget {
  /// Dialog title/heading
  final String title;
  
  /// Dialog message body
  final String message;
  
  /// Label for confirmation button (default: "Confirm")
  final String confirmButtonLabel;
  
  /// Label for cancel button (default: "Cancel")
  final String cancelButtonLabel;
  
  /// Callback fired when user confirms
  final VoidCallback? onConfirm;
  
  /// Callback fired when user cancels
  final VoidCallback? onCancel;
  
  /// Custom color for confirm button (default: error color for destructive)
  final Color? confirmButtonColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmButtonLabel = 'Confirm',
    this.cancelButtonLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final btnColor = confirmButtonColor ?? scheme.error;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    onCancel?.call();
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    cancelButtonLabel,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: btnColor == scheme.error
                        ? scheme.onError
                        : scheme.onPrimary,
                  ),
                  onPressed: () {
                    onConfirm?.call();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(confirmButtonLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Show modal confirmation dialog and return user's choice.
/// 
/// Blocks user interaction until dialog is dismissed. Returns bool indicating
/// whether user confirmed or cancelled.
/// 
/// Parameters:
/// - [context]: BuildContext for navigation and theming
/// - [title]: Dialog heading
/// - [message]: Dialog body text
/// - [confirmButtonLabel]: Text on confirm button (default: "Confirm")
/// - [cancelButtonLabel]: Text on cancel button (default: "Cancel")
/// - [onConfirm]: Optional callback before closing (if confirmed)
/// - [onCancel]: Optional callback before closing (if cancelled)
/// - [confirmButtonColor]: Custom color for confirm button (default: error/red)
/// 
/// Returns: true if confirmed, false if cancelled, null if dismissed via back
/// 
/// Example:
/// ```dart
/// final confirmed = await showConfirmationDialog(
///   context,
///   title: 'Delete Task?',
///   message: 'This action cannot be undone.',
///   confirmButtonLabel: 'Delete',
///   confirmButtonColor: Colors.red,
/// );
/// if (confirmed ?? false) {
///   // User confirmed deletion
/// }
/// ```
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmButtonLabel = 'Confirm',
  String cancelButtonLabel = 'Cancel',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  Color? confirmButtonColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmationDialog(
      title: title,
      message: message,
      confirmButtonLabel: confirmButtonLabel,
      cancelButtonLabel: cancelButtonLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmButtonColor: confirmButtonColor,
    ),
  );
}

// ============================================================================
// DIALOG TYPE 3: Auto-Dismiss Popup Dialog (1.5 sec, centered, status message)
// ============================================================================
/// Material Design 3 centered popup that auto-dismisses after 1.5 seconds.
/// 
/// Features:
/// - Centered on screen with scale + fade animation
/// - Displays icon, title, and message with color coding
/// - Shows auto-dismiss progress bar
/// - Automatically closes after timeout
/// - Non-blocking (doesn't interrupt user)
/// - Perfect for status updates that don't require action
/// 
/// Best for: Status confirmations without user action needed
/// Example: "Profile updated", "Entry saved", "Connection restored"
class AutoDismissDialog extends StatefulWidget {
  /// Dialog title/heading
  final String title;
  
  /// Dialog message body
  final String message;
  
  /// Color scheme and icon based on message type
  final AppMessageType type;
  
  /// Duration before auto-dismissing (default: 1.5 seconds)
  final Duration duration;
  
  /// Optional callback when dialog is dismissed
  final VoidCallback? onDismiss;

  const AutoDismissDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = AppMessageType.success,
    this.duration = const Duration(milliseconds: 1500),
    this.onDismiss,
  });

  @override
  State<AutoDismissDialog> createState() => _AutoDismissDialogState();
}

class _AutoDismissDialogState extends State<AutoDismissDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, widget.type);
    final icon = _iconFor(widget.type);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: scheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with colored background
                Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Message
                Text(
                  widget.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Progress indicator
                LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show centered auto-dismiss status popup dialog.
/// 
/// Displays a status message in the center of the screen with visual feedback
/// (icon, color, progress bar). Automatically dismisses after specified duration.
/// 
/// Parameters:
/// - [context]: BuildContext for navigation and theming
/// - [title]: Dialog heading
/// - [message]: Dialog body text
/// - [type]: Message type for color/icon (default: success)
/// - [duration]: Auto-dismiss timeout (default: 1.5 seconds)
/// - [onDismiss]: Optional callback when dialog disappears
/// 
/// Example:
/// ```dart
/// await showAutoDismissDialog(
///   context,
///   title: 'Task Created',
///   message: 'Your new task has been added.',
///   type: AppMessageType.success,
/// );
/// ```
Future<void> showAutoDismissDialog(
  BuildContext context, {
  required String title,
  required String message,
  AppMessageType type = AppMessageType.success,
  Duration duration = const Duration(milliseconds: 1500),
  VoidCallback? onDismiss,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AutoDismissDialog(
      title: title,
      message: message,
      type: type,
      duration: duration,
      onDismiss: onDismiss,
    ),
  );
}
