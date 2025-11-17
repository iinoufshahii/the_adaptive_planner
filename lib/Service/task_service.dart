// lib/services/task_service.dart (UPDATED)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subtask.dart';
import '../models/task.dart';
import 'task_prioritization_service.dart';

/// Provides task data access and management through Firestore.
///
/// Handles CRUD operations for tasks, including creation, updates, deletion,
/// and retrieval with optional smart prioritization based on user's mood
/// and energy levels. All tasks are scoped to the current authenticated user.
class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retrieves all tasks for the current user as a stream.
  ///
  /// Returns an empty stream if no user is authenticated.
  /// Tasks are ordered by deadline (earliest first).
  Stream<List<Task>> getTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Gets tasks with AI-powered smart prioritization.
  ///
  /// Prioritizes tasks based on the user's current mood and energy levels
  /// to suggest the most suitable tasks to work on now.
  ///
  /// Parameters:
  ///   - [currentMood] The user's current mood (e.g., 'happy', 'stressed')
  ///   - [currentEnergyLevel] Current energy level (e.g., 'high', 'low')
  Stream<List<Task>> getSmartPrioritizedTasks(
      String? currentMood, String? currentEnergyLevel) {
    return getTasks().map((tasks) =>
        _prioritizeTasksByMood(tasks, currentMood, currentEnergyLevel));
  }

  /// Prioritizes tasks based on current mood and energy levels using TaskPrioritizationService
  List<Task> _prioritizeTasksByMood(
      List<Task> tasks, String? currentMood, String? currentEnergyLevel) {
    // Use the new TaskPrioritizationService for advanced prioritization
    return TaskPrioritizationService.prioritizeTasks(
      tasks,
      currentMood,
      currentEnergyLevel,
      (currentMood != null || currentEnergyLevel != null)
          ? DateTime.now()
          : null,
    );
  }

  Future<void> addTask(Task task) async {
    await _db.collection('tasks').add(task.toFirestore(forCreate: true));
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _db.collection('tasks').doc(task.id).update(task.toFirestore());
  }

  /// Update subtasks for a specific task with full Subtask objects
  Future<void> updateTaskSubtasks(
      String taskId, List<String> subtaskTitles) async {
    try {
      // Get existing task to retrieve current subtasks
      final taskDoc = await _db.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final existingSubtasks = (data['subtasks'] as List<dynamic>? ?? [])
          .map((s) => Subtask.fromMap(s as Map<String, dynamic>))
          .toList();

      // Create new subtask objects with unique IDs
      final newSubtasks = subtaskTitles
          .asMap()
          .entries
          .map((e) => Subtask(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    e.key.toString(),
                title: e.value,
                isCompleted: false,
                order: existingSubtasks.length + e.key,
              ))
          .toList();

      // Merge existing and new subtasks
      final mergedSubtasks = [...existingSubtasks, ...newSubtasks];

      await _db.collection('tasks').doc(taskId).update({
        'subtasks': mergedSubtasks.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating subtasks: $e');
      rethrow;
    }
  }

  /// Toggle a specific subtask's completion status
  Future<void> toggleSubtaskCompletion(String taskId, String subtaskId) async {
    try {
      final taskDoc = await _db.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final subtasksData =
          List<Map<String, dynamic>>.from(data['subtasks'] ?? []);

      final subtaskIndex = subtasksData.indexWhere((s) => s['id'] == subtaskId);
      if (subtaskIndex != -1) {
        subtasksData[subtaskIndex]['isCompleted'] =
            !(subtasksData[subtaskIndex]['isCompleted'] as bool? ?? false);

        await _db.collection('tasks').doc(taskId).update({
          'subtasks': subtasksData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error toggling subtask: $e');
    }
  }

  /// Update a subtask's title
  Future<void> updateSubtaskTitle(
      String taskId, String subtaskId, String newTitle) async {
    try {
      final taskDoc = await _db.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final subtasksData =
          List<Map<String, dynamic>>.from(data['subtasks'] ?? []);

      final subtaskIndex = subtasksData.indexWhere((s) => s['id'] == subtaskId);
      if (subtaskIndex != -1) {
        subtasksData[subtaskIndex]['title'] = newTitle;

        await _db.collection('tasks').doc(taskId).update({
          'subtasks': subtasksData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating subtask title: $e');
    }
  }

  /// Delete a specific subtask
  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    try {
      final taskDoc = await _db.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final subtasksData =
          List<Map<String, dynamic>>.from(data['subtasks'] ?? []);

      subtasksData.removeWhere((s) => s['id'] == subtaskId);

      await _db.collection('tasks').doc(taskId).update({
        'subtasks': subtasksData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting subtask: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  /// Get a single task by ID as a stream for real-time updates
  Stream<Task?> getTaskById(String taskId) {
    return _db.collection('tasks').doc(taskId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Task.fromFirestore(doc.data()!, doc.id);
    });
  }
}
