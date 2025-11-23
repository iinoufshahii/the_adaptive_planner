/// Service for managing task categories in Firestore.
///
/// Handles CRUD operations for custom task categories with support for:
/// - Default categories (Study, Household, Wellness, Work, Personal)
/// - Custom user-created categories
/// - Category name updates across all associated tasks
/// - Deletion with automatic reassignment to "No Category"
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service managing task categorization in Firestore.
///
/// Provides functionality to create, read, update, and delete task categories.
/// Categories are stored per-user in Firestore subcollections.
class CategoryService {
  /// Firestore instance for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase Auth instance for user identification
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Predefined default categories available to all users
  static const List<String> defaultCategories = [
    'Study',
    'Household',
    'Wellness',
    'Work',
    'Personal'
  ];

  /// Gets a stream of user's custom categories combined with defaults.
  ///
  /// Returns stream containing:
  /// 1. All default categories (Study, Household, etc.)
  /// 2. User's custom categories
  /// 3. "No Category" as catch-all option
  ///
  /// Returns empty stream if user is not authenticated.
  Stream<List<String>> getUserCategories() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .snapshots()
        .map((snapshot) {
      final customCategories =
          snapshot.docs.map((doc) => doc['name'] as String).toList();
      // Combine: defaults + custom + no category option
      return [...defaultCategories, ...customCategories, 'No Category'];
    });
  }

  /// Retrieves all available categories for current user (future-based).
  ///
  /// Combines default categories, user-created categories, and "No Category".
  /// Returns only defaults and "No Category" if user is not authenticated.
  ///
  /// Returns:
  ///   List of all available category names
  Future<List<String>> getAllCategories() async {
    final user = _auth.currentUser;
    if (user == null) return [...defaultCategories, 'No Category'];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      final customCategories =
          snapshot.docs.map((doc) => doc['name'] as String).toList();
      return [...defaultCategories, ...customCategories, 'No Category'];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return defaultCategories;
    }
  }

  /// Creates a new custom category for the current user.
  ///
  /// Prevents duplicate categories (case-insensitive comparison).
  /// Stores both original case and lowercase version for flexible querying.
  ///
  /// Parameters:
  ///   - [name]: The category name to create
  ///
  /// Throws:
  ///   - Exception if user not authenticated
  ///   - Exception if category already exists
  Future<void> addCategory(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check for duplicate category (case-insensitive)
    final existing = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .where('nameLower', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Category already exists');
    }

    // Add new category document
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .add({
      'name': name,
      'nameLower': name.toLowerCase(), // For case-insensitive queries
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates an existing custom category name.
  ///
  /// Prevents modification of default categories.
  /// Automatically updates all tasks using the old category name.
  ///
  /// Parameters:
  ///   - [oldName]: Current category name
  ///   - [newName]: New category name
  ///
  /// Throws:
  ///   - Exception if category is a default category
  ///   - Exception if category not found
  Future<void> updateCategory(String oldName, String newName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Prevent modification of default categories
    if (defaultCategories.contains(oldName)) {
      throw Exception('Cannot edit default categories');
    }

    // Find the category document
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .where('name', isEqualTo: oldName)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Category not found');
    }

    final docId = snapshot.docs.first.id;

    // Update all tasks with this category
    await _updateTaskCategories(oldName, newName);

    // Update the category document
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .doc(docId)
        .update({
      'name': newName,
      'nameLower': newName.toLowerCase(),
    });
  }

  /// Deletes a custom category from the current user's account.
  ///
  /// Prevents deletion of default categories.
  /// Reassigns all tasks with this category to "No Category".
  ///
  /// Parameters:
  ///   - [name]: Category name to delete
  ///
  /// Throws:
  ///   - Exception if category is a default category
  ///   - Exception if category not found
  Future<void> deleteCategory(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Prevent deletion of default categories
    if (defaultCategories.contains(name)) {
      throw Exception('Cannot delete default categories');
    }

    // Find the category document
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Category not found');
    }

    final docId = snapshot.docs.first.id;

    // Reassign all tasks with this category to "No Category"
    await _updateTaskCategories(name, 'No Category');

    // Delete the category document
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .doc(docId)
        .delete();
  }

  /// Helper method: Updates all tasks using old category to use new category.
  ///
  /// Performs batch update on all task documents matching the old category.
  ///
  /// Parameters:
  ///   - [oldName]: Original category name
  ///   - [newName]: New category name to assign
  Future<void> _updateTaskCategories(String oldName, String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Find all tasks with the old category
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .where('category', isEqualTo: oldName)
          .get();

      // Update each task to use new category
      for (final doc in snapshot.docs) {
        await doc.reference.update({'category': newName});
      }
    } catch (e) {
      debugPrint('Error updating task categories: $e');
    }
  }

  /// Checks if a category name is custom (not default or system).
  ///
  /// Parameters:
  ///   - [name]: Category name to check
  ///
  /// Returns:
  ///   true if category is user-created, false if default or system
  static bool isCustomCategory(String name) {
    return !defaultCategories.contains(name) && name != 'No Category';
  }

  /// Deletes all custom categories for current user (fresh start).
  ///
  /// Note: Default categories remain available.
  /// All tasks lose their custom category assignments.
  ///
  /// Throws:
  ///   Exception if user not authenticated or deletion fails
  Future<void> clearAllCategories() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get all custom category documents
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      // Delete each document
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error clearing categories: $e');
      rethrow;
    }
  }
}
