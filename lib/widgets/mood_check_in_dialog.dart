// lib/widgets/mood_check_in_dialog.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/mood_service.dart';

class MoodCheckInDialog extends StatefulWidget {
  final VoidCallback? onDismissed;
  final VoidCallback? onCompleted;

  const MoodCheckInDialog({
    super.key,
    this.onDismissed,
    this.onCompleted,
  });

  @override
  State<MoodCheckInDialog> createState() => _MoodCheckInDialogState();
}

class _MoodCheckInDialogState extends State<MoodCheckInDialog> {
  bool _isSubmitting = false;

  static const List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😊', 'mood': 'Happy', 'color': Colors.green},
    {'emoji': '😐', 'mood': 'Neutral', 'color': Colors.blue},
    {'emoji': '😔', 'mood': 'Sad', 'color': Colors.indigo},
    {'emoji': '😠', 'mood': 'Angry', 'color': Colors.red},
    {'emoji': '😩', 'mood': 'Stressed', 'color': Colors.orange},
    {'emoji': '🧘', 'mood': 'Calm', 'color': Colors.teal},
  ];

  Future<void> _selectMood(String mood) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      try {
        await context.read<MoodService>().addMood(mood.toLowerCase());
        if (mounted) {
          Navigator.of(context).pop();
          widget.onCompleted?.call();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mood logged: $mood'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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

  void _dismiss() {
    Navigator.of(context).pop();
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with dismiss button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'How are you feeling?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : _dismiss,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track your daily mood to help personalize your experience',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Mood options grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _moodOptions.length,
              itemBuilder: (context, index) {
                final option = _moodOptions[index];
                final isEnabled = !_isSubmitting;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled ? () => _selectMood(option['mood']) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isEnabled
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surface.withOpacity(0.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option['emoji'],
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['mood'],
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isEnabled
                                  ? option['color']
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                              fontWeight: FontWeight.w500,
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

            const SizedBox(height: 24),

            // Skip button
            TextButton(
              onPressed: _isSubmitting ? null : _dismiss,
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Loading indicator
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the mood check-in dialog
Future<void> showMoodCheckInDialog(
  BuildContext context, {
  VoidCallback? onDismissed,
  VoidCallback? onCompleted,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => MoodCheckInDialog(
      onDismissed: onDismissed,
      onCompleted: onCompleted,
    ),
  );
}
