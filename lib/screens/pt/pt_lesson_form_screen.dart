import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course_model.dart';
import '../../models/course_lesson_model.dart';
import '../../services/lesson_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';

class PTLessonFormScreen extends StatefulWidget {
  final CourseModel course;
  final CourseLessonModel? lesson;
  final int nextLessonNumber;

  const PTLessonFormScreen({
    super.key,
    required this.course,
    this.lesson,
    this.nextLessonNumber = 1,
  });

  @override
  State<PTLessonFormScreen> createState() => _PTLessonFormScreenState();
}

class _PTLessonFormScreenState extends State<PTLessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lessonService = LessonService();
  final _storageService = StorageService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  int _lessonNumber = 1;
  LessonFileType _fileType = LessonFileType.image;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  File? _selectedFile;
  String? _fileUrl; // URL from existing lesson or uploaded file
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _titleController.text = widget.lesson!.title;
      _descriptionController.text = widget.lesson!.description ?? '';
      _fileUrl = widget.lesson!.fileUrl;
      _lessonNumber = widget.lesson!.lessonNumber;
      _fileType = widget.lesson!.fileType;
      _selectedDate = widget.lesson!.lessonDate;
      if (_selectedDate != null) {
        _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
      }
    } else {
      _lessonNumber = widget.nextLessonNumber;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _fileType = LessonFileType.image;
          _fileUrl = null; // Clear existing URL when new file is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _fileType = LessonFileType.video;
          _fileUrl = null; // Clear existing URL when new file is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final uploadedUrl = await _storageService.uploadLessonFile(
        file: _selectedFile!,
        userId: user.id,
        courseId: widget.course.id,
        isVideo: _fileType == LessonFileType.video,
      );

      if (uploadedUrl != null && mounted) {
        setState(() {
          _fileUrl = uploadedUrl;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_selectedTime == null) {
          _selectedTime = TimeOfDay.now();
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if file is selected but not uploaded
    if (_selectedFile != null && _fileUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload the selected file first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if file URL is available
    if (_fileUrl == null || _fileUrl!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select and upload a file'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime? lessonDate;
      if (_selectedDate != null && _selectedTime != null) {
        lessonDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      final lesson = CourseLessonModel(
        id: widget.lesson?.id ?? '',
        courseId: widget.course.id,
        lessonNumber: _lessonNumber,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        fileUrl: _fileUrl!,
        fileType: _fileType,
        lessonDate: lessonDate,
        createdAt: widget.lesson?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.lesson != null) {
        success = await _lessonService.updateLesson(lesson);
      } else {
        final id = await _lessonService.createLesson(lesson);
        success = id != null;
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lesson != null
                ? 'Lesson updated successfully'
                : 'Lesson created successfully'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save lesson'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson != null ? 'Edit Lesson' : 'Add Lesson'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveLesson,
              tooltip: 'Save',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course: ${widget.course.title}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: TextEditingController(text: _lessonNumber.toString()),
                decoration: const InputDecoration(
                  labelText: 'Lesson Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                readOnly: true,
                onTap: () async {
                  final number = await showDialog<int>(
                    context: context,
                    builder: (context) {
                      int tempNumber = _lessonNumber;
                      return AlertDialog(
                        title: const Text('Lesson Number'),
                        content: StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Current: $tempNumber'),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if (tempNumber > 1) {
                                          setState(() => tempNumber--);
                                        }
                                      },
                                    ),
                                    Text(
                                      '$tempNumber',
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() => tempNumber++);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, tempNumber),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                  if (number != null) {
                    setState(() => _lessonNumber = number);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Lesson Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter lesson title';
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
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // File Upload Section
              const Text(
                'File Upload *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isUploading ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isUploading ? null : _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Pick Video'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // File Preview and Upload
              if (_selectedFile != null || _fileUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _fileType == LessonFileType.image ? Icons.image : Icons.video_library,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFile != null
                                  ? _selectedFile!.path.split('/').last
                                  : 'File uploaded',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedFile != null && _fileUrl == null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() => _selectedFile = null);
                              },
                              tooltip: 'Remove',
                            ),
                        ],
                      ),
                      if (_selectedFile != null && _fileType == LessonFileType.image) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedFile!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      if (_fileUrl != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'URL: ${_fileUrl!.substring(0, _fileUrl!.length > 50 ? 50 : _fileUrl!.length)}...',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (_selectedFile != null && _fileUrl == null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadFile,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload),
                            label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select an image or video file',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Schedule (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedDate == null ? null : _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Select Time'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedDate != null && _selectedTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Scheduled: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} ${_selectedTime!.format(context)}',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _selectedTime = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLesson,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.lesson != null ? 'Update Lesson' : 'Create Lesson'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

