/// Session Student model - Many-to-many relationship between Session and Student
class SessionStudentModel {
  final String id;
  final String sessionId; // FK -> session.id
  final String studentId; // FK -> user.id (Student)
  final DateTime createdAt;

  SessionStudentModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.createdAt,
  });

  /// Create SessionStudentModel from Supabase response
  factory SessionStudentModel.fromSupabase(Map<String, dynamic> doc) {
    return SessionStudentModel(
      id: doc['id'] as String,
      sessionId: doc['session_id'] as String,
      studentId: doc['student_id'] as String,
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SessionStudentModel copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    DateTime? createdAt,
  }) {
    return SessionStudentModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}







