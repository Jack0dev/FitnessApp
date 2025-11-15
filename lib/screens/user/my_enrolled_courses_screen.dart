import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';
import 'user_course_detail_screen.dart';

class MyEnrolledCoursesScreen extends StatefulWidget {
  const MyEnrolledCoursesScreen({super.key});

  @override
  State<MyEnrolledCoursesScreen> createState() => _MyEnrolledCoursesScreenState();
}

class _MyEnrolledCoursesScreenState extends State<MyEnrolledCoursesScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _enrolledCourses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get user enrollments
      final enrollments = await _courseService.getUserEnrollments(user.id);
      
      // Get course details for each enrollment
      final List<Map<String, dynamic>> coursesData = [];
      for (final enrollment in enrollments) {
        final course = await _courseService.getCourseById(enrollment.courseId);
        if (course != null) {
          coursesData.add({
            'course': course,
            'enrollment': enrollment,
          });
        }
      }

      setState(() {
        _enrolledCourses = coursesData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Enrolled Courses'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEnrolledCourses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _enrolledCourses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No enrolled courses yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enroll in courses to start your fitness journey!',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEnrolledCourses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _enrolledCourses.length,
                        itemBuilder: (context, index) {
                          final data = _enrolledCourses[index];
                          final course = data['course'] as CourseModel;
                          final enrollment = data['enrollment'] as EnrollmentModel;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserCourseDetailScreen(
                                      course: course,
                                      enrollment: enrollment,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Course Image
                                    if (course.imageUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          course.imageUrl!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 150,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (course.imageUrl != null) const SizedBox(height: 12),

                                    // Course Title
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Course Description
                                    Text(
                                      course.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Course Info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoChip(
                                          icon: Icons.person,
                                          label: 'Instructor',
                                          value: course.instructorName ?? 'N/A',
                                        ),
                                        _buildInfoChip(
                                          icon: Icons.timer,
                                          label: 'Duration',
                                          value: '${course.duration} days',
                                        ),
                                        _buildInfoChip(
                                          icon: Icons.group,
                                          label: 'Students',
                                          value: '${course.currentStudents}/${course.maxStudents}',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Enrollment Status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
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
                                                size: 16,
                                                color: enrollment.paymentStatus == PaymentStatus.paid
                                                    ? Colors.green[800]
                                                    : Colors.orange[800],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                enrollment.paymentStatus == PaymentStatus.paid
                                                    ? 'Paid'
                                                    : 'Pending Payment',
                                                style: TextStyle(
                                                  color: enrollment.paymentStatus == PaymentStatus.paid
                                                      ? Colors.green[800]
                                                      : Colors.orange[800],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Enrolled: ${_formatDate(enrollment.enrolledAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

