/// Task model for comprehensive task management with priority, categories, and subtasks.
///
/// This file defines:
/// - TaskPriority enum: high, medium, low for task importance ranking
/// - TaskCategory enum: study, household, wellness, work, personal for organization
/// - TaskEnergyLevel enum: high, medium, low for effort estimation
/// - Task class: Complete task data model with serialization/deserialization
///
/// Features:
/// - Decomposition into Subtask objects for progress tracking
/// - Priority and energy-level based task recommendations
/// - Full Firestore integration with safe timestamp conversion
/// - Immutable-style copying for state management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_base.dart';
import 'subtask.dart';

/// Priority levels indicating the urgency/importance of a task.
///
/// - high: Urgent, time-sensitive, or critical tasks
/// - medium: Important but flexible deadline
/// - low: Nice-to-have, can be postponed
///
/// Used in task sorting, recommendations, and UI prioritization.
enum TaskPriority { high, medium, low }

/// Task categorization enabling organization and filtering by life domain.
///
/// - study: Educational tasks, learning, coursework
/// - household: Chores, maintenance, household management
/// - wellness: Health, exercise, meditation, self-care
/// - work: Professional tasks, projects, deliverables
/// - personal: Personal projects, hobbies, goals
///
/// Supports custom categories stored as strings for flexibility.
enum TaskCategory { study, household, wellness, work, personal }

/// Energy level requirements indicating effort needed to complete task.
///
/// - high: Intensive, demanding, requires full mental capacity
/// - medium: Moderate effort, some focus required
/// - low: Simple, routine, minimal mental effort
///
/// Used to match tasks to user's current energy and mood state.
enum TaskEnergyLevel { high, medium, low }

/// Model representing a task with metadata, subtasks, and completion state.
///
/// Central data model for task management incorporating priority, energy requirements,
/// and decomposition into subtasks for better progress tracking.
///
/// Key features:
/// - Priority and energy-based task recommendations
/// - Hierarchical decomposition with Subtask objects
/// - Full Firestore CRUD integration
/// - Safe null-handling and type conversion
class Task {
  /// Unique Firestore document ID for this task (null before first save)
  final String? id;

  /// User ID that owns this task for multi-user data isolation
  final String userId;

  /// Brief title/name of the task
  final String title;

  /// Optional detailed description of what needs to be done
  final String? description;

  /// Deadline date/time by which the task should be completed
  final DateTime deadline;

  /// Priority level of the task (high/medium/low)
  final TaskPriority priority;

  /// Category/domain for the task (supports default and custom categories)
  final String category;

  /// Energy level required to complete this task (high/medium/low)
  final TaskEnergyLevel requiredEnergy;

  /// Whether the task has been marked as completed
  final bool isCompleted;

  /// List of Subtask objects that break down this task into smaller units
  final List<Subtask> subtasks;

  /// Constructor for creating a Task instance.
  ///
  /// Parameters:
  /// - [id]: Optional Firestore document ID (null for new tasks)
  /// - [userId]: Required user ID for data isolation
  /// - [title]: Required task title
  /// - [description]: Optional detailed description
  /// - [deadline]: Required deadline date/time
  /// - [priority]: Required priority level
  /// - [category]: Required category (string for flexibility)
  /// - [requiredEnergy]: Required energy level estimate
  /// - [isCompleted]: Completion status (default: false)
  /// - [subtasks]: List of subtasks (default: empty list)
  Task({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.deadline,
    required this.priority,
    required this.category,
    required this.requiredEnergy,
    this.isCompleted = false,
    this.subtasks = const [],
  });

  /// Converts Task object to a Map for Firestore storage.
  ///
  /// Handles:
  /// - Enum-to-string conversion for priority and requiredEnergy
  /// - Subtask serialization via Subtask.toMap()
  /// - Optional server timestamp for audit tracking
  ///
  /// Parameters:
  /// - [forCreate]: If true, adds server timestamp for document creation tracking
  ///
  /// Returns: Map ready for Firestore storage
  Map<String, dynamic> toFirestore({bool forCreate = false}) {
    final data = <String, dynamic>{
      'userId': userId,
      'title': title,
      'description': description,
      'deadline': deadline, // Firestore auto-converts DateTime to Timestamp
      'priority': ModelUtils.enumToString(priority),
      'category': category,
      'requiredEnergy': ModelUtils.enumToString(requiredEnergy),
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
    };

    // Add server timestamp for new documents (audit trail)
    if (forCreate) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    return data;
  }

  /// Factory constructor to create Task from Firestore Map data.
  ///
  /// Handles:
  /// - Safe enum conversion with defaults
  /// - Flexible deadline parsing (Timestamp/DateTime/String)
  /// - Subtask reconstruction from stored maps
  /// - Graceful null-handling for optional fields
  ///
  /// Parameters:
  /// - [map]: Firestore document data
  /// - [id]: Firestore document ID
  ///
  /// Returns: Task instance with all fields safely initialized
  factory Task.fromFirestore(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? 'Untitled') as String,
      description: map['description'] as String?,
      deadline: ModelUtils.parseDateTime(
        map['deadline'],
        fallback: DateTime.now().add(const Duration(days: 7)),
      ),
      priority: ModelUtils.stringToEnum(
        TaskPriority.values,
        (map['priority'] ?? 'medium') as String,
      ),
      category: (map['category'] ?? 'personal') as String,
      requiredEnergy: ModelUtils.stringToEnum(
        TaskEnergyLevel.values,
        (map['requiredEnergy'] ?? 'medium') as String,
      ),
      isCompleted: (map['isCompleted'] ?? false) as bool,
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Creates a copy of this Task with optionally updated fields.
  ///
  /// Enables immutable-style updates without rebuilding entire object.
  /// Fields set to null remain unchanged from original instance.
  ///
  /// Returns: New Task instance with updated fields
  ///
  /// Example:
  /// ```dart
  /// final updatedTask = task.copyWith(
  ///   title: 'New Title',
  ///   isCompleted: true,
  /// );
  /// ```
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    String? category,
    TaskEnergyLevel? requiredEnergy,
    bool? isCompleted,
    List<Subtask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      requiredEnergy: requiredEnergy ?? this.requiredEnergy,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  /// Provides readable string representation for debugging.
  ///
  /// Returns: String with task ID, title, and completion status
  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted, '
        'priority: ${ModelUtils.enumToString(priority)})';
  }
}
