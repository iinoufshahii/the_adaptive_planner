/// Journal screen for viewing, creating, editing, and deleting journal entries.
/// Uses StreamBuilder to listen for real-time journal entries from Firestore.
/// Displays entries in a grid/list with reading view, edit capability, and delete confirmation.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dialogs/app_dialogs.dart';
import '../models/journal_entry.dart';
import '../Service/journal_service.dart';
import '../Widgets/Responsive_widget.dart';
import '../Widgets/Card_Widget.dart';
import 'edit_journal_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final JournalService _journalService = JournalService();
  String _sortBy = 'date'; // 'date' or 'mood'
  String? _selectedMood; // 'positive', 'negative', 'neutral', or null for all
  bool _sortAscending = false; // false = newest first, true = oldest first

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Sort Journal Entries'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sort By:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ListTile(
                      title: const Text('Date'),
                      leading: Radio<String>(
                        value: 'date',
                        // ignore: deprecated_member_use
                        groupValue: _sortBy,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                          this.setState(() {});
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Mood'),
                      leading: Radio<String>(
                        value: 'mood',
                        // ignore: deprecated_member_use
                        groupValue: _sortBy,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                          this.setState(() {});
                        },
                      ),
                    ),
                    if (_sortBy == 'mood') ...[
                      const SizedBox(height: 16),
                      const Divider()
                    ],
                    if (_sortBy == 'mood') ...[const SizedBox(height: 8)],
                    if (_sortBy == 'mood')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filter by Mood:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButton<String?>(
                            value: _selectedMood,
                            isExpanded: true,
                            hint: const Text('All Moods'),
                            items: const [
                              DropdownMenuItem(
                                  value: null, child: Text('All Moods')),
                              DropdownMenuItem(
                                  value: 'positive', child: Text('Positive')),
                              DropdownMenuItem(
                                  value: 'negative', child: Text('Negative')),
                              DropdownMenuItem(
                                  value: 'neutral', child: Text('Neutral')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedMood = value);
                              this.setState(() {});
                            },
                          ),
                        ],
                      ),
                    if (_sortBy == 'date') ...[
                      const SizedBox(height: 16),
                      const Divider()
                    ],
                    if (_sortBy == 'date') ...[const SizedBox(height: 8)],
                    if (_sortBy == 'date')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ListTile(
                            title: const Text('Newest First'),
                            leading: Radio<bool>(
                              value: false,
                              // ignore: deprecated_member_use
                              groupValue: _sortAscending,
                              // ignore: deprecated_member_use
                              onChanged: (value) {
                                setState(() => _sortAscending = value!);
                                this.setState(() {});
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Oldest First'),
                            leading: Radio<bool>(
                              value: true,
                              // ignore: deprecated_member_use
                              groupValue: _sortAscending,
                              // ignore: deprecated_member_use
                              onChanged: (value) {
                                setState(() => _sortAscending = value!);
                                this.setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<JournalEntry> _sortEntries(List<JournalEntry> entries) {
    List<JournalEntry> sorted = List.from(entries);

    if (_sortBy == 'date') {
      sorted.sort((a, b) =>
          _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    } else if (_sortBy == 'mood') {
      if (_selectedMood != null) {
        sorted = sorted
            .where((e) => e.mood?.toLowerCase() == _selectedMood)
            .toList();
      }
      // Secondary sort by date (newest first) when sorted by mood
      sorted.sort((a, b) => b.date.compareTo(a.date));
    }

    return sorted;
  }

  void _navigateToNewEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewJournalEntryScreen(),
      ),
    );
  }

  void _navigateToReadingView(JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JournalReadingView(entry: entry),
      ),
    );
  }

  void _navigateToEditScreen(JournalEntry entry) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EditJournalEntryScreen(entry: entry),
      ),
    )
        .then((_) {
      // Refresh when returning from edit - the StreamBuilder will automatically
      // detect the changes in Firestore and update the UI
      setState(() {});
    });
  }

  Future<bool?> _showDeleteConfirmationDialog(JournalEntry entry) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Entry',
      message: 'Are you sure you want to permanently delete this entry?',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          if (entry.id != null) {
            await _journalService.deleteJournalEntry(entry.id!);
            if (mounted) {
              await showAutoDismissDialog(
                context,
                title: 'Success',
                message: 'Journal entry deleted',
                type: AppMessageType.success,
              );
            }
          }
        } catch (e) {
          if (mounted) {
            await showAutoDismissDialog(
              context,
              title: 'Error',
              message: 'Failed to delete entry: $e',
              type: AppMessageType.error,
            );
          }
        }
      },
    );
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveUtils.getIconSize(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              size: iconSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showSortDialog,
            tooltip: 'Sort entries',
          ),
        ],
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _journalService.getJournalEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No journal entries yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to create your first entry',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          var entries = snapshot.data!;
          entries = _sortEntries(entries);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    ResponsiveUtils.isWeb(context) ? 1000 : double.infinity,
              ),
              child: ListView.builder(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getDefaultPadding(context).toDouble()),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _buildJournalEntryCard(entries[index]);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: _navigateToNewEntry,
        tooltip: 'New Journal Entry',
        child: Icon(Icons.add_rounded,
            color: Theme.of(context).colorScheme.onSecondary, size: 30),
      ),
    );
  }

  // --- HELPER METHODS FOR MOOD COLORS (STATIC) ---
  /// Returns color for mood type (positive=green, negative=red, neutral=blue)
  static Color _getMoodColor(String? mood) {
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
  static LinearGradient _getMoodGradient(String? mood) {
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

  // --- HELPER WIDGET FOR THE JOURNAL CARD ---
  Widget _buildJournalEntryCard(JournalEntry entry) {
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text('Edit',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit
          _navigateToEditScreen(entry);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Delete
          final confirmed = await _showDeleteConfirmationDialog(entry);
          return confirmed ?? false;
        }
        return false;
      },
      child: JournalCard(
        date: entry.date,
        mood: entry.mood,
        aiFeedback: entry.aiFeedback,
        actionableSteps: entry.actionableSteps,
        onTap: () => _navigateToReadingView(entry),
      ),
    );
  }

  // --- HELPER METHODS FOR MOOD COLORS (STATIC) ---
}

// --- JOURNAL READING VIEW ---
class JournalReadingView extends StatefulWidget {
  final JournalEntry entry;

  const JournalReadingView({super.key, required this.entry});

  @override
  State<JournalReadingView> createState() => _JournalReadingViewState();
}

class _JournalReadingViewState extends State<JournalReadingView> {
  void _navigateToEditScreen(JournalEntry entry) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EditJournalEntryScreen(entry: entry),
      ),
    )
        .then((_) {
      // Refresh when returning from edit
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(ResponsiveUtils.getIconSize(context) * 0.15),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(
                ResponsiveUtils.getCardBorderRadius(context) * 0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                size: ResponsiveUtils.getIconSize(context) * 0.6),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(ResponsiveUtils.getIconSize(context) * 0.15),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getCardBorderRadius(context) * 0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.edit,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  size: ResponsiveUtils.getIconSize(context) * 0.6),
              onPressed: () => _navigateToEditScreen(widget.entry),
              tooltip: 'Edit Entry',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                  ]
                : [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.getDefaultPadding(context).toDouble(),
              ResponsiveUtils.getTitleFontSize(context) + 80,
              ResponsiveUtils.getDefaultPadding(context).toDouble(),
              ResponsiveUtils.getDefaultPadding(context).toDouble() * 1.5,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      ResponsiveUtils.isWeb(context) ? 900 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Mood Header Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.all(
                              ResponsiveUtils.getDefaultPadding(context)
                                  .toDouble()),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.grey.shade800.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getCardBorderRadius(context)
                                    .toDouble()),
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
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
                              Text(
                                DateFormat('EEEE, d MMMM yyyy')
                                    .format(widget.entry.date),
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveUtils.getTitleFontSize(context),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              SizedBox(
                                  height: ResponsiveUtils.getColumnSpacing(
                                          context) *
                                      0.5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('h:mm a')
                                        .format(widget.entry.date),
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getBodyFontSize(
                                              context) *
                                          0.9,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (widget.entry.mood != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            ResponsiveUtils.getDefaultPadding(
                                                    context) *
                                                0.7,
                                        vertical:
                                            ResponsiveUtils.getColumnSpacing(
                                                    context) *
                                                0.4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _JournalScreenState
                                            ._getMoodGradient(
                                                widget.entry.mood),
                                        borderRadius: BorderRadius.circular(
                                            ResponsiveUtils.getCardBorderRadius(
                                                    context) *
                                                0.75),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _JournalScreenState
                                                    ._getMoodColor(
                                                        widget.entry.mood)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        widget.entry.mood!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              ResponsiveUtils.getBodyFontSize(
                                                      context) *
                                                  0.85,
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
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getColumnSpacing(context) * 1.5),

                    // Main Content
                    Text(
                      'Your Entry',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getTitleFontSize(context) * 0.7,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey.shade800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getColumnSpacing(context) * 0.75),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getCardBorderRadius(context)
                              .toDouble()),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: EdgeInsets.all(
                              ResponsiveUtils.getDefaultPadding(context)
                                  .toDouble()),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.grey.shade800.withValues(alpha: 0.8)
                                : Colors.grey.shade50.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getCardBorderRadius(context)
                                    .toDouble()),
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
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
                            widget.entry.text,
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtils.getBodyFontSize(context) *
                                      0.95,
                              height: 1.8,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getColumnSpacing(context) * 1.5),

                    // AI Insights Section
                    if (widget.entry.aiFeedback != null &&
                        widget.entry.aiFeedback!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Suggestion',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtils.getTitleFontSize(context) *
                                      0.7,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey.shade800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(
                              height:
                                  ResponsiveUtils.getColumnSpacing(context) *
                                      0.75),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getCardBorderRadius(context)
                                    .toDouble()),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: EdgeInsets.all(
                                    ResponsiveUtils.getDefaultPadding(context)
                                        .toDouble()),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? [
                                            Colors.blue.withValues(alpha: 0.15),
                                            Colors.blue.withValues(alpha: 0.08),
                                          ]
                                        : [
                                            Colors.blue.withValues(alpha: 0.1),
                                            Colors.blue.withValues(alpha: 0.05),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getCardBorderRadius(
                                              context)
                                          .toDouble()),
                                  border: Border.all(
                                    color: Colors.blue.withValues(
                                        alpha: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 0.4
                                            : 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: ResponsiveUtils.getIconSize(
                                                  context) *
                                              1.25,
                                          height: ResponsiveUtils.getIconSize(
                                                  context) *
                                              1.25,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.shade400,
                                                Colors.blue.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                ResponsiveUtils
                                                        .getCardBorderRadius(
                                                            context) *
                                                    0.65),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.shade400
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.lightbulb,
                                            color: Colors.white,
                                            size: ResponsiveUtils.getIconSize(
                                                    context) *
                                                0.7,
                                          ),
                                        ),
                                        SizedBox(
                                            width: ResponsiveUtils
                                                    .getColumnSpacing(context) *
                                                0.5),
                                        Expanded(
                                          child: Text(
                                            'Insight',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils
                                                      .getTitleFontSize(
                                                          context) *
                                                  0.65,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.blue.shade300
                                                  : Colors.blue.shade700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        height:
                                            ResponsiveUtils.getColumnSpacing(
                                                    context) *
                                                0.5),
                                    Text(
                                      widget.entry.aiFeedback!,
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveUtils.getBodyFontSize(
                                                    context) *
                                                0.9,
                                        height: 1.7,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),

                    // Actionable Steps Section
                    if (widget.entry.actionableSteps != null &&
                        widget.entry.actionableSteps!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actionable Steps',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtils.getTitleFontSize(context) *
                                      0.7,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey.shade800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(
                              height:
                                  ResponsiveUtils.getColumnSpacing(context) *
                                      0.75),
                          ...widget.entry.actionableSteps!
                              .asMap()
                              .entries
                              .map((e) {
                            int idx = e.key;
                            String step = e.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: ResponsiveUtils.getColumnSpacing(
                                          context) *
                                      0.75),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.getCardBorderRadius(context)
                                        .toDouble()),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                        ResponsiveUtils.getDefaultPadding(
                                                context)
                                            .toDouble()),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? [
                                                Colors.green
                                                    .withValues(alpha: 0.15),
                                                Colors.green
                                                    .withValues(alpha: 0.08),
                                              ]
                                            : [
                                                Colors.green
                                                    .withValues(alpha: 0.08),
                                                Colors.green
                                                    .withValues(alpha: 0.03),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          ResponsiveUtils.getCardBorderRadius(
                                                  context)
                                              .toDouble()),
                                      border: Border.all(
                                        color: Colors.green.withValues(
                                            alpha:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? 0.35
                                                    : 0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green
                                              .withValues(alpha: 0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: ResponsiveUtils.getIconSize(
                                                  context) *
                                              1.1,
                                          height: ResponsiveUtils.getIconSize(
                                                  context) *
                                              1.1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.green.shade400,
                                                Colors.green.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                ResponsiveUtils
                                                        .getCardBorderRadius(
                                                            context) *
                                                    0.65),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.green.shade400
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${idx + 1}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: ResponsiveUtils
                                                        .getBodyFontSize(
                                                            context) *
                                                    0.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            width: ResponsiveUtils
                                                    .getColumnSpacing(context) *
                                                0.5),
                                        Expanded(
                                          child: Text(
                                            step,
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils
                                                      .getBodyFontSize(
                                                          context) *
                                                  0.95,
                                              height: 1.6,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey.shade800,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          SizedBox(
                              height:
                                  ResponsiveUtils.getColumnSpacing(context)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// --- END OF JOURNAL READING VIEW ---
