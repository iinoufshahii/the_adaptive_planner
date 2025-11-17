/// Journal entry creation and editing screen with rich text input.
/// Provides text editor for composing/editing journal entries with glassmorphic UI.
/// Handles entry persistence to Firestore with confirmation dialog before saving.
/// Displays save confirmation and provides user feedback on operation status.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';
import '../Service/journal_service.dart';
import '../Widgets/Responsive_widget.dart';
import '../dialogs/app_dialogs.dart';
import 'journal_screen.dart';

// --- Common UI Components ---

/// Builds the date/time header card for journal entries
Widget _buildDateTimeCard(BuildContext context, DateTime date,
    {required bool isNewEntry}) {
  final theme = Theme.of(context);

  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(28),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardTheme.color?.withValues(alpha: 0.85) ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('d MMMM yyyy').format(date),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE').format(date),
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade400.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    DateFormat('h:mm a').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Builds the text input field for journal entries
Widget _buildTextInputField(
    BuildContext context, TextEditingController controller, String hintText) {
  final theme = Theme.of(context);

  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        decoration: BoxDecoration(
          color: theme.cardTheme.color?.withValues(alpha: 0.9) ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.all(24),
            filled: false,
          ),
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(
            fontSize: 16,
            height: 1.7,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}

/// Builds the action button (Save/Update)
Widget _buildActionButton(
  BuildContext context, {
  required String label,
  required VoidCallback? onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade400.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.blue.shade400.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class NewJournalEntryScreen extends StatefulWidget {
  const NewJournalEntryScreen({super.key});

  @override
  State<NewJournalEntryScreen> createState() => _NewJournalEntryScreenState();
}

class _NewJournalEntryScreenState extends State<NewJournalEntryScreen> {
  final JournalService _journalService = JournalService();
  late final TextEditingController _textController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  Future<void> _saveEntry() async {
    // Prevent double save
    if (_isSaving) return;

    if (_textController.text.trim().isEmpty) {
      await showAutoDismissDialog(
        context,
        title: 'Empty Entry',
        message: 'Please write something before saving.',
        type: AppMessageType.warning,
      );
      return;
    }

    final confirmed = await _showSaveConfirmationDialog();
    if (confirmed != true) return;

    _isSaving = true;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Saving Entry...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await _journalService.addJournalEntry(_textController.text);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await showAutoDismissDialog(
          context,
          title: 'Entry Saved',
          message: 'Your journal entry has been saved successfully!',
          type: AppMessageType.success,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        final errorMsg = e.toString().contains('Network')
            ? 'Network error. Please check your connection and try again.'
            : e.toString().contains('Permission')
                ? 'Permission denied. Please check your account settings.'
                : 'Error saving entry: ${e.toString()}';
        await showAutoDismissDialog(
          context,
          title: 'Save Failed',
          message: errorMsg,
          type: AppMessageType.error,
        );
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<bool?> _showSaveConfirmationDialog() async {
    final result = await showConfirmationDialog(
      context,
      title: 'Save Entry',
      message: 'Save this journal entry?',
      confirmButtonLabel: 'Save',
      cancelButtonLabel: 'Cancel',
    );
    return result;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final borderRadius = ResponsiveUtils.getCardBorderRadius(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'New Entry',
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin:
              EdgeInsets.all(ResponsiveUtils.getColumnSpacing(context) * 0.5),
          decoration: BoxDecoration(
            color:
                theme.cardTheme.color?.withValues(alpha: 0.9) ?? Colors.white,
            borderRadius: BorderRadius.circular(borderRadius.toDouble() * 0.75),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.toDouble(),
                    padding.toDouble(),
                    padding.toDouble(),
                    padding.toDouble(),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWeb ? 900 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateTimeCard(context, DateTime.now(),
                              isNewEntry: true),
                          const SizedBox(height: 24),
                          Text(
                            'Your Entry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextInputField(
                            context,
                            _textController,
                            "Write your journal entry here...",
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildActionButton(
              context,
              label: 'Save Entry',
              onPressed: _saveEntry,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Edit Journal Entry Screen ---

class EditJournalEntryScreen extends StatefulWidget {
  final JournalEntry entry;

  const EditJournalEntryScreen({super.key, required this.entry});

  @override
  State<EditJournalEntryScreen> createState() => _EditJournalEntryScreenState();
}

class _EditJournalEntryScreenState extends State<EditJournalEntryScreen> {
  final JournalService _journalService = JournalService();
  late final TextEditingController _textController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry.text);
  }

  Future<void> _updateEntry() async {
    // Prevent double save
    if (_isSaving) return;

    if (_textController.text.trim().isEmpty) {
      await showAutoDismissDialog(
        context,
        title: 'Empty Entry',
        message: 'Please write something before saving.',
        type: AppMessageType.warning,
      );
      return;
    }

    final confirmed = await _showSaveConfirmationDialog();
    if (confirmed != true) return;

    _isSaving = true;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Updating Entry...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (widget.entry.id != null) {
        await _journalService.updateJournalEntry(
          widget.entry.id!,
          _textController.text,
        );
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          // Show success dialog and auto-dismiss after 3 seconds
          await showAutoDismissDialog(
            context,
            title: 'Entry Updated',
            message: 'Your journal entry has been updated successfully!',
            type: AppMessageType.success,
          );
          if (mounted) {
            // Navigate back after dialog closes
            Navigator.of(context).pop(); // Close edit screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => JournalReadingView(entry: widget.entry),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        final errorMsg = e.toString().contains('Network')
            ? 'Network error. Please check your connection and try again.'
            : e.toString().contains('Permission')
                ? 'Permission denied. Please check your account settings.'
                : 'Error updating entry: ${e.toString()}';
        await showAutoDismissDialog(
          context,
          title: 'Update Failed',
          message: errorMsg,
          type: AppMessageType.error,
        );
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<bool?> _showSaveConfirmationDialog() async {
    final result = await showConfirmationDialog(
      context,
      title: 'Save Changes',
      message: 'Update this journal entry?',
      confirmButtonLabel: 'Update',
      cancelButtonLabel: 'Cancel',
    );
    return result;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final borderRadius = ResponsiveUtils.getCardBorderRadius(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Entry',
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin:
              EdgeInsets.all(ResponsiveUtils.getColumnSpacing(context) * 0.5),
          decoration: BoxDecoration(
            color:
                theme.cardTheme.color?.withValues(alpha: 0.9) ?? Colors.white,
            borderRadius: BorderRadius.circular(borderRadius.toDouble() * 0.75),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.toDouble(),
                    padding.toDouble(),
                    padding.toDouble(),
                    padding.toDouble(),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWeb ? 900 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateTimeCard(context, widget.entry.date,
                              isNewEntry: false),
                          const SizedBox(height: 24),
                          Text(
                            'Your Entry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextInputField(
                            context,
                            _textController,
                            "Edit your journal entry...",
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildActionButton(
              context,
              label: 'Update Entry',
              onPressed: _updateEntry,
            ),
          ],
        ),
      ),
    );
  }
}
