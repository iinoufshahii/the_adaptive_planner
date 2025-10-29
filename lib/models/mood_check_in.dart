// lib/models/mood_check_in.dart

class MoodCheckIn {
  final String id;
  final String userId;
  final String mood; // e.g. happy, neutral, sad, angry, stressed, calm
  final DateTime date; // timestamp of the check-in
  final DateTime createdAt;

  MoodCheckIn({
    required this.id,
    required this.userId,
    required this.mood,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'mood': mood,
        'date': date,
        'createdAt': createdAt,
      };

  factory MoodCheckIn.fromMap(Map<String, dynamic> map, String id) {
    return MoodCheckIn(
      id: id,
      userId: map['userId'] as String? ?? '',
      mood: map['mood'] as String? ?? 'neutral',
      date: (map['date'] as dynamic) is DateTime
          ? map['date'] as DateTime
          : (map['date'] as dynamic).toDate() as DateTime,
      createdAt: (map['createdAt'] as dynamic) is DateTime
          ? map['createdAt'] as DateTime
          : (map['createdAt'] as dynamic).toDate() as DateTime,
    );
  }
}
