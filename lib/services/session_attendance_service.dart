import 'dart:convert';
import 'common/sql_database_service.dart';
import '../config/supabase_config.dart';
import '../models/session_model.dart';
import '../models/student_attendance_model.dart';
import '../models/session_qr_model.dart';
import '../models/trainer_attendance_model.dart';
import 'session/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// Service for managing attendance using Session-based system
/// Works with new database schema: session, student_attendance, session_qr, session_student
class SessionAttendanceService {
  SqlDatabaseService? _sqlService;
  final SessionService _sessionService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  SessionAttendanceService() : _sessionService = SessionService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. SessionAttendanceService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  // ========== SESSION QR CODE MANAGEMENT ==========

  /// Generate a QR token for a session
  Future<SessionQRModel?> generateSessionQR(String sessionId, {Duration? expiration}) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final expiresAt = DateTime.now().add(expiration ?? const Duration(hours: 2));
      final token = _generateUniqueToken();

      final qrId = DateTime.now().millisecondsSinceEpoch.toString();
      final qrData = {
        'id': qrId,
        'session_id': sessionId,
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
        'is_used': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _sqlService!.client
          .from('session_qr')
          .insert(qrData)
          .select()
          .single();

      return SessionQRModel.fromSupabase(response);
    } catch (e) {
      print('Failed to generate session QR: $e');
      return null;
    }
  }

  /// Get active QR token for a session
  Future<SessionQRModel?> getActiveSessionQR(String sessionId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final now = DateTime.now().toIso8601String();
      final response = await _sqlService!.client
          .from('session_qr')
          .select()
          .eq('session_id', sessionId)
          .eq('is_used', false)
          .gt('expires_at', now)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return SessionQRModel.fromSupabase(response);
    } catch (e) {
      print('Failed to get active session QR: $e');
      return null;
    }
  }

  /// Validate and use a QR token
  Future<bool> validateAndUseQRToken(String token) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final qrRecord = await _sqlService!.client
          .from('session_qr')
          .select()
          .eq('token', token)
          .maybeSingle();

      if (qrRecord == null) return false;

      final qr = SessionQRModel.fromSupabase(qrRecord);
      if (!qr.isValid) return false;

      // Mark as used
      await _sqlService!.client
          .from('session_qr')
          .update({'is_used': true})
          .eq('token', token);

      return true;
    } catch (e) {
      print('Failed to validate QR token: $e');
      return false;
    }
  }

  /// Generate unique token
  String _generateUniqueToken() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ========== SESSION STUDENT MANAGEMENT ==========

  /// Add student to session
  Future<bool> addStudentToSession(String sessionId, String studentId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final sessionStudentId = DateTime.now().millisecondsSinceEpoch.toString();
      await _sqlService!.client.from('session_student').insert({
        'id': sessionStudentId,
        'session_id': sessionId,
        'student_id': studentId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Failed to add student to session: $e');
      return false;
    }
  }

  /// Remove student from session
  Future<bool> removeStudentFromSession(String sessionId, String studentId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      await _sqlService!.client
          .from('session_student')
          .delete()
          .eq('session_id', sessionId)
          .eq('student_id', studentId);
      return true;
    } catch (e) {
      print('Failed to remove student from session: $e');
      return false;
    }
  }

  /// Check if student is enrolled in session
  Future<bool> isStudentEnrolledInSession(String sessionId, String studentId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('session_student')
          .select()
          .eq('session_id', sessionId)
          .eq('student_id', studentId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Failed to check student enrollment: $e');
      return false;
    }
  }

  /// Get all students enrolled in a session
  Future<List<String>> getSessionStudents(String sessionId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('session_student')
          .select('student_id')
          .eq('session_id', sessionId);

      return (response as List)
          .map((doc) => doc['student_id'] as String)
          .toList();
    } catch (e) {
      print('Failed to get session students: $e');
      return [];
    }
  }

  // ========== STUDENT ATTENDANCE ==========

  /// Parse QR code of Session (for student to scan)
  Map<String, dynamic>? parseSessionQRCode(String qrData) {
    try {
      // Try query string format: session_id=xxx&type=session_attendance&token=yyy
      final queryData = Uri.splitQueryString(qrData.replaceFirst('?', ''));

      if (queryData.containsKey('session_id') &&
          queryData['type'] == 'session_attendance') {
        return queryData;
      }

      // Try JSON format
      try {
        final jsonData = jsonDecode(qrData) as Map<String, dynamic>;
        if (jsonData['type'] == 'session_attendance' &&
            jsonData.containsKey('session_id')) {
          return jsonData;
        }
      } catch (_) {
        // Not JSON, continue
      }

      return null;
    } catch (e) {
      print('Error parsing session QR code: $e');
      return null;
    }
  }

  /// Validate session time window for attendance
  bool isValidSessionTime(SessionModel session) {
    final now = DateTime.now();
    final sessionDateTime = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
      session.startTime.hour,
      session.startTime.minute,
    );

    final endDateTime = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
      session.endTime.hour,
      session.endTime.minute,
    );

    // Allow 15 minutes before start, 30 minutes after end
    final allowedStart = sessionDateTime.subtract(const Duration(minutes: 15));
    final allowedEnd = endDateTime.add(const Duration(minutes: 30));

    return now.isAfter(allowedStart) && now.isBefore(allowedEnd);
  }

  /// Mark attendance when student scans Session QR code
  Future<Map<String, dynamic>> markAttendanceBySession({
    required String sessionId,
    required String userId,
    String? qrToken,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      // Get session
      final session = await _sessionService.getSessionById(sessionId);
      if (session == null) {
        return {
          'success': false,
          'message': 'Session không tồn tại',
        };
      }

      // Validate session time window
      if (!isValidSessionTime(session)) {
        return {
          'success': false,
          'message': 'Ngoài thời gian cho phép chấm công',
        };
      }

      // Check if student is enrolled in session
      final isEnrolled = await isStudentEnrolledInSession(sessionId, userId);
      if (!isEnrolled) {
        return {
          'success': false,
          'message': 'Bạn chưa được đăng ký vào session này',
        };
      }

      // Validate QR token if provided
      if (qrToken != null) {
        final isValidToken = await validateAndUseQRToken(qrToken);
        if (!isValidToken) {
          return {
            'success': false,
            'message': 'QR code không hợp lệ hoặc đã được sử dụng',
          };
        }
      }

      // Check if already marked attendance
      final existing = await _sqlService!.client
          .from('student_attendance')
          .select()
          .eq('session_id', sessionId)
          .eq('student_id', userId)
          .maybeSingle();

      final attendanceId = DateTime.now().millisecondsSinceEpoch.toString();
      final checkInTime = DateTime.now();

      if (existing != null) {
        // Update existing attendance
        await _sqlService!.client
            .from('student_attendance')
            .update({
              'check_in_time': checkInTime.toIso8601String(),
              if (qrToken != null) 'qr_token_used': qrToken,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('session_id', sessionId)
            .eq('student_id', userId);
      } else {
        // Create new attendance record
        await _sqlService!.client.from('student_attendance').insert({
          'id': attendanceId,
          'session_id': sessionId,
          'student_id': userId,
          'check_in_time': checkInTime.toIso8601String(),
          if (qrToken != null) 'qr_token_used': qrToken,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return {
        'success': true,
        'message': 'Điểm danh thành công',
      };
    } catch (e) {
      print('Failed to mark attendance by session: $e');
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Get attendance list for a session
  Future<List<StudentAttendanceModel>> getSessionAttendance(String sessionId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('student_attendance')
          .select()
          .eq('session_id', sessionId)
          .order('check_in_time', ascending: false);

      return (response as List)
          .map((doc) => StudentAttendanceModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get session attendance: $e');
      return [];
    }
  }

  /// Get attendance with user details for a session
  Future<List<Map<String, dynamic>>> getSessionAttendanceWithUsers(String sessionId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('student_attendance')
          .select('''
            *,
            user:student_id (
              id,
              display_name,
              email,
              photo_url
            )
          ''')
          .eq('session_id', sessionId)
          .order('check_in_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to get session attendance with users: $e');
      return [];
    }
  }

  // ========== TRAINER ATTENDANCE ==========

  /// Check in trainer for a session
  Future<Map<String, dynamic>> checkInTrainer({
    required String sessionId,
    required String trainerId,
    double? latitude,
    double? longitude,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final attendanceId = DateTime.now().millisecondsSinceEpoch.toString();
      final checkInTime = DateTime.now();

      // Check if already exists
      final existing = await _sqlService!.client
          .from('trainer_attendance')
          .select()
          .eq('session_id', sessionId)
          .eq('trainer_id', trainerId)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await _sqlService!.client
            .from('trainer_attendance')
            .update({
              'check_in_time': checkInTime.toIso8601String(),
              if (latitude != null) 'check_in_lat': latitude,
              if (longitude != null) 'check_in_long': longitude,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('session_id', sessionId)
            .eq('trainer_id', trainerId);
      } else {
        // Create new
        await _sqlService!.client.from('trainer_attendance').insert({
          'id': attendanceId,
          'session_id': sessionId,
          'trainer_id': trainerId,
          'check_in_time': checkInTime.toIso8601String(),
          if (latitude != null) 'check_in_lat': latitude,
          if (longitude != null) 'check_in_long': longitude,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return {
        'success': true,
        'message': 'Check-in thành công',
      };
    } catch (e) {
      print('Failed to check in trainer: $e');
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Check out trainer for a session
  Future<Map<String, dynamic>> checkOutTrainer({
    required String sessionId,
    required String trainerId,
    double? latitude,
    double? longitude,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final checkOutTime = DateTime.now();

      await _sqlService!.client
          .from('trainer_attendance')
          .update({
            'check_out_time': checkOutTime.toIso8601String(),
            if (latitude != null) 'check_out_lat': latitude,
            if (longitude != null) 'check_out_long': longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('session_id', sessionId)
          .eq('trainer_id', trainerId);

      return {
        'success': true,
        'message': 'Check-out thành công',
      };
    } catch (e) {
      print('Failed to check out trainer: $e');
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Get trainer attendance for a session
  Future<TrainerAttendanceModel?> getTrainerAttendance({
    required String sessionId,
    required String trainerId,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('trainer_attendance')
          .select()
          .eq('session_id', sessionId)
          .eq('trainer_id', trainerId)
          .maybeSingle();

      if (response == null) return null;
      return TrainerAttendanceModel.fromSupabase(response);
    } catch (e) {
      print('Failed to get trainer attendance: $e');
      return null;
    }
  }
}


