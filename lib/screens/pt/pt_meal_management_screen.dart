import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/meal_model.dart';
import '../../services/content/meal_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import 'pt_meal_form_screen.dart';

class PTMealManagementScreen extends StatefulWidget {
  final CourseModel course;

  const PTMealManagementScreen({super.key, required this.course});

  @override
  State<PTMealManagementScreen> createState() => _PTMealManagementScreenState();
}

class _PTMealManagementScreenState extends State<PTMealManagementScreen> {
  final _mealService = MealService();
  List<MealModel> _meals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final meals = await _mealService.getMealsByCourse(widget.course.id);
      setState(() {
        _meals = meals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMeal(MealModel meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: 'Xóa bữa ăn',
          variant: TextVariant.headlineSmall,
          color: DesignTokens.textPrimary,
        ),
        content: CustomText(
          text: 'Bạn có chắc chắn muốn xóa "${meal.title}"?',
          variant: TextVariant.bodyMedium,
          color: DesignTokens.textSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const CustomText(
              text: 'Hủy',
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
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

    if (confirm == true) {
      final success = await _mealService.deleteMeal(meal.mealId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomText(
              text: 'Đã xóa bữa ăn thành công',
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
        _loadMeals();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomText(
              text: 'Không thể xóa bữa ăn',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      CustomText(
                        text: 'Lỗi: $_error',
                        variant: TextVariant.bodyMedium,
                        color: DesignTokens.error,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Thử lại',
                        icon: Icons.refresh,
                        onPressed: _loadMeals,
                        variant: ButtonVariant.primary,
                        size: ButtonSize.medium,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMeals,
                  child: _meals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              CustomText(
                                text: 'Chưa có bữa ăn nào',
                                variant: TextVariant.headlineSmall,
                                color: DesignTokens.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                text: 'Thêm bữa ăn đầu tiên cho khóa học này!',
                                variant: TextVariant.bodyMedium,
                                color: DesignTokens.textLight,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                label: 'Thêm bữa ăn',
                                icon: Icons.add,
                                onPressed: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PTMealFormScreen(
                                        course: widget.course,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadMeals();
                                  }
                                },
                                variant: ButtonVariant.primary,
                                size: ButtonSize.medium,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Header with add button
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomText(
                                    text: 'Danh sách bữa ăn (${_meals.length})',
                                    variant: TextVariant.headlineSmall,
                                    color: DesignTokens.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  CustomButton(
                                    label: 'Thêm bữa ăn',
                                    icon: Icons.add,
                                    onPressed: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => PTMealFormScreen(
                                            course: widget.course,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadMeals();
                                      }
                                    },
                                    variant: ButtonVariant.primary,
                                    size: ButtonSize.medium,
                                  ),
                                ],
                              ),
                            ),
                            // Meals list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _meals.length,
                                itemBuilder: (context, index) {
                                  final meal = _meals[index];
                                  return CustomCard(
                                    variant: CardVariant.white,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getMealTimeSlotColor(meal.mealTimeSlot),
                                        child: Icon(
                                          _getMealTimeSlotIcon(meal.mealTimeSlot),
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: CustomText(
                                        text: meal.title,
                                        variant: TextVariant.titleMedium,
                                        color: DesignTokens.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            text: '${_formatDate(meal.mealDate)} - ${_getMealTimeSlotName(meal.mealTimeSlot)}',
                                            variant: TextVariant.bodySmall,
                                            color: DesignTokens.textSecondary,
                                          ),
                                          if (meal.totalCalories != null)
                                            CustomText(
                                              text: '${meal.totalCalories} kcal',
                                              variant: TextVariant.bodySmall,
                                              color: DesignTokens.textSecondary,
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            onPressed: () async {
                                              final result = await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => PTMealFormScreen(
                                                    course: widget.course,
                                                    meal: meal,
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadMeals();
                                              }
                                            },
                                            tooltip: 'Chỉnh sửa',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                            onPressed: () => _deleteMeal(meal),
                                            tooltip: 'Xóa',
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (meal.description != null) ...[
                                                Text(
                                                  'Mô tả:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(meal.description!),
                                                const SizedBox(height: 12),
                                              ],
                                              if (meal.items.isNotEmpty) ...[
                                                Text(
                                                  'Chi tiết món ăn:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ...meal.items.map((item) => Padding(
                                                      padding: const EdgeInsets.only(bottom: 8),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.restaurant_menu, size: 16, color: Colors.grey[600]),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              '${item.foodName}${item.servingSizeGram != null ? ' (${item.servingSizeGram}g)' : ''}',
                                                              style: const TextStyle(fontSize: 14),
                                                            ),
                                                          ),
                                                          if (item.calories != null)
                                                            Text(
                                                              '${item.calories} kcal',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    )),
                                              ],
                                              if (meal.proteinGram != null || meal.carbGram != null || meal.fatGram != null) ...[
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    if (meal.proteinGram != null)
                                                      _buildMacroChip('Protein', '${meal.proteinGram}g', Colors.blue),
                                                    if (meal.carbGram != null) ...[
                                                      const SizedBox(width: 8),
                                                      _buildMacroChip('Carb', '${meal.carbGram}g', Colors.orange),
                                                    ],
                                                    if (meal.fatGram != null) ...[
                                                      const SizedBox(width: 8),
                                                      _buildMacroChip('Fat', '${meal.fatGram}g', Colors.green),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PTMealFormScreen(course: widget.course),
            ),
          );
          if (result == true) {
            _loadMeals();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Thêm bữa ăn',
      ),
    );
  }

  Color _getMealTimeSlotColor(String timeSlot) {
    switch (timeSlot) {
      case 'Breakfast':
        return Colors.orange;
      case 'Lunch':
        return Colors.blue;
      case 'Dinner':
        return Colors.purple;
      case 'Snack':
        return Colors.green;
      case 'Pre-workout':
        return Colors.red;
      case 'Post-workout':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getMealTimeSlotIcon(String timeSlot) {
    switch (timeSlot) {
      case 'Breakfast':
        return Icons.wb_sunny;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Snack':
        return Icons.cookie;
      case 'Pre-workout':
        return Icons.fitness_center;
      case 'Post-workout':
        return Icons.sports_gymnastics;
      default:
        return Icons.restaurant;
    }
  }

  String _getMealTimeSlotName(String timeSlot) {
    switch (timeSlot) {
      case 'Breakfast':
        return 'Bữa sáng';
      case 'Lunch':
        return 'Bữa trưa';
      case 'Dinner':
        return 'Bữa tối';
      case 'Snack':
        return 'Đồ ăn nhẹ';
      case 'Pre-workout':
        return 'Trước tập';
      case 'Post-workout':
        return 'Sau tập';
      default:
        return timeSlot;
    }
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

