import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course/course_service.dart';
import '../../widgets/loading_widget.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _courseService = CourseService();
  CourseModel? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoading = true);
    try {
      final course = await _courseService.getCourseById(widget.courseId);
      setState(() {
        _course = course;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading course: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _course == null
              ? const Center(child: Text('Course not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_course!.imageUrl != null)
                        Image.network(
                          _course!.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _course!.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _course!.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              '\$${_course!.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('${_course!.duration} days'),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(_course!.status.displayName),
                            backgroundColor: _course!.status == CourseStatus.active
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Students: ${_course!.currentStudents}/${_course!.maxStudents}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_course!.instructorName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Instructor: ${_course!.instructorName}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}





