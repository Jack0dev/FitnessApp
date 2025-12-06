/// Attendance model - Represents student attendance for a schedule
class AttendanceModel {
  final String id;
  final String scheduleId; // FK -> Schedule
  final String userId; // FK -> User (student)
  final String courseId; // FK -> Course
  final String? lessonId; // FK -> Lesson (optional)
  final DateTime attendanceTime; // When attendance was recorded
  final AttendanceStatus status; // Attendance status
  final String? notes; // Optional notes
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.scheduleId,
    required this.userId,
    required this.courseId,
    this.lessonId,
    required this.attendanceTime,
    this.status = AttendanceStatus.present,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AttendanceModel from Supabase response
  factory AttendanceModel.fromSupabase(Map<String, dynamic> doc) {
    return AttendanceModel(
      id: doc['id'] as String,
      scheduleId: doc['schedule_id'] as String,
      userId: doc['user_id'] as String,
      courseId: doc['course_id'] as String,
      lessonId: doc['lesson_id'] as String?,
      attendanceTime: doc['attendance_time'] != null
          ? DateTime.parse(doc['attendance_time'] as String)
          : DateTime.now(),
      status: AttendanceStatus.fromString(doc['status'] as String?),
      notes: doc['notes'] as String?,
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
      'schedule_id': scheduleId,
      'user_id': userId,
      'course_id': courseId,
      if (lessonId != null) 'lesson_id': lessonId,
      'attendance_time': attendanceTime.toIso8601String(),
      'status': status.value,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? scheduleId,
    String? userId,
    String? courseId,
    String? lessonId,
    DateTime? attendanceTime,
    AttendanceStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      attendanceTime: attendanceTime ?? this.attendanceTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Attendance status enum
enum AttendanceStatus {
  present('present', 'Có mặt'),
  absent('absent', 'Vắng mặt'),
  late('late', 'Đi muộn'),
  excused('excused', 'Có phép');

  final String value;
  final String displayName;

  const AttendanceStatus(this.value, this.displayName);

  static AttendanceStatus fromString(String? value) {
    if (value == null) return AttendanceStatus.present;
    return AttendanceStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => AttendanceStatus.present,
    );
  }
}








