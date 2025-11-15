import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import 'user_course_lessons_screen.dart';
import 'user_course_schedule_screen.dart';

class UserCourseDetailScreen extends StatelessWidget {
  final CourseModel course;
  final EnrollmentModel enrollment;

  const UserCourseDetailScreen({
    super.key,
    required this.course,
    required this.enrollment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            if (course.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  course.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
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
            if (course.imageUrl != null) const SizedBox(height: 16),

            // Course Title
            Text(
              course.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Enrollment Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: enrollment.paymentStatus == PaymentStatus.paid
                    ? Colors.green[100]
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    enrollment.paymentStatus == PaymentStatus.paid
                        ? Icons.check_circle
                        : Icons.pending,
                    size: 18,
                    color: enrollment.paymentStatus == PaymentStatus.paid
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    enrollment.paymentStatus == PaymentStatus.paid
                        ? 'Payment Confirmed'
                        : 'Pending Payment',
                    style: TextStyle(
                      color: enrollment.paymentStatus == PaymentStatus.paid
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

            // Course Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Course Details
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
              value: course.instructorName ?? 'N/A',
            ),
            _buildDetailRow(
              icon: Icons.timer,
              label: 'Duration',
              value: '${course.duration} days',
            ),
            _buildDetailRow(
              icon: Icons.group,
              label: 'Max Students',
              value: course.maxStudents.toString(),
            ),
            _buildDetailRow(
              icon: Icons.people,
              label: 'Current Students',
              value: course.currentStudents.toString(),
            ),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Price',
              value: '\$${course.price.toStringAsFixed(0)}',
              valueColor: Colors.green,
            ),
            _buildDetailRow(
              icon: Icons.trending_up,
              label: 'Level',
              value: course.level.displayName,
              valueColor: _getLevelColor(course.level),
            ),
            const SizedBox(height: 24),

            // Enrollment Information
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
              value: _formatDate(enrollment.enrolledAt),
            ),
            if (enrollment.paymentAt != null)
              _buildDetailRow(
                icon: Icons.payment,
                label: 'Payment Date',
                value: _formatDate(enrollment.paymentAt!),
              ),
            if (enrollment.transactionId != null)
              _buildDetailRow(
                icon: Icons.receipt,
                label: 'Transaction ID',
                value: enrollment.transactionId!,
              ),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Amount Paid',
              value: '\$${(enrollment.amountPaid ?? 0).toStringAsFixed(0)}',
              valueColor: Colors.green,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (enrollment.paymentStatus != PaymentStatus.paid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please complete payment to access course content'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
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
            if (enrollment.paymentStatus == PaymentStatus.paid) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserCourseLessonsScreen(
                              course: course,
                              enrollment: enrollment,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('View Documents'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserCourseScheduleScreen(
                              course: course,
                              enrollment: enrollment,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('View Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

