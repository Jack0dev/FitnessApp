import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course/course_service.dart';
import '../../services/course/lesson_service.dart';
import '../../services/user/data_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'pt_chat_screen.dart';
import 'pt_lesson_form_screen.dart';
import 'pt_session_screen.dart';
import 'pt_session_form_screen.dart';
import '../../models/course_lesson_model.dart';


class PTCourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const PTCourseDetailScreen({super.key, required this.course});

  @override
  State<PTCourseDetailScreen> createState() => _PTCourseDetailScreenState();
}

class _PTCourseDetailScreenState extends State<PTCourseDetailScreen> with SingleTickerProviderStateMixin {
  final _courseService = CourseService();
  final _lessonService = LessonService();
  final _dataService = DataService();
  List<EnrollmentModel> _enrollments = [];
  Map<String, dynamic> _students = {};
  List<CourseLessonModel> _lessons = [];
  int _lessonsCount = 0;
  bool _isLoading = true;
  bool _isLoadingStudents = false;
  String? _error;
  late TabController _tabController;
  
  // Simple in-memory cache for user data
  static final Map<String, Map<String, dynamic>> _userCache = {};
  
  static const List<String> _tabNames = [
    'Chi tiết',
    'Bài Học',
    'Lịch Trình',
    'Học viên',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          print('📑 [PTCourseDetail] Tab changed to: ${_tabNames[_tabController.index]} (Index: ${_tabController.index})');
          // Trigger rebuild to show/hide FAB
          setState(() {});
        }
      });
    print('📱 [PTCourseDetail] Screen initialized - Course: ${widget.course.title} (ID: ${widget.course.id})');
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    print('📱 [PTCourseDetail] Screen disposed - Course: ${widget.course.title} (ID: ${widget.course.id})');
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    print('🔄 [PTCourseDetail] Loading data started - Course: ${widget.course.title} (ID: ${widget.course.id})');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      print('🔄 [PTCourseDetail] Loading data for course: ${widget.course.id}');
      
      // Load enrollments and lessons in parallel
      final results = await Future.wait([
        _courseService.getCourseEnrollments(widget.course.id),
        _lessonService.getCourseLessons(widget.course.id),
      ]);
      
      final enrollments = results[0] as List<EnrollmentModel>;
      final lessons = results[1] as List<CourseLessonModel>;
      
      print('✅ [PTCourseDetail] Loaded ${enrollments.length} enrollments, ${lessons.length} lessons');
      
      // Progressive loading: Show enrollments and lessons immediately
      if (mounted) {
        setState(() {
          _enrollments = enrollments;
          _lessons = lessons;
          _lessonsCount = lessons.length;
          _isLoading = false;
          _error = null;
        });
      }
      
      // Load student data in background using batch query (much faster)
      _loadStudentData(enrollments);
    } catch (e, stackTrace) {
      print('❌ [PTCourseDetail] Error loading data: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(
              text: 'Lỗi khi tải dữ liệu: ${e.toString()}',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  /// Load student data using batch query for optimal performance
  Future<void> _loadStudentData(List<EnrollmentModel> enrollments) async {
    if (enrollments.isEmpty || !mounted) return;
    
    setState(() {
      _isLoadingStudents = true;
    });
    
    try {
      // Get unique user IDs
      final userIds = enrollments.map((e) => e.userId).toSet().toList();
      
      // Check cache first
      final Map<String, dynamic> students = {};
      final List<String> uncachedUserIds = [];
      
      for (final userId in userIds) {
        if (_userCache.containsKey(userId)) {
          students[userId] = _userCache[userId]!;
        } else {
          uncachedUserIds.add(userId);
        }
      }
      
      // Batch query for uncached users (single database call instead of N calls)
      if (uncachedUserIds.isNotEmpty) {
        print('🔄 [PTCourseDetail] Loading ${uncachedUserIds.length} users via batch query');
        final users = await _dataService.getUsersByIds(uncachedUserIds);
        
        for (final entry in users.entries) {
          final user = entry.value;
          final userData = {
            'displayName': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
          };
          
          // Cache the user data
          _userCache[entry.key] = userData;
          students[entry.key] = userData;
        }
      }
      
      if (mounted) {
        setState(() {
          _students = students;
          _isLoadingStudents = false;
        });
        print('✅ [PTCourseDetail] Loaded ${students.length} student profiles');
      }
    } catch (e) {
      print('⚠️ [PTCourseDetail] Error loading student data: $e');
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📱 [PTCourseDetail] Building screen - Course: ${widget.course.title}');
    return Scaffold(
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

        title: const CustomText(
          text: 'Thông tin khóa học',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: DesignTokens.primary,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorColor: DesignTokens.primary,
          indicatorWeight: 3,
          onTap: (index) {
            print('📑 [PTCourseDetail] Tab tapped: ${_tabNames[index]} (Index: $index)');
          },
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info, size: 18),
                  const SizedBox(width: 8),
                  const Text('Chi tiết'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, size: 18),
                  const SizedBox(width: 8),
                  const Text('Bài Học'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  const Text('Lịch Trình'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 18),
                  const SizedBox(width: 8),
                  const Text('Học viên'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
            ? const LoadingWidget()
            : _error != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildLessonsTab(),
                      _buildScheduleTab(),
                      _buildStudentsTab(),
                    ],
                  ),
      floatingActionButton: _tabController.index == 1 || _tabController.index == 2
          ? FloatingActionButton(
              onPressed: () async {
                if (_tabController.index == 1) {
                  // Lessons tab
                  final nextLessonNumber = _lessons.isEmpty
                      ? 1
                      : (_lessons.map((l) => l.lessonNumber).reduce((a, b) => a > b ? a : b) + 1);
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PTLessonFormScreen(
                        course: widget.course,
                        nextLessonNumber: nextLessonNumber,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                } else if (_tabController.index == 2) {
                  // Session tab - Navigate to session form
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      // ✅ ĐÃ SỬA: Truyền tên khóa học vào initialTitle
                      builder: (context) => PTSessionFormScreen(
                        initialTitle: widget.course.title,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                }
              },
              child: const Icon(Icons.add),
              tooltip: _tabController.index == 1 ? 'Thêm bài học' : 'Thêm session',
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    print('📑 [PTCourseDetail] Building Overview tab');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CourseImageHeader(imageUrl: widget.course.imageUrl),
          if (widget.course.imageUrl != null) const SizedBox(height: DesignTokens.spacingMD),
          CustomCard(
            variant: CardVariant.white,
            padding: const EdgeInsets.all(DesignTokens.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: widget.course.title,
                  variant: TextVariant.displaySmall,
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: DesignTokens.spacingSM),
                CustomText(
                  text: widget.course.description,
                  variant: TextVariant.bodyLarge,
                  color: DesignTokens.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMD),
          CustomCard(
            variant: CardVariant.white,
            padding: const EdgeInsets.all(DesignTokens.spacingMD),
            child: Column(
              children: [
                InfoRowCard(
                  icon: Icons.attach_money,
                  label: context.translate('price'),
                  value: '${_formatPrice(widget.course.price)} VND',
                  iconColor: DesignTokens.info,
                ),
                InfoRowCard(
                  icon: Icons.access_time,
                  label: context.translate('duration'),
                  value: '${widget.course.duration} ${context.translate('days')}',
                  iconColor: DesignTokens.warning,
                ),
                InfoRowCard(
                  icon: Icons.people,
                  label: context.translate('students'),
                  value: '${widget.course.currentStudents}/${widget.course.maxStudents}',
                  iconColor: DesignTokens.success,
                ),
                InfoRowCard(
                  icon: Icons.trending_up,
                  label: context.translate('level'),
                  value: widget.course.level.displayName,
                  iconColor: DesignTokens.primary,
                ),
                InfoRowCard(
                  icon: Icons.menu_book,
                  label: context.translate('lessons'),
                  value: _lessonsCount.toString(),
                  iconColor: DesignTokens.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    print('📑 [PTCourseDetail] Building Students tab - ${_enrollments.length} enrollments');
    final paidEnrollments = _enrollments.where((e) => e.paymentStatus == PaymentStatus.paid).toList();
    final pendingEnrollments = _enrollments.where((e) => e.paymentStatus == PaymentStatus.pending).toList();

    if (_enrollments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () {
          print('🔄 [PTCourseDetail] Refresh triggered from Students tab');
          return _loadData();
        },
        child: EmptyStateWidget(
          icon: Icons.people_outline,
          title: context.translate('no_students_enrolled'),
        ),
      );
    }

    // Use ListView.builder for virtual scrolling (better performance with 50-100+ items)
    return RefreshIndicator(
      onRefresh: () {
        print('🔄 [PTCourseDetail] Refresh triggered from Students tab (with data)');
        return _loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(DesignTokens.spacingMD),
        itemCount: _calculateStudentListItems(paidEnrollments, pendingEnrollments),
        itemBuilder: (context, index) {
          return _buildStudentListItem(index, paidEnrollments, pendingEnrollments);
        },
      ),
    );
  }

  /// Calculate total items for ListView.builder (headers + cards)
  int _calculateStudentListItems(List<EnrollmentModel> paid, List<EnrollmentModel> pending) {
    int count = 0;
    if (paid.isNotEmpty) count += 1 + paid.length; // header + items
    if (pending.isNotEmpty) count += 1 + pending.length; // header + items
    return count;
  }

  /// Build list item based on index (optimized for large lists)
  Widget _buildStudentListItem(
    int index,
    List<EnrollmentModel> paidEnrollments,
    List<EnrollmentModel> pendingEnrollments,
  ) {
    int currentIndex = 0;

    // Paid students section
    if (paidEnrollments.isNotEmpty) {
      if (index == currentIndex) {
        // Header
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacingSM, top: DesignTokens.spacingSM),
          child: CustomText(
            text: context.translate('paid_students'),
            variant: TextVariant.headlineSmall,
            color: DesignTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      currentIndex++;

      if (index < currentIndex + paidEnrollments.length) {
        // Paid student card
        final enrollmentIndex = index - currentIndex;
        return _buildEnrollmentCard(paidEnrollments[enrollmentIndex], true);
      }
      currentIndex += paidEnrollments.length;

      // Spacer between sections
      if (pendingEnrollments.isNotEmpty && index == currentIndex) {
        return const SizedBox(height: DesignTokens.spacingMD);
      }
      if (pendingEnrollments.isNotEmpty) currentIndex++;
    }

    // Pending students section
    if (pendingEnrollments.isNotEmpty) {
      if (index == currentIndex) {
        // Header
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacingSM, top: DesignTokens.spacingSM),
          child: CustomText(
            text: context.translate('pending_payment'),
            variant: TextVariant.headlineSmall,
            color: DesignTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      currentIndex++;

      if (index < currentIndex + pendingEnrollments.length) {
        // Pending student card
        final enrollmentIndex = index - currentIndex;
        return _buildEnrollmentCard(pendingEnrollments[enrollmentIndex], false);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildEnrollmentCard(EnrollmentModel enrollment, bool isPaid) {
    final student = _students[enrollment.userId] as Map<String, dynamic>?;
    final displayName = student?['displayName'] ?? context.translate('user');
    final email = student?['email'] as String?;
    final photoURL = student?['photoURL'] as String?;
    final isLoadingStudent = _isLoadingStudents && student == null;

    return StudentEnrollmentCard(
      displayName: displayName,
      email: email,
      photoURL: photoURL,
      enrolledAt: enrollment.enrolledAt,
      isPaid: isPaid,
      isLoading: isLoadingStudent,
      onChatPressed: isPaid
          ? () {
              print('🚀 [PTCourseDetail] Navigating to PTChatScreen - Student: $displayName (${enrollment.userId})');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PTChatScreen(
                    studentId: enrollment.userId,
                    course: widget.course,
                  ),
                ),
              ).then((_) {
                print('📱 [PTCourseDetail] Returned from PTChatScreen');
              });
            }
          : null,
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildLessonsTab() {
    print('📑 [PTCourseDetail] Building Lessons tab - ${_lessons.length} lessons');
    final sortedLessons = List<CourseLessonModel>.from(_lessons)
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    final nextLessonNumber = _lessons.isEmpty
        ? 1
        : (_lessons.map((l) => l.lessonNumber).reduce((a, b) => a > b ? a : b) + 1);

    return RefreshIndicator(
      onRefresh: () {
        print('🔄 [PTCourseDetail] Refresh triggered from Lessons tab');
        return _loadData();
      },
      child: sortedLessons.isEmpty
          ? EmptyStateWidget(
              icon: Icons.menu_book_outlined,
              title: 'Chưa có bài học nào',
              subtitle: 'Thêm bài học đầu tiên!',
              actionLabel: 'Thêm bài học',
              actionIcon: Icons.add,
              onAction: () async {
                print('🚀 [PTCourseDetail] Navigating to PTLessonFormScreen (Create) - Course: ${widget.course.title}');
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PTLessonFormScreen(
                      course: widget.course,
                      nextLessonNumber: nextLessonNumber,
                    ),
                  ),
                );
                print('📱 [PTCourseDetail] Returned from PTLessonFormScreen (Create) - Result: $result');
                if (result == true) {
                  _loadData();
                }
              },
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(DesignTokens.spacingMD),
                    itemCount: sortedLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = sortedLessons[index];
                      return LessonCard(
                        lesson: lesson,
                        onEdit: () async {
                          print('🚀 [PTCourseDetail] Navigating to PTLessonFormScreen (Edit) - Lesson: ${lesson.title} (${lesson.id})');
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PTLessonFormScreen(
                                course: widget.course,
                                lesson: lesson,
                              ),
                            ),
                          );
                          print('📱 [PTCourseDetail] Returned from PTLessonFormScreen (Edit) - Result: $result');
                          if (result == true) {
                            _loadData();
                          }
                        },
                        onDelete: () async {
                          print('🗑️ [PTCourseDetail] Delete lesson requested - Lesson: ${lesson.title} (${lesson.id})');
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const CustomText(
                                text: 'Xóa bài học',
                                variant: TextVariant.headlineSmall,
                                color: DesignTokens.textPrimary,
                              ),
                              content: CustomText(
                                text: 'Bạn có chắc chắn muốn xóa "${lesson.title}"?',
                                variant: TextVariant.bodyMedium,
                                color: DesignTokens.textSecondary,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const CustomText(
                                    text: 'Hủy',
                                    variant: TextVariant.bodyMedium,
                                    color: DesignTokens.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
                                  child: const CustomText(
                                    text: 'Xóa',
                                    variant: TextVariant.bodyMedium,
                                    color: DesignTokens.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            print('🗑️ [PTCourseDetail] Deleting lesson - Lesson: ${lesson.title} (${lesson.id})');
                            final success = await _lessonService.deleteLesson(lesson.id);
                            print('🗑️ [PTCourseDetail] Delete lesson result: $success');
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const CustomText(
                                    text: 'Đã xóa bài học thành công',
                                    variant: TextVariant.bodyMedium,
                                    color: Colors.white,
                                  ),
                                  backgroundColor: DesignTokens.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                  ),
                                ),
                              );
                              _loadData();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const CustomText(
                                    text: 'Không thể xóa bài học',
                                    variant: TextVariant.bodyMedium,
                                    color: Colors.white,
                                  ),
                                  backgroundColor: DesignTokens.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildScheduleTab() {
    final courseTitleValue = widget.course.title; // Dòng này
    print('📑 [PTCourseDetail] Building Schedule tab');
    // Note: Session is trainer-based, not course-based
    // Show session screen for the trainer
    // BẮT BUỘC THÊM LOG NÀY
    print('*** CHECKPOINT 1: PTCourseDetailScreen.title = $courseTitleValue');
    return PTSessionScreen(
      hideAppBar: true,
      courseTitle: courseTitleValue, // ✅ Truyền tên khóa học vào đây
    );
  }

  Widget _buildErrorWidget() {
    return ErrorDisplayWidget(
      title: 'Không thể tải dữ liệu',
      message: _error ?? 'Đã xảy ra lỗi không xác định',
      onRetry: _loadData,
    );
  }
}

