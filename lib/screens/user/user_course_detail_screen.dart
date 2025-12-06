import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/auth/auth_service.dart';
import '../../services/course/course_service.dart';

import 'user_course_lessons_screen.dart';
import 'user_course_enroll_screen.dart';

class UserCourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  final EnrollmentModel enrollment;

  const UserCourseDetailScreen({
    super.key,
    required this.course,
    required this.enrollment,
  });

  @override
  State<UserCourseDetailScreen> createState() =>
      _UserCourseDetailScreenState();
}

class _UserCourseDetailScreenState extends State<UserCourseDetailScreen> {
  final _authService = AuthService();
  final _courseService = CourseService();

  bool _isLoading = false;
  late EnrollmentModel _enrollment; // trạng thái enrollment hiện tại

  @override
  void initState() {
    super.initState();
    _enrollment = widget.enrollment;
  }

  /// Reload lại enrollment của user cho khóa học này từ Supabase
  Future<void> _reloadEnrollment() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final enrollments = await _courseService.getUserEnrollments(user.id);
      final updated = enrollments.firstWhere(
            (e) => e.courseId == widget.course.id,
        orElse: () => _enrollment,
      );

      setState(() {
        _enrollment = updated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reloading enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mở màn hình thanh toán / enroll
  Future<void> _onCompletePaymentPressed() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UserCourseEnrollScreen(
          course: widget.course,
          existingEnrollmentId: _enrollment.id, // DÙNG ENROLLMENT HIỆN TẠI
        ),
      ),
    );

    // Nếu UserCourseEnrollScreen trả về true → giả định thanh toán thành công
    if (result == true) {
      await _reloadEnrollment();
    }
  }

  /// Mở danh sách bài học sau khi đã thanh toán
  void _onLessonsPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserCourseLessonsScreen(
          course: widget.course,
          enrollment: _enrollment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPaid = _enrollment.paymentStatus == PaymentStatus.paid;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('course_detail')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========= ẢNH KHÓA HỌC =========
            if (widget.course.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.course.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
            if (widget.course.imageUrl != null)
              const SizedBox(height: 16),

            // ========= TIÊU ĐỀ =========
            Text(
              widget.course.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ========= TRẠNG THÁI THANH TOÁN (BADGE) =========
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: hasPaid ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasPaid ? Icons.check_circle : Icons.pending,
                    size: 18,
                    color: hasPaid
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasPaid ? 'Payment Confirmed' : 'Pending Payment',
                    style: TextStyle(
                      color: hasPaid
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========= DESCRIPTION =========
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.course.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ========= COURSE DETAILS =========
            const Text(
              'Course Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.person,
              label: 'Instructor',
              value: widget.course.instructorName ?? 'N/A',
            ),
            _buildDetailRow(
              icon: Icons.timer,
              label: 'Thời lượng',
              value: '${widget.course.duration} days',
            ),
            _buildDetailRow(
              icon: Icons.group,
              label: 'Max Students',
              value: widget.course.maxStudents.toString(),
            ),
            _buildDetailRow(
              icon: Icons.people,
              label: 'Current Students',
              value: widget.course.currentStudents.toString(),
            ),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Giá',
              value: '\$${widget.course.price.toStringAsFixed(0)}',
              valueColor: Colors.green,
            ),
            _buildDetailRow(
              icon: Icons.trending_up,
              label: 'Cấp độ',
              value: widget.course.level.displayName,
              valueColor: _getLevelColor(widget.course.level),
            ),
            const SizedBox(height: 24),

            // ========= ENROLLMENT INFO =========
            const Text(
              'Enrollment Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Enrolled Date',
              value: _formatDate(_enrollment.enrolledAt),
            ),
            if (_enrollment.paymentAt != null)
              _buildDetailRow(
                icon: Icons.payment,
                label: 'Payment Date',
                value: _formatDate(_enrollment.paymentAt!),
              ),
            if (_enrollment.transactionId != null)
              _buildDetailRow(
                icon: Icons.receipt,
                label: 'Transaction ID',
                value: _enrollment.transactionId!,
              ),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Amount Paid',
              value:
              '\$${(_enrollment.amountPaid ?? 0).toStringAsFixed(0)}',
              valueColor: Colors.green,
            ),
            const SizedBox(height: 24),

            // ========= ACTION BUTTONS =========
            if (!hasPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onCompletePaymentPressed,
                  icon: const Icon(Icons.payment),
                  label: const Text('Complete Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onLessonsPressed,
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Bài học'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getLevelColor(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return Colors.green;
      case CourseLevel.intermediate:
        return Colors.orange;
      case CourseLevel.advanced:
        return Colors.red;
    }
  }
}
