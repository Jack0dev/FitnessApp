import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course/course_service.dart';
import '../../services/auth/auth_service.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/widgets.dart';
import 'pt_course_form_screen.dart';
import 'pt_course_detail_screen.dart';
import 'package:intl/intl.dart';

class PTCoursesManagementScreen extends StatefulWidget {
  const PTCoursesManagementScreen({super.key});

  @override
  State<PTCoursesManagementScreen> createState() => _PTCoursesManagementScreenState();
}

class _PTCoursesManagementScreenState extends State<PTCoursesManagementScreen> {
  final _courseService = CourseService();
  final _authService = AuthService();
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  List<CourseModel> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final courses = await _courseService.getCoursesByInstructor(user.id);
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khóa học'),
        content: Text('Bạn có chắc chắn muốn xóa "${course.title}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _courseService.deleteCourse(course.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa khóa học thành công')),
        );
        _loadCourses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa khóa học'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: DesignTokens.surface,

        // --- 1. Thêm nút Back vào vị trí leading (bên trái tiêu đề) ---
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DesignTokens.textPrimary), // Hoặc Icons.arrow_back_ios
          onPressed: () {
            Navigator.of(context).pop(); // Thực hiện hành động quay lại
          },
          tooltip: 'Back',
        ),

        title: CustomText(
          text: 'Khóa học',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: DesignTokens.textPrimary),
            onPressed: _loadCourses,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.add, color: DesignTokens.textPrimary),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PTCourseFormScreen(),
                ),
              );
              if (result == true) {
                _loadCourses();
              }
            },
            tooltip: 'Create New Course',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorState(colorScheme)
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: _courses.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : Column(
                          children: [
                            _buildStatsHeader(colorScheme),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _courses.length,
                                itemBuilder: (context, index) {
                                  final course = _courses[index];
                                  return _buildCourseCard(course, colorScheme, index);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingLG),
              decoration: BoxDecoration(
                color: DesignTokens.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: DesignTokens.error,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLG),
            CustomText(
              text: 'Error loading courses',
              variant: TextVariant.headlineSmall,
              color: DesignTokens.textPrimary,
            ),
            const SizedBox(height: DesignTokens.spacingSM),
            CustomText(
              text: _error ?? 'Unknown error',
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingLG),
            CustomButton(
              label: 'Thử lại',
              icon: Icons.refresh,
              onPressed: _loadCourses,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingLG),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 64,
                color: DesignTokens.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLG),
            CustomText(
              text: 'No courses yet',
              variant: TextVariant.displaySmall,
              color: DesignTokens.textPrimary,
            ),
            const SizedBox(height: DesignTokens.spacingSM),
            CustomText(
              text: 'Create your first course to start teaching!',
              variant: TextVariant.bodyLarge,
              color: DesignTokens.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingXL),
            CustomButton(
              label: 'Tạo khóa học',
              icon: Icons.add,
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PTCourseFormScreen(),
                  ),
                );
                if (result == true) {
                  _loadCourses();
                }
              },
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(ColorScheme colorScheme) {
    final activeCount = _courses.where((c) => c.status == CourseStatus.active).length;
    final totalStudents = _courses.fold<int>(0, (sum, c) => sum + c.currentStudents);
    final totalRevenue = _courses.fold<double>(0, (sum, c) => sum + (c.price * c.currentStudents));

    return Container(
      margin: const EdgeInsets.all(DesignTokens.spacingMD),
      padding: const EdgeInsets.all(DesignTokens.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary,
            DesignTokens.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        boxShadow: DesignTokens.shadowLG,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.school, '${_courses.length}', 'Courses', colorScheme),
          _buildStatItem(Icons.check_circle, '$activeCount', 'Active', colorScheme),
          _buildStatItem(Icons.people, '$totalStudents', 'Students', colorScheme),
          _buildStatItem(Icons.attach_money, formatter.format(totalRevenue), 'Revenue', colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(CourseModel course, ColorScheme colorScheme, int index) {
    return CustomCard(
      variant: CardVariant.white,
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PTCourseDetailScreen(course: course),
          ),
        ).then((_) => _loadCourses());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingSM),
                decoration: BoxDecoration(
                  color: course.status == CourseStatus.active
                      ? DesignTokens.success.withOpacity(0.1)
                      : DesignTokens.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
                child: Icon(
                  Icons.school,
                  color: course.status == CourseStatus.active
                      ? DesignTokens.success
                      : DesignTokens.textLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: course.title,
                      variant: TextVariant.titleLarge,
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: course.status),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: DesignTokens.textPrimary),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: DesignTokens.textPrimary),
                        const SizedBox(width: 8),
                        CustomText(
                          text: 'Chỉnh sửa',
                          variant: TextVariant.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: DesignTokens.error),
                        const SizedBox(width: 8),
                        CustomText(
                          text: 'Xóa',
                          variant: TextVariant.bodyMedium,
                          color: DesignTokens.error,
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PTCourseFormScreen(course: course),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadCourses();
                      }
                    });
                  } else if (value == 'delete') {
                    _deleteCourse(course);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingSM),
          CustomText(
            text: course.description,
            variant: TextVariant.bodyMedium,
            color: DesignTokens.textSecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.spacingMD),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.attach_money,
                  formatter.format(course.price),
                  DesignTokens.info,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingSM),
              Expanded(
                child: _buildInfoChip(
                  Icons.people,
                  '${course.currentStudents}/${course.maxStudents}',
                  DesignTokens.success,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingSM),
              Expanded(
                child: _buildInfoChip(
                  Icons.calendar_today,
                  '${course.duration} days',
                  DesignTokens.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingSM, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: CustomText(
              text: text,
              variant: TextVariant.bodySmall,
              color: color,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CourseStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case CourseStatus.active:
        color = DesignTokens.success;
        text = 'Active';
        break;
      case CourseStatus.inactive:
        color = DesignTokens.textLight;
        text = 'Inactive';
        break;
      case CourseStatus.completed:
        color = DesignTokens.info;
        text = 'Completed';
        break;
      case CourseStatus.canceled:
        color = DesignTokens.error;
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: CustomText(
        text: text,
        variant: TextVariant.bodySmall,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

