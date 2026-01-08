/// Models for the lesson system.
/// 
/// These models match the Django backend models.

/// Represents a dynamic practice sequence for interactive lessons
class PracticeSequence {
  final int id;
  final int order;
  final List<String> notes; // e.g., ["C", "C", "D", "D"]

  PracticeSequence({
    required this.id,
    required this.order,
    required this.notes,
  });

  factory PracticeSequence.fromJson(Map<String, dynamic> json) {
    return PracticeSequence(
      id: json['id'],
      order: json['order'],
      notes: List<String>.from(json['notes']),
    );
  }
}
