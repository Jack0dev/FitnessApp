import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import 'sql_database_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing courses using Supabase only
class CourseService {
  SqlDatabaseService? _sqlService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  CourseService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  // ========== COURSE CRUD ==========

  /// Get all courses
  Future<List<CourseModel>> getAllCourses() async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('courses')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((doc) => CourseModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get all courses: $e');
      return [];
    }
  }

  /// Get course by ID
  Future<CourseModel?> getCourseById(String courseId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('courses')
          .select()
          .eq('id', courseId)
          .single();
      return CourseModel.fromSupabase(response);
    } catch (e) {
      print('Failed to get course: $e');
      return null;
    }
  }

  /// Create course
  Future<String?> createCourse(CourseModel course) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      // Generate UUID if id is empty
      final courseData = course.toSupabase();
      if (courseData['id'] == null || (courseData['id'] as String).isEmpty) {
        courseData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final response = await _sqlService!.client
          .from('courses')
          .insert(courseData)
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      print('Failed to create course: $e');
      return null;
    }
  }

  /// Update course
  Future<bool> updateCourse(CourseModel course) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      await _sqlService!.client
          .from('courses')
          .update(course.toSupabase())
          .eq('id', course.id);
      return true;
    } catch (e) {
      print('Failed to update course: $e');
      return false;
    }
  }

  /// Delete course
  Future<bool> deleteCourse(String courseId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      await _sqlService!.client
          .from('courses')
          .delete()
          .eq('id', courseId);
      return true;
    } catch (e) {
      print('Failed to delete course: $e');
      return false;
    }
  }

  /// Get courses by instructor (PT)
  Future<List<CourseModel>> getCoursesByInstructor(String instructorId) async {
    final allCourses = await getAllCourses();
    return allCourses
        .where((course) => course.instructorId == instructorId)
        .toList();
  }

  // ========== ENROLLMENT ==========

  /// Enroll user in course
  Future<String?> enrollUser({
    required String userId,
    required String courseId,
    required double amount,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    final enrollment = EnrollmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID
      userId: userId,
      courseId: courseId,
      paymentStatus: PaymentStatus.pending,
      enrolledAt: DateTime.now(),
      amountPaid: amount,
    );

    try {
      final response = await _sqlService!.client
          .from('enrollments')
          .insert(enrollment.toSupabase())
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      print('Failed to enroll user: $e');
      return null;
    }
  }

  /// Get user enrollments
  Future<List<EnrollmentModel>> getUserEnrollments(String userId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('enrollments')
          .select()
          .eq('user_id', userId)
          .order('enrolled_at', ascending: false);
      return (response as List)
          .map((doc) => EnrollmentModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get user enrollments: $e');
      return [];
    }
  }

  /// Get course enrollments
  Future<List<EnrollmentModel>> getCourseEnrollments(String courseId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('enrollments')
          .select()
          .eq('course_id', courseId)
          .order('enrolled_at', ascending: false);
      return (response as List)
          .map((doc) => EnrollmentModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get course enrollments: $e');
      return [];
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus({
    required String enrollmentId,
    required PaymentStatus status,
    String? transactionId,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      await _sqlService!.client
          .from('enrollments')
          .update({
            'payment_status': status.value,
            'payment_at': DateTime.now().toIso8601String(),
            if (transactionId != null) 'transaction_id': transactionId,
          })
          .eq('id', enrollmentId);
      return true;
    } catch (e) {
      print('Failed to update payment status: $e');
      return false;
    }
  }

  /// Check if user is enrolled
  Future<bool> isUserEnrolled(String userId, String courseId) async {
    final enrollments = await getUserEnrollments(userId);
    return enrollments.any((e) => e.courseId == courseId);
  }

  /// Confirm payment for enrollment (called after QR payment is successful)
  /// This will trigger the database trigger to update enrollment and course status
  Future<bool> confirmPayment({
    required String enrollmentId,
    required String transactionId,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. CourseService requires Supabase.');
    }

    try {
      // Get enrollment info first to get course_id
      final enrollmentResponse = await _sqlService!.client
          .from('enrollments')
          .select('course_id, payment_status')
          .eq('id', enrollmentId)
          .single();
      
      final courseId = enrollmentResponse['course_id'] as String;
      final oldPaymentStatus = enrollmentResponse['payment_status'] as String?;
      
      print('🔄 [CourseService] Updating payment status for enrollment: $enrollmentId');
      print('   Course ID: $courseId');
      print('   Old payment status: $oldPaymentStatus');
      
      // Get course info before update to check current_students
      final courseBeforeResponse = await _sqlService!.client
          .from('courses')
          .select('current_students, max_students')
          .eq('id', courseId)
          .single();
      final currentStudentsBefore = courseBeforeResponse['current_students'] as int? ?? 0;
      
      print('   Current students before: $currentStudentsBefore');

      // Update payment status to paid
      // This will trigger the database trigger to:
      // 1. Update enrollment payment_status = 'paid'
      // 2. Increment course current_students
      // 3. Update user enrollment information
      await _sqlService!.client
          .from('enrollments')
          .update({
            'payment_status': PaymentStatus.paid.value,
            'payment_at': DateTime.now().toIso8601String(),
            'transaction_id': transactionId,
          })
          .eq('id', enrollmentId);
      
      print('✅ [CourseService] Payment status updated to paid for enrollment: $enrollmentId');
      
      // Wait a bit for trigger to execute, then verify
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify trigger executed by checking course current_students
      final courseAfterResponse = await _sqlService!.client
          .from('courses')
          .select('current_students')
          .eq('id', courseId)
          .single();
      final currentStudentsAfter = courseAfterResponse['current_students'] as int? ?? 0;
      
      print('   Current students after: $currentStudentsAfter');
      
      if (oldPaymentStatus != 'paid' && currentStudentsAfter == currentStudentsBefore + 1) {
        print('✅ [CourseService] Trigger executed successfully! Course students incremented.');
      } else if (oldPaymentStatus == 'paid') {
        print('⚠️ [CourseService] Payment was already paid. No change to student count.');
      } else {
        print('⚠️ [CourseService] Trigger may not have executed. Expected: ${currentStudentsBefore + 1}, Got: $currentStudentsAfter');
      }
      
      return true;
    } catch (e) {
      print('❌ [CourseService] Failed to confirm payment: $e');
      return false;
    }
  }
}

