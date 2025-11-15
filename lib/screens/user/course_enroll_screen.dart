import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../../services/lesson_service.dart';
import '../../widgets/loading_widget.dart';
import 'user_course_schedule_screen.dart';

class CourseEnrollScreen extends StatefulWidget {
  final CourseModel course;

  const CourseEnrollScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseEnrollScreen> createState() => _CourseEnrollScreenState();
}

class _CourseEnrollScreenState extends State<CourseEnrollScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isEnrolling = false;
  bool _showQRCode = false;
  String? _enrollmentId;
  String? _qrCodeData;
  Timer? _paymentCheckTimer;

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _enrollCourse() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to enroll in courses'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if user is already enrolled
    final isEnrolled = await _courseService.isUserEnrolled(user.id, widget.course.id);
    if (isEnrolled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already enrolled in this course'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if course is available
    if (!widget.course.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This course is not available for enrollment'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isEnrolling = true;
    });

    try {
      // Create enrollment with pending payment status
      final enrollmentId = await _courseService.enrollUser(
        userId: user.id,
        courseId: widget.course.id,
        amount: widget.course.price,
      );

      if (enrollmentId != null) {
        setState(() {
          _enrollmentId = enrollmentId;
          _qrCodeData = _generateQRCodeData(enrollmentId, user.id, widget.course.id, widget.course.price);
          _showQRCode = true;
          _isEnrolling = false;
        });

        // Start checking payment status
        _startPaymentCheckTimer(enrollmentId);
      } else {
        setState(() {
          _isEnrolling = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to enroll in course. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isEnrolling = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enrolling in course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateQRCodeData(String enrollmentId, String userId, String courseId, double amount) {
    // Generate QR code data with enrollment information
    // Format: JSON string with enrollment details
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

  void _startPaymentCheckTimer(String enrollmentId) {
    // Check payment status every 3 seconds
    _paymentCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final enrollments = await _courseService.getUserEnrollments(_authService.currentUser!.id);
        final enrollment = enrollments.firstWhere(
          (e) => e.id == enrollmentId,
          orElse: () => enrollments.isNotEmpty ? enrollments.first : throw Exception('Not found'),
        );

        if (enrollment.paymentStatus == PaymentStatus.paid) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _showQRCode = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! You are now enrolled in this course.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            // Refresh course data and navigate back
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.of(context).pop(true); // Return true to indicate success
              }
            });
          }
        } else if (enrollment.paymentStatus == PaymentStatus.failed) {
          timer.cancel();
          if (mounted) {
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
        }
      } catch (e) {
        print('Error checking payment status: $e');
      }
    });
  }

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
                    label: 'Instructor',
                    value: widget.course.instructorName ?? 'No instructor',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: '${widget.course.duration} days',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.people,
                    label: 'Students',
                    value: '${widget.course.currentStudents}/${widget.course.maxStudents}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.attach_money,
                    label: 'Price',
                    value: '\$${widget.course.price.toStringAsFixed(0)}',
                    valueColor: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.trending_up,
                    label: 'Level',
                    value: widget.course.level.displayName,
                    valueColor: _getLevelColor(widget.course.level),
                  ),
                  const SizedBox(height: 32),
                  
                  // View Schedule Button (for non-enrolled courses)
                  if (!_showQRCode)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showCourseSchedule(context);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('View Schedule'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (!_showQRCode) const SizedBox(height: 16),
                  
                  // QR Code for Payment
                  if (_showQRCode && _qrCodeData != null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Scan QR Code to Pay',
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
                            'Waiting for payment confirmation...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
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
                                onPressed: () async {
                                  // Simulate payment confirmation for testing
                                  // In production, this would be handled by payment gateway
                                  if (_enrollmentId != null) {
                                    final success = await _courseService.confirmPayment(
                                      enrollmentId: _enrollmentId!,
                                      transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
                                    );
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Payment confirmed (simulated). Check payment status...'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Simulate Payment'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // Enroll Button
                    SizedBox(
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
                    ),
                ],
              ),
            ),
    );
  }

  void _showCourseSchedule(BuildContext context) async {
    final lessonService = LessonService();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final lessons = await lessonService.getCourseLessons(widget.course.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (lessons.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No schedule available for this course yet'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // Create a dummy enrollment for viewing schedule (course info only, no payment status)
          final dummyEnrollment = EnrollmentModel(
            id: 'temp',
            userId: _authService.currentUser?.id ?? '',
            courseId: widget.course.id,
            paymentStatus: PaymentStatus.pending,
            enrolledAt: DateTime.now(),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserCourseScheduleScreen(
                course: widget.course,
                enrollment: dummyEnrollment,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

