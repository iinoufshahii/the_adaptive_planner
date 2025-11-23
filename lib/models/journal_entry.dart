/// Journal entry model for personal reflection and mood tracking.
///
/// This file defines:
/// - JournalEntryType enum: full vs moodCheckIn entries
/// - JournalEntry class: Complete journal entry with AI analysis
///
/// Features:
/// - Support for full journal entries and quick mood check-ins
/// - AI-generated feedback and actionable steps
/// - Mood and sentiment tracking
/// - Full Firestore integration
library;

import 'package:cloud_firestore/cloud_firestore.dart';


/// Entry type differentiation for journal data.
///
/// - full: Complete journal entry with text, mood, AI feedback
/// - moodCheckIn: Quick mood/energy check-in (minimal data)
///
/// Used for flexible journaling that supports both deep reflection and quick updates.
enum JournalEntryType { full, moodCheckIn }

/// Model representing a journal entry with text content, mood tracking, and AI analysis.
///
/// Supports both full journal entries and quick mood check-in entries.
/// Stores user reflections, AI-generated feedback, and actionable steps for personal growth.
///
/// Key features:
/// - Flexible entry typing (full vs mood check-in)
/// - AI-powered sentiment analysis and feedback
/// - Mood and emotional state tracking
/// - Actionable insights generation
/// - Full Firestore CRUD support
class JournalEntry {
  /// Unique Firestore document ID for this journal entry (null before first save)
  final String? id;

  /// User ID that owns this entry for multi-user data isolation
  final String userId;

  /// Main text content of the journal entry written by the user
  final String text;

  /// Date/timestamp when the entry was created
  final DateTime date;

  /// Optional mood captured during journaling (e.g., 'happy', 'sad', 'anxious')
  final String? mood;

  /// Optional AI-generated feedback analyzing the journal entry sentiment and content
  final String? aiFeedback;

  /// Optional list of actionable steps generated from journal analysis
  final List<String>? actionableSteps;

  /// Entry type indicator: 'full' for complete entries or 'moodCheckIn' for quick check-ins
  /// Enables flexible journaling that supports both deep reflection and quick updates
  final String entryType;

  /// Constructor for creating a JournalEntry instance.
  ///
  /// Parameters:
  /// - [id]: Optional Firestore document ID (null for new entries)
  /// - [userId]: Required user ID for data isolation
  /// - [text]: Required entry text content
  /// - [date]: Required creation date/time
  /// - [mood]: Optional mood state during journaling
  /// - [aiFeedback]: Optional AI-generated analysis
  /// - [actionableSteps]: Optional list of recommended actions
  /// - [entryType]: Entry type (default: 'full' for backward compatibility)
  JournalEntry({
    this.id,
    required this.userId,
    required this.text,
    required this.date,
    this.mood,
    this.aiFeedback,
    this.actionableSteps,
    this.entryType = 'full',
  });

  /// Converts JournalEntry to a Map for Firestore storage.
  ///
  /// Handles serialization of all fields including nested lists.
  ///
  /// Returns: Map ready for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'aiFeedback': aiFeedback,
      'actionableSteps': actionableSteps,
      'entryType': entryType,
    };
  }

  /// Factory constructor to create JournalEntry from Firestore Map data.
  ///
  /// Safely handles:
  /// - Optional fields with null preservation
  /// - Timestamp to DateTime conversion
  /// - Dynamic list casting to List<String>
  /// - Backward compatibility for missing entryType
  ///
  /// Parameters:
  /// - [map]: Firestore document data
  /// - [documentId]: Firestore document ID
  ///
  /// Returns: JournalEntry instance with all fields safely initialized
  factory JournalEntry.fromMap(Map<String, dynamic> map, String documentId) {
    return JournalEntry(
      id: documentId,
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      mood: map['mood'],
      aiFeedback: map['aiFeedback'],
      actionableSteps: map['actionableSteps'] != null
          ? List<String>.from(map['actionableSteps'])
          : null,
      entryType: map['entryType'] ?? 'full',
    );
  }
}
