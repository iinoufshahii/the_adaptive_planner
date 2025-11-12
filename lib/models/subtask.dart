// lib/models/subtask.dart

class Subtask {
  final String id;
  final String title;
  final bool isCompleted;
  final int order;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.order = 0,
  });

  // Convert Subtask to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  // Create Subtask from Map
  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      order: map['order'] as int? ?? 0,
    );
  }

  // CopyWith method
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

  @override
  String toString() => 'Subtask(id: $id, title: $title, isCompleted: $isCompleted)';
}
