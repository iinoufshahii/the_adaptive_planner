/// Subtask model for granular task decomposition and progress tracking.
///
/// Subtasks enable breaking down complex tasks into smaller, manageable units,
/// allowing users to:
/// - Track progress on individual components
/// - Estimate effort more accurately
/// - Maintain momentum with quick wins
///
/// Features:
/// - Unique ID for individual tracking
/// - Order-based sequencing within parent task
/// - Completion tracking independent of parent task
/// - Immutable-style updates via copyWith()
library;

/// Model representing a subtask within a parent Task.
/// Subtasks enable task decomposition into smaller, manageable work units
/// and allow granular progress tracking.
class Subtask {
  /// Unique identifier for this subtask (typically UUID)
  final String id;

  /// Descriptive title of the subtask
  final String title;

  /// Completion status of the subtask
  final bool isCompleted;

  /// Ordering index to maintain subtask sequence within a task
  /// (0-based, allows gaps for future insertions)
  final int order;

  /// Constructor for creating a Subtask instance.
  ///
  /// Parameters:
  /// - [id]: Required unique identifier
  /// - [title]: Required descriptive title
  /// - [isCompleted]: Completion status (default: false)
  /// - [order]: Ordering index (default: 0, allows gaps)
  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.order = 0,
  });

  /// Converts Subtask to a Map for Firestore storage.
  ///
  /// Returns: Map with all fields ready for Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  /// Factory constructor to create Subtask from a Firestore Map.
  ///
  /// Safely handles missing fields with sensible defaults to prevent null errors.
  ///
  /// Parameters:
  /// - [map]: Firestore document data
  ///
  /// Returns: Subtask instance with all fields safely initialized
  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      order: map['order'] as int? ?? 0,
    );
  }

  /// Creates a copy of this Subtask with optionally updated fields.
  ///
  /// Enables immutable-style updates without rebuilding the entire object.
  /// Fields set to null are unchanged from the original instance.
  ///
  /// Returns: New Subtask instance with updated fields
  ///
  /// Example:
  /// ```dart
  /// final updated = subtask.copyWith(isCompleted: true);
  /// ```
  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? order,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  /// Provides a readable string representation of the Subtask for debugging.
  ///
  /// Includes: id, title, and completion status
  @override
  String toString() =>
      'Subtask(id: $id, title: $title, isCompleted: $isCompleted)';
}
