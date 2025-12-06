/// Meal model for Course meal management
class MealModel {
  final int mealId;
  final String? userId; // FK -> Users (nếu là nhật ký ăn của user)
  final String? courseId; // FK -> Courses (nếu là bữa ăn thuộc khóa học)
  final DateTime mealDate; // Ngày ăn
  final String mealTimeSlot; // Bữa: Breakfast / Lunch / Dinner / Snack...
  final String title; // Tên bữa: "Bữa sáng low-carb", "Post-workout"...
  final String? description; // Mô tả ngắn bữa ăn
  final int? totalCalories; // Tổng kcal của cả bữa
  final double? proteinGram; // Tổng protein (g)
  final double? carbGram; // Tổng carb (g)
  final double? fatGram; // Tổng fat (g)
  final double? fiberGram; // Chất xơ (g) - optional
  final int? waterMl; // Lượng nước gợi ý kèm bữa (nếu có)
  final double? totalWeightGram; // Tổng khối lượng thức ăn (g)
  final bool isCompleted; // User đã ăn/báo cáo hoàn thành bữa ăn chưa
  final String? note; // Ghi chú: "quên ăn", "ăn thêm 1 lát bánh mì",...
  final String? imageUrl; // Hình minh họa bữa ăn (nếu có)
  final DateTime createdAt;
  final DateTime? updatedAt;
  List<MealItemModel> items; // Chi tiết các món ăn

  MealModel({
    required this.mealId,
    this.userId,
    this.courseId,
    required this.mealDate,
    required this.mealTimeSlot,
    required this.title,
    this.description,
    this.totalCalories,
    this.proteinGram,
    this.carbGram,
    this.fatGram,
    this.fiberGram,
    this.waterMl,
    this.totalWeightGram,
    this.isCompleted = false,
    this.note,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  /// Create MealModel from Supabase response
  factory MealModel.fromSupabase(Map<String, dynamic> doc) {
    return MealModel(
      mealId: doc['meal_id'] as int,
      userId: doc['user_id'] as String?,
      courseId: doc['course_id'] as String?,
      mealDate: doc['meal_date'] != null
          ? DateTime.parse(doc['meal_date'] as String)
          : DateTime.now(),
      mealTimeSlot: doc['meal_time_slot'] as String,
      title: doc['title'] as String,
      description: doc['description'] as String?,
      totalCalories: doc['total_calories'] as int?,
      proteinGram: (doc['protein_gram'] as num?)?.toDouble(),
      carbGram: (doc['carb_gram'] as num?)?.toDouble(),
      fatGram: (doc['fat_gram'] as num?)?.toDouble(),
      fiberGram: (doc['fiber_gram'] as num?)?.toDouble(),
      waterMl: doc['water_ml'] as int?,
      totalWeightGram: (doc['total_weight_gram'] as num?)?.toDouble(),
      isCompleted: doc['is_completed'] is bool 
          ? (doc['is_completed'] as bool)
          : (doc['is_completed'] == 1 || doc['is_completed'] == true),
      note: doc['note'] as String?,
      imageUrl: doc['image_url'] as String?,
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
      updatedAt: doc['updated_at'] != null
          ? DateTime.parse(doc['updated_at'] as String)
          : null,
      items: [], // Will be loaded separately
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'meal_id': mealId,
      if (userId != null) 'user_id': userId,
      if (courseId != null) 'course_id': courseId,
      'meal_date': mealDate.toIso8601String().split('T')[0], // DATE format
      'meal_time_slot': mealTimeSlot,
      'title': title,
      if (description != null) 'description': description,
      if (totalCalories != null) 'total_calories': totalCalories,
      if (proteinGram != null) 'protein_gram': proteinGram,
      if (carbGram != null) 'carb_gram': carbGram,
      if (fatGram != null) 'fat_gram': fatGram,
      if (fiberGram != null) 'fiber_gram': fiberGram,
      if (waterMl != null) 'water_ml': waterMl,
      if (totalWeightGram != null) 'total_weight_gram': totalWeightGram,
      'is_completed': isCompleted, // BOOLEAN in PostgreSQL
      if (note != null) 'note': note,
      if (imageUrl != null) 'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  MealModel copyWith({
    int? mealId,
    String? userId,
    String? courseId,
    DateTime? mealDate,
    String? mealTimeSlot,
    String? title,
    String? description,
    int? totalCalories,
    double? proteinGram,
    double? carbGram,
    double? fatGram,
    double? fiberGram,
    int? waterMl,
    double? totalWeightGram,
    bool? isCompleted,
    String? note,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MealItemModel>? items,
  }) {
    return MealModel(
      mealId: mealId ?? this.mealId,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      mealDate: mealDate ?? this.mealDate,
      mealTimeSlot: mealTimeSlot ?? this.mealTimeSlot,
      title: title ?? this.title,
      description: description ?? this.description,
      totalCalories: totalCalories ?? this.totalCalories,
      proteinGram: proteinGram ?? this.proteinGram,
      carbGram: carbGram ?? this.carbGram,
      fatGram: fatGram ?? this.fatGram,
      fiberGram: fiberGram ?? this.fiberGram,
      waterMl: waterMl ?? this.waterMl,
      totalWeightGram: totalWeightGram ?? this.totalWeightGram,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

/// Meal Item model - Chi tiết từng món ăn trong bữa
class MealItemModel {
  final int mealItemId;
  final int mealId; // FK -> Meals
  final String foodName; // Tên món: "Ức gà", "Cơm trắng", "Bông cải luộc"
  final double? servingSizeGram; // Khối lượng (g)
  final int? calories; // kcal cho món này
  final double? proteinGram;
  final double? carbGram;
  final double? fatGram;
  final String? note; // VD: "có thể thay bằng ức gà áp chảo"

  MealItemModel({
    required this.mealItemId,
    required this.mealId,
    required this.foodName,
    this.servingSizeGram,
    this.calories,
    this.proteinGram,
    this.carbGram,
    this.fatGram,
    this.note,
  });

  /// Create MealItemModel from Supabase response
  factory MealItemModel.fromSupabase(Map<String, dynamic> doc) {
    return MealItemModel(
      mealItemId: doc['meal_item_id'] as int,
      mealId: doc['meal_id'] as int,
      foodName: doc['food_name'] as String,
      servingSizeGram: (doc['serving_size_gram'] as num?)?.toDouble(),
      calories: doc['calories'] as int?,
      proteinGram: (doc['protein_gram'] as num?)?.toDouble(),
      carbGram: (doc['carb_gram'] as num?)?.toDouble(),
      fatGram: (doc['fat_gram'] as num?)?.toDouble(),
      note: doc['note'] as String?,
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'meal_item_id': mealItemId,
      'meal_id': mealId,
      'food_name': foodName,
      if (servingSizeGram != null) 'serving_size_gram': servingSizeGram,
      if (calories != null) 'calories': calories,
      if (proteinGram != null) 'protein_gram': proteinGram,
      if (carbGram != null) 'carb_gram': carbGram,
      if (fatGram != null) 'fat_gram': fatGram,
      if (note != null) 'note': note,
    };
  }

  MealItemModel copyWith({
    int? mealItemId,
    int? mealId,
    String? foodName,
    double? servingSizeGram,
    int? calories,
    double? proteinGram,
    double? carbGram,
    double? fatGram,
    String? note,
  }) {
    return MealItemModel(
      mealItemId: mealItemId ?? this.mealItemId,
      mealId: mealId ?? this.mealId,
      foodName: foodName ?? this.foodName,
      servingSizeGram: servingSizeGram ?? this.servingSizeGram,
      calories: calories ?? this.calories,
      proteinGram: proteinGram ?? this.proteinGram,
      carbGram: carbGram ?? this.carbGram,
      fatGram: fatGram ?? this.fatGram,
      note: note ?? this.note,
    );
  }
}

/// Meal time slot enum
enum MealTimeSlot {
  breakfast('Breakfast', 'Bữa sáng'),
  lunch('Lunch', 'Bữa trưa'),
  dinner('Dinner', 'Bữa tối'),
  snack('Snack', 'Đồ ăn nhẹ'),
  preWorkout('Pre-workout', 'Trước tập'),
  postWorkout('Post-workout', 'Sau tập');

  final String value;
  final String displayName;

  const MealTimeSlot(this.value, this.displayName);

  static MealTimeSlot fromString(String? value) {
    if (value == null) return MealTimeSlot.breakfast;
    return MealTimeSlot.values.firstWhere(
      (slot) => slot.value == value,
      orElse: () => MealTimeSlot.breakfast,
    );
  }
}

