import '../models/meal_model.dart';
import 'common/sql_database_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing meals using Supabase
class MealService {
  SqlDatabaseService? _sqlService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  MealService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. MealService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  // ========== MEAL CRUD ==========

  /// Get meals by course ID
  Future<List<MealModel>> getMealsByCourse(String courseId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      final response = await _sqlService!.client
          .from('meal')
          .select()
          .eq('course_id', courseId)
          .order('meal_date', ascending: true)
          .order('meal_time_slot', ascending: true);
      
      final meals = (response as List)
          .map((doc) => MealModel.fromSupabase(doc))
          .toList();

      // Load meal items for each meal
      final mealsWithItems = <MealModel>[];
      for (final meal in meals) {
        final items = await getMealItems(meal.mealId);
        mealsWithItems.add(meal.copyWith(items: items));
      }

      return mealsWithItems;
    } catch (e) {
      print('Failed to get meals by course: $e');
      return [];
    }
  }

  /// Get meals by user ID
  Future<List<MealModel>> getMealsByUser(String userId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      final response = await _sqlService!.client
          .from('meal')
          .select()
          .eq('user_id', userId)
          .order('meal_date', ascending: true)
          .order('meal_time_slot', ascending: true);
      
      return (response as List)
          .map((doc) => MealModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get meals by user: $e');
      return [];
    }
  }

  /// Get meal by ID
  Future<MealModel?> getMealById(int mealId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      final response = await _sqlService!.client
          .from('meal')
          .select()
          .eq('id', mealId)
          .single();
      
      final meal = MealModel.fromSupabase(response);
      final items = await getMealItems(mealId);
      return meal.copyWith(items: items);
    } catch (e) {
      print('Failed to get meal: $e');
      return null;
    }
  }

  /// Create meal
  Future<int?> createMeal(MealModel meal) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      final mealData = meal.toSupabase();
      // Remove id for insert (auto-generated)
      mealData.remove('id');

      final response = await _sqlService!.client
          .from('meal')
          .insert(mealData)
          .select('id')
          .single();
      
      final newMealId = response['id'] as int;

      // Insert meal items if any
      if (meal.items.isNotEmpty) {
        for (final item in meal.items) {
          final itemData = item.toSupabase();
          itemData.remove('id');
          itemData['meal_id'] = newMealId;
          await _sqlService!.client
              .from('meal_item')
              .insert(itemData);
        }
      }

      return newMealId;
    } catch (e) {
      print('Failed to create meal: $e');
      return null;
    }
  }

  /// Update meal
  Future<bool> updateMeal(MealModel meal) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      final mealData = meal.toSupabase();
      mealData['updated_at'] = DateTime.now().toIso8601String();

      await _sqlService!.client
          .from('meal')
          .update(mealData)
          .eq('id', meal.mealId);
      
      return true;
    } catch (e) {
      print('Failed to update meal: $e');
      return false;
    }
  }

  /// Delete meal
  Future<bool> deleteMeal(int mealId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      // Delete meal items first (cascade should handle this, but being explicit)
      await _sqlService!.client
          .from('meal_item')
          .delete()
          .eq('meal_id', mealId);

      await _sqlService!.client
          .from('meal')
          .delete()
          .eq('id', mealId);
      
      return true;
    } catch (e) {
      print('Failed to delete meal: $e');
      return false;
    }
  }

  // ========== MEAL ITEM CRUD ==========

  /// Get meal items by meal ID
  Future<List<MealItemModel>> getMealItems(int mealId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      final response = await _sqlService!.client
          .from('meal_item')
          .select()
          .eq('meal_id', mealId);
      
      return (response as List)
          .map((doc) => MealItemModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get meal items: $e');
      return [];
    }
  }

  /// Create meal item
  Future<int?> createMealItem(MealItemModel item) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      final itemData = item.toSupabase();
      // Remove id for insert (auto-generated)
      itemData.remove('id');

      final response = await _sqlService!.client
          .from('meal_item')
          .insert(itemData)
          .select('id')
          .single();
      
      return response['id'] as int;
    } catch (e) {
      print('Failed to create meal item: $e');
      return null;
    }
  }

  /// Update meal item
  Future<bool> updateMealItem(MealItemModel item) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      await _sqlService!.client
          .from('meal_item')
          .update(item.toSupabase())
          .eq('id', item.mealItemId);
      
      return true;
    } catch (e) {
      print('Failed to update meal item: $e');
      return false;
    }
  }

  /// Delete meal item
  Future<bool> deleteMealItem(int mealItemId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      await _sqlService!.client
          .from('meal_item')
          .delete()
          .eq('id', mealItemId);
      
      return true;
    } catch (e) {
      print('Failed to delete meal item: $e');
      return false;
    }
  }
}

