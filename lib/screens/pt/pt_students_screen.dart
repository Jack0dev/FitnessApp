import 'package:flutter/material.dart';
import '../../services/course/course_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/user_model.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'pt_chat_screen.dart';
import 'pt_student_progress_screen.dart';

class PTStudentsScreen extends StatefulWidget {
  final CourseModel? course;

  const PTStudentsScreen({super.key, this.course});

  @override
  State<PTStudentsScreen> createState() => _PTStudentsScreenState();
}

class _PTStudentsScreenState extends State<PTStudentsScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  final _dataService = DataService();

  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;
  List<EnrollmentModel> _enrollments = [];
  Map<String, UserModel> _students = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.course;
    _loadCourses();
    if (_selectedCourse != null) {
      _loadStudents(_selectedCourse!.id);
    }
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final courses = await _courseService.getCoursesByInstructor(user.id);
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() => _isLoading = true);
    try {
      final enrollments = await _courseService.getCourseEnrollments(courseId);
      final paidEnrollments = enrollments
          .where((e) => e.paymentStatus == PaymentStatus.paid)
          .toList();

      // Load user data for each student
      final Map<String, UserModel> students = {};
      for (final enrollment in paidEnrollments) {
        try {
          final user = await _dataService.getUserData(enrollment.userId);
          if (user != null) {
            students[enrollment.userId] = user;
          }
        } catch (e) {
          print('Failed to load user ${enrollment.userId}: $e');
        }
      }

      setState(() {
        _enrollments = paidEnrollments;
        _students = students;
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
        title: context.translate('my_students'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorDisplayWidget(
                  message: _error!,
                  onRetry: _loadCourses,
                )
              : Column(
                  children: [
                    // Course Filter Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingLG,
                        vertical: DesignTokens.spacingMD,
                      ),
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
                        label: context.translate('select_course'),
                        icon: Icons.school,
                        value: _selectedCourse,
                        hint: context.translate('select_course'),
                        items: _courses.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: CustomText(
                              text: course.title,
                              variant: TextVariant.bodyMedium,
                              color: DesignTokens.textPrimary,
                            ),
                          );
                        }).toList(),
                        onChanged: (course) {
                          setState(() => _selectedCourse = course);
                          if (course != null) {
                            _loadStudents(course.id);
                          } else {
                            setState(() {
                              _enrollments = [];
                              _students = {};
                            });
                          }
                        },
                      ),
                    ),

                    // Students List
                    Expanded(
                      child: _selectedCourse == null
                          ? EmptyStateWidget(
                              icon: Icons.school_outlined,
                              title: context.translate('select_course'),
                              subtitle: '${context.translate('select_course')} ${context.translate('to')} ${context.translate('view')} ${context.translate('students')}',
                            )
                          : _enrollments.isEmpty
                              ? EmptyStateWidget(
                                  icon: Icons.people_outline,
                                  title: context.translate('no_students_enrolled'),
                                  subtitle: '${context.translate('no_students_enrolled')} ${context.translate('in')} ${_selectedCourse!.title}',
                                )
                              : RefreshIndicator(
                                  onRefresh: () => _loadStudents(_selectedCourse!.id),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(DesignTokens.spacingLG),
                                    itemCount: _enrollments.length,
                                    itemBuilder: (context, index) {
                                      final enrollment = _enrollments[index];
                                      final student = _students[enrollment.userId];

                                      return _buildStudentCard(
                                        context,
                                        enrollment,
                                        student,
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    EnrollmentModel enrollment,
    UserModel? student,
  ) {
    return CustomCard(
      variant: CardVariant.white,
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMD),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(student),
            const SizedBox(width: DesignTokens.spacingMD),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: student?.displayName ?? context.translate('user'),
                    variant: TextVariant.titleMedium,
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  if (student?.email != null) ...[
                    const SizedBox(height: DesignTokens.spacingXS),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: DesignTokens.textSecondary,
                        ),
                        const SizedBox(width: DesignTokens.spacingXS),
                        Expanded(
                          child: CustomText(
                            text: student!.email!,
                            variant: TextVariant.bodySmall,
                            color: DesignTokens.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacingXS),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: DesignTokens.textSecondary,
                      ),
                      const SizedBox(width: DesignTokens.spacingXS),
                      CustomText(
                        text: '${context.translate('enrolled_at')}: ${_formatDate(enrollment.enrolledAt)}',
                        variant: TextVariant.bodySmall,
                        color: DesignTokens.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.trending_up,
                  color: DesignTokens.primary,
                  tooltip: context.translate('view_progress'),
                  onPressed: () {
                    if (student != null && _selectedCourse != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PTStudentProgressScreen(
                            student: student,
                            course: _selectedCourse!,
                            enrollment: enrollment,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: DesignTokens.spacingSM),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: DesignTokens.accent,
                  tooltip: context.translate('chat'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PTChatScreen(
                          studentId: enrollment.userId,
                          course: _selectedCourse,
                        ),
                      ),
                    );
                  },
                  isGradient: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel? student) {
    if (student?.photoURL != null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            student!.photoURL!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: DesignTokens.gradientPrimary,
                  ),
                ),
                child: Center(
                  child: CustomText(
                    text: (student.displayName ?? 'U')[0].toUpperCase(),
                    variant: TextVariant.headlineSmall,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: DesignTokens.gradientPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomText(
          text: (student?.displayName ?? 'U')[0].toUpperCase(),
          variant: TextVariant.headlineSmall,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    bool isGradient = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isGradient
            ? LinearGradient(colors: DesignTokens.gradientAccent)
            : null,
        color: isGradient ? null : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: isGradient
            ? null
            : Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isGradient ? Colors.white : color,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

