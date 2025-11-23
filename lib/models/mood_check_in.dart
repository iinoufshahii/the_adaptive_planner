/// Mood check-in model for capturing emotional and energy state.
///
/// This file provides:
/// - MoodCheckIn class: Emotional state snapshot with timestamps
///
/// Features:
/// - Quick mood/energy state capture
/// - Separate tracking for check-in time vs creation time
/// - Wellness tracking and personalization foundation
/// - Flexible DateTime parsing (DateTime or Timestamp)
library;

/// Model representing a user's mood check-in data at a specific point in time.
///
/// Captures emotional and energy state for wellness tracking and personalization features.
/// Enables mood-aware task recommendations and emotional intelligence features.
///
/// Key features:
/// - Timestamped mood snapshots for trend analysis
/// - Energy level tracking for task matching
/// - Separate check-in vs creation timestamps for analytics
/// - Safe DateTime conversion from multiple formats
class MoodCheckIn {
  /// Unique identifier for this mood check-in record (typically Firestore doc ID)
  final String id;

  /// User ID that owns this check-in for multi-user data isolation
  final String userId;

  /// Current mood state (e.g., 'happy', 'neutral', 'sad', 'angry', 'stressed', 'calm')
  final String mood;

  /// Current energy level (e.g., 'high', 'medium', 'low')
  final String energyLevel;

  /// Timestamp of when the mood check-in was recorded by the user
  final DateTime date;

  /// Timestamp of when the record was created in the database
  final DateTime createdAt;

  /// Constructor for creating a MoodCheckIn instance with required emotional state data.
  ///
  /// Parameters:
  /// - [id]: Required unique identifier
  /// - [userId]: Required user ID for data isolation
  /// - [mood]: Required current mood state
  /// - [energyLevel]: Required energy level
  /// - [date]: Required check-in timestamp
  /// - [createdAt]: Required creation timestamp
  MoodCheckIn({
    required this.id,
    required this.userId,
    required this.mood,
    required this.energyLevel,
    required this.date,
    required this.createdAt,
  });

  /// Converts MoodCheckIn to a Map for Firestore storage.
  ///
  /// Preserves DateTime objects for automatic Firestore serialization.
  ///
  /// Returns: Map ready for Firestore storage
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'mood': mood,
        'energyLevel': energyLevel,
        'date': date,
        'createdAt': createdAt,
      };

  /// Factory constructor to create MoodCheckIn from a Firestore Map.
  ///
  /// Safely handles flexible DateTime conversion supporting both native DateTime
  /// and Timestamp objects.
  ///
  /// Parameters:
  /// - [map]: Firestore document data
  /// - [id]: Firestore document ID
  ///
  /// Returns: MoodCheckIn instance with all fields safely initialized
  factory MoodCheckIn.fromMap(Map<String, dynamic> map, String id) {
    // Helper function: safely convert date field (DateTime or Timestamp)
    DateTime parseDateTime(dynamic raw) {
      if (raw is DateTime) {
        return raw;
      } else if (raw != null) {
        try {
          return (raw as dynamic).toDate() as DateTime;
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return MoodCheckIn(
      id: id,
      userId: map['userId'] as String? ?? '',
      mood: map['mood'] as String? ?? 'neutral',
      energyLevel: map['energyLevel'] as String? ?? 'medium',
      date: parseDateTime(map['date']),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  /// Provides readable string representation for debugging.
  ///
  /// Returns: String with mood, energy, and timestamps
  @override
  String toString() {
    return 'MoodCheckIn(id: $id, mood: $mood, energyLevel: $energyLevel)';
  }
}
