import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/auth/auth_service.dart';
import '../../services/course/course_service.dart';
import '../../widgets/loading_widget.dart';

class UserCourseEnrollScreen extends StatefulWidget {
  final CourseModel course;

  /// Nếu khác null nghĩa là đã có enrollment trước đó (pending / failed)
  /// → màn này chỉ dùng để thanh toán cho enrollment đó.
  final String? existingEnrollmentId;

  const UserCourseEnrollScreen({
    super.key,
    required this.course,
    this.existingEnrollmentId,
  });

  @override
  State<UserCourseEnrollScreen> createState() =>
      _UserCourseEnrollScreenState();
}

class _UserCourseEnrollScreenState extends State<UserCourseEnrollScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isEnrolling = false;
  bool _showQRCode = false;

  String? _enrollmentId;
  String? _qrCodeData;
  Timer? _paymentCheckTimer;

  @override
  void initState() {
    super.initState();

    // Nếu được gọi từ "Complete Payment" → load enrollment cũ
    if (widget.existingEnrollmentId != null) {
      _initWithExistingEnrollment();
    }
  }

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    super.dispose();
  }

  // =========================================================
  // INIT WITH EXISTING ENROLLMENT (từ nút Complete Payment)
  // =========================================================
  Future<void> _initWithExistingEnrollment() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final enrollments = await _courseService.getUserEnrollments(user.id);

      EnrollmentModel? existing;
      try {
        existing = enrollments.firstWhere(
              (e) => e.id == widget.existingEnrollmentId,
        );
      } catch (_) {
        existing = null;
      }

      if (existing == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot find enrollment for this course'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (existing.paymentStatus == PaymentStatus.paid) {
        // Đã thanh toán rồi thì không cần hiện QR nữa
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already enrolled in this course'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isLoading = false);
        // Đóng màn luôn
        Navigator.of(context).pop(true);
        return;
      }

      // Pending / Failed → tạo QR cho enrollment này
      setState(() {
        _enrollmentId = existing!.id;
        _qrCodeData = _generateQRCodeData(
          existing.id,
          existing.userId,
          existing.courseId,
          existing.amountPaid ?? widget.course.price,
        );
        _showQRCode = true;
        _isLoading = false;
      });

      _startPaymentCheckTimer(existing.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading existing enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // ENROLL COURSE (trường hợp CHƯA có enrollment)
  // =========================================================
  Future<void> _enrollCourse() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to enroll in courses'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Không dùng isUserEnrolled nữa, tự check chi tiết
    setState(() {
      _isEnrolling = true;
    });

    try {
      final enrollments = await _courseService.getUserEnrollments(user.id);

      EnrollmentModel? existing;
      if (enrollments.isNotEmpty) {
        try {
          existing = enrollments.firstWhere(
                (e) => e.courseId == widget.course.id,
          );
        } catch (_) {
          existing = null;
        }
      }

      if (existing != null) {
        // Đã có enrollment cho course này
        if (existing.paymentStatus == PaymentStatus.paid) {
          // Đã thanh toán
          if (!mounted) return;
          setState(() {
            _isEnrolling = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already enrolled in this course'),
              backgroundColor: Colors.orange,
            ),
          );
          // Đóng màn, báo success luôn
          Navigator.of(context).pop(true);
          return;
        } else {
          // Pending / Failed → dùng lại enrollment cũ
          setState(() {
            _enrollmentId = existing!.id;
            _qrCodeData = _generateQRCodeData(
              existing.id,
              existing.userId,
              existing.courseId,
              existing.amountPaid ?? widget.course.price,
            );
            _showQRCode = true;
            _isEnrolling = false;
          });

          _startPaymentCheckTimer(existing.id);
          return;
        }
      }

      // Chưa có enrollment → tạo mới
      if (!widget.course.isAvailable) {
        if (!mounted) return;
        setState(() {
          _isEnrolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This course is not available for enrollment'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final enrollmentId = await _courseService.enrollUser(
        userId: user.id,
        courseId: widget.course.id,
        amount: widget.course.price,
      );

      if (enrollmentId != null) {
        setState(() {
          _enrollmentId = enrollmentId;
          _qrCodeData = _generateQRCodeData(
            enrollmentId,
            user.id,
            widget.course.id,
            widget.course.price,
          );
          _showQRCode = true;
          _isEnrolling = false;
        });

        _startPaymentCheckTimer(enrollmentId);
      } else {
        setState(() {
          _isEnrolling = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to enroll in course. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isEnrolling = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enrolling in course: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // QR DATA
  // =========================================================
  String _generateQRCodeData(
      String enrollmentId,
      String userId,
      String courseId,
      double amount,
      ) {
    final data = {
      'enrollment_id': enrollmentId,
      'user_id': userId,
      'course_id': courseId,
      'amount': amount,
      'course_title': widget.course.title,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'course_enrollment_payment',
    };
    return jsonEncode(data);
  }

  // =========================================================
  // AUTO POLL PAYMENT STATUS
  // =========================================================
  void _startPaymentCheckTimer(String enrollmentId) {
    _paymentCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
          try {
            final user = _authService.currentUser;
            if (user == null) return;

            final enrollments = await _courseService.getUserEnrollments(user.id);

            final enrollment = enrollments.firstWhere(
                  (e) => e.id == enrollmentId,
              orElse: () => enrollments.isNotEmpty
                  ? enrollments.first
                  : throw Exception('Not found'),
            );

            if (enrollment.paymentStatus == PaymentStatus.paid) {
              timer.cancel();
              if (!mounted) return;
              setState(() {
                _showQRCode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Payment successful! You are now enrolled in this course.',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              });
            } else if (enrollment.paymentStatus == PaymentStatus.failed) {
              timer.cancel();
              if (!mounted) return;
              setState(() {
                _showQRCode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (_) {
            // only log if needed
          }
        });
  }

  // =========================================================
  // MANUAL CHECK PAYMENT STATUS
  // =========================================================
  Future<void> _checkPaymentStatusManually() async {
    final user = _authService.currentUser;
    if (user == null || _enrollmentId == null) return;

    try {
      final enrollments = await _courseService.getUserEnrollments(user.id);
      final enrollment = enrollments.firstWhere(
            (e) => e.id == _enrollmentId,
        orElse: () => enrollments.isNotEmpty
            ? enrollments.first
            : throw Exception('Not found'),
      );

      if (enrollment.paymentStatus == PaymentStatus.paid) {
        if (!mounted) return;
        setState(() {
          _showQRCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment successful! You are now enrolled in this course.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else if (enrollment.paymentStatus == PaymentStatus.failed) {
        if (!mounted) return;
        setState(() {
          _showQRCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment is still pending. Please wait a moment and try again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking payment status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // SIMULATE PAYMENT (DEMO, KHÔNG DÙNG MOMO)
  // =========================================================
  Future<void> _simulatePaymentComplete() async {
    if (_enrollmentId == null) return;

    final success = await _courseService.confirmPayment(
      enrollmentId: _enrollmentId!,
      transactionId: 'SIMULATED-${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed (demo). Checking status...'),
          backgroundColor: Colors.blue,
        ),
      );
      await _checkPaymentStatusManually();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm payment (demo).'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            if (widget.course.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.course.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 24),

            // Course Details
            Text(
              widget.course.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.course.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),

            // Course Info
            _InfoRow(
              icon: Icons.person,
              label: 'Giảng viên',
              value: widget.course.instructorName ?? 'Không có giảng viên',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.access_time,
              label: 'Thời lượng',
              value: '${widget.course.duration} ngày',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.people,
              label: 'Học viên',
              value:
              '${widget.course.currentStudents}/${widget.course.maxStudents}',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.attach_money,
              label: 'Giá',
              value: '\$${widget.course.price.toStringAsFixed(0)}',
              valueColor: Colors.green,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.trending_up,
              label: 'Cấp độ',
              value: widget.course.level.displayName,
              valueColor: _getLevelColor(widget.course.level),
            ),
            const SizedBox(height: 32),

            // PAYMENT UI
            if (_showQRCode && _qrCodeData != null)
              _buildPaymentSection()
            else
              _buildEnrollButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            'Thanh toán khóa học',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          QrImageView(
            data: _qrCodeData!,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),

          Text(
            'Amount: \$${widget.course.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Scan QR to pay (in real integration) or use the demo button below.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          if (_enrollmentId != null)
            Text(
              'Enrollment ID: ${_enrollmentId!.substring(0, _enrollmentId!.length > 12 ? 12 : _enrollmentId!.length)}...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showQRCode = false;
                    _paymentCheckTimer?.cancel();
                  });
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: _simulatePaymentComplete,
                icon: const Icon(Icons.check_circle),
                label: const Text('Hoàn tất thanh toán (demo)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              onPressed: _checkPaymentStatusManually,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Tôi đã thanh toán xong, kiểm tra trạng thái',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isEnrolling ? null : _enrollCourse,
        icon: _isEnrolling
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.payment),
        label: Text(_isEnrolling ? 'Processing...' : 'Enroll & Pay'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
