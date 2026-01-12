/// Models for the lesson system.
/// 
/// These models match the Django backend models.

/// Represents a learning level (Level 1, Level 2, etc.)
class LessonModule {
  final int id;
  final String title;
  final String description;
  final int order;
  final List<LessonItem> lessons;

  LessonModule({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.lessons,
  });

  factory LessonModule.fromJson(Map<String, dynamic> json) {
    return LessonModule(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      order: json['order'],
      lessons: (json['lessons'] as List)
          .map((l) => LessonItem.fromJson(l))
          .toList(),
    );
  }
}

/// Represents an individual lesson within a module
class LessonItem {
  final int id;
  final String title;
  final String type; // 'theory', 'quiz', 'practice'
  final int order;

  LessonItem({
    required this.id,
    required this.title,
    required this.type,
    required this.order,
  });

  factory LessonItem.fromJson(Map<String, dynamic> json) {
    return LessonItem(
      id: json['id'],
      title: json['title'],
      type: json['lesson_type'] ?? 'theory',
      order: json['order'],
    );
  }
}

/// Represents a dynamic practice sequence for interactive lessons
class PracticeSequence {
  final int id;
  final int order;
  final String type; // 'listen', 'learn', 'identify', 'read'
  final List<String> notes; // e.g., ["C", "C", "D", "D"]

  PracticeSequence({
    required this.id,
    required this.order,
    this.type = 'listen',
    required this.notes,
  });

  factory PracticeSequence.fromJson(Map<String, dynamic> json) {
    return PracticeSequence(
      id: json['id'],
      order: json['order'],
      type: json['sequence_type'] ?? 'listen',
      notes: List<String>.from(json['notes']),
    );
  }
}
