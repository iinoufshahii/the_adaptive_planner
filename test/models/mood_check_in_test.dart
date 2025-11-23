/// Unit tests for MoodCheckIn model
///
/// Tests the MoodCheckIn model's:
/// - Constructor and field initialization
/// - Serialization to/from Firestore
/// - Mood and energy level values
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adaptive_planner/models/mood_check_in.dart';

void main() {
  group('MoodCheckIn Model', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('Constructor', () {
      test('should create a mood check-in with all fields', () {
        final mood = MoodCheckIn(
          id: 'mood123',
          userId: 'user123',
          mood: 'happy',
          energyLevel: 'high',
          date: now,
          createdAt: now,
        );

        expect(mood.id, equals('mood123'));
        expect(mood.userId, equals('user123'));
        expect(mood.mood, equals('happy'));
        expect(mood.energyLevel, equals('high'));
      });

      test('should accept various mood values', () {
        final moods = ['happy', 'sad', 'neutral', 'stressed', 'calm', 'angry'];

        for (final moodValue in moods) {
          final mood = MoodCheckIn(
            id: 'mood123',
            userId: 'user123',
            mood: moodValue,
            energyLevel: 'medium',
            date: now,
            createdAt: now,
          );

          expect(mood.mood, equals(moodValue));
        }
      });

      test('should accept various energy level values', () {
        final energyLevels = ['high', 'medium', 'low'];

        for (final energy in energyLevels) {
          final mood = MoodCheckIn(
            id: 'mood123',
            userId: 'user123',
            mood: 'happy',
            energyLevel: energy,
            date: now,
            createdAt: now,
          );

          expect(mood.energyLevel, equals(energy));
        }
      });
    });

    group('toMap()', () {
      test('should convert mood check-in to map', () {
        final mood = MoodCheckIn(
          id: 'mood123',
          userId: 'user123',
          mood: 'happy',
          energyLevel: 'high',
          date: now,
          createdAt: now,
        );

        final map = mood.toMap();

        expect(map['userId'], equals('user123'));
        expect(map['mood'], equals('happy'));
        expect(map['energyLevel'], equals('high'));
        expect(map['date'], isA<DateTime>());
        expect(map['createdAt'], isA<DateTime>());
      });
    });

    group('fromFirestore()', () {
      test('should deserialize from firestore data', () {
        final firestoreData = {
          'userId': 'user123',
          'mood': 'sad',
          'energyLevel': 'low',
          'date': Timestamp.fromDate(now),
          'createdAt': Timestamp.fromDate(now),
        };

        final mood = MoodCheckIn.fromMap(firestoreData, 'mood123');

        expect(mood.id, equals('mood123'));
        expect(mood.userId, equals('user123'));
        expect(mood.mood, equals('sad'));
        expect(mood.energyLevel, equals('low'));
      });

      test('should handle timestamp conversions', () {
        final timestamp = Timestamp.fromDate(now);
        final firestoreData = {
          'userId': 'user123',
          'mood': 'neutral',
          'energyLevel': 'medium',
          'date': timestamp,
          'createdAt': timestamp,
        };

        final mood = MoodCheckIn.fromMap(firestoreData, 'mood123');

        expect(mood.date.year, equals(now.year));
        expect(mood.date.month, equals(now.month));
        expect(mood.date.day, equals(now.day));
      });
    });

    group('Mood tracking', () {
      test('should track mood progression throughout day', () {
        final morning = MoodCheckIn(
          id: '1',
          userId: 'user123',
          mood: 'tired',
          energyLevel: 'low',
          date: DateTime(now.year, now.month, now.day, 8),
          createdAt: DateTime(now.year, now.month, now.day, 8),
        );

        final afternoon = MoodCheckIn(
          id: '2',
          userId: 'user123',
          mood: 'happy',
          energyLevel: 'high',
          date: DateTime(now.year, now.month, now.day, 14),
          createdAt: DateTime(now.year, now.month, now.day, 14),
        );

        final evening = MoodCheckIn(
          id: '3',
          userId: 'user123',
          mood: 'calm',
          energyLevel: 'medium',
          date: DateTime(now.year, now.month, now.day, 20),
          createdAt: DateTime(now.year, now.month, now.day, 20),
        );

        expect(morning.mood, equals('tired'));
        expect(afternoon.mood, equals('happy'));
        expect(evening.mood, equals('calm'));
      });
    });

    group('Energy level patterns', () {
      test('should correlate mood and energy level', () {
        final positiveStates = [
          ('happy', 'high'),
          ('calm', 'medium'),
          ('relaxed', 'medium'),
        ];

        final negativeStates = [
          ('sad', 'low'),
          ('stressed', 'low'),
          ('tired', 'low'),
        ];

        for (final (mood, energy) in positiveStates) {
          final moodCheck = MoodCheckIn(
            id: 'mood123',
            userId: 'user123',
            mood: mood,
            energyLevel: energy,
            date: now,
            createdAt: now,
          );

          expect(moodCheck.mood, equals(mood));
          expect(moodCheck.energyLevel, equals(energy));
        }

        for (final (mood, energy) in negativeStates) {
          final moodCheck = MoodCheckIn(
            id: 'mood123',
            userId: 'user123',
            mood: mood,
            energyLevel: energy,
            date: now,
            createdAt: now,
          );

          expect(moodCheck.mood, equals(mood));
          expect(moodCheck.energyLevel, equals(energy));
        }
      });
    });
  });
}
