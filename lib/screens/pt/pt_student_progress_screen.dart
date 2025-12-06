import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/course_model.dart';
import '../../models/user_model.dart';
import '../../models/course_lesson_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course/lesson_service.dart';
import '../../services/attendance/session_attendance_service.dart';
import '../../services/session/session_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';

/// Screen for PT to view student progress in a course
class PTStudentProgressScreen extends StatefulWidget {
  final UserModel student;
  final CourseModel course;
  final EnrollmentModel enrollment;

  const PTStudentProgressScreen({
    super.key,
    required this.student,
    required this.course,
    required this.enrollment,
  });

  @override
  State<PTStudentProgressScreen> createState() =>
      _PTStudentProgressScreenState();
}

class _PTStudentProgressScreenState
    extends State<PTStudentProgressScreen> {
  final _lessonService = LessonService();
  final _attendanceService = SessionAttendanceService();
  final _sessionService = SessionService();

  List<CourseLessonModel> _lessons = [];
  int _totalSessions = 0;
  int _attendedSessions = 0;
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
      final results = await Future.wait([
        _lessonService.getCourseLessons(widget.course.id),
        _loadAttendanceStats(),
      ]);

      final lessons = results[0] as List<CourseLessonModel>;
      final attendanceStats =
      results[1] as Map<String, int>;

      setState(() {
        _lessons = lessons;
        _totalSessions = attendanceStats['total'] ?? 0;
        _attendedSessions = attendanceStats['attended'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>> _loadAttendanceStats() async {
    try {
      final trainerId = widget.course.instructorId;
      if (trainerId == null) {
        return {'total': 0, 'attended': 0};
      }

      final sessions =
      await _sessionService.getTrainerSessions(trainerId);
      final totalSessions = sessions.length;

      int attendedCount = 0;
      for (final session in sessions) {
        try {
          final attendance = await _attendanceService
              .getSessionAttendanceWithUsers(session.id);
          final studentAttended =
          attendance.any((a) => a['user']?['id'] ==
              widget.student.uid); // dùng uid
          if (studentAttended) {
            attendedCount++;
          }
        } catch (_) {
          // bỏ qua nếu lỗi từng session
        }
      }

      return {
        'total': totalSessions,
        'attended': attendedCount,
      };
    } catch (e) {
      return {'total': 0, 'attended': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: const CustomAppBar(
        title: 'Tiến độ học tập',
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? _buildErrorWidget()
          : RefreshIndicator(
        onRefresh: _loadProgress,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(
              DesignTokens.spacingMD),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildStudentInfoCard(),
              const SizedBox(
                  height: DesignTokens.spacingMD),
              _buildCourseInfoCard(),
              const SizedBox(
                  height: DesignTokens.spacingMD),
              _buildProgressOverview(),
              const SizedBox(
                  height: DesignTokens.spacingMD),
              _buildAttendanceStats(),
              const SizedBox(
                  height: DesignTokens.spacingMD),
              _buildLessonsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return ErrorDisplayWidget(
      title: 'Không thể tải dữ liệu',
      message: _error ?? 'Đã xảy ra lỗi không xác định',
      onRetry: _loadProgress,
    );
  }

  Widget _buildStudentInfoCard() {
    return CustomCard(
      variant: CardVariant.white,
      child: Padding(
        padding: const EdgeInsets.all(
            DesignTokens.spacingMD),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: widget.student.photoURL != null
                  ? NetworkImage(widget.student.photoURL!)
                  : null,
              child: widget.student.photoURL == null
                  ? Icon(
                Icons.person,
                size: 32,
                color: DesignTokens.textSecondary,
              )
                  : null,
            ),
            const SizedBox(
                width: DesignTokens.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: widget.student.displayName ??
                        'Chưa có tên',
                    variant: TextVariant.titleLarge,
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  if (widget.student.email != null) ...[
                    const SizedBox(height: 4),
                    CustomText(
                      text: widget.student.email!,
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfoCard() {
    return CustomCard(
      variant: CardVariant.white,
      child: Padding(
        padding: const EdgeInsets.all(
            DesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CustomText(
              text: widget.course.title,
              variant: TextVariant.titleLarge,
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(
                height: DesignTokens.spacingSM),
            CustomText(
              text:
              widget.course.description,
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.course.startDate != null ||
                widget.course.endDate != null) ...[
              const SizedBox(
                  height: DesignTokens.spacingSM),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: DesignTokens.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    text: widget.course.startDate != null &&
                        widget.course.endDate != null
                        ? '${DateFormat('dd/MM/yyyy').format(widget.course.startDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.course.endDate!)}'
                        : widget.course.startDate != null
                        ? 'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(widget.course.startDate!)}'
                        : 'Kết thúc: ${DateFormat('dd/MM/yyyy').format(widget.course.endDate!)}',
                    variant: TextVariant.bodySmall,
                    color: DesignTokens.textSecondary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    // Placeholder: hiện tại chưa tracking từng bài học, để 0%
    const double progress = 0.0;

    return CustomCard(
      variant: CardVariant.white,
      child: Padding(
        padding: const EdgeInsets.all(
            DesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'Tiến độ học tập',
                  variant: TextVariant.titleMedium,
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                CustomText(
                  text: '${_lessons.length} bài học',
                  variant: TextVariant.bodyMedium,
                  color: DesignTokens.textSecondary,
                ),
              ],
            ),
            const SizedBox(
                height: DesignTokens.spacingMD),
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: DesignTokens.surfaceLight,
              ),
              child: FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.primary,
                        DesignTokens.secondary,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
                height: DesignTokens.spacingSM),
            CustomText(
              text:
              'Hệ thống đang cập nhật tính năng theo dõi tiến độ bài học',
              variant: TextVariant.bodySmall,
              color: DesignTokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final attendanceRate = _totalSessions > 0
        ? (_attendedSessions / _totalSessions * 100)
        .toStringAsFixed(1)
        : '0.0';

    return CustomCard(
      variant: CardVariant.white,
      child: Padding(
        padding: const EdgeInsets.all(
            DesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Thống kê tham gia',
              variant: TextVariant.titleMedium,
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(
                height: DesignTokens.spacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.event,
                    label: 'Tổng buổi học',
                    value: '$_totalSessions',
                    color: DesignTokens.info,
                  ),
                ),
                const SizedBox(
                    width: DesignTokens.spacingMD),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'Đã tham gia',
                    value: '$_attendedSessions',
                    color: DesignTokens.success,
                  ),
                ),
                const SizedBox(
                    width: DesignTokens.spacingMD),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.percent,
                    label: 'Tỷ lệ',
                    value: '$attendanceRate%',
                    color: DesignTokens.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(
          DesignTokens.spacingSM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
        BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          CustomText(
            text: value,
            variant: TextVariant.titleLarge,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          CustomText(
            text: label,
            variant: TextVariant.bodySmall,
            color: DesignTokens.textSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList() {
    if (_lessons.isEmpty) {
      return CustomCard(
        variant: CardVariant.white,
        child: Padding(
          padding: const EdgeInsets.all(
              DesignTokens.spacingMD),
          child: Column(
            children: [
              Icon(
                Icons.book_outlined,
                size: 48,
                color: DesignTokens.textSecondary,
              ),
              const SizedBox(
                  height: DesignTokens.spacingSM),
              CustomText(
                text: 'Chưa có bài học nào',
                variant: TextVariant.bodyLarge,
                color: DesignTokens.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    return CustomCard(
      variant: CardVariant.white,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
            const EdgeInsets.all(DesignTokens.spacingMD),
            child: CustomText(
              text:
              'Danh sách bài học (${_lessons.length})',
              variant: TextVariant.titleMedium,
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 1),
          ..._lessons.map((lesson) {
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomText(
                    text: '${lesson.lessonNumber}',
                    variant: TextVariant.titleMedium,
                    color: DesignTokens.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: CustomText(
                text: lesson.title,
                variant: TextVariant.bodyLarge,
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              subtitle: lesson.description != null
                  ? CustomText(
                text: lesson.description!,
                variant: TextVariant.bodySmall,
                color: DesignTokens.textSecondary,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
              )
                  : null,
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: DesignTokens.textSecondary,
              ),
            );
          }),
        ],
      ),
    );
  }
}


