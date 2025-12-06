import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../common/sql_database_service.dart';
import '../../config/supabase_config.dart';
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
      throw Exception(
        'Supabase not initialized. CourseService requires Supabase.',
      );
    }
    _sqlService = SqlDatabaseService();
  }

  SupabaseClient get _client {
    if (_sqlService == null) {
      throw Exception(
        'Supabase not initialized. CourseService requires Supabase.',
      );
    }
    return _sqlService!.client;
  }

  // ======================================================================
  // ========== COURSE CRUD ===============================================
  // ======================================================================

  /// Get all courses
  Future<List<CourseModel>> getAllCourses() async {
    try {
      final response = await _client
          .from('course')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((doc) => CourseModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('❌ [CourseService] Failed to get all courses: $e');
      return [];
    }
  }

  /// Get course by ID
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final response = await _client
          .from('course')
          .select()
          .eq('id', courseId)
          .single();

      return CourseModel.fromSupabase(response);
    } catch (e) {
      print('❌ [CourseService] Failed to get course: $e');
      return null;
    }
  }

  /// Create course
  Future<String?> createCourse(CourseModel course) async {
    try {
      final data = course.toSupabase();

      // Generate simple text id nếu chưa có
      if (data['id'] == null || (data['id'] as String).isEmpty) {
        data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final response =
      await _client.from('course').insert(data).select().single();
      return response['id'] as String;
    } catch (e) {
      print('❌ [CourseService] Failed to create course: $e');
      return null;
    }
  }

  /// Update course
  Future<bool> updateCourse(CourseModel course) async {
    try {
      await _client
          .from('course')
          .update(course.toSupabase())
          .eq('id', course.id);
      return true;
    } catch (e) {
      print('❌ [CourseService] Failed to update course: $e');
      return false;
    }
  }

  /// Delete course
  Future<bool> deleteCourse(String courseId) async {
    try {
      await _client.from('course').delete().eq('id', courseId);
      return true;
    } catch (e) {
      print('❌ [CourseService] Failed to delete course: $e');
      return false;
    }
  }

  /// Get courses by instructor (PT)
  Future<List<CourseModel>> getCoursesByInstructor(
      String instructorId,
      ) async {
    final allCourses = await getAllCourses();
    return allCourses
        .where((course) => course.instructorId == instructorId)
        .toList();
  }

  // ======================================================================
  // ========== ENROLLMENT ================================================
  // ======================================================================

  /// Enroll user in course (tạo enrollment ở trạng thái pending)
  Future<String?> enrollUser({
    required String userId,
    required String courseId,
    required double amount,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final enrollment = EnrollmentModel(
      id: id,
      userId: userId,
      courseId: courseId,
      paymentStatus: PaymentStatus.pending,
      enrolledAt: DateTime.now(),
      // có thể để null nếu bạn muốn chỉ set amount_paid khi đã thanh toán xong
      amountPaid: amount,
    );

    try {
      final response = await _client
          .from('enrollment')
          .insert(enrollment.toSupabase())
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      print('❌ [CourseService] Failed to enroll user: $e');
      return null;
    }
  }

  /// Get user enrollments
  Future<List<EnrollmentModel>> getUserEnrollments(String userId) async {
    try {
      final response = await _client
          .from('enrollment')
          .select()
          .eq('user_id', userId)
          .order('enrolled_at', ascending: false);

      return (response as List)
          .map((doc) => EnrollmentModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('❌ [CourseService] Failed to get user enrollments: $e');
      return [];
    }
  }

  /// Get course enrollments
  Future<List<EnrollmentModel>> getCourseEnrollments(String courseId) async {
    try {
      final response = await _client
          .from('enrollment')
          .select()
          .eq('course_id', courseId)
          .order('enrolled_at', ascending: false);

      return (response as List)
          .map((doc) => EnrollmentModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('❌ [CourseService] Failed to get course enrollments: $e');
      return [];
    }
  }

  // ======================================================================
  // ========== COURSE MEMBERS (BẢNG course_member) =======================
  // ======================================================================

  /// Thêm / cập nhật course_member khi user đã thanh toán thành công
  Future<bool> _addCourseMember({
    required String courseId,
    required String userId,
    required String enrollmentId,
  }) async {
    try {
      final memberId = DateTime.now().millisecondsSinceEpoch.toString();

      await _client.from('course_member').upsert(
        {
          'id': memberId,
          'course_id': courseId,
          'user_id': userId,
          'enrollment_id': enrollmentId,
          'status': 'active',
          'joined_at': DateTime.now().toIso8601String(),
        },
        // unique constraint: (course_id, user_id)
        onConflict: 'course_id,user_id',
      );

      print(
        '✅ [CourseService] course_member upserted for user $userId in course $courseId',
      );
      return true;
    } catch (e) {
      print('❌ [CourseService] Failed to upsert course_member: $e');
      return false;
    }
  }

  /// Lấy danh sách member của 1 khóa học (nếu sau này cần dùng UI)
  Future<List<Map<String, dynamic>>> getCourseMembers(String courseId) async {
    try {
      final response = await _client
          .from('course_member')
          .select()
          .eq('course_id', courseId)
          .eq('status', 'active')
          .order('joined_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ [CourseService] Failed to get course members: $e');
      return [];
    }
  }

  // ======================================================================
  // ========== PAYMENT STATUS & CONFIRMATION =============================
  // ======================================================================

  /// Update payment status (có kèm logic tăng/giảm current_students + thêm course_member)
  Future<bool> updatePaymentStatus({
    required String enrollmentId,
    required PaymentStatus status,
    String? transactionId,
  }) async {
    try {
      // Lấy info enrollment hiện tại
      final enrollmentResponse = await _client
          .from('enrollment')
          .select('course_id, user_id, payment_status')
          .eq('id', enrollmentId)
          .single();

      final courseId = enrollmentResponse['course_id'] as String;
      final userId = enrollmentResponse['user_id'] as String;
      final oldPaymentStatus = enrollmentResponse['payment_status'] as String?;

      print('🔄 [CourseService] updatePaymentStatus for enrollment: $enrollmentId');
      print('   Course ID: $courseId');
      print('   User ID: $userId');
      print('   Old status: $oldPaymentStatus → New: ${status.value}');

      // Cập nhật trạng thái thanh toán
      await _client.from('enrollment').update({
        'payment_status': status.value,
        'payment_at': DateTime.now().toIso8601String(),
        if (transactionId != null) 'transaction_id': transactionId,
      }).eq('id', enrollmentId);

      // Nếu status không đổi thì thôi
      if (oldPaymentStatus == status.value) {
        print('ℹ️ [CourseService] Payment status unchanged. Nothing more to do.');
        return true;
      }

      // Lấy thông tin course
      final courseResponse = await _client
          .from('course')
          .select('current_students, max_students')
          .eq('id', courseId)
          .single();

      final currentStudents = courseResponse['current_students'] as int? ?? 0;
      final maxStudents = courseResponse['max_students'] as int? ?? 0;

      // từ non-paid → paid: tăng current_students + thêm course_member
      if (status == PaymentStatus.paid &&
          oldPaymentStatus != PaymentStatus.paid.value) {
        // Cập nhật current_students
        if (currentStudents < maxStudents) {
          await _client.from('course').update({
            'current_students': currentStudents + 1,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', courseId);
          print(
            '✅ [CourseService] Incremented current_students for course: $courseId',
          );
        } else {
          print(
            '⚠️ [CourseService] Course $courseId is already at max capacity ($maxStudents)',
          );
        }

        // Thêm / update course_member
        await _addCourseMember(
          courseId: courseId,
          userId: userId,
          enrollmentId: enrollmentId,
        );
      }
      // từ paid → failed/refunded: giảm current_students
      else if (oldPaymentStatus == PaymentStatus.paid.value &&
          (status == PaymentStatus.failed ||
              status == PaymentStatus.refunded)) {
        if (currentStudents > 0) {
          await _client.from('course').update({
            'current_students': currentStudents - 1,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', courseId);
          print(
            '✅ [CourseService] Decremented current_students for course: $courseId',
          );
        }
      }

      return true;
    } catch (e) {
      print('❌ [CourseService] Failed to update payment status: $e');
      return false;
    }
  }

  /// Check if user is *member* of course (đã thanh toán, đang active)
  Future<bool> isUserEnrolled(String userId, String courseId) async {
    try {
      final response = await _client
          .from('course_member')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .eq('status', 'active')
          .limit(1);

      final list = response as List;
      final isMember = list.isNotEmpty;
      print(
        'ℹ️ [CourseService] isUserEnrolled(user: $userId, course: $courseId) = $isMember',
      );
      return isMember;
    } catch (e) {
      print('❌ [CourseService] Failed to check isUserEnrolled: $e');
      return false;
    }
  }

  /// Confirm payment cho 1 enrollment (dùng khi gateway báo thanh toán thành công)
  /// - Set payment_status = paid
  /// - Set payment_at, transaction_id
  /// - Tăng current_students nếu trước đó chưa paid
  /// - Thêm vào bảng course_member
  Future<bool> confirmPayment({
    required String enrollmentId,
    required String transactionId,
  }) async {
    try {
      final success = await updatePaymentStatus(
        enrollmentId: enrollmentId,
        status: PaymentStatus.paid,
        transactionId: transactionId,
      );

      if (success) {
        print(
          '✅ [CourseService] confirmPayment completed for enrollment: $enrollmentId',
        );
      } else {
        print(
          '❌ [CourseService] confirmPayment failed for enrollment: $enrollmentId',
        );
      }

      return success;
    } catch (e) {
      print('❌ [CourseService] Failed to confirm payment: $e');
      return false;
    }
  }
}
