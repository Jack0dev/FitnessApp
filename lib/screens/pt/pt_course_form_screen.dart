import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course_model.dart';
import '../../models/equipment_model.dart';
import '../../services/course/course_service.dart';
import '../../services/course/exercise_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/common/storage_service.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/widgets.dart';

class PTCourseFormScreen extends StatefulWidget {
  final CourseModel? course;

  const PTCourseFormScreen({super.key, this.course});

  @override
  State<PTCourseFormScreen> createState() => _PTCourseFormScreenState();
}

class _PTCourseFormScreenState extends State<PTCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  late final CourseService _courseService;
  late final ExerciseService _exerciseService;
  final _authService = AuthService();
  late final DataService _dataService;
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  
  CourseLevel _level = CourseLevel.beginner;
  CourseStatus _status = CourseStatus.active;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedEquipment = [];
  List<EquipmentModel> _availableEquipment = [];
  bool _isLoading = false;
  bool _isLoadingEquipment = true;
  bool _isExpandingEquipment = false;
  String? _initializationError;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    try {
      _courseService = CourseService();
      _exerciseService = ExerciseService();
      _dataService = DataService();
    } catch (e) {
      _initializationError = 'Không thể khởi tạo dịch vụ: $e';
      print('Error initializing services: $e');
    }
    
    if (widget.course != null) {
      _titleController.text = widget.course!.title;
      _descriptionController.text = widget.course!.description;
      _priceController.text = widget.course!.price.toString();
      _durationController.text = widget.course!.duration.toString();
      _maxStudentsController.text = widget.course!.maxStudents.toString();
      _uploadedImageUrl = widget.course!.imageUrl;
      _level = widget.course!.level;
      _status = widget.course!.status;
      _startDate = widget.course!.startDate;
      _endDate = widget.course!.endDate;
      _selectedEquipment = List<String>.from(widget.course!.equipment ?? []);
    }
    
    if (_initializationError == null) {
      _loadEquipment();
    }
  }

  Future<void> _loadEquipment() async {
    if (_initializationError != null) return;
    
    setState(() => _isLoadingEquipment = true);
    try {
      final equipment = await _exerciseService.getAllEquipment();
      setState(() {
        _availableEquipment = equipment;
        _isLoadingEquipment = false;
      });
    } catch (e) {
      print('Failed to load equipment: $e');
      setState(() => _isLoadingEquipment = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageUrl = null; // Clear uploaded URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: ${e.toString()}'),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return _uploadedImageUrl; // Return existing URL if no new image
    }

    final user = _authService.currentUser;
    if (user == null) return null;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final publicUrl = await _storageService.uploadImage(
        imageFile: _selectedImage!,
        userId: user.id,
        folder: 'course_images',
      );

      if (publicUrl != null) {
        setState(() {
          _uploadedImageUrl = publicUrl;
          _isUploadingImage = false;
        });
        return publicUrl;
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi upload ảnh: ${e.toString()}'),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }

    return null;
  }

  IconData _getEquipmentIcon(String? iconName) {
    // Map icon names to Material icons
    if (iconName == null) return Icons.fitness_center;
    
    final iconMap = {
      'fitness_center': Icons.fitness_center,
      'sports_gymnastics': Icons.sports_gymnastics,
      'cable': Icons.cable,
      'linear_scale': Icons.linear_scale,
      'chair': Icons.chair,
      'directions_run': Icons.directions_run,
      'directions_bike': Icons.directions_bike,
      'sports_martial_arts': Icons.sports_martial_arts,
      'sports_basketball': Icons.sports_basketball,
      'crop_square': Icons.crop_square,
      'skip_next': Icons.skip_next,
      'circle': Icons.circle,
    };
    
    return iconMap[iconName] ?? Icons.fitness_center;
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

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_initializationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text(_initializationError!)),
              ],
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userModel = await _dataService.getUserData(user.id);
      if (userModel == null) {
        throw Exception('User data not found');
      }

      CourseModel course = CourseModel(
        id: widget.course?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructorId: user.id,
        instructorName: userModel.displayName,
        price: double.tryParse(_priceController.text) ?? 0.0,
        duration: int.tryParse(_durationController.text) ?? 0,
        maxStudents: int.tryParse(_maxStudentsController.text) ?? 0,
        imageUrl: _uploadedImageUrl,
        startDate: _startDate,
        endDate: _endDate,
        equipment: _selectedEquipment.isEmpty ? null : _selectedEquipment,
        level: _level,
        status: _status,
        createdAt: widget.course?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Upload image first if a new one was selected
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage();
        if (uploadedUrl == null && _uploadedImageUrl == null) {
          // Image upload failed and no existing URL
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi upload ảnh. Vui lòng thử lại.'),
                backgroundColor: DesignTokens.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        // Update course with new image URL
        course = course.copyWith(imageUrl: uploadedUrl);
      }

      bool success;
      if (widget.course != null) {
        success = await _courseService.updateCourse(course);
      } else {
        final id = await _courseService.createCourse(course);
        success = id != null;
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(widget.course != null
                    ? 'Course updated successfully'
                    : 'Course created successfully'),
              ],
            ),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Không thể lưu khóa học'),
              ],
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $e')),
              ],
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      backgroundColor: DesignTokens.background,
      appBar: CustomAppBar(
        title: widget.course != null ? 'Chỉnh sửa khóa học' : 'Tạo khóa học mới',
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primary),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CustomButton(
                label: 'Lưu',
                icon: Icons.check,
                onPressed: _saveCourse,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ),
        ],
      ),
      body: _initializationError != null
          ? ErrorDisplayWidget(
              title: 'Lỗi khởi tạo',
              message: _initializationError!,
              onRetry: () => Navigator.pop(context),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(DesignTokens.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // Title Input
              CustomInput(
                label: 'Tên khóa học',
                icon: Icons.title,
                controller: _titleController,
                hint: 'Nhập tên khóa học',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên khóa học';
                  }
                  return null;
                },
              ),

              // Description Input
              CustomInput(
                label: 'Mô tả',
                icon: Icons.description,
                controller: _descriptionController,
                hint: 'Mô tả chi tiết về khóa học',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),

              // Price and Duration Row
              Row(
                children: [
                  NumberInputCard(
                    label: 'Giá',
                    icon: Icons.attach_money,
                    iconColor: DesignTokens.success,
                    controller: _priceController,
                    suffix: '₫',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nhập giá';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Giá không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  SizedBox(width: DesignTokens.spacingMD),
                  NumberInputCard(
                    label: 'Thời lượng',
                    icon: Icons.calendar_today,
                    iconColor: DesignTokens.info,
                    controller: _durationController,
                    suffix: 'ngày',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nhập thời lượng';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // Max Students
              NumberInputCard(
                label: 'Số học viên tối đa',
                icon: Icons.people,
                iconColor: DesignTokens.warning,
                controller: _maxStudentsController,
                suffix: 'người',
                useExpanded: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập số lượng';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Không hợp lệ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: DesignTokens.spacingMD),

              // Start Date and End Date
              Row(
                children: [
                  Expanded(
                    child: DatePickerInput(
                      label: 'Ngày bắt đầu',
                      icon: Icons.calendar_today,
                      selectedDate: _startDate ?? DateTime.now(),
                      onDateSelected: (date) {
                        setState(() {
                          _startDate = date;
                          // Auto-set end date if it's before start date
                          if (_endDate != null && _endDate!.isBefore(date)) {
                            _endDate = date.add(const Duration(days: 30));
                          }
                        });
                      },
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      formatter: (date) {
                        return '${date.day}/${date.month}/${date.year}';
                      },
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMD),
                  Expanded(
                    child: DatePickerInput(
                      label: 'Ngày kết thúc',
                      icon: Icons.event,
                      selectedDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
                      onDateSelected: (date) {
                        if (_startDate != null && date.isBefore(_startDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const CustomText(
                                text: 'Ngày kết thúc phải sau ngày bắt đầu',
                                variant: TextVariant.bodyMedium,
                                color: Colors.white,
                              ),
                              backgroundColor: DesignTokens.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _endDate = date;
                        });
                      },
                      firstDate: _startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      formatter: (date) {
                        return '${date.day}/${date.month}/${date.year}';
                      },
                    ),
                  ),
                ],
              ),

              // Image Upload
              CustomCard(
                variant: CardVariant.gymFresh,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, size: 18, color: DesignTokens.primary),
                        const SizedBox(width: 8),
                        CustomText(
                          text: 'Hình ảnh khóa học',
                          variant: TextVariant.titleMedium,
                          color: DesignTokens.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: DesignTokens.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DesignTokens.borderDefault,
                            width: 1.5,
                          ),
                        ),
                        child: _isUploadingImage
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primary),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomText(
                                      text: 'Đang upload...',
                                      variant: TextVariant.bodyMedium,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ],
                                ),
                              )
                            : (_selectedImage != null || _uploadedImageUrl != null)
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _selectedImage != null
                                            ? Image.file(
                                                _selectedImage!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                                              )
                                            : (_uploadedImageUrl != null
                                                ? Image.network(
                                                    _uploadedImageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                                                  )
                                                : _buildImagePlaceholder()),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18),
                                            color: Colors.white,
                                            onPressed: () {
                                              setState(() {
                                                _selectedImage = null;
                                                _uploadedImageUrl = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : _buildImagePlaceholder(),
                      ),
                    ),
                    if (_selectedImage != null || _uploadedImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextButton.icon(
                          onPressed: _isUploadingImage ? null : _pickImage,
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Chọn ảnh khác'),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Equipment Selection
              CustomCard(
                variant: CardVariant.gymFresh,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fitness_center, size: 18, color: DesignTokens.primary),
                        const SizedBox(width: 8),
                        CustomText(
                          text: 'Dụng cụ tập',
                          variant: TextVariant.titleMedium,
                          color: DesignTokens.textPrimary,
                        ),
                        const Spacer(),
                        if (_selectedEquipment.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: DesignTokens.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomText(
                              text: '${_selectedEquipment.length} đã chọn',
                              variant: TextVariant.bodyMedium,
                              color: DesignTokens.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingMD),
                    if (_isLoadingEquipment)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(DesignTokens.spacingLG),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primary),
                          ),
                        ),
                      )
                    else if (_availableEquipment.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.fitness_center_outlined,
                        title: 'Chưa có dụng cụ nào',
                        subtitle: 'Vui lòng thêm dụng cụ vào hệ thống',
                        iconColor: DesignTokens.textLight,
                      )
                    else ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: (_isExpandingEquipment
                                ? _availableEquipment
                                : _availableEquipment.take(5))
                            .map((equipment) {
                          final name = equipment.name;
                          final icon = _getEquipmentIcon(equipment.icon);
                          final isSelected = _selectedEquipment.contains(name);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedEquipment.remove(name);
                                } else {
                                  _selectedEquipment.add(name);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DesignTokens.primary
                                    : DesignTokens.surfaceLight,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                border: Border.all(
                                  color: isSelected
                                      ? DesignTokens.primary
                                      : DesignTokens.borderLight,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected ? DesignTokens.shadowGreenMD : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected ? Colors.white : DesignTokens.primary,
                                  ),
                                  SizedBox(width: 8),
                                  CustomText(
                                    text: name,
                                    variant: TextVariant.bodyMedium,
                                    color: isSelected ? Colors.white : DesignTokens.textDark,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                  if (isSelected) ...[
                                    SizedBox(width: 6),
                                    Icon(Icons.check_circle, size: 16, color: Colors.white),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_availableEquipment.length > 5 && !_isExpandingEquipment)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isExpandingEquipment = true;
                                });
                              },
                              icon: const Icon(Icons.expand_more, size: 18),
                              label: Text('Xem thêm ${_availableEquipment.length - 5} dụng cụ'),
                              style: TextButton.styleFrom(
                                foregroundColor: DesignTokens.primary,
                              ),
                            ),
                          ),
                        ),
                      if (_isExpandingEquipment && _availableEquipment.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isExpandingEquipment = false;
                                });
                              },
                              icon: const Icon(Icons.expand_less, size: 18),
                              label: const Text('Ẩn bớt'),
                              style: TextButton.styleFrom(
                                foregroundColor: DesignTokens.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // Level Selection
              SelectionCard(
                label: 'Độ khó',
                icon: Icons.trending_up,
                child: CustomDropdown<CourseLevel>(
                  label: '',
                  value: _level,
                  items: CourseLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Row(
                        children: [
                          Icon(
                            _getLevelIcon(level),
                            size: 20,
                            color: _getLevelColor(level),
                          ),
                          const SizedBox(width: 12),
                          CustomText(
                            text: level.displayName,
                            variant: TextVariant.bodyLarge,
                            color: DesignTokens.textDark,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _level = value);
                    }
                  },
                ),
              ),

              // Status Selection
              SelectionCard(
                label: 'Trạng thái',
                icon: Icons.info,
                child: CustomDropdown<CourseStatus>(
                  label: '',
                  value: _status,
                  items: CourseStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CustomText(
                            text: status.displayName,
                            variant: TextVariant.bodyLarge,
                            color: DesignTokens.textDark,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
              ),

              SizedBox(height: DesignTokens.spacingLG),

              // Save Button
              CustomButton(
                label: widget.course != null ? 'Cập nhật khóa học' : 'Tạo khóa học',
                icon: Icons.save,
                onPressed: _saveCourse,
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                isLoading: _isLoading,
                isFullWidth: true,
              ),

              SizedBox(height: DesignTokens.spacingMD),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLevelIcon(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return Icons.arrow_upward;
      case CourseLevel.intermediate:
        return Icons.trending_up;
      case CourseLevel.advanced:
        return Icons.arrow_upward;
    }
  }

  Color _getLevelColor(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return DesignTokens.success;
      case CourseLevel.intermediate:
        return DesignTokens.warning;
      case CourseLevel.advanced:
        return DesignTokens.error;
    }
  }

  Color _getStatusColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.active:
        return DesignTokens.success;
      case CourseStatus.inactive:
        return DesignTokens.textLight;
      case CourseStatus.completed:
        return DesignTokens.info;
      case CourseStatus.canceled:
        return DesignTokens.error;
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: DesignTokens.textLight,
          ),
          const SizedBox(height: 12),
          CustomText(
            text: 'Nhấn để chọn ảnh',
            variant: TextVariant.bodyMedium,
            color: DesignTokens.textSecondary,
          ),
        ],
      ),
    );
  }
}
