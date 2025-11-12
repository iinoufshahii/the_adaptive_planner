// lib/models/task.dart (UPDATED)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'subtask.dart';

// --- NEW ENUM DEFINITIONS ---
enum TaskPriority { high, medium, low }

enum TaskCategory { study, household, wellness, work, personal }

enum TaskEnergyLevel { high, medium, low }
// ----------------------------

class Task {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final DateTime deadline;
  final TaskPriority priority; // Changed type from String to enum
  final TaskCategory category; // Changed type from String to enum
  final TaskEnergyLevel requiredEnergy; // Changed type from String to enum
  final bool isCompleted;
  final List<Subtask> subtasks; // Changed from List<String> to List<Subtask>

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

  // Helper to convert enum to String for storage
  static String _enumToString(Object e) => e.toString().split('.').last;

  // Helper to convert string to enum
  static T _stringToEnum<T>(List<T> values, String value) {
    return values.firstWhere(
      (e) => _enumToString(e as Object) == value,
      orElse: () => values.first,
    );
  }

  // Convert Task object to a Map for Firestore
  Map<String, dynamic> toFirestore({bool forCreate = false}) {
    final data = <String, dynamic>{
      'userId': userId,
      'title': title,
      'description': description,
      'deadline': deadline, // store as timestamp
      'priority': _enumToString(priority),
      'category': _enumToString(category),
      'requiredEnergy': _enumToString(requiredEnergy),
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((s) => s.toMap()).toList(), // Convert Subtask objects to maps
    };
    if (forCreate) data['createdAt'] = FieldValue.serverTimestamp();
    return data;
  }

  // Create a Task object from a Firestore document
  factory Task.fromFirestore(Map<String, dynamic> map, String id) {
    DateTime parseDeadline(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return Task(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? 'Untitled') as String,
      description: map['description'] as String?,
      deadline: parseDeadline(map['deadline']),
      priority: _stringToEnum(
          TaskPriority.values, (map['priority'] ?? 'medium') as String),
      category: _stringToEnum(
          TaskCategory.values, (map['category'] ?? 'personal') as String),
      requiredEnergy: _stringToEnum(TaskEnergyLevel.values,
          (map['requiredEnergy'] ?? 'medium') as String),
      isCompleted: (map['isCompleted'] ?? false) as bool,
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [], // Parse subtasks as Subtask objects
    );
  }

  // CopyWith method for easy updates
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    TaskCategory? category,
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
}
