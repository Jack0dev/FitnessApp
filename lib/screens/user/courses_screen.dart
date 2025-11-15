import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';
import 'course_enroll_screen.dart';
import 'user_course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with SingleTickerProviderStateMixin {
  final _courseService = CourseService();
  final _authService = AuthService();
  late TabController _tabController;

  // All Courses
  List<CourseModel> _allCourses = [];
  List<CourseModel> _filteredAllCourses = [];
  bool _isLoadingAllCourses = true;

  // My Courses
  List<Map<String, dynamic>> _enrolledCourses = [];
  List<Map<String, dynamic>> _filteredEnrolledCourses = [];
  bool _isLoadingMyCourses = true;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  CourseLevel? _selectedLevel;
  CourseStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllCourses();
    _loadMyCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCourses() async {
    setState(() => _isLoadingAllCourses = true);
    try {
      final courses = await _courseService.getAllCourses();
      setState(() {
        _allCourses = courses;
        _applyFilters();
        _isLoadingAllCourses = false;
      });
    } catch (e) {
      setState(() => _isLoadingAllCourses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  Future<void> _loadMyCourses() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isLoadingMyCourses = false);
      return;
    }

    setState(() => _isLoadingMyCourses = true);
    try {
      final enrollments = await _courseService.getUserEnrollments(user.id);
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
        _applyFilters();
        _isLoadingMyCourses = false;
      });
    } catch (e) {
      setState(() => _isLoadingMyCourses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading enrolled courses: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final searchQuery = _searchController.text.toLowerCase();

    // Filter All Courses
    _filteredAllCourses = _allCourses.where((course) {
      final matchesSearch = searchQuery.isEmpty ||
          course.title.toLowerCase().contains(searchQuery) ||
          course.description.toLowerCase().contains(searchQuery) ||
          (course.instructorName?.toLowerCase().contains(searchQuery) ?? false);

      final matchesLevel = _selectedLevel == null || course.level == _selectedLevel;
      final matchesStatus = _selectedStatus == null || course.status == _selectedStatus;

      return matchesSearch && matchesLevel && matchesStatus;
    }).toList();

    // Filter My Courses
    _filteredEnrolledCourses = _enrolledCourses.where((data) {
      final course = data['course'] as CourseModel;
      final matchesSearch = searchQuery.isEmpty ||
          course.title.toLowerCase().contains(searchQuery) ||
          course.description.toLowerCase().contains(searchQuery) ||
          (course.instructorName?.toLowerCase().contains(searchQuery) ?? false);

      final matchesLevel = _selectedLevel == null || course.level == _selectedLevel;
      final matchesStatus = _selectedStatus == null || course.status == _selectedStatus;

      return matchesSearch && matchesLevel && matchesStatus;
    }).toList();

    setState(() {});
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Courses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level Filter
              const Text(
                'Level',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: CourseLevel.values.map((level) {
                  final isSelected = _selectedLevel == level;
                  return FilterChip(
                    label: Text(level.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        _selectedLevel = selected ? level : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Status Filter
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: CourseStatus.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return FilterChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        _selectedStatus = selected ? status : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedLevel = null;
                  _selectedStatus = null;
                });
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Courses', icon: Icon(Icons.library_books)),
            Tab(text: 'My Courses', icon: Icon(Icons.school)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
                _loadAllCourses();
              } else {
                _loadMyCourses();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Active Filters
          if (_selectedLevel != null || _selectedStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedLevel != null)
                    Chip(
                      label: Text('Level: ${_selectedLevel!.displayName}'),
                      onDeleted: () {
                        setState(() {
                          _selectedLevel = null;
                          _applyFilters();
                        });
                      },
                    ),
                  if (_selectedStatus != null)
                    Chip(
                      label: Text('Status: ${_selectedStatus!.displayName}'),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = null;
                          _applyFilters();
                        });
                      },
                    ),
                ],
              ),
            ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Courses Tab
                _buildAllCoursesTab(),
                // My Courses Tab
                _buildMyCoursesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCoursesTab() {
    if (_isLoadingAllCourses) {
      return const LoadingWidget();
    }

    if (_filteredAllCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _allCourses.isEmpty
                  ? 'No courses available'
                  : 'No courses match your filters',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_allCourses.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedLevel = null;
                    _selectedStatus = null;
                    _searchController.clear();
                  });
                  _applyFilters();
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllCourses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAllCourses.length,
        itemBuilder: (context, index) {
          final course = _filteredAllCourses[index];
          return _AllCourseCard(
            course: course,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CourseEnrollScreen(course: course),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMyCoursesTab() {
    if (_isLoadingMyCourses) {
      return const LoadingWidget();
    }

    if (_filteredEnrolledCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _enrolledCourses.isEmpty
                  ? 'No enrolled courses yet'
                  : 'No courses match your filters',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_enrolledCourses.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Enroll in courses to start your fitness journey!',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedLevel = null;
                    _selectedStatus = null;
                    _searchController.clear();
                  });
                  _applyFilters();
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyCourses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEnrolledCourses.length,
        itemBuilder: (context, index) {
          final data = _filteredEnrolledCourses[index];
          final course = data['course'] as CourseModel;
          final enrollment = data['enrollment'] as EnrollmentModel;

          return _MyCourseCard(
            course: course,
            enrollment: enrollment,
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
          );
        },
      ),
    );
  }
}

class _AllCourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _AllCourseCard({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  course.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _StatusBadge(status: course.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(course.instructorName ?? 'N/A', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const Spacer(),
                      Icon(Icons.trending_up, size: 16, color: _getLevelColor(course.level)),
                      const SizedBox(width: 4),
                      Text(course.level.displayName, style: TextStyle(fontSize: 14, color: _getLevelColor(course.level))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${course.duration} days', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const Spacer(),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${course.currentStudents}/${course.maxStudents}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${course.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      if (course.isFull)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Full', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Available', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

class _MyCourseCard extends StatelessWidget {
  final CourseModel course;
  final EnrollmentModel enrollment;
  final VoidCallback onTap;

  const _MyCourseCard({
    required this.course,
    required this.enrollment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (course.imageUrl != null) ...[
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
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                course.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(icon: Icons.person, label: 'Instructor', value: course.instructorName ?? 'N/A'),
                  _buildInfoChip(icon: Icons.timer, label: 'Duration', value: '${course.duration} days'),
                  _buildInfoChip(icon: Icons.group, label: 'Students', value: '${course.currentStudents}/${course.maxStudents}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: enrollment.paymentStatus == PaymentStatus.paid ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          enrollment.paymentStatus == PaymentStatus.paid ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: enrollment.paymentStatus == PaymentStatus.paid ? Colors.green[800] : Colors.orange[800],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          enrollment.paymentStatus == PaymentStatus.paid ? 'Paid' : 'Pending',
                          style: TextStyle(
                            color: enrollment.paymentStatus == PaymentStatus.paid ? Colors.green[800] : Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Enrolled: ${_formatDate(enrollment.enrolledAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
        color = Colors.green;
        text = 'Active';
        break;
      case CourseStatus.inactive:
        color = Colors.grey;
        text = 'Inactive';
        break;
      case CourseStatus.completed:
        color = Colors.blue;
        text = 'Completed';
        break;
      case CourseStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

