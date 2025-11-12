// lib/models/focus_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FocusSession {
  final String? id;
  final String userId;
  final DateTime start;
  final DateTime end;
  final int durationMinutes;

  FocusSession({
    this.id,
    required this.userId,
    required this.start,
    required this.end,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'durationMinutes': durationMinutes,
      };

  factory FocusSession.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FocusSession(
      id: doc.id,
      userId: d['userId'] as String,
      start: (d['start'] as Timestamp).toDate(),
      end: (d['end'] as Timestamp).toDate(),
      durationMinutes: (d['durationMinutes'] as num).toInt(),
    );
  }
}

class UserFocusPrefs {
  final String userId;
  final int dailyGoalMinutes;
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakInterval;

  UserFocusPrefs({
    required this.userId,
    required this.dailyGoalMinutes,
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.longBreakInterval,
  });

  Map<String, dynamic> toMap() => {
        'dailyGoalMinutes': dailyGoalMinutes,
        'workMinutes': workMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'longBreakInterval': longBreakInterval,
      };

  factory UserFocusPrefs.fromDoc(String userId, DocumentSnapshot? doc) {
    if (doc == null || !doc.exists) {
      // Default values for a new user
      return UserFocusPrefs(
        userId: userId,
        dailyGoalMinutes: 240, // 4 hours
        workMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakInterval: 4,
      );
    }
    final d = doc.data() as Map<String, dynamic>;
    return UserFocusPrefs(
      userId: userId,
      dailyGoalMinutes: (d['dailyGoalMinutes'] ?? 240) as int,
      workMinutes: (d['workMinutes'] ?? 25) as int,
      shortBreakMinutes: (d['shortBreakMinutes'] ?? 5) as int,
      longBreakMinutes: (d['longBreakMinutes'] ?? 15) as int,
      longBreakInterval: (d['longBreakInterval'] ?? 4) as int,
    );
  }
}
