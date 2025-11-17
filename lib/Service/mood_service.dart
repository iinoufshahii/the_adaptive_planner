// lib/services/mood_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mood_check_in.dart';

class MoodService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _col => _firestore.collection('moodCheckIns');

  Future<void> addMood(String mood, String energyLevel) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    await _col.add({
      'userId': user.uid,
      'mood': mood,
      'energyLevel': energyLevel,
      'date': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
    });
  }

  // Check if user has logged mood today
  Future<bool> hasMoodToday(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final query = await _col
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Stream of today mood check-ins (multiple allowed)
  Stream<List<MoodCheckIn>> todayMoods(String userId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                MoodCheckIn.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // Latest mood for today (or null)
  Stream<MoodCheckIn?> latestMoodToday(String userId) {
    return todayMoods(userId).map((list) => list.isEmpty ? null : list.last);
  }

  // Last 7 days inclusive (day aligned)
  Stream<List<MoodCheckIn>> last7Days(String userId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final end =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                MoodCheckIn.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // Monthly check-ins for heat map
  Stream<List<MoodCheckIn>> monthMoods(String userId, DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 1);
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: first)
        .where('date', isLessThan: next)
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                MoodCheckIn.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // Streak (consecutive days with at least one check-in up to today)
  Future<int> currentStreak(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Look back up to 60 days (reasonable cap)
      final lookBack = today.subtract(const Duration(days: 60));
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: lookBack)
          .where('date', isLessThan: today.add(const Duration(days: 1)))
          .orderBy('date', descending: true)
          .get();

      final daysWith = <DateTime>{};
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        final ts = data['date'];
        DateTime dt;
        if (ts is DateTime) {
          dt = ts;
        } else {
          dt = (ts as Timestamp).toDate();
        }
        daysWith.add(DateTime(dt.year, dt.month, dt.day));
      }

      int streak = 0;
      for (int offset = 0; offset < 61; offset++) {
        final day = today.subtract(Duration(days: offset));
        if (daysWith.contains(day)) {
          streak++;
        } else {
          if (offset == 0) {
            continue; // allow zero-today case to not break if desire; but we'll break anyway
          }
          break;
        }
      }
      return streak;
    } catch (e) {
      print('Error calculating mood streak: $e');
      return 0; // Return 0 streak on error
    }
  }
}
