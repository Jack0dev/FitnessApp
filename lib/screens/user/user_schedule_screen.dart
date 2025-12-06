import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course/course_service.dart';
import '../../services/course/lesson_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/loading_widget.dart';
import '../../core/localization/app_localizations.dart';
import 'user_course_schedule_screen.dart';

class UserScheduleScreen extends StatefulWidget {
  const UserScheduleScreen({super.key});

  @override
  State<UserScheduleScreen> createState() => _UserScheduleScreenState();
}

class _UserScheduleScreenState extends State<UserScheduleScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _enrolledCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _enrolledCourses = [];
        });
        return;
      }

      final enrollments = await _courseService.getUserEnrollments(user.id);
      final courses = <Map<String, dynamic>>[];

      for (final enrollment in enrollments) {
        if (enrollment.paymentStatus == PaymentStatus.paid) {
          final course = await _courseService.getCourseById(enrollment.courseId);
          if (course != null) {
            courses.add({
              'course': course,
              'enrollment': enrollment,
            });
          }
        }
      }

      setState(() {
        _enrolledCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _enrolledCourses = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('schedule')),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _enrolledCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No enrolled courses',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enroll in a course to see your schedule',
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
                      final course = _enrolledCourses[index]['course'] as CourseModel;
                      final enrollment = _enrolledCourses[index]['enrollment'] as EnrollmentModel;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            course.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(course.description),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserCourseScheduleScreen(
                                  course: course,
                                  enrollment: enrollment,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
