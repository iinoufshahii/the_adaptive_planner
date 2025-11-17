/// Focus session models for tracking user productivity and Pomodoro preferences.
///
/// This file provides:
/// - FocusSession: Individual focus/work session with timing metrics
/// - UserFocusPrefs: User-configurable Pomodoro and focus preferences
///
/// Features:
/// - Session timing with Firestore timestamp conversion
/// - Pomodoro configuration management
/// - Safe default preferences for new users
/// - Full type safety with null checks

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a single focus/work session for tracking time spent on tasks.
///
/// Contains timing information and duration metrics for analytics and progress tracking.
/// Stores start/end times and calculated duration for session analytics.
class FocusSession {
  /// Unique Firestore document ID for this session (null before first save)
  final String? id;

  /// User ID that owns this focus session for multi-user data isolation
  final String userId;

  /// Start timestamp of when the focus session began
  final DateTime start;

  /// End timestamp of when the focus session ended
  final DateTime end;

  /// Duration of the focus session in minutes for tracking metrics
  final int durationMinutes;

  /// Constructor for creating a FocusSession instance with required timing data.
  ///
  /// Parameters:
  /// - [id]: Optional Firestore document ID (null until saved)
  /// - [userId]: Required user ID that owns this session
  /// - [start]: Required session start time
  /// - [end]: Required session end time
  /// - [durationMinutes]: Required calculated session duration in minutes
  FocusSession({
    this.id,
    required this.userId,
    required this.start,
    required this.end,
    required this.durationMinutes,
  });

  /// Converts FocusSession to a Map for Firestore storage.
  ///
  /// Converts DateTime objects to Firestore Timestamp format for proper storage.
  /// Note: ID is not included (used as document ID in Firestore).
  ///
  /// Returns: Map ready for Firestore storage with Timestamp conversions
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'durationMinutes': durationMinutes,
      };

  /// Factory constructor to create FocusSession from Firestore DocumentSnapshot.
  ///
  /// Automatically extracts document ID and converts Firestore Timestamp back to DateTime.
  /// Safe handling of date conversions from Firestore format.
  ///
  /// Parameters:
  /// - [doc]: Firestore DocumentSnapshot containing session data
  ///
  /// Returns: FocusSession instance with all fields properly initialized
  factory FocusSession.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FocusSession(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      start: (d['start'] as Timestamp).toDate(),
      end: (d['end'] as Timestamp).toDate(),
      durationMinutes: (d['durationMinutes'] as num).toInt(),
    );
  }
}

/// Model for storing user-configurable focus session preferences and Pomodoro settings.
/// Manages timer durations and daily focus goals for individual users.
class UserFocusPrefs {
  /// User ID that owns these preferences for multi-user data isolation
  final String userId;

  /// Daily focus goal in minutes that the user aims to achieve
  final int dailyGoalMinutes;

  /// Duration of a work/focus block in minutes (typically 25 for Pomodoro)
  final int workMinutes;

  /// Duration of a short break in minutes (typically 5 for Pomodoro)
  final int shortBreakMinutes;

  /// Duration of a long break in minutes after several work cycles (typically 15)
  final int longBreakMinutes;

  /// Number of work cycles before triggering a long break (typically 4)
  final int longBreakInterval;

  /// Constructor for creating UserFocusPrefs instance with all required settings
  UserFocusPrefs({
    required this.userId,
    required this.dailyGoalMinutes,
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.longBreakInterval,
  });

  /// Converts UserFocusPrefs to a Map for Firestore storage.
  /// Excludes userId as it serves as the document ID in Firestore.
  Map<String, dynamic> toMap() => {
        'dailyGoalMinutes': dailyGoalMinutes,
        'workMinutes': workMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'longBreakInterval': longBreakInterval,
      };

  /// Factory constructor to create UserFocusPrefs from Firestore DocumentSnapshot.
  ///
  /// Returns default preferences if document doesn't exist or is null (first-time user scenario).
  ///
  /// Parameters:
  /// - [userId]: User ID that owns these preferences
  /// - [doc]: Firestore DocumentSnapshot (null returns defaults)
  ///
  /// Returns: UserFocusPrefs with either document data or safe defaults
  factory UserFocusPrefs.fromDoc(String userId, DocumentSnapshot? doc) {
    // Conditional check: if doc is null or doesn't exist, create defaults for new user
    if (doc == null || !doc.exists) {
      // Default values for a new user following standard Pomodoro settings
      return UserFocusPrefs(
        userId: userId,
        dailyGoalMinutes: 240, // 4 hours of total focus time daily
        workMinutes: 25, // Standard Pomodoro work interval
        shortBreakMinutes: 5, // Standard Pomodoro short break
        longBreakMinutes: 15, // Standard Pomodoro long break
        longBreakInterval: 4, // Long break after 4 work cycles
      );
    }
    // Document exists: extract data with null-coalescing operators for safe access
    final d = doc.data() as Map<String, dynamic>;
    return UserFocusPrefs(
      userId: userId,
      dailyGoalMinutes: (d['dailyGoalMinutes'] ?? 240)
          as int, // Default to 4 hours if missing
      workMinutes:
          (d['workMinutes'] ?? 25) as int, // Default to 25 min if missing
      shortBreakMinutes:
          (d['shortBreakMinutes'] ?? 5) as int, // Default to 5 min if missing
      longBreakMinutes:
          (d['longBreakMinutes'] ?? 15) as int, // Default to 15 min if missing
      longBreakInterval: (d['longBreakInterval'] ?? 4)
          as int, // Default to 4 cycles if missing
    );
  }

  /// Creates a copy of UserFocusPrefs with optionally overridden values.
  ///
  /// Used for immutable-style updates to preferences. Omitted parameters retain original values.
  ///
  /// Example: `newPrefs = prefs.copyWith(workMinutes: 30)`
  ///
  /// Parameters:
  /// - [userId]: Optional new user ID (rarely changed)
  /// - [dailyGoalMinutes]: Optional new daily focus goal
  /// - [workMinutes]: Optional new work interval duration
  /// - [shortBreakMinutes]: Optional new short break duration
  /// - [longBreakMinutes]: Optional new long break duration
  /// - [longBreakInterval]: Optional new long break interval
  ///
  /// Returns: New UserFocusPrefs instance with updated fields
  UserFocusPrefs copyWith({
    String? userId,
    int? dailyGoalMinutes,
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakInterval,
  }) =>
      UserFocusPrefs(
        userId: userId ?? this.userId,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        workMinutes: workMinutes ?? this.workMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      );

  /// Provides readable string representation for debugging.
  ///
  /// Returns: String with key configuration values
  @override
  String toString() => 'UserFocusPrefs(daily: ${dailyGoalMinutes}m, '
      'work: ${workMinutes}m, break: ${shortBreakMinutes}m/${longBreakMinutes}m)';
}
