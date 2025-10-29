// lib/models/journal_entry.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// An enum to differentiate between a full journal entry and a quick mood check-in.
enum JournalEntryType { full, moodCheckIn }

class JournalEntry {
  final String? id;
  final String userId;
  final String text;
  final DateTime date;
  final String? mood;
  final String? aiFeedback;
  final List<String>? actionableSteps;
  final String entryType; // New field to store the type

  JournalEntry({
    this.id,
    required this.userId,
    required this.text,
    required this.date,
    this.mood,
    this.aiFeedback,
    this.actionableSteps,
    this.entryType = 'full', // Default to 'full' for existing entries
  });

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