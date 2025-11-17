/// Unit tests for Task model serialization and deserialization
///
/// Tests the Task model's:
/// - toMap() and fromFirestore() conversions
/// - Proper enum handling
/// - Null value handling
/// - Timestamp conversions

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adaptive_planner/models/task.dart';

void main() {
  group('Task Model', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('Constructor', () {
      test('should create a task with all required parameters', () {
        final task = Task(
          userId: 'user123',
          title: 'Test Task',
          deadline: now,
          priority: TaskPriority.high,
          category: 'work',
          requiredEnergy: TaskEnergyLevel.high,
        );

        expect(task.userId, equals('user123'));
        expect(task.title, equals('Test Task'));
        expect(task.priority, equals(TaskPriority.high));
        expect(task.isCompleted, equals(false));
      });

      test('should set defaults correctly', () {
        final task = Task(
          userId: 'user123',
          title: 'Test Task',
          deadline: now,
          priority: TaskPriority.medium,
          category: 'work',
          requiredEnergy: TaskEnergyLevel.medium,
        );

        expect(task.isCompleted, equals(false));
        expect(task.subtasks, equals([]));
      });

      test('should handle optional fields', () {
        final task = Task(
          userId: 'user123',
          title: 'Test Task',
          description: 'Test Description',
          deadline: now,
          priority: TaskPriority.low,
          category: 'personal',
          requiredEnergy: TaskEnergyLevel.low,
          id: 'task123',
        );

        expect(task.id, equals('task123'));
        expect(task.description, equals('Test Description'));
      });
    });

    group('toFirestore()', () {
      test('should convert task to map correctly', () {
        final task = Task(
          userId: 'user123',
          title: 'Test Task',
          deadline: now,
          priority: TaskPriority.high,
          category: 'work',
          requiredEnergy: TaskEnergyLevel.high,
        );

        final map = task.toFirestore();

        expect(map['userId'], equals('user123'));
        expect(map['title'], equals('Test Task'));
        expect(map['priority'], equals('high'));
        expect(map['requiredEnergy'], equals('high'));
        expect(map['isCompleted'], equals(false));
      });

      test('should convert enum values to strings', () {
        final task = Task(
          userId: 'user123',
          title: 'Test Task',
          deadline: now,
          priority: TaskPriority.medium,
          category: 'study',
          requiredEnergy: TaskEnergyLevel.low,
        );

        final map = task.toFirestore();

        expect(map['priority'], equals('medium'));
        expect(map['requiredEnergy'], equals('low'));
      });

      test('should include forCreate flag in metadata', () {
        final task = Task(
          userId: 'user123',
          title: 'Test Task',
          deadline: now,
          priority: TaskPriority.high,
          category: 'work',
          requiredEnergy: TaskEnergyLevel.high,
        );

        final mapCreate = task.toFirestore(forCreate: true);
        expect(mapCreate.containsKey('createdAt'), isTrue);
      });
    });

    group('fromFirestore()', () {
      test('should deserialize from firestore data', () {
        final firestoreData = {
          'userId': 'user123',
          'title': 'Test Task',
          'deadline': Timestamp.fromDate(now),
          'priority': 'high',
          'category': 'work',
          'requiredEnergy': 'high',
          'isCompleted': false,
          'subtasks': [],
        };

        final task = Task.fromFirestore(firestoreData, 'task123');

        expect(task.id, equals('task123'));
        expect(task.userId, equals('user123'));
        expect(task.title, equals('Test Task'));
        expect(task.priority, equals(TaskPriority.high));
        expect(task.isCompleted, equals(false));
      });

      test('should handle missing optional fields', () {
        final firestoreData = {
          'userId': 'user123',
          'title': 'Test Task',
          'deadline': Timestamp.fromDate(now),
          'priority': 'low',
          'category': 'personal',
          'requiredEnergy': 'medium',
          'isCompleted': false,
          'subtasks': [],
        };

        final task = Task.fromFirestore(firestoreData, 'task123');

        expect(task.description, isNull);
      });

      test('should convert string enums back to enum values', () {
        final firestoreData = {
          'userId': 'user123',
          'title': 'Test Task',
          'deadline': Timestamp.fromDate(now),
          'priority': 'medium',
          'category': 'study',
          'requiredEnergy': 'low',
          'isCompleted': false,
          'subtasks': [],
        };

        final task = Task.fromFirestore(firestoreData, 'task123');

        expect(task.priority, equals(TaskPriority.medium));
        expect(task.requiredEnergy, equals(TaskEnergyLevel.low));
      });
    });

    group('Priority Enum', () {
      test('should have correct priority values', () {
        expect(TaskPriority.high.name, equals('high'));
        expect(TaskPriority.medium.name, equals('medium'));
        expect(TaskPriority.low.name, equals('low'));
      });
    });

    group('Energy Level Enum', () {
      test('should have correct energy level values', () {
        expect(TaskEnergyLevel.high.name, equals('high'));
        expect(TaskEnergyLevel.medium.name, equals('medium'));
        expect(TaskEnergyLevel.low.name, equals('low'));
      });
    });

    group('Task comparison', () {
      test('should be able to compare two tasks', () {
        final task1 = Task(
          userId: 'user123',
          title: 'Test Task',
          deadline: now,
          priority: TaskPriority.high,
          category: 'work',
          requiredEnergy: TaskEnergyLevel.high,
          id: 'task1',
        );

        final task2 = Task(
          userId: 'user123',
          title: 'Test Task',
          deadline: now,
          priority: TaskPriority.high,
          category: 'work',
          requiredEnergy: TaskEnergyLevel.high,
          id: 'task1',
        );

        expect(task1.id, equals(task2.id));
      });
    });
  });
}
