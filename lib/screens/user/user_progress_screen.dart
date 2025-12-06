import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course/course_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/course/lesson_service.dart';
import '../../services/session/session_service.dart';
import '../../services/attendance/session_attendance_service.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'user_course_detail_screen.dart';

/// Màn hình xem tiến độ học tập cho user
class UserProgressScreen extends StatefulWidget {
  const UserProgressScreen({super.key});

  @override
  State<UserProgressScreen> createState() => _UserProgressScreenState();
}

class _UserProgressScreenState extends State<UserProgressScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  final _lessonService = LessonService();
  final _sessionService = SessionService();
  final _attendanceService = SessionAttendanceService();

  List<Map<String, dynamic>> _progressData = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final enrollments = await _courseService.getUserEnrollments(user.id);
      final paidEnrollments = enrollments
          .where((e) => e.paymentStatus == PaymentStatus.paid)
          .toList();

      final List<Map<String, dynamic>> progress = [];

      for (final enrollment in paidEnrollments) {
        final course = await _courseService.getCourseById(enrollment.courseId);
        if (course == null) continue;

        final lessons = await _lessonService.getCourseLessons(course.id);
        
        // Calculate attendance if course has trainer
        int totalSessions = 0;
        int attendedSessions = 0;
        
        if (course.instructorId != null) {
          try {
            final sessions = await _sessionService.getTrainerSessions(course.instructorId!);
            totalSessions = sessions.length;
            
            for (final session in sessions) {
              try {
                final attendanceList = await _attendanceService
                    .getSessionAttendanceWithUsers(session.id);
                final userAttended = attendanceList.any(
                  (a) => a['user']?['id'] == user.id,
                );
                if (userAttended) attendedSessions++;
              } catch (_) {
                continue;
              }
            }
          } catch (_) {
            // Skip if error
          }
        }

        // Note: CourseLessonModel doesn't have scheduledDate
        // For now, consider all lessons as available (not completed)
        // TODO: Integrate with session service to track lesson completion
        final completedLessons = 0;

        progress.add({
          'course': course,
          'enrollment': enrollment,
          'totalLessons': lessons.length,
          'completedLessons': completedLessons,
          'totalSessions': totalSessions,
          'attendedSessions': attendedSessions,
        });
      }

      setState(() {
        _progressData = progress;
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
      appBar: CustomAppBar(
        title: context.translate('progress'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorDisplayWidget(
                  message: _error!,
                  onRetry: _loadProgress,
                )
              : _progressData.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.trending_up,
                      title: context.translate('no_progress_data'),
                      subtitle: context.translate('enroll_course_to_track_progress'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProgress,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(DesignTokens.spacingLG),
                        itemCount: _progressData.length,
                        itemBuilder: (context, index) {
                          final data = _progressData[index];
                          final course = data['course'] as CourseModel;
                          final enrollment = data['enrollment'] as EnrollmentModel;
                          final totalLessons = data['totalLessons'] as int;
                          final completedLessons = data['completedLessons'] as int;
                          final totalSessions = data['totalSessions'] as int;
                          final attendedSessions = data['attendedSessions'] as int;

                          final lessonProgress = totalLessons > 0 
                              ? (completedLessons / totalLessons * 100).round()
                              : 0;
                          final attendanceProgress = totalSessions > 0
                              ? (attendedSessions / totalSessions * 100).round()
                              : 0;

                          return CustomCard(
                            variant: CardVariant.white,
                            margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
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
                              borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                              child: Padding(
                                padding: const EdgeInsets.all(DesignTokens.spacingMD),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: course.title,
                                      variant: TextVariant.titleLarge,
                                      color: DesignTokens.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const SizedBox(height: DesignTokens.spacingLG),
                                    
                                    // Lessons Progress
                                    _buildProgressItem(
                                      icon: Icons.book,
                                      label: context.translate('lessons'),
                                      current: completedLessons,
                                      total: totalLessons,
                                      progress: lessonProgress,
                                      color: DesignTokens.info,
                                    ),
                                    
                                    const SizedBox(height: DesignTokens.spacingMD),
                                    
                                    // Attendance Progress
                                    if (totalSessions > 0)
                                      _buildProgressItem(
                                        icon: Icons.check_circle,
                                        label: context.translate('attendance'),
                                        current: attendedSessions,
                                        total: totalSessions,
                                        progress: attendanceProgress,
                                        color: DesignTokens.success,
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

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required int current,
    required int total,
    required int progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: DesignTokens.spacingXS),
                CustomText(
                  text: label,
                  variant: TextVariant.bodyMedium,
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            CustomText(
              text: '$current/$total ($progress%)',
              variant: TextVariant.bodyMedium,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
