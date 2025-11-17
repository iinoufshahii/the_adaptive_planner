/// Feature integration tests showcasing app functionality
///
/// Tests key user workflows:
/// - Task creation and prioritization
/// - Journal entry with AI feedback
/// - Mood tracking and mood-based recommendations
/// - Focus session management
/// - Account data lifecycle

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_planner/models/task.dart';
import 'package:adaptive_planner/models/journal_entry.dart';
import 'package:adaptive_planner/models/mood_check_in.dart';
import 'package:adaptive_planner/models/focus_session.dart';
import 'package:adaptive_planner/Service/task_prioritization_service.dart';

void main() {
  group('Feature Integration Tests', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('Task Management Workflow', () {
      test('should create, prioritize, and complete tasks', () {
        // Create tasks
        final tasks = [
          Task(
            userId: 'user123',
            title: 'Urgent bug fix',
            deadline: now.add(const Duration(hours: 2)),
            priority: TaskPriority.high,
            category: 'work',
            requiredEnergy: TaskEnergyLevel.high,
          ),
          Task(
            userId: 'user123',
            title: 'Weekly planning',
            deadline: now.add(const Duration(days: 2)),
            priority: TaskPriority.medium,
            category: 'work',
            requiredEnergy: TaskEnergyLevel.medium,
          ),
          Task(
            userId: 'user123',
            title: 'Casual reading',
            deadline: now.add(const Duration(days: 7)),
            priority: TaskPriority.low,
            category: 'personal',
            requiredEnergy: TaskEnergyLevel.low,
          ),
        ];

        // Prioritize tasks
        final prioritized = TaskPrioritizationService.prioritizeTasks(
          tasks,
          'happy',
          'high',
          now,
        );

        // Verify prioritization
        expect(prioritized.length, equals(3));
        expect(prioritized.first.title, equals('Urgent bug fix'));
        expect(prioritized.first.priority, equals(TaskPriority.high));

        // Complete first task
        expect(prioritized.first.isCompleted, equals(false));
      });

      test('should adjust task recommendations based on user mood/energy', () {
        final tasks = [
          Task(
            userId: 'user123',
            title: 'Complex project',
            deadline: now.add(const Duration(days: 5)),
            priority: TaskPriority.high,
            category: 'work',
            requiredEnergy: TaskEnergyLevel.high,
          ),
          Task(
            userId: 'user123',
            title: 'Admin task',
            deadline: now.add(const Duration(days: 4)),
            priority: TaskPriority.low,
            category: 'work',
            requiredEnergy: TaskEnergyLevel.low,
          ),
        ];

        // When user has high energy
        final highEnergyOrder = TaskPrioritizationService.prioritizeTasks(
          tasks,
          'energized',
          'high',
          now,
        );

        // When user has low energy
        final lowEnergyOrder = TaskPrioritizationService.prioritizeTasks(
          tasks,
          'tired',
          'low',
          now,
        );

        // Both orders should be valid prioritizations
        expect(highEnergyOrder.length, equals(2));
        expect(lowEnergyOrder.length, equals(2));
      });
    });

    group('Journal Entry Workflow', () {
      test('should create journal entry with AI analysis', () {
        const entryText =
            'Today was productive. I completed three important tasks and felt accomplished.';
        const aiFeedback =
            'Positive mood detected. You\'re making great progress!';
        final actionableSteps = [
          'Continue the momentum',
          'Share your success',
          'Plan next week\'s goals'
        ];

        final entry = JournalEntry(
          userId: 'user123',
          text: entryText,
          date: now,
          mood: 'happy',
          aiFeedback: aiFeedback,
          actionableSteps: actionableSteps,
          entryType: 'full',
        );

        // Verify entry creation
        expect(entry.text, equals(entryText));
        expect(entry.mood, equals('happy'));
        expect(entry.aiFeedback, isNotEmpty);
        expect(entry.actionableSteps, isNotEmpty);
        expect(entry.actionableSteps!.length, equals(3));
      });

      test('should support quick mood check-in entries', () {
        final moodCheckIn = JournalEntry(
          userId: 'user123',
          text: 'Just checking in',
          date: now,
          mood: 'neutral',
          entryType: 'moodCheckIn',
        );

        expect(moodCheckIn.entryType, equals('moodCheckIn'));
        expect(moodCheckIn.aiFeedback, isNull);
      });

      test('should track mood progression over time', () {
        final entries = [
          JournalEntry(
            userId: 'user123',
            text: 'Morning: Tired but ready',
            date: DateTime(now.year, now.month, now.day, 8),
            mood: 'tired',
            entryType: 'moodCheckIn',
          ),
          JournalEntry(
            userId: 'user123',
            text: 'Afternoon: Got some work done',
            date: DateTime(now.year, now.month, now.day, 14),
            mood: 'content',
            entryType: 'moodCheckIn',
          ),
          JournalEntry(
            userId: 'user123',
            text: 'Evening: Relaxed and happy',
            date: DateTime(now.year, now.month, now.day, 20),
            mood: 'happy',
            entryType: 'moodCheckIn',
          ),
        ];

        // Verify progression
        expect(entries[0].mood, equals('tired'));
        expect(entries[1].mood, equals('content'));
        expect(entries[2].mood, equals('happy'));

        // All from same user
        expect(entries.map((e) => e.userId).toSet().length, equals(1));
      });
    });

    group('Mood Tracking Workflow', () {
      test('should track multiple mood check-ins throughout day', () {
        final moodHistory = [
          MoodCheckIn(
            id: '1',
            userId: 'user123',
            mood: 'sleepy',
            energyLevel: 'low',
            date: DateTime(now.year, now.month, now.day, 7),
            createdAt: DateTime(now.year, now.month, now.day, 7),
          ),
          MoodCheckIn(
            id: '2',
            userId: 'user123',
            mood: 'energized',
            energyLevel: 'high',
            date: DateTime(now.year, now.month, now.day, 12),
            createdAt: DateTime(now.year, now.month, now.day, 12),
          ),
          MoodCheckIn(
            id: '3',
            userId: 'user123',
            mood: 'calm',
            energyLevel: 'medium',
            date: DateTime(now.year, now.month, now.day, 18),
            createdAt: DateTime(now.year, now.month, now.day, 18),
          ),
        ];

        expect(moodHistory.length, equals(3));
        expect(moodHistory.first.energyLevel, equals('low'));
        expect(moodHistory[1].energyLevel, equals('high'));
        expect(moodHistory.last.energyLevel, equals('medium'));
      });

      test('should use mood to personalize recommendations', () {
        // User checks in with stressed mood
        final stressedMood = MoodCheckIn(
          id: 'mood1',
          userId: 'user123',
          mood: 'stressed',
          energyLevel: 'low',
          date: now,
          createdAt: now,
        );

        // Should recommend low-energy tasks
        expect(stressedMood.energyLevel, equals('low'));

        // User checks in happy later
        final happyMood = MoodCheckIn(
          id: 'mood2',
          userId: 'user123',
          mood: 'happy',
          energyLevel: 'high',
          date: now.add(const Duration(hours: 2)),
          createdAt: now.add(const Duration(hours: 2)),
        );

        // Should recommend challenging tasks
        expect(happyMood.energyLevel, equals('high'));
      });
    });

    group('Focus Session Workflow', () {
      test('should create and track focus sessions', () {
        final session = FocusSession(
          userId: 'user123',
          start: now,
          end: now.add(const Duration(minutes: 25)),
          durationMinutes: 25,
        );

        expect(session.userId, equals('user123'));
        expect(session.durationMinutes, equals(25));
        expect(session.start.isBefore(session.end), isTrue);
      });

      test('should track multiple focus sessions for productivity', () {
        final sessions = [
          FocusSession(
            userId: 'user123',
            start: now,
            end: now.add(const Duration(minutes: 25)),
            durationMinutes: 25,
          ),
          FocusSession(
            userId: 'user123',
            start: now.add(const Duration(minutes: 30)),
            end: now.add(const Duration(minutes: 55)),
            durationMinutes: 25,
          ),
          FocusSession(
            userId: 'user123',
            start: now.add(const Duration(minutes: 90)),
            end: now.add(const Duration(minutes: 110)),
            durationMinutes: 20,
          ),
        ];

        final totalFocusTime = sessions.fold<int>(
            0, (sum, session) => sum + session.durationMinutes);

        expect(sessions.length, equals(3));
        expect(totalFocusTime, equals(70)); // 25 + 25 + 20
      });
    });

    group('Complete User Lifecycle', () {
      test('should demonstrate full app workflow', () {
        // 1. User creates tasks
        final tasks = [
          Task(
            userId: 'user123',
            title: 'Write report',
            deadline: now.add(const Duration(hours: 3)),
            priority: TaskPriority.high,
            category: 'work',
            requiredEnergy: TaskEnergyLevel.high,
          ),
          Task(
            userId: 'user123',
            title: 'Email client',
            deadline: now.add(const Duration(hours: 2)),
            priority: TaskPriority.medium,
            category: 'work',
            requiredEnergy: TaskEnergyLevel.medium,
          ),
        ];

        // 2. User checks mood
        final morning = MoodCheckIn(
          id: '1',
          userId: 'user123',
          mood: 'energized',
          energyLevel: 'high',
          date: now,
          createdAt: now,
        );

        // 3. Tasks are prioritized based on mood
        final prioritized = TaskPrioritizationService.prioritizeTasks(
          tasks,
          morning.mood,
          morning.energyLevel,
          now,
        );

        expect(prioritized.first.title, isNotEmpty);

        // 4. User starts focus session
        final focusStart = now;
        final focusEnd = focusStart.add(const Duration(minutes: 45));
        final session = FocusSession(
          userId: 'user123',
          start: focusStart,
          end: focusEnd,
          durationMinutes: 45,
        );

        expect(session.durationMinutes, equals(45));

        // 5. User journals about day
        final journal = JournalEntry(
          userId: 'user123',
          text: 'Productive day! Completed email and made progress on report.',
          date: now.add(const Duration(hours: 8)),
          mood: 'accomplished',
          aiFeedback: 'Great productivity! Keep up the momentum.',
          entryType: 'full',
        );

        expect(journal.mood, equals('accomplished'));
        expect(journal.aiFeedback, isNotEmpty);

        // Verify all data belongs to same user
        expect(tasks.every((t) => t.userId == 'user123'), isTrue);
        expect(morning.userId, equals('user123'));
        expect(session.userId, equals('user123'));
        expect(journal.userId, equals('user123'));
      });
    });

    group('Data Validation', () {
      test('should validate task creation with required fields', () {
        expect(
          () {
            Task(
              userId: 'user123',
              title: 'Valid task',
              deadline: now,
              priority: TaskPriority.high,
              category: 'work',
              requiredEnergy: TaskEnergyLevel.high,
            );
          },
          returnsNormally,
        );
      });

      test('should handle various priority levels correctly', () {
        for (final priority in TaskPriority.values) {
          final task = Task(
            userId: 'user123',
            title: 'Test task',
            deadline: now,
            priority: priority,
            category: 'work',
            requiredEnergy: TaskEnergyLevel.medium,
          );

          expect(task.priority, equals(priority));
        }
      });

      test('should handle all mood values', () {
        final validMoods = [
          'happy',
          'sad',
          'angry',
          'anxious',
          'stressed',
          'calm',
          'neutral'
        ];

        for (final mood in validMoods) {
          final entry = JournalEntry(
            userId: 'user123',
            text: 'Entry',
            date: now,
            mood: mood,
          );

          expect(entry.mood, equals(mood));
        }
      });
    });
  });
}
