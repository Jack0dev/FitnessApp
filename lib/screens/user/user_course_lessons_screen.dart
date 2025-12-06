import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/course_lesson_model.dart';
import '../../services/course/lesson_service.dart';
import '../../widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class UserCourseLessonsScreen extends StatefulWidget {
  final CourseModel course;
  final EnrollmentModel enrollment;

  const UserCourseLessonsScreen({
    super.key,
    required this.course,
    required this.enrollment,
  });

  @override
  State<UserCourseLessonsScreen> createState() => _UserCourseLessonsScreenState();
}

class _UserCourseLessonsScreenState extends State<UserCourseLessonsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lessons - ${widget.course.title}'),
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
                      Text(
                        'Error: $_error',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLessons,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _lessons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No lessons available yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your instructor will add lessons soon!',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLessons,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                _showLessonDetail(context, lesson);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Lesson Number and Title
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Lesson ${lesson.lessonNumber}',
                                            style: TextStyle(
                                              color: Colors.blue[800],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            lesson.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        lesson.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    // Background Image Preview
                                    if (lesson.backgroundImageUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          lesson.backgroundImageUrl!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 150,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Exercises List
                                    if (lesson.exercises.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Bài tập:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...lesson.exercises.map((exercise) {
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  exercise.exerciseName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (exercise.equipment.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    spacing: 4,
                                                    children: exercise.equipment.map((eq) {
                                                      return Chip(
                                                        label: Text(eq, style: const TextStyle(fontSize: 11)),
                                                        padding: EdgeInsets.zero,
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  children: [
                                                    if (exercise.sets != null)
                                                      Text('${exercise.sets} hiệp', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                    if (exercise.reps != null)
                                                      Text('${exercise.reps} rep', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                    if (exercise.restTimeSeconds != null)
                                                      Text('Nghỉ: ${exercise.restTimeSeconds}s', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                  ],
                                                ),
                                                if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    exercise.notes!,
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
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

  void _showLessonDetail(BuildContext context, CourseLessonModel lesson) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lesson ${lesson.lessonNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            lesson.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Lesson Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                        Text(
                          lesson.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Background Image Preview
                      if (lesson.backgroundImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            lesson.backgroundImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      // Exercises List
                      if (lesson.exercises.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Bài tập:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...lesson.exercises.map((exercise) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.exerciseName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (exercise.equipment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: exercise.equipment.map((eq) {
                                        return Chip(
                                          label: Text(eq, style: const TextStyle(fontSize: 12)),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      if (exercise.sets != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.repeat, size: 16, color: Colors.grey[700]),
                                            const SizedBox(width: 4),
                                            Text('${exercise.sets} hiệp', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                          ],
                                        ),
                                      if (exercise.reps != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.fitness_center, size: 16, color: Colors.grey[700]),
                                            const SizedBox(width: 4),
                                            Text('${exercise.reps} rep', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                          ],
                                        ),
                                      if (exercise.restTimeSeconds != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.timer, size: 16, color: Colors.grey[700]),
                                            const SizedBox(width: 4),
                                            Text('Nghỉ: ${exercise.restTimeSeconds}s', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        exercise.notes!,
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              // Dialog Footer
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    if (lesson.backgroundImageUrl != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(lesson.backgroundImageUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Không thể mở URL hình ảnh'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Xem hình ảnh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

