import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/course_lesson_model.dart';
import '../../services/lesson_service.dart';
import '../../widgets/loading_widget.dart';
import 'pt_lesson_form_screen.dart';

class PTScheduleScreen extends StatefulWidget {
  final CourseModel course;

  const PTScheduleScreen({super.key, required this.course});

  @override
  State<PTScheduleScreen> createState() => _PTScheduleScreenState();
}

class _PTScheduleScreenState extends State<PTScheduleScreen> {
  final _lessonService = LessonService();
  List<CourseLessonModel> _lessons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessons = await _lessonService.getCourseLessons(widget.course.id);
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLesson(CourseLessonModel lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _lessonService.deleteLesson(lesson.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson deleted successfully')),
        );
        _loadLessons();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete lesson'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule - ${widget.course.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PTLessonFormScreen(
                    course: widget.course,
                    nextLessonNumber: _lessons.isEmpty ? 1 : (_lessons.map((l) => l.lessonNumber).reduce((a, b) => a > b ? a : b) + 1),
                  ),
                ),
              );
              if (result == true) {
                _loadLessons();
              }
            },
            tooltip: 'Add Lesson',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLessons,
            tooltip: 'Refresh',
          ),
        ],
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
                      Text('Error: $_error', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLessons,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLessons,
                  child: _lessons.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No lessons scheduled yet',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add lessons to create your teaching schedule',
                                style: TextStyle(color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = _lessons[index];
                            final isToday = lesson.lessonDate != null &&
                                lesson.lessonDate!.year == DateTime.now().year &&
                                lesson.lessonDate!.month == DateTime.now().month &&
                                lesson.lessonDate!.day == DateTime.now().day;

                            return Card(
                              margin: EdgeInsets.only(bottom: index < _lessons.length - 1 ? 16 : 0),
                              elevation: isToday ? 4 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isToday
                                    ? const BorderSide(color: Colors.blue, width: 2)
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isToday ? Colors.blue : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${lesson.lessonNumber}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isToday ? Colors.white : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  lesson.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? Colors.blue[800] : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lesson.description != null && lesson.description!.isNotEmpty)
                                      Text(lesson.description!),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(lesson.fileType.icon, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          lesson.fileType.displayName,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        if (lesson.lessonDate != null) ...[
                                          const SizedBox(width: 12),
                                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDateTime(lesson.lessonDate!),
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isToday)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Today',
                                          style: TextStyle(
                                            color: Colors.blue[800],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () async {
                                        final result = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => PTLessonFormScreen(
                                              course: widget.course,
                                              lesson: lesson,
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadLessons();
                                        }
                                      },
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _deleteLesson(lesson),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

