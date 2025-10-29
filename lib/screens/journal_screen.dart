// lib/screens/journal_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import 'edit_journal_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final JournalService _journalService = JournalService();
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  void _saveEntry() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _journalService.addJournalEntry(_textController.text);
      _textController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Entry saved! Analyzing mood...'),
              duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEditScreen(JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditJournalScreen(entry: entry),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              const Text('Are you sure you want to delete this journal entry?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Journal',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Input Section ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: "How are you feeling today?",
                        border: InputBorder.none,
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEntry,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Entry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Past Entries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            // --- List Section ---
            Expanded(
              child: StreamBuilder<List<JournalEntry>>(
                stream: _journalService.getJournalEntries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No journal entries yet.\nWrite one above to get started!',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final entries = snapshot.data!;

                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildJournalEntryCard(entry);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET FOR THE JOURNAL CARD ---
  Widget _buildJournalEntryCard(JournalEntry entry) {
    Color getMoodColor(String? mood) {
      switch (mood?.toLowerCase()) {
        case 'positive': return Colors.green.shade100;
        case 'negative': return Colors.red.shade100;
        case 'mixed': return Colors.orange.shade100;
        case 'neutral': return Colors.blue.shade100;
        default: return Colors.grey.shade200;
      }
    }

    Color getMoodTextColor(String? mood) {
      switch (mood?.toLowerCase()) {
        case 'positive': return Colors.green.shade800;
        case 'negative': return Colors.red.shade800;
        case 'mixed': return Colors.orange.shade800;
        case 'neutral': return Colors.blue.shade800;
        default: return Colors.grey.shade800;
      }
    }

    return Dismissible(
      key: ValueKey(entry.id),
      // --- Swipe Right (Edit) ---
      background: Container(
        color: Colors.blue.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Row(children: [
          Icon(Icons.edit, color: Colors.white),
          SizedBox(width: 8),
          Text('Edit', style: TextStyle(color: Colors.white)),
        ]),
      ),
      // --- Swipe Left (Delete) ---
      secondaryBackground: Container(
        color: Colors.red.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Delete', style: TextStyle(color: Colors.white)),
          SizedBox(width: 8),
          Icon(Icons.delete, color: Colors.white),
        ]),
      ),
      // --- Confirm Dismiss Logic (FIXED) ---
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) { // Swiping Left (Delete)
          final confirmed = await _showDeleteConfirmationDialog();
          if (confirmed == true && entry.id != null) {
            await _journalService.deleteJournalEntry(entry.id!);
          }
          return confirmed;
        }
        if (direction == DismissDirection.startToEnd) { // Swiping Right (Edit)
          _navigateToEditScreen(entry);
          return false; // Return false to prevent the item from being dismissed
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ExpansionTile(
          title: Text(entry.text, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              DateFormat.yMMMd().add_jm().format(entry.date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          trailing: entry.mood != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getMoodColor(entry.mood),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(entry.mood!,
                      style: TextStyle(
                          color: getMoodTextColor(entry.mood),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              : const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          
          // VVV THIS IS THE NEW/UPDATED SECTION VVV
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),

                  // AI Feedback Section
                  if (entry.aiFeedback != null && entry.aiFeedback!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Feedback:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(entry.aiFeedback!,
                            style: TextStyle(
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Actionable Steps Section
                  if (entry.actionableSteps != null && entry.actionableSteps!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actionable Steps:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 8),
                        ...entry.actionableSteps!.map((step) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 16, color: Colors.green.shade400),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(step)),
                                ],
                              ),
                            )),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}