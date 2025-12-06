import 'dart:convert';
import '../common/sql_database_service.dart';
import '../../config/supabase_config.dart';
import '../../models/attendance_model.dart';
import '../../models/enrollment_model.dart';
import '../course/course_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing attendance using QR code
/// 
/// ⚠️ NOTE: For session-based attendance, use SessionAttendanceService instead.
/// This service is for lesson-based attendance only.
class AttendanceService {
  SqlDatabaseService? _sqlService;
  final CourseService _courseService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  AttendanceService() 
      : _courseService = CourseService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. AttendanceService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  /// Mark attendance for a student in a lesson
  Future<bool> markAttendance({
    required String userId,
    required String courseId,
    required String lessonId,
    required DateTime attendanceTime,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      // Check if attendance already exists
      final existing = await _sqlService!.client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (existing != null) {
        // Update existing attendance
        await _sqlService!.client
            .from('attendance')
            .update({
              'attendance_time': attendanceTime.toIso8601String(),
              'status': 'present',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('lesson_id', lessonId);
      } else {
        // Create new attendance record
        await _sqlService!.client.from('attendance').insert({
          'user_id': userId,
          'course_id': courseId,
          'lesson_id': lessonId,
          'attendance_time': attendanceTime.toIso8601String(),
          'status': 'present',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      print('Failed to mark attendance: $e');
      return false;
    }
  }

  /// Get attendance for a lesson
  Future<List<Map<String, dynamic>>> getLessonAttendance(String lessonId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('attendance')
          .select('''
            *,
            user:user_id (
              id,
              display_name,
              email,
              photo_url
            )
          ''')
          .eq('lesson_id', lessonId)
          .order('attendance_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to get lesson attendance: $e');
      return [];
    }
  }

  /// Get attendance for a course
  Future<List<Map<String, dynamic>>> getCourseAttendance(String courseId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('attendance')
          .select('''
            *,
            user:user_id (
              id,
              display_name,
              email,
              photo_url
            ),
            lesson:lesson_id (
              id,
              title,
              lesson_number
            )
          ''')
          .eq('course_id', courseId)
          .order('attendance_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to get course attendance: $e');
      return [];
    }
  }

  /// Parse QR code data for attendance (legacy - for lesson-based)
  Map<String, dynamic>? parseAttendanceQRCode(String qrData) {
    try {
      // QR code format: JSON with user_id, course_id, lesson_id
      final data = qrData.split('|');
      if (data.length >= 3) {
        return {
          'user_id': data[0],
          'course_id': data[1],
          'lesson_id': data[2],
        };
      }
      
      // Try JSON format
      final jsonData = Map<String, dynamic>.from(
        Uri.splitQueryString(qrData.replaceFirst('?', '')),
      );
      
      if (jsonData.containsKey('user_id') && 
          jsonData.containsKey('course_id') && 
          jsonData.containsKey('lesson_id')) {
        return jsonData;
      }
      
      return null;
    } catch (e) {
      print('Error parsing QR code: $e');
      return null;
    }
  }

  // ========== DEPRECATED: SCHEDULE-BASED ATTENDANCE ==========
  // ⚠️ These methods are deprecated. Use SessionAttendanceService instead.

  /// Parse QR code of Schedule (for student to scan)
  /// 
  /// ⚠️ DEPRECATED: Use SessionAttendanceService.parseSessionQRCode() instead.
  @Deprecated('Use SessionAttendanceService.parseSessionQRCode() instead')
  Map<String, dynamic>? parseScheduleQRCode(String qrData) {
    print('⚠️ DEPRECATED: parseScheduleQRCode() called. Use SessionAttendanceService.parseSessionQRCode() instead.');
    return null;
  }

  /// Parse QR code of Student (for PT to scan)
  Map<String, dynamic>? parseStudentQRCode(String qrData) {
    try {
      // Try query string format: user_id=xxx&course_id=yyy&type=student_attendance
      final queryData = Uri.splitQueryString(qrData.replaceFirst('?', ''));
      
      if (queryData.containsKey('user_id') && 
          queryData['type'] == 'student_attendance') {
        return queryData;
      }
      
      // Try JSON format
      try {
        final jsonData = jsonDecode(qrData) as Map<String, dynamic>;
        if (jsonData['type'] == 'student_attendance' && 
            jsonData.containsKey('user_id')) {
          return jsonData;
        }
      } catch (_) {
        // Not JSON, continue
      }
      
      return null;
    } catch (e) {
      print('Error parsing student QR code: $e');
      return null;
    }
  }

  /// Validate schedule time window for attendance
  /// 
  /// ⚠️ DEPRECATED: Use SessionAttendanceService.isValidSessionTime() instead.
  @Deprecated('Use SessionAttendanceService.isValidSessionTime() instead')
  bool isValidScheduleTime(dynamic schedule) {
    print('⚠️ DEPRECATED: isValidScheduleTime() called. Use SessionAttendanceService.isValidSessionTime() instead.');
    return false;
  }

  /// Determine attendance status based on schedule time
  /// 
  /// ⚠️ DEPRECATED: This method is no longer used.
  @Deprecated('This method is deprecated')
  AttendanceStatus determineAttendanceStatus(dynamic schedule) {
    print('⚠️ DEPRECATED: determineAttendanceStatus() called.');
    return AttendanceStatus.present;
  }

  /// Check if user is enrolled and paid in course
  Future<bool> isUserEnrolledAndPaid(String userId, String courseId) async {
    try {
      final enrollments = await _courseService.getCourseEnrollments(courseId);
      final enrollment = enrollments.firstWhere(
        (e) => e.userId == userId,
        orElse: () => EnrollmentModel(
          id: '',
          userId: '',
          courseId: '',
          paymentStatus: PaymentStatus.pending,
          enrolledAt: DateTime.now(),
        ),
      );
      
      return enrollment.userId == userId && 
             enrollment.paymentStatus == PaymentStatus.paid;
    } catch (e) {
      print('Error checking enrollment: $e');
      return false;
    }
  }

  /// Mark attendance when student scans Schedule QR code
  /// 
  /// ⚠️ DEPRECATED: Use SessionAttendanceService.markAttendanceBySession() instead.
  @Deprecated('Use SessionAttendanceService.markAttendanceBySession() instead')
  Future<Map<String, dynamic>> markAttendanceBySchedule({
    required String scheduleId,
    required String userId,
  }) async {
    print('⚠️ DEPRECATED: markAttendanceBySchedule() called. Use SessionAttendanceService.markAttendanceBySession() instead.');
    return {
      'success': false,
      'message': 'Method deprecated. Use SessionAttendanceService instead.',
    };
  }

  /// Mark attendance when PT scans Student QR code
  /// 
  /// ⚠️ DEPRECATED: Use SessionAttendanceService.markAttendanceBySession() instead.
  @Deprecated('Use SessionAttendanceService.markAttendanceBySession() instead')
  Future<Map<String, dynamic>> markAttendanceByStudentQR({
    required String scheduleId,
    required String userId,
  }) async {
    print('⚠️ DEPRECATED: markAttendanceByStudentQR() called. Use SessionAttendanceService.markAttendanceBySession() instead.');
    return {
      'success': false,
      'message': 'Method deprecated. Use SessionAttendanceService instead.',
    };
  }

  /// Get attendance list for a schedule
  /// 
  /// ⚠️ DEPRECATED: Use SessionAttendanceService.getSessionAttendance() instead.
  @Deprecated('Use SessionAttendanceService.getSessionAttendance() instead')
  Future<List<AttendanceModel>> getScheduleAttendance(String scheduleId) async {
    print('⚠️ DEPRECATED: getScheduleAttendance() called. Use SessionAttendanceService.getSessionAttendance() instead.');
    return [];
  }

  /// Get attendance with user details for a schedule
  /// 
  /// ⚠️ DEPRECATED: Use SessionAttendanceService.getSessionAttendanceWithUsers() instead.
  @Deprecated('Use SessionAttendanceService.getSessionAttendanceWithUsers() instead')
  Future<List<Map<String, dynamic>>> getScheduleAttendanceWithUsers(String scheduleId) async {
    print('⚠️ DEPRECATED: getScheduleAttendanceWithUsers() called. Use SessionAttendanceService.getSessionAttendanceWithUsers() instead.');
    return [];
  }
}
