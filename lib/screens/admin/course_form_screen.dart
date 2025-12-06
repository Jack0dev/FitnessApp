import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course/course_service.dart';
import '../../models/user_model.dart';
import '../../services/user/data_service.dart';

class CourseFormScreen extends StatefulWidget {
  final CourseModel? course;

  const CourseFormScreen({super.key, this.course});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  final _courseService = CourseService();
  final _dataService = DataService();
  
  String? _selectedInstructorId;
  List<UserModel> _instructors = [];
  CourseStatus _status = CourseStatus.active;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    if (widget.course != null) {
      _titleController.text = widget.course!.title;
      _descriptionController.text = widget.course!.description;
      _priceController.text = widget.course!.price.toString();
      _durationController.text = widget.course!.duration.toString();
      _maxStudentsController.text = widget.course!.maxStudents.toString();
      _selectedInstructorId = widget.course!.instructorId;
      _status = widget.course!.status;
    }
  }

  Future<void> _loadInstructors() async {
    // Load all PTs
    try {
      final allUsers = await _dataService.getAllUsers(); // Need to implement this
      setState(() {
        _instructors = allUsers.where((u) => u.role == UserRole.pt).toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final course = CourseModel(
        id: widget.course?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructorId: _selectedInstructorId,
        instructorName: _instructors
            .firstWhere((u) => u.uid == _selectedInstructorId, orElse: () => UserModel(uid: ''))
            .displayName,
        price: double.tryParse(_priceController.text) ?? 0.0,
        duration: int.tryParse(_durationController.text) ?? 0,
        maxStudents: int.tryParse(_maxStudentsController.text) ?? 0,
        status: _status,
        createdAt: widget.course?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.course != null) {
        success = await _courseService.updateCourse(course);
      } else {
        final id = await _courseService.createCourse(course);
        success = id != null;
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.course != null
                  ? 'Course updated successfully'
                  : 'Course created successfully'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể lưu khóa học')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course != null ? 'Edit Course' : 'Create Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedInstructorId,
                decoration: const InputDecoration(
                  labelText: 'Giảng viên (PT)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Không có giảng viên')),
                  ..._instructors.map((instructor) => DropdownMenuItem(
                        value: instructor.uid,
                        child: Text(instructor.displayName ?? instructor.email ?? 'Không xác định'),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedInstructorId = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (days)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter duration';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter valid duration';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxStudentsController,
                decoration: const InputDecoration(
                  labelText: 'Max Students',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter max students';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CourseStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: CourseStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    )).toList(),
                onChanged: (value) {
                  setState(() => _status = value!);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCourse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.course != null ? 'Update Course' : 'Create Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





