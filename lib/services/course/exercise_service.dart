import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/exercise_model.dart';
import '../../models/equipment_model.dart';

/// Service for managing exercises and equipment
class ExerciseService {
  final _supabase = Supabase.instance.client;

  /// Get all exercises
  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      final response = await _supabase
          .from('exercise')
          .select()
          .order('name');

      return (response as List)
          .map((doc) => ExerciseModel.fromSupabase(doc as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting exercises: $e');
      rethrow;
    }
  }

  /// Get exercise by ID
  Future<ExerciseModel?> getExerciseById(int exerciseId) async {
    try {
      final response = await _supabase
          .from('exercise')
          .select()
          .eq('id', exerciseId)
          .single();

      return ExerciseModel.fromSupabase(response);
    } catch (e) {
      print('Error getting exercise: $e');
      return null;
    }
  }

  /// Get all equipment
  Future<List<EquipmentModel>> getAllEquipment() async {
    try {
      final response = await _supabase
          .from('equipment_item')
          .select()
          .order('name');

      return (response as List)
          .map((doc) => EquipmentModel.fromSupabase(doc as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting equipment: $e');
      rethrow;
    }
  }

  /// Get equipment for a specific exercise
  Future<List<EquipmentModel>> getEquipmentForExercise(int exerciseId) async {
    try {
      final response = await _supabase
          .from('exercise_equipment')
          .select('equipment(*)')
          .eq('exercise_id', exerciseId);

      return (response as List)
          .map((doc) {
            final equipmentData = (doc as Map<String, dynamic>)['equipment'];
            if (equipmentData != null) {
              return EquipmentModel.fromSupabase(equipmentData as Map<String, dynamic>);
            }
            return null;
          })
          .whereType<EquipmentModel>()
          .toList();
    } catch (e) {
      print('Error getting equipment for exercise: $e');
      return [];
    }
  }

  /// Get exercises by category
  Future<List<ExerciseModel>> getExercisesByCategory(String category) async {
    try {
      final response = await _supabase
          .from('exercise')
          .select()
          .eq('category', category)
          .order('name');

      return (response as List)
          .map((doc) => ExerciseModel.fromSupabase(doc as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting exercises by category: $e');
      return [];
    }
  }

  /// Get exercises by difficulty
  Future<List<ExerciseModel>> getExercisesByDifficulty(String difficulty) async {
    try {
      final response = await _supabase
          .from('exercise')
          .select()
          .eq('difficulty', difficulty)
          .order('name');

      return (response as List)
          .map((doc) => ExerciseModel.fromSupabase(doc as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting exercises by difficulty: $e');
      return [];
    }
  }
}
