import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/course_lesson_model.dart';
import '../../models/lesson_exercise_model.dart';
import '../../models/exercise_model.dart';
import '../../models/equipment_model.dart';
import '../../services/course/lesson_service.dart';
import '../../services/course/exercise_service.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/section_header.dart';
import '../../widgets/empty_state_widget.dart';

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
  final _lessonService = LessonService();
  final _exerciseService = ExerciseService();

  int _lessonNumber = 1;
  bool _isLoading = false;
  bool _isLoadingData = true;
  List<LessonExerciseModel> _exercises = [];
  List<ExerciseModel> _availableExercises = [];
  List<EquipmentModel> _availableEquipment = [];

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _lessonNumber = widget.lesson!.lessonNumber;
      // Set order indices for exercises
      _exercises = widget.lesson!.exercises.asMap().entries.map((entry) {
        return entry.value.copyWith(orderIndex: entry.key);
      }).toList();
    } else {
      _lessonNumber = widget.nextLessonNumber;
    }
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final exercises = await _exerciseService.getAllExercises();
      final equipment = await _exerciseService.getAllEquipment();
      setState(() {
        _availableExercises = exercises;
        _availableEquipment = equipment;
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(
              text: 'Lỗi tải dữ liệu: $e',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isLoadingData = false);
      }
    }
  }


  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        exercise: null,
        availableExercises: _availableExercises,
        availableEquipment: _availableEquipment,
        onSave: (exercise) {
          setState(() {
            // Set order index based on current length
            _exercises.add(exercise.copyWith(orderIndex: _exercises.length));
          });
        },
      ),
    );
  }

  void _editExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        exercise: _exercises[index],
        availableExercises: _availableExercises,
        availableEquipment: _availableEquipment,
        onSave: (exercise) {
          setState(() {
            // Preserve order index
            _exercises[index] = exercise.copyWith(orderIndex: index);
          });
        },
      ),
    );
  }

  void _deleteExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: 'Xóa bài tập',
          variant: TextVariant.headlineSmall,
          color: DesignTokens.textPrimary,
        ),
        content: const CustomText(
          text: 'Bạn có chắc chắn muốn xóa bài tập này?',
          variant: TextVariant.bodyMedium,
          color: DesignTokens.textSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _exercises.removeAt(index);
                // Update order indices
                for (int i = index; i < _exercises.length; i++) {
                  _exercises[i] = _exercises[i].copyWith(orderIndex: i);
                }
              });
              Navigator.pop(context);
            },
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
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Auto-generate title from lesson number
      final title = 'Bài học $_lessonNumber';
      
      final lesson = CourseLessonModel(
        id: widget.lesson?.id ?? '',
        courseId: widget.course.id,
        lessonNumber: _lessonNumber,
        title: title,
        description: null,
        backgroundImageUrl: null,
        exercises: _exercises,
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
            content: CustomText(
              text: widget.lesson != null
                  ? 'Cập nhật bài học thành công'
                  : 'Tạo bài học thành công',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomText(
              text: 'Lưu bài học thất bại',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
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
            content: CustomText(
              text: 'Lỗi: $e',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: DesignTokens.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DesignTokens.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText(
          text: widget.lesson != null ? 'Chỉnh sửa bài học' : 'Thêm bài học',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
        ),
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
                onPressed: _saveLesson,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ),
        ],
      ),
      body: _isLoadingData
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primary),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.spacingMD),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCard(
                      variant: CardVariant.gymFresh,
                      child: Row(
                        children: [
                          Icon(Icons.school, color: DesignTokens.primary, size: 24),
                          SizedBox(width: DesignTokens.spacingMD),
                          Expanded(
                            child: CustomText(
                              text: widget.course.title,
                              variant: TextVariant.titleLarge,
                              color: DesignTokens.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingLG),
                    SelectionCard(
                      label: 'Số thứ tự bài học',
                      icon: Icons.numbers,
                      child: InkWell(
                        onTap: () async {
                          final number = await showDialog<int>(
                            context: context,
                            builder: (context) {
                              int tempNumber = _lessonNumber;
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                ),
                                title: CustomText(
                                  text: 'Số thứ tự bài học',
                                  variant: TextVariant.headlineSmall,
                                  color: DesignTokens.textPrimary,
                                ),
                                content: StatefulBuilder(
                                  builder: (context, setState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomText(
                                          text: 'Hiện tại: $tempNumber',
                                          variant: TextVariant.bodyLarge,
                                          color: DesignTokens.textSecondary,
                                        ),
                                        SizedBox(height: DesignTokens.spacingMD),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.remove_circle_outline, size: 32),
                                              color: DesignTokens.primary,
                                              onPressed: () {
                                                if (tempNumber > 1) {
                                                  setState(() => tempNumber--);
                                                }
                                              },
                                            ),
                                            SizedBox(width: DesignTokens.spacingMD),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: DesignTokens.spacingLG,
                                                vertical: DesignTokens.spacingMD,
                                              ),
                                              decoration: BoxDecoration(
                                                color: DesignTokens.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                              ),
                                              child: CustomText(
                                                text: '$tempNumber',
                                                variant: TextVariant.displaySmall,
                                                color: DesignTokens.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: DesignTokens.spacingMD),
                                            IconButton(
                                              icon: Icon(Icons.add_circle_outline, size: 32),
                                              color: DesignTokens.primary,
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
                                    child: CustomText(
                                      text: 'Hủy',
                                      variant: TextVariant.bodyMedium,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                  CustomButton(
                                    label: 'OK',
                                    icon: Icons.check,
                                    onPressed: () => Navigator.pop(context, tempNumber),
                                    variant: ButtonVariant.primary,
                                    size: ButtonSize.small,
                                  ),
                                ],
                              );
                            },
                          );
                          if (number != null) {
                            setState(() => _lessonNumber = number);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(DesignTokens.spacingMD),
                          decoration: BoxDecoration(
                            color: DesignTokens.surfaceLight,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: '$_lessonNumber',
                                variant: TextVariant.headlineMedium,
                                color: DesignTokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              Icon(Icons.edit, color: DesignTokens.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingLG),
                    // Exercises Section
                    SectionHeader(
                      title: 'Bài tập',
                      icon: Icons.fitness_center,
                      actionLabel: 'Thêm bài tập',
                      actionIcon: Icons.add,
                      onAction: _addExercise,
                    ),
                    SizedBox(height: DesignTokens.spacingMD),
                    if (_exercises.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.fitness_center_outlined,
                        title: 'Chưa có bài tập nào',
                        subtitle: 'Nhấn "Thêm bài tập" để bắt đầu',
                        actionLabel: 'Thêm bài tập',
                        actionIcon: Icons.add,
                        onAction: _addExercise,
                      )
              else
                ..._exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return CustomCard(
                    variant: CardVariant.gymFresh,
                    margin: EdgeInsets.only(bottom: DesignTokens.spacingSM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                text: exercise.exerciseName,
                                variant: TextVariant.titleMedium,
                                color: DesignTokens.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: DesignTokens.primary),
                                  onPressed: () => _editExercise(index),
                                  tooltip: 'Sửa',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: DesignTokens.error),
                                  onPressed: () => _deleteExercise(index),
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (exercise.equipment.isNotEmpty) ...[
                          SizedBox(height: DesignTokens.spacingSM),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: exercise.equipment.map((eq) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DesignTokens.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: DesignTokens.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: CustomText(
                                  text: eq,
                                  variant: TextVariant.bodySmall,
                                  color: DesignTokens.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        SizedBox(height: DesignTokens.spacingSM),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (exercise.sets != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat, size: 16, color: DesignTokens.textSecondary),
                                  SizedBox(width: 4),
                                  CustomText(
                                    text: '${exercise.sets} hiệp',
                                    variant: TextVariant.bodySmall,
                                    color: DesignTokens.textSecondary,
                                  ),
                                ],
                              ),
                            if (exercise.reps != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat_one, size: 16, color: DesignTokens.textSecondary),
                                  SizedBox(width: 4),
                                  CustomText(
                                    text: '${exercise.reps} rep',
                                    variant: TextVariant.bodySmall,
                                    color: DesignTokens.textSecondary,
                                  ),
                                ],
                              ),
                            if (exercise.restTimeSeconds != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 16, color: DesignTokens.textSecondary),
                                  SizedBox(width: 4),
                                  CustomText(
                                    text: 'Nghỉ: ${exercise.restTimeSeconds}s',
                                    variant: TextVariant.bodySmall,
                                    color: DesignTokens.textSecondary,
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                          SizedBox(height: DesignTokens.spacingSM),
                          Container(
                            padding: EdgeInsets.all(DesignTokens.spacingSM),
                            decoration: BoxDecoration(
                              color: DesignTokens.surfaceLight,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note_outlined, size: 16, color: DesignTokens.textSecondary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: CustomText(
                                    text: exercise.notes!,
                                    variant: TextVariant.bodySmall,
                                    color: DesignTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              SizedBox(height: DesignTokens.spacingLG),
              CustomButton(
                label: widget.lesson != null ? 'Cập nhật bài học' : 'Tạo bài học',
                icon: Icons.save,
                onPressed: _isLoading ? null : _saveLesson,
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog for adding/editing exercises
class _ExerciseDialog extends StatefulWidget {
  final LessonExerciseModel? exercise;
  final List<ExerciseModel> availableExercises;
  final List<EquipmentModel> availableEquipment;
  final Function(LessonExerciseModel) onSave;

  const _ExerciseDialog({
    this.exercise,
    required this.availableExercises,
    required this.availableEquipment,
    required this.onSave,
  });

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  ExerciseModel? _selectedExercise;
  Set<int> _selectedEquipmentIds = {};
  Set<String> _selectedEquipmentNames = {}; // For display
  double _sets = 3.0;
  double _reps = 10.0;
  double _restTime = 60.0;

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null && widget.availableExercises.isNotEmpty) {
      // Find the exercise from available exercises
      ExerciseModel? foundExercise;
      
      // Try to find by exerciseId first (if not 0)
      if (widget.exercise!.exerciseId > 0) {
        try {
          foundExercise = widget.availableExercises.firstWhere(
            (e) => e.exerciseId == widget.exercise!.exerciseId,
          );
        } catch (e) {
          // Not found by ID, try by name
        }
      }
      
      // If not found by ID, try by name
      if (foundExercise == null && widget.exercise!.exerciseName.isNotEmpty) {
        try {
          foundExercise = widget.availableExercises.firstWhere(
            (e) => e.name == widget.exercise!.exerciseName,
          );
        } catch (e) {
          // Not found by name either
        }
      }
      
      // Default to first exercise if still not found
      _selectedExercise = foundExercise ?? widget.availableExercises.first;
      
      _sets = widget.exercise!.sets?.toDouble() ?? 3.0;
      _reps = widget.exercise!.reps?.toDouble() ?? 10.0;
      _restTime = widget.exercise!.restTimeSeconds?.toDouble() ?? 60.0;
      _notesController.text = widget.exercise!.notes ?? '';
      
      // Load equipment IDs and names
      _selectedEquipmentIds = Set.from(widget.exercise!.equipmentIds);
      _selectedEquipmentNames = Set.from(widget.exercise!.equipment);
    } else {
      // Default to first exercise if available
      if (widget.availableExercises.isNotEmpty) {
        _selectedExercise = widget.availableExercises.first;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            text: 'Vui lòng chọn bài tập',
            variant: TextVariant.bodyMedium,
            color: Colors.white,
          ),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_selectedExercise!.exerciseId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            text: 'Bài tập không hợp lệ. Vui lòng chọn lại.',
            variant: TextVariant.bodyMedium,
            color: Colors.white,
          ),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final exercise = LessonExerciseModel(
      id: widget.exercise?.id,
      exerciseId: _selectedExercise!.exerciseId,
      exerciseName: _selectedExercise!.name,
      equipmentIds: _selectedEquipmentIds.toList(),
      equipment: _selectedEquipmentNames.toList(),
      sets: _sets.toInt(),
      reps: _reps.toInt(),
      restTimeSeconds: _restTime.toInt(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      orderIndex: widget.exercise?.orderIndex ?? 0,
    );

    widget.onSave(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomText(
        text: widget.exercise != null ? 'Sửa bài tập' : 'Thêm bài tập',
        variant: TextVariant.headlineSmall,
        color: DesignTokens.textPrimary,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Selection Dropdown
              CustomDropdown<ExerciseModel>(
                label: 'Chọn bài tập',
                icon: Icons.fitness_center,
                value: _selectedExercise,
                items: widget.availableExercises.map((exercise) {
                  return DropdownMenuItem<ExerciseModel>(
                    value: exercise,
                    child: CustomText(
                      text: exercise.name,
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textPrimary,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExercise = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn bài tập';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Equipment Selection
              const CustomText(
                text: 'Dụng cụ tập',
                variant: TextVariant.titleMedium,
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableEquipment.map((equipment) {
                  final isSelected = _selectedEquipmentIds.contains(equipment.equipmentId);
                  return FilterChip(
                    label: CustomText(
                      text: equipment.name,
                      variant: TextVariant.bodySmall,
                      color: DesignTokens.textPrimary,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEquipmentIds.add(equipment.equipmentId);
                          _selectedEquipmentNames.add(equipment.name);
                        } else {
                          _selectedEquipmentIds.remove(equipment.equipmentId);
                          _selectedEquipmentNames.remove(equipment.name);
                        }
                      });
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[800],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Sets Slider
              SliderInputCard(
                label: 'Số hiệp',
                icon: Icons.repeat,
                value: _sets,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  setState(() {
                    _sets = value;
                  });
                },
                formatter: (val) => '${val.toInt()} hiệp',
              ),
              const SizedBox(height: 16),
              // Reps Slider
              SliderInputCard(
                label: 'Số rep',
                icon: Icons.repeat_one,
                value: _reps,
                min: 1,
                max: 50,
                divisions: 49,
                onChanged: (value) {
                  setState(() {
                    _reps = value;
                  });
                },
                formatter: (val) => '${val.toInt()} rep',
              ),
              const SizedBox(height: 16),
              // Rest Time Slider
              SliderInputCard(
                label: 'Thời gian nghỉ',
                icon: Icons.timer_outlined,
                value: _restTime,
                min: 0,
                max: 300,
                divisions: 60,
                onChanged: (value) {
                  setState(() {
                    _restTime = value;
                  });
                },
                formatter: (val) => '${val.toInt()} giây',
              ),
              const SizedBox(height: 16),
              // Notes
              CustomInput(
                label: 'Ghi chú',
                icon: Icons.note_outlined,
                controller: _notesController,
                hint: 'Nhập ghi chú (tùy chọn)',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: CustomText(
            text: 'Hủy',
            variant: TextVariant.bodyMedium,
            color: DesignTokens.textSecondary,
          ),
        ),
        CustomButton(
          label: 'Lưu',
          icon: Icons.check,
          onPressed: _save,
          variant: ButtonVariant.primary,
          size: ButtonSize.small,
        ),
      ],
    );
  }
}
