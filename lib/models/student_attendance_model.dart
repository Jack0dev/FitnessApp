/// Student Attendance model - Represents student attendance for a session
/// Replaces AttendanceModel based on new database schema
class StudentAttendanceModel {
  final String id;
  final String studentId; // FK -> user.id (Student)
  final String sessionId; // FK -> session.id
  final DateTime checkInTime; // When attendance was recorded
  final String? qrTokenUsed; // FK -> session_qr.token (nullable, for QR code validation)
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentAttendanceModel({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.checkInTime,
    this.qrTokenUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create StudentAttendanceModel from Supabase response
  factory StudentAttendanceModel.fromSupabase(Map<String, dynamic> doc) {
    return StudentAttendanceModel(
      id: doc['id'] as String,
      studentId: doc['student_id'] as String,
      sessionId: doc['session_id'] as String,
      checkInTime: doc['check_in_time'] != null
          ? DateTime.parse(doc['check_in_time'] as String)
          : DateTime.now(),
      qrTokenUsed: doc['qr_token_used'] as String?,
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
      updatedAt: doc['updated_at'] != null
          ? DateTime.parse(doc['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'student_id': studentId,
      'session_id': sessionId,
      'check_in_time': checkInTime.toIso8601String(),
      if (qrTokenUsed != null) 'qr_token_used': qrTokenUsed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StudentAttendanceModel copyWith({
    String? id,
    String? studentId,
    String? sessionId,
    DateTime? checkInTime,
    String? qrTokenUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentAttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      sessionId: sessionId ?? this.sessionId,
      checkInTime: checkInTime ?? this.checkInTime,
      qrTokenUsed: qrTokenUsed ?? this.qrTokenUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}







