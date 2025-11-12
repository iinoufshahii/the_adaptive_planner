// lib/services/task_service.dart (UPDATED)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import 'task_prioritization_service.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// Get tasks with smart prioritization based on mood and energy levels
  Stream<List<Task>> getSmartPrioritizedTasks(String? currentMood) {
    return getTasks()
        .map((tasks) => _prioritizeTasksByMood(tasks, currentMood));
  }

  /// Prioritize tasks based on current mood and energy levels using TaskPrioritizationService
  List<Task> _prioritizeTasksByMood(List<Task> tasks, String? currentMood) {
    // Use the new TaskPrioritizationService for advanced prioritization
    return TaskPrioritizationService.prioritizeTasks(
      tasks,
      currentMood,
      currentMood != null ? DateTime.now() : null,
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
  Future<void> updateTaskSubtasks(String taskId, List<String> subtaskTitles) async {
    // Convert string titles to Subtask objects with unique IDs
    final subtasks = subtaskTitles
        .asMap()
        .entries
        .map((e) => Subtask(
              id: DateTime.now().millisecondsSinceEpoch.toString() + e.key.toString(),
              title: e.value,
              isCompleted: false,
              order: e.key,
            ))
        .toList();
    
    await _db.collection('tasks').doc(taskId).update({
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle a specific subtask's completion status
  Future<void> toggleSubtaskCompletion(String taskId, String subtaskId) async {
    try {
      final taskDoc = await _db.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final subtasksData = List<Map<String, dynamic>>.from(data['subtasks'] ?? []);
      
      final subtaskIndex = subtasksData.indexWhere((s) => s['id'] == subtaskId);
      if (subtaskIndex != -1) {
        subtasksData[subtaskIndex]['isCompleted'] = !(subtasksData[subtaskIndex]['isCompleted'] as bool? ?? false);
        
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
  Future<void> updateSubtaskTitle(String taskId, String subtaskId, String newTitle) async {
    try {
      final taskDoc = await _db.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final subtasksData = List<Map<String, dynamic>>.from(data['subtasks'] ?? []);
      
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
      final subtasksData = List<Map<String, dynamic>>.from(data['subtasks'] ?? []);
      
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
    return _db
        .collection('tasks')
        .doc(taskId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Task.fromFirestore(doc.data()!, doc.id);
    });
  }
}
