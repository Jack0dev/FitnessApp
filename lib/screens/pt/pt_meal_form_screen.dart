import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/meal_model.dart';
import '../../services/content/meal_service.dart';
import '../../services/common/sql_database_service.dart';
import '../../config/supabase_config.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/section_header.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/date_picker_input.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PTMealFormScreen extends StatefulWidget {
  final CourseModel course;
  final MealModel? meal;

  const PTMealFormScreen({super.key, required this.course, this.meal});

  @override
  State<PTMealFormScreen> createState() => _PTMealFormScreenState();
}

class _PTMealFormScreenState extends State<PTMealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealService = MealService();
  SqlDatabaseService? _sqlService;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalCaloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _waterController = TextEditingController();
  final _totalWeightController = TextEditingController();
  final _noteController = TextEditingController();
  final _imageUrlController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  MealTimeSlot _selectedTimeSlot = MealTimeSlot.breakfast;
  List<MealItemModel> _mealItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize SQL service if Supabase is configured
    if (SupabaseConfig.isConfigured && Supabase.instance.isInitialized) {
      _sqlService = SqlDatabaseService();
    }
    if (widget.meal != null) {
      _titleController.text = widget.meal!.title;
      _descriptionController.text = widget.meal!.description ?? '';
      _totalCaloriesController.text = widget.meal!.totalCalories?.toString() ?? '';
      _proteinController.text = widget.meal!.proteinGram?.toString() ?? '';
      _carbController.text = widget.meal!.carbGram?.toString() ?? '';
      _fatController.text = widget.meal!.fatGram?.toString() ?? '';
      _fiberController.text = widget.meal!.fiberGram?.toString() ?? '';
      _waterController.text = widget.meal!.waterMl?.toString() ?? '';
      _totalWeightController.text = widget.meal!.totalWeightGram?.toString() ?? '';
      _noteController.text = widget.meal!.note ?? '';
      _imageUrlController.text = widget.meal!.imageUrl ?? '';
      _selectedDate = widget.meal!.mealDate;
      _selectedTimeSlot = MealTimeSlot.fromString(widget.meal!.mealTimeSlot);
      _mealItems = List.from(widget.meal!.items);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _totalCaloriesController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _waterController.dispose();
    _totalWeightController.dispose();
    _noteController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final meal = MealModel(
        mealId: widget.meal?.mealId ?? 0,
        courseId: widget.course.id,
        mealDate: _selectedDate,
        mealTimeSlot: _selectedTimeSlot.value,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        totalCalories: _totalCaloriesController.text.trim().isEmpty
            ? null
            : int.tryParse(_totalCaloriesController.text),
        proteinGram: _proteinController.text.trim().isEmpty
            ? null
            : double.tryParse(_proteinController.text),
        carbGram: _carbController.text.trim().isEmpty
            ? null
            : double.tryParse(_carbController.text),
        fatGram: _fatController.text.trim().isEmpty
            ? null
            : double.tryParse(_fatController.text),
        fiberGram: _fiberController.text.trim().isEmpty
            ? null
            : double.tryParse(_fiberController.text),
        waterMl: _waterController.text.trim().isEmpty
            ? null
            : int.tryParse(_waterController.text),
        totalWeightGram: _totalWeightController.text.trim().isEmpty
            ? null
            : double.tryParse(_totalWeightController.text),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        createdAt: widget.meal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        items: _mealItems,
      );

      bool success;
      if (widget.meal != null) {
        success = await _mealService.updateMeal(meal);
        // Update meal items separately
        if (success) {
          // Delete existing items and recreate (simplified approach)
          for (final item in widget.meal!.items) {
            await _mealService.deleteMealItem(item.mealItemId);
          }
          // Create new items
          if (_sqlService != null && _mealItems.isNotEmpty) {
            for (final item in _mealItems) {
              final itemData = item.toSupabase();
              itemData.remove('meal_item_id');
              itemData['meal_id'] = meal.mealId;
              await _sqlService!.client
                  .from('meal_item')
                  .insert(itemData);
            }
          }
        }
      } else {
        final mealId = await _mealService.createMeal(meal);
        success = mealId != null;
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(
              text: widget.meal != null
                  ? 'Đã cập nhật bữa ăn thành công'
                  : 'Đã tạo bữa ăn thành công',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
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
            content: const CustomText(
              text: 'Không thể lưu bữa ăn',
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

  void _addMealItem() {
    showDialog(
      context: context,
      builder: (context) => _MealItemDialog(
        onSave: (item) {
          setState(() {
            _mealItems.add(item);
          });
        },
      ),
    );
  }

  void _editMealItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _MealItemDialog(
        item: _mealItems[index],
        onSave: (item) {
          setState(() {
            _mealItems[index] = item;
          });
        },
      ),
    );
  }

  void _deleteMealItem(int index) {
    setState(() {
      _mealItems.removeAt(index);
    });
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
          text: widget.meal != null ? 'Chỉnh sửa bữa ăn' : 'Thêm bữa ăn',
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
                onPressed: _saveMeal,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Time Slot
              Row(
                children: [
                  Expanded(
                    child: DatePickerInput(
                      label: 'Ngày ăn',
                      icon: Icons.calendar_today,
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                      },
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingMD),
                  Expanded(
                    child: SelectionCard(
                      label: 'Bữa',
                      icon: Icons.restaurant,
                      child: CustomDropdown<MealTimeSlot>(
                        label: '',
                        value: _selectedTimeSlot,
                        items: MealTimeSlot.values.map((slot) {
                          return DropdownMenuItem(
                            value: slot,
                            child: CustomText(
                              text: slot.displayName,
                              variant: TextVariant.bodyMedium,
                              color: DesignTokens.textPrimary,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTimeSlot = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingMD),
              CustomInput(
                label: 'Tên bữa ăn',
                icon: Icons.restaurant_menu,
                controller: _titleController,
                hint: 'Ví dụ: Bữa sáng low-carb',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên bữa ăn';
                  }
                  return null;
                },
              ),
              SizedBox(height: DesignTokens.spacingMD),
              CustomInput(
                label: 'Mô tả',
                icon: Icons.description,
                controller: _descriptionController,
                hint: 'Mô tả về bữa ăn',
                maxLines: 3,
              ),
              SizedBox(height: DesignTokens.spacingLG),
              // Macros
              SectionHeader(
                title: 'Thông tin dinh dưỡng',
                icon: Icons.local_dining,
              ),
              SizedBox(height: DesignTokens.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: NumberInputCard(
                      label: 'Calories',
                      icon: Icons.local_fire_department,
                      iconColor: DesignTokens.warning,
                      controller: _totalCaloriesController,
                      suffix: 'kcal',
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingMD),
                  Expanded(
                    child: NumberInputCard(
                      label: 'Protein',
                      icon: Icons.egg,
                      iconColor: DesignTokens.info,
                      controller: _proteinController,
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: NumberInputCard(
                      label: 'Carb',
                      icon: Icons.grain,
                      iconColor: DesignTokens.secondary,
                      controller: _carbController,
                      suffix: 'g',
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingMD),
                  Expanded(
                    child: NumberInputCard(
                      label: 'Fat',
                      icon: Icons.water_drop,
                      iconColor: DesignTokens.accent,
                      controller: _fatController,
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: NumberInputCard(
                      label: 'Chất xơ',
                      icon: Icons.eco,
                      iconColor: DesignTokens.success,
                      controller: _fiberController,
                      suffix: 'g',
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingMD),
                  Expanded(
                    child: NumberInputCard(
                      label: 'Nước',
                      icon: Icons.water,
                      iconColor: DesignTokens.info,
                      controller: _waterController,
                      suffix: 'ml',
                    ),
                  ),
                ],
              ),
              NumberInputCard(
                label: 'Tổng khối lượng',
                icon: Icons.scale,
                iconColor: DesignTokens.textSecondary,
                controller: _totalWeightController,
                suffix: 'g',
                useExpanded: false,
              ),
              SizedBox(height: DesignTokens.spacingMD),
              CustomInput(
                label: 'Ghi chú',
                icon: Icons.note_outlined,
                controller: _noteController,
                hint: 'Ghi chú về bữa ăn',
                maxLines: 2,
              ),
              SizedBox(height: DesignTokens.spacingMD),
              CustomInput(
                label: 'URL hình ảnh',
                icon: Icons.image,
                controller: _imageUrlController,
                hint: 'https://example.com/image.jpg',
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: DesignTokens.spacingLG),
              // Meal Items
              SectionHeader(
                title: 'Chi tiết món ăn',
                icon: Icons.restaurant_menu,
                actionLabel: 'Thêm món',
                actionIcon: Icons.add,
                onAction: _addMealItem,
              ),
              SizedBox(height: DesignTokens.spacingMD),
              if (_mealItems.isEmpty)
                EmptyStateWidget(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Chưa có món ăn nào',
                  subtitle: 'Nhấn "Thêm món" để bắt đầu',
                  actionLabel: 'Thêm món',
                  actionIcon: Icons.add,
                  onAction: _addMealItem,
                )
              else
                ..._mealItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return CustomCard(
                    variant: CardVariant.gymFresh,
                    margin: EdgeInsets.only(bottom: DesignTokens.spacingSM),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(DesignTokens.spacingMD),
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                          ),
                          child: Icon(Icons.restaurant_menu, color: DesignTokens.primary, size: 24),
                        ),
                        SizedBox(width: DesignTokens.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: item.foodName,
                                variant: TextVariant.titleMedium,
                                color: DesignTokens.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item.servingSizeGram != null)
                                    CustomText(
                                      text: '${item.servingSizeGram!.toInt()}g',
                                      variant: TextVariant.bodySmall,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  if (item.calories != null)
                                    CustomText(
                                      text: '${item.calories} kcal',
                                      variant: TextVariant.bodySmall,
                                      color: DesignTokens.textSecondary,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: 20, color: DesignTokens.primary),
                              onPressed: () => _editMealItem(index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, size: 20, color: DesignTokens.error),
                              onPressed: () => _deleteMealItem(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              SizedBox(height: DesignTokens.spacingLG),
              CustomButton(
                label: widget.meal != null ? 'Cập nhật bữa ăn' : 'Tạo bữa ăn',
                icon: Icons.save,
                onPressed: _isLoading ? null : _saveMeal,
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

class _MealItemDialog extends StatefulWidget {
  final MealItemModel? item;
  final Function(MealItemModel) onSave;

  const _MealItemDialog({this.item, required this.onSave});

  @override
  State<_MealItemDialog> createState() => _MealItemDialogState();
}

class _MealItemDialogState extends State<_MealItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _foodNameController.text = widget.item!.foodName;
      _servingSizeController.text = widget.item!.servingSizeGram?.toString() ?? '';
      _caloriesController.text = widget.item!.calories?.toString() ?? '';
      _proteinController.text = widget.item!.proteinGram?.toString() ?? '';
      _carbController.text = widget.item!.carbGram?.toString() ?? '';
      _fatController.text = widget.item!.fatGram?.toString() ?? '';
      _noteController.text = widget.item!.note ?? '';
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final item = MealItemModel(
      mealItemId: widget.item?.mealItemId ?? 0,
      mealId: widget.item?.mealId ?? 0,
      foodName: _foodNameController.text.trim(),
      servingSizeGram: _servingSizeController.text.trim().isEmpty
          ? null
          : double.tryParse(_servingSizeController.text),
      calories: _caloriesController.text.trim().isEmpty
          ? null
          : int.tryParse(_caloriesController.text),
      proteinGram: _proteinController.text.trim().isEmpty
          ? null
          : double.tryParse(_proteinController.text),
      carbGram: _carbController.text.trim().isEmpty
          ? null
          : double.tryParse(_carbController.text),
      fatGram: _fatController.text.trim().isEmpty
          ? null
          : double.tryParse(_fatController.text),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    widget.onSave(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomText(
        text: widget.item != null ? 'Chỉnh sửa món ăn' : 'Thêm món ăn',
        variant: TextVariant.headlineSmall,
        color: DesignTokens.textPrimary,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInput(
                label: 'Tên món ăn',
                icon: Icons.restaurant_menu,
                controller: _foodNameController,
                hint: 'Nhập tên món ăn',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên món ăn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NumberInputCard(
                      label: 'Khối lượng',
                      icon: Icons.scale,
                      iconColor: DesignTokens.textSecondary,
                      controller: _servingSizeController,
                      suffix: 'g',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberInputCard(
                      label: 'Calories',
                      icon: Icons.local_fire_department,
                      iconColor: DesignTokens.warning,
                      controller: _caloriesController,
                      suffix: 'kcal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NumberInputCard(
                      label: 'Protein',
                      icon: Icons.egg,
                      iconColor: DesignTokens.info,
                      controller: _proteinController,
                      suffix: 'g',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberInputCard(
                      label: 'Carb',
                      icon: Icons.grain,
                      iconColor: DesignTokens.secondary,
                      controller: _carbController,
                      suffix: 'g',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberInputCard(
                      label: 'Fat',
                      icon: Icons.water_drop,
                      iconColor: DesignTokens.accent,
                      controller: _fatController,
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Ghi chú',
                icon: Icons.note_outlined,
                controller: _noteController,
                hint: 'Ghi chú về món ăn',
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

