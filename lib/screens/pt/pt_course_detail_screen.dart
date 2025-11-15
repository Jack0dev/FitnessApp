import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course_service.dart';
import '../../services/lesson_service.dart';
import '../../widgets/loading_widget.dart';
import 'pt_schedule_screen.dart';

class PTCourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const PTCourseDetailScreen({super.key, required this.course});

  @override
  State<PTCourseDetailScreen> createState() => _PTCourseDetailScreenState();
}

class _PTCourseDetailScreenState extends State<PTCourseDetailScreen> {
  final _courseService = CourseService();
  final _lessonService = LessonService();
  List<EnrollmentModel> _enrollments = [];
  int _lessonsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final enrollments = await _courseService.getCourseEnrollments(widget.course.id);
      final lessons = await _lessonService.getCourseLessons(widget.course.id);
      setState(() {
        _enrollments = enrollments;
        _lessonsCount = lessons.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.course.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.info)),
              Tab(text: 'Students', icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: _isLoading
            ? const LoadingWidget()
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildStudentsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.course.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.course.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                ),
              ),
            ),
          if (widget.course.imageUrl != null) const SizedBox(height: 16),
          Text(
            widget.course.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.course.description,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.attach_money, 'Price', '\$${widget.course.price.toStringAsFixed(0)}'),
          _buildInfoRow(Icons.access_time, 'Duration', '${widget.course.duration} days'),
          _buildInfoRow(Icons.people, 'Students', '${widget.course.currentStudents}/${widget.course.maxStudents}'),
          _buildInfoRow(Icons.trending_up, 'Level', widget.course.level.displayName),
          _buildInfoRow(Icons.menu_book, 'Lessons', _lessonsCount.toString()),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PTScheduleScreen(course: widget.course),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Manage Schedule'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    final paidEnrollments = _enrollments.where((e) => e.paymentStatus == PaymentStatus.paid).toList();
    final pendingEnrollments = _enrollments.where((e) => e.paymentStatus == PaymentStatus.pending).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (paidEnrollments.isNotEmpty) ...[
            const Text(
              'Paid Students',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...paidEnrollments.map((enrollment) => _buildEnrollmentCard(enrollment, true)),
            const SizedBox(height: 24),
          ],
          if (pendingEnrollments.isNotEmpty) ...[
            const Text(
              'Pending Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...pendingEnrollments.map((enrollment) => _buildEnrollmentCard(enrollment, false)),
          ],
          if (_enrollments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No students enrolled yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(EnrollmentModel enrollment, bool isPaid) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid ? Colors.green : Colors.orange,
          child: Icon(isPaid ? Icons.check : Icons.pending, color: Colors.white),
        ),
        title: Text('User ID: ${enrollment.userId.substring(0, 8)}...'),
        subtitle: Text('Enrolled: ${_formatDate(enrollment.enrolledAt)}'),
        trailing: Chip(
          label: Text(isPaid ? 'Paid' : 'Pending'),
          backgroundColor: isPaid ? Colors.green[100] : Colors.orange[100],
          labelStyle: TextStyle(
            color: isPaid ? Colors.green[800] : Colors.orange[800],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

