// lib/services/journal_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/journal_entry.dart';
import 'ai_service.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AiService _aiService = AiService();

  Stream<List<JournalEntry>> getJournalEntries() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('journals')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Make sure to cast the data Map to the correct type
        return JournalEntry.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addJournalEntry(String text) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    // First, create the entry with null mood/feedback/steps
    final newEntry = JournalEntry(
      userId: user.uid,
      text: text,
      date: DateTime.now(),
      // actionableSteps is null by default in the constructor
    );

    // Save the initial entry to get a document ID
    DocumentReference docRef =
        await _firestore.collection('journals').add(newEntry.toMap());

    // --- AI Integration Step ---
    // Now, analyze the text in the background and update the entry
    try {
      // The AI service now returns a Map<String, dynamic>
      final Map<String, dynamic> aiResult =
          await _aiService.analyzeJournalEntry(text);

      // VVV THIS IS THE UPDATED PART VVV
      await docRef.update({
        'mood': aiResult['mood'],
        'aiFeedback': aiResult['feedback'],
        'actionableSteps': aiResult['actionableSteps'], // Save the new steps
      });
    } catch (e) {
      print("Could not get AI analysis: $e");
      // Optionally update the entry with an error state
      await docRef.update({
        'mood': 'Error',
        'aiFeedback': 'Could not analyze entry at this time.',
        'actionableSteps': [], // Save an empty list on error
      });
    }
  }

  Future<void> deleteJournalEntry(String entryId) async {
    await _firestore.collection('journals').doc(entryId).delete();
  }

  // When updating, we should also re-analyze the entry for new feedback
  Future<void> updateJournalEntry(String entryId, String newText) async {
    // First, just update the text and clear the old feedback
    await _firestore.collection('journals').doc(entryId).update({
      'text': newText,
      'mood': null,
      'aiFeedback': null,
      'actionableSteps': null,
    });

    // Now, re-run the analysis in the background
    try {
      final Map<String, dynamic> aiResult =
          await _aiService.analyzeJournalEntry(newText);
      await _firestore.collection('journals').doc(entryId).update({
        'mood': aiResult['mood'],
        'aiFeedback': aiResult['feedback'],
        'actionableSteps': aiResult['actionableSteps'],
      });
    } catch (e) {
      print("Could not get AI analysis on update: $e");
      await _firestore.collection('journals').doc(entryId).update({
        'mood': 'Error',
        'aiFeedback': 'Could not re-analyze entry.',
        'actionableSteps': [],
      });
    }
  }

  // VVV ADD THIS NEW METHOD VVV
  /// Saves a simple mood check-in entry.
  Future<void> addMoodCheckIn(String userId, String mood) async {
    final newEntry = JournalEntry(
      userId: userId,
      text: 'Mood check-in.', // Simple text placeholder
      date: DateTime.now(),
      mood: mood,
      entryType: 'moodCheckIn', // Set the new type
    );
    await _firestore.collection('journals').add(newEntry.toMap());
  }

  // VVV AND ADD THIS METHOD VVV
  /// Gets a stream of the latest mood check-in entry for today.
  Stream<JournalEntry?> getLatestMoodForToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('journals')
        .where('userId', isEqualTo: userId)
        .where('entryType', isEqualTo: 'moodCheckIn')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null; // No mood check-in for today yet
      }
      return JournalEntry.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }
}
