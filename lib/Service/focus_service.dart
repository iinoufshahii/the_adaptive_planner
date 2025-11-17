// lib/services/focus_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/focus_session.dart';

class FocusService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _sessions => _db.collection('focusSessions');
  CollectionReference _userPrefs(String userId) =>
      _db.collection('users').doc(userId).collection('focusPrefs');

  /// Creates a new session document and returns its id.
  Future<String> createSession(FocusSession session) async {
    final doc = await _sessions.add(session.toMap());
    return doc.id;
  }

  /// Updates an existing session document.
  Future<void> updateSession(String sessionId,
      {DateTime? end, int? durationMinutes}) async {
    final Map<String, dynamic> data = {};
    if (end != null) data['end'] = Timestamp.fromDate(end);
    if (durationMinutes != null) data['durationMinutes'] = durationMinutes;
    if (data.isNotEmpty) {
      await _sessions.doc(sessionId).update(data);
    }
  }

  /// Gets a stream of all sessions for a specific user on a given day.
  Stream<List<FocusSession>> sessionsForDay(String userId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _sessions
        .where('userId', isEqualTo: userId)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) => snap.docs.map(FocusSession.fromDoc).toList());
  }

  /// Gets a stream of user preferences.
  Stream<UserFocusPrefs> focusPrefsStream(String userId) {
    return _userPrefs(userId)
        .doc('prefs') // Use a consistent document ID
        .snapshots()
        .map((doc) => UserFocusPrefs.fromDoc(userId, doc));
  }

  /// Updates user preferences.
  Future<void> updatePrefs(UserFocusPrefs prefs) async {
    await _userPrefs(prefs.userId)
        .doc('prefs')
        .set(prefs.toMap(), SetOptions(merge: true));
  }

  /// Stores the last date the daily progress was reset.
  Future<void> setLastResetDate(String userId, DateTime date) async {
    final isoDate = "${date.year}-${date.month}-${date.day}";
    await _userPrefs(userId)
        .doc('prefs')
        .set({'lastResetDate': isoDate}, SetOptions(merge: true));
  }

  /// Retrieves the last reset date.
  Future<String?> getLastResetDate(String userId) async {
    final doc = await _userPrefs(userId).doc('prefs').get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['lastResetDate'] as String?;
  }
}
