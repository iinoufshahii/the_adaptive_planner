/// Unit tests for JournalEntry model
///
/// Tests the JournalEntry model's:
/// - Constructor with different entry types
/// - AI feedback and actionable steps
/// - Serialization/deserialization
/// - Entry type handling (full vs moodCheckIn)

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adaptive_planner/models/journal_entry.dart';

void main() {
  group('JournalEntry Model', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('Constructor', () {
      test('should create a full journal entry with AI feedback', () {
        const aiFeedback = 'You seem to be feeling reflective today';
        final actionableSteps = ['Take a break', 'Go for a walk'];

        final entry = JournalEntry(
          userId: 'user123',
          text: 'Today was a good day',
          date: now,
          mood: 'happy',
          aiFeedback: aiFeedback,
          actionableSteps: actionableSteps,
          entryType: 'full',
        );

        expect(entry.userId, equals('user123'));
        expect(entry.text, equals('Today was a good day'));
        expect(entry.aiFeedback, equals(aiFeedback));
        expect(entry.actionableSteps, equals(actionableSteps));
        expect(entry.entryType, equals('full'));
      });

      test('should create a mood check-in entry', () {
        final entry = JournalEntry(
          userId: 'user123',
          text: 'Quick check-in',
          date: now,
          mood: 'stressed',
          entryType: 'moodCheckIn',
        );

        expect(entry.entryType, equals('moodCheckIn'));
        expect(entry.aiFeedback, isNull);
      });

      test('should use default entry type as full', () {
        final entry = JournalEntry(
          userId: 'user123',
          text: 'Default entry',
          date: now,
        );

        expect(entry.entryType, equals('full'));
      });

      test('should support various mood values', () {
        final moods = ['happy', 'sad', 'anxious', 'calm', 'stressed'];

        for (final mood in moods) {
          final entry = JournalEntry(
            userId: 'user123',
            text: 'Test entry',
            date: now,
            mood: mood,
          );

          expect(entry.mood, equals(mood));
        }
      });
    });

    group('toMap()', () {
      test('should serialize journal entry to map', () {
        final entry = JournalEntry(
          userId: 'user123',
          text: 'Test entry',
          date: now,
          mood: 'happy',
          aiFeedback: 'Great mood!',
          actionableSteps: ['Step 1', 'Step 2'],
          entryType: 'full',
        );

        final map = entry.toMap();

        expect(map['userId'], equals('user123'));
        expect(map['text'], equals('Test entry'));
        expect(map['mood'], equals('happy'));
        expect(map['aiFeedback'], equals('Great mood!'));
        expect(map['actionableSteps'], equals(['Step 1', 'Step 2']));
        expect(map['entryType'], equals('full'));
      });
    });

    group('fromFirestore()', () {
      test('should deserialize journal entry from firestore', () {
        final firestoreData = {
          'userId': 'user123',
          'text': 'Test entry content',
          'date': Timestamp.fromDate(now),
          'mood': 'happy',
          'aiFeedback': 'Positive sentiment detected',
          'actionableSteps': ['Exercise', 'Meditate'],
          'entryType': 'full',
        };

        final entry = JournalEntry.fromMap(firestoreData, 'entry123');

        expect(entry.id, equals('entry123'));
        expect(entry.userId, equals('user123'));
        expect(entry.text, equals('Test entry content'));
        expect(entry.mood, equals('happy'));
      });

      test('should handle missing optional fields', () {
        final firestoreData = {
          'userId': 'user123',
          'text': 'Simple entry',
          'date': Timestamp.fromDate(now),
          'entryType': 'moodCheckIn',
        };

        final entry = JournalEntry.fromMap(firestoreData, 'entry123');

        expect(entry.aiFeedback, isNull);
        expect(entry.actionableSteps, isNull);
        expect(entry.mood, isNull);
      });
    });

    group('AI Analysis Features', () {
      test('should store AI-generated feedback', () {
        const feedback =
            'You expressed gratitude and positive emotions. Consider continuing activities that bring you joy.';

        final entry = JournalEntry(
          userId: 'user123',
          text: 'Had a wonderful day with friends',
          date: now,
          mood: 'happy',
          aiFeedback: feedback,
          entryType: 'full',
        );

        expect(entry.aiFeedback, equals(feedback));
        expect(entry.aiFeedback!.length, greaterThan(0));
      });

      test('should store actionable steps from AI analysis', () {
        final steps = [
          'Schedule regular social activities',
          'Share your positive experiences with others',
          'Maintain this momentum by setting small daily goals'
        ];

        final entry = JournalEntry(
          userId: 'user123',
          text: 'Feeling accomplished',
          date: now,
          actionableSteps: steps,
          entryType: 'full',
        );

        expect(entry.actionableSteps, equals(steps));
        expect(entry.actionableSteps!.length, equals(3));
      });

      test('should handle complex AI feedback text', () {
        const complexFeedback =
            'Your entry shows signs of reflection and self-awareness. '
            'You mentioned struggling with time management, which is a common challenge. '
            'Consider breaking tasks into smaller, manageable steps.';

        final entry = JournalEntry(
          userId: 'user123',
          text: 'Struggling with productivity today',
          date: now,
          mood: 'frustrated',
          aiFeedback: complexFeedback,
          entryType: 'full',
        );

        expect(entry.aiFeedback, contains('reflection'));
        expect(entry.aiFeedback, contains('time management'));
      });
    });

    group('Entry Types', () {
      test('should differentiate between full and mood check-in entries', () {
        final fullEntry = JournalEntry(
          userId: 'user123',
          text: 'Detailed reflection',
          date: now,
          entryType: 'full',
        );

        final quickEntry = JournalEntry(
          userId: 'user123',
          text: 'Quick mood update',
          date: now,
          entryType: 'moodCheckIn',
        );

        expect(fullEntry.entryType, equals('full'));
        expect(quickEntry.entryType, equals('moodCheckIn'));
      });

      test('should support mood-based queries for check-ins', () {
        final entries = [
          JournalEntry(
            userId: 'user123',
            text: 'Feeling great',
            date: now,
            mood: 'happy',
            entryType: 'moodCheckIn',
          ),
          JournalEntry(
            userId: 'user123',
            text: 'Long reflection',
            date: now,
            mood: 'thoughtful',
            entryType: 'full',
          ),
        ];

        final moodCheckIns = entries
            .where((e) => e.entryType == 'moodCheckIn' && e.mood != null)
            .toList();

        expect(moodCheckIns.length, equals(1));
        expect(moodCheckIns.first.mood, equals('happy'));
      });
    });

    group('Journal Entry Timestamps', () {
      test('should preserve entry date and time', () {
        final specificTime =
            DateTime(2024, 6, 15, 14, 30, 45); // June 15, 2024 at 2:30:45 PM

        final entry = JournalEntry(
          userId: 'user123',
          text: 'Timed entry',
          date: specificTime,
        );

        expect(entry.date.year, equals(2024));
        expect(entry.date.month, equals(6));
        expect(entry.date.day, equals(15));
        expect(entry.date.hour, equals(14));
        expect(entry.date.minute, equals(30));
      });
    });

    group('Content Management', () {
      test('should handle long journal entries', () {
        const longText =
            'This is a very long journal entry that describes the entire day in detail. '
            'It started in the morning when I woke up feeling refreshed. '
            'Throughout the day, I encountered various challenges and achievements. '
            'By evening, I reflected on the entire experience and found it rewarding.';

        final entry = JournalEntry(
          userId: 'user123',
          text: longText,
          date: now,
        );

        expect(entry.text.length, greaterThan(100));
        expect(entry.text, equals(longText));
      });

      test('should handle special characters in journal text', () {
        const specialText =
            'Today was great! 🎉 I felt: happy, energized & motivated. #Blessed';

        final entry = JournalEntry(
          userId: 'user123',
          text: specialText,
          date: now,
        );

        expect(entry.text, contains('🎉'));
        expect(entry.text, contains('#Blessed'));
      });
    });
  });
}
