import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/session_model.dart';
import '../../services/course/course_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/session/session_service.dart';
import '../../services/attendance/session_attendance_service.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'user_course_detail_screen.dart';

/// Màn hình xem lịch sử điểm danh cho user
class UserAttendanceScreen extends StatefulWidget {
  const UserAttendanceScreen({super.key});

  @override
  State<UserAttendanceScreen> createState() => _UserAttendanceScreenState();
}

class _UserAttendanceScreenState extends State<UserAttendanceScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  final _sessionService = SessionService();
  final _attendanceService = SessionAttendanceService();

  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = true;
  String? _error;
  CourseModel? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
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

      // Get all enrolled courses
      final enrollments = await _courseService.getUserEnrollments(user.id);
      final paidEnrollments = enrollments
          .where((e) => e.paymentStatus == PaymentStatus.paid)
          .toList();

      final List<Map<String, dynamic>> history = [];
      final Map<String, EnrollmentModel> enrollmentMap = {};
      for (final enrollment in paidEnrollments) {
        enrollmentMap[enrollment.courseId] = enrollment;
      }

      for (final enrollment in paidEnrollments) {
        final course = await _courseService.getCourseById(enrollment.courseId);
        if (course == null || course.instructorId == null) continue;

        // Get all sessions for this course's trainer
        final sessions = await _sessionService.getTrainerSessions(course.instructorId!);
        
        for (final session in sessions) {
          try {
            final attendanceList = await _attendanceService
                .getSessionAttendanceWithUsers(session.id);
            
            // Check if user attended this session
            final userAttendance = attendanceList.firstWhere(
              (a) => a['user']?['id'] == user.id,
              orElse: () => {},
            );

            if (userAttendance.isNotEmpty) {
              history.add({
                'course': course,
                'enrollment': enrollment,
                'session': session,
                'attendance': userAttendance,
                'checkInTime': userAttendance['attendance']?['check_in_time'],
              });
            }
          } catch (e) {
            // Skip if error loading attendance for this session
            continue;
          }
        }
      }

      // Sort by date (newest first)
      history.sort((a, b) {
        final aDate = (a['session'] as SessionModel).date;
        final bDate = (b['session'] as SessionModel).date;
        return bDate.compareTo(aDate);
      });

      setState(() {
        _attendanceHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    if (_selectedCourse == null) return _attendanceHistory;
    return _attendanceHistory
        .where((item) => (item['course'] as CourseModel).id == _selectedCourse!.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.translate('attendance'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorDisplayWidget(
                  message: _error!,
                  onRetry: _loadAttendanceHistory,
                )
              : Column(
                  children: [
                    // Course Filter
                    if (_attendanceHistory.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.spacingMD),
                        decoration: BoxDecoration(
                          color: DesignTokens.surfaceLight,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomDropdown<CourseModel>(
                          label: context.translate('filter_by_course'),
                          icon: Icons.filter_list,
                          value: _selectedCourse,
                          hint: context.translate('all_courses'),
                          items: [
                            DropdownMenuItem<CourseModel>(
                              value: null,
                              child: CustomText(
                                text: context.translate('all_courses'),
                                variant: TextVariant.bodyMedium,
                                color: DesignTokens.textPrimary,
                              ),
                            ),
                            ..._attendanceHistory
                                .map((item) => item['course'] as CourseModel)
                                .toSet()
                                .map((course) {
                              return DropdownMenuItem<CourseModel>(
                                value: course,
                                child: CustomText(
                                  text: course.title,
                                  variant: TextVariant.bodyMedium,
                                  color: DesignTokens.textPrimary,
                                ),
                              );
                            }),
                          ],
                          onChanged: (course) {
                            setState(() => _selectedCourse = course);
                          },
                        ),
                      ),
                    ],

                    // Attendance History
                    Expanded(
                      child: _attendanceHistory.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.event_busy,
                              title: context.translate('no_attendance_recorded'),
                              subtitle: context.translate('attendance_will_appear_here'),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAttendanceHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(DesignTokens.spacingLG),
                                itemCount: _getFilteredHistory().length,
                                itemBuilder: (context, index) {
                                  final item = _getFilteredHistory()[index];
                                  final course = item['course'] as CourseModel;
                                  final session = item['session'] as SessionModel;
                                  final checkInTime = item['checkInTime'] as DateTime?;

                                  return CustomCard(
                                    variant: CardVariant.white,
                                    margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
                                    child: InkWell(
                                      onTap: () {
                                        // Navigate to course detail
                                        final enrollment = item['enrollment'] as EnrollmentModel?;
                                        if (enrollment != null) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => UserCourseDetailScreen(
                                                course: course,
                                                enrollment: enrollment,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                                      child: Padding(
                                        padding: const EdgeInsets.all(DesignTokens.spacingMD),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(DesignTokens.spacingSM),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: DesignTokens.gradientSuccess,
                                                    ),
                                                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                                  ),
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: DesignTokens.spacingMD),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      CustomText(
                                                        text: session.title,
                                                        variant: TextVariant.titleMedium,
                                                        color: DesignTokens.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      const SizedBox(height: DesignTokens.spacingXS),
                                                      CustomText(
                                                        text: course.title,
                                                        variant: TextVariant.bodySmall,
                                                        color: DesignTokens.textSecondary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: DesignTokens.spacingMD),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: DesignTokens.textSecondary,
                                                ),
                                                const SizedBox(width: DesignTokens.spacingXS),
                                                CustomText(
                                                  text: _formatDate(session.date),
                                                  variant: TextVariant.bodySmall,
                                                  color: DesignTokens.textSecondary,
                                                ),
                                                const SizedBox(width: DesignTokens.spacingMD),
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: DesignTokens.textSecondary,
                                                ),
                                                const SizedBox(width: DesignTokens.spacingXS),
                                                CustomText(
                                                  text: '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                                                  variant: TextVariant.bodySmall,
                                                  color: DesignTokens.textSecondary,
                                                ),
                                              ],
                                            ),
                                            if (checkInTime != null) ...[
                                              const SizedBox(height: DesignTokens.spacingSM),
                                              Container(
                                                padding: const EdgeInsets.all(DesignTokens.spacingSM),
                                                decoration: BoxDecoration(
                                                  color: DesignTokens.success.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      size: 14,
                                                      color: DesignTokens.success,
                                                    ),
                                                    const SizedBox(width: DesignTokens.spacingXS),
                                                    CustomText(
                                                      text: '${context.translate('checked_in_at')}: ${_formatDateTime(checkInTime)}',
                                                      variant: TextVariant.bodySmall,
                                                      color: DesignTokens.success,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return context.translate('today');
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return context.translate('tomorrow');
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return context.translate('yesterday');
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
