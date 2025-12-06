import '../../models/course_lesson_model.dart';
import '../../models/lesson_exercise_model.dart';
import '../common/sql_database_service.dart';
import '../../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing course lessons/documents using Supabase
class LessonService {
  SqlDatabaseService? _sqlService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  LessonService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. LessonService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  // ========== LESSON CRUD ==========

  /// Get all lessons for a course
  Future<List<CourseLessonModel>> getCourseLessons(String courseId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. LessonService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('lesson')
          .select()
          .eq('course_id', courseId)
          .order('lesson_number', ascending: true);
      
      final lessons = <CourseLessonModel>[];
      for (final doc in response as List) {
        final lesson = CourseLessonModel.fromSupabase(doc);
        // Load exercises from relational tables
        final exercises = await _loadLessonExercises(lesson.id);
        lessons.add(lesson.copyWith(exercises: exercises));
      }
      return lessons;
    } catch (e) {
      print('Failed to get course lessons: $e');
      return [];
    }
  }

  /// Get lesson by ID
  Future<CourseLessonModel?> getLessonById(String lessonId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. LessonService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('lesson')
          .select()
          .eq('id', lessonId)
          .single();
      final lesson = CourseLessonModel.fromSupabase(response);
      // Load exercises from relational tables
      final exercises = await _loadLessonExercises(lessonId);
      return lesson.copyWith(exercises: exercises);
    } catch (e) {
      print('Failed to get lesson: $e');
      return null;
    }
  }

  /// Create lesson
  Future<String?> createLesson(CourseLessonModel lesson) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. LessonService requires Supabase.');
    }

    try {
      // Generate UUID if id is empty
      final lessonData = lesson.toSupabase();
      // Remove exercises from lessonData as we'll save them separately
      lessonData.remove('exercises');
      
      if (lessonData['id'] == null || (lessonData['id'] as String).isEmpty) {
        lessonData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final response = await _sqlService!.client
          .from('lesson')
          .insert(lessonData)
          .select()
          .single();
      
      final lessonId = response['id'] as String;
      
      // Save exercises to relational tables
      await _saveLessonExercises(lessonId, lesson.exercises);
      
      return lessonId;
    } catch (e) {
      print('Failed to create lesson: $e');
      return null;
    }
  }

  /// Update lesson
  Future<bool> updateLesson(CourseLessonModel lesson) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. LessonService requires Supabase.');
    }

    try {
      final lessonData = lesson.toSupabase();
      // Remove exercises from lessonData as we'll save them separately
      lessonData.remove('exercises');
      
      await _sqlService!.client
          .from('lesson')
          .update(lessonData)
          .eq('id', lesson.id);
      
      // Update exercises in relational tables
      await _saveLessonExercises(lesson.id, lesson.exercises);
      
      return true;
    } catch (e) {
      print('Failed to update lesson: $e');
      return false;
    }
  }

  /// Delete lesson
  Future<bool> deleteLesson(String lessonId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. LessonService requires Supabase.');
    }

    try {
      // Exercises and equipment will be deleted automatically due to CASCADE
      await _sqlService!.client
          .from('lesson')
          .delete()
          .eq('id', lessonId);
      return true;
    } catch (e) {
      print('Failed to delete lesson: $e');
      return false;
    }
  }

  // ========== LESSON EXERCISES CRUD ==========

  /// Load exercises for a lesson from relational tables
  /// Optimized with batch queries to avoid N+1 problem
  Future<List<LessonExerciseModel>> _loadLessonExercises(String lessonId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      // Load lesson exercises
      final exercisesResponse = await _sqlService!.client
          .from('lesson_exercise')
          .select()
          .eq('lesson_id', lessonId)
          .order('order_index', ascending: true);

      if ((exercisesResponse as List).isEmpty) {
        return [];
      }

      final exercises = <LessonExerciseModel>[];
      final exerciseDataList = exercisesResponse as List;
      
      // Batch load: Get all exercise IDs and lesson exercise IDs first
      final exerciseIds = <int>[];
      final lessonExerciseIds = <int>[];
      final exerciseIdMap = <int, Map<String, dynamic>>{}; // lessonExerciseId -> exerciseData
      
      for (final exerciseData in exerciseDataList) {
        final lessonExerciseId = exerciseData['id'] as int;
        final exerciseId = exerciseData['exercise_id'] as int;
        exerciseIds.add(exerciseId);
        lessonExerciseIds.add(lessonExerciseId);
        exerciseIdMap[lessonExerciseId] = exerciseData;
      }
      
      // Batch load all exercises at once (if any)
      final Map<int, Map<String, dynamic>> exerciseMap = {};
      if (exerciseIds.isNotEmpty) {
        try {
          // Use or() filter for batch query
          final uniqueExerciseIds = exerciseIds.toSet().toList();
          if (uniqueExerciseIds.length == 1) {
            final response = await _sqlService!.client
                .from('exercise')
                .select()
                .eq('id', uniqueExerciseIds.first);
            for (final ex in response as List) {
              exerciseMap[ex['id'] as int] = ex as Map<String, dynamic>;
            }
          } else {
            // Use or() filter for multiple IDs
            final orConditions = uniqueExerciseIds.map((id) => 'id.eq.$id').join(',');
            final response = await _sqlService!.client
                .from('exercise')
                .select()
                .or(orConditions);
            for (final ex in response as List) {
              exerciseMap[ex['id'] as int] = ex as Map<String, dynamic>;
            }
          }
        } catch (e) {
          print('⚠️ [LessonService] Failed to batch load exercises: $e');
          // Continue with empty exerciseMap - will use exerciseId only
        }
      }
      
      // Batch load all equipment relationships at once
      final Map<int, List<int>> equipmentMap = {}; // lessonExerciseId -> [equipmentIds]
      if (lessonExerciseIds.isNotEmpty) {
        try {
          // Load all equipment relationships in one query
          final orConditions = lessonExerciseIds.map((id) => 'lesson_exercise_id.eq.$id').join(',');
          final equipmentResponse = await _sqlService!.client
              .from('lesson_exercise_equipment_item')
              .select('lesson_exercise_id,equipment_item_id')
              .or(orConditions);
          
          for (final item in equipmentResponse as List) {
            final leId = item['lesson_exercise_id'] as int;
            final eqId = item['equipment_item_id'] as int;
            equipmentMap.putIfAbsent(leId, () => []).add(eqId);
          }
        } catch (e) {
          print('⚠️ [LessonService] Failed to batch load equipment relationships: $e');
          // Continue with empty equipmentMap
        }
      }
      
      // Batch load all equipment items
      final Map<int, Map<String, dynamic>> equipmentItemMap = {};
      final allEquipmentIds = <int>[];
      for (final ids in equipmentMap.values) {
        allEquipmentIds.addAll(ids);
      }
      
      if (allEquipmentIds.isNotEmpty) {
        try {
          final uniqueEquipmentIds = allEquipmentIds.toSet().toList();
          if (uniqueEquipmentIds.length == 1) {
            final response = await _sqlService!.client
                .from('equipment_item')
                .select()
                .eq('id', uniqueEquipmentIds.first);
            for (final eq in response as List) {
              equipmentItemMap[eq['id'] as int] = eq as Map<String, dynamic>;
            }
          } else if (uniqueEquipmentIds.length > 1) {
            // Use or() filter for batch query
            final orConditions = uniqueEquipmentIds.map((id) => 'id.eq.$id').join(',');
            final response = await _sqlService!.client
                .from('equipment_item')
                .select()
                .or(orConditions);
            for (final eq in response as List) {
              equipmentItemMap[eq['id'] as int] = eq as Map<String, dynamic>;
            }
          }
        } catch (e) {
          print('⚠️ [LessonService] Failed to batch load equipment items: $e');
          // Continue with empty equipmentItemMap
        }
      }
      
      // Build exercises with loaded data
      for (final exerciseData in exerciseDataList) {
        final lessonExerciseId = exerciseData['id'] as int;
        final exerciseId = exerciseData['exercise_id'] as int;
        
        // Get exercise details from batch-loaded map
        final exercise = exerciseMap[exerciseId];
        
        // Get equipment list from batch-loaded maps
        final equipmentList = <Map<String, dynamic>>[];
        final equipmentIds = equipmentMap[lessonExerciseId] ?? [];
        for (final eqId in equipmentIds) {
          final equipment = equipmentItemMap[eqId];
          if (equipment != null) {
            equipmentList.add(equipment);
          }
        }
        
        // Only add if exercise was found or exerciseId is available
        if (exercise != null || exerciseId > 0) {
          exercises.add(LessonExerciseModel.fromSupabase(
            exerciseData,
            exercise,
            equipmentList,
          ));
        } else {
          print('⚠️ [LessonService] Skipping lesson_exercise $lessonExerciseId - exercise not found');
        }
      }
      
      return exercises;
    } catch (e) {
      print('❌ [LessonService] Failed to load lesson exercises: $e');
      // Return empty list instead of throwing to allow lessons to load even if exercises fail
      return [];
    }
  }

  /// Save exercises for a lesson to relational tables
  Future<void> _saveLessonExercises(String lessonId, List<LessonExerciseModel> exercises) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized.');
    }

    try {
      // First, delete all existing exercises for this lesson
      final existingExercises = await _sqlService!.client
          .from('lesson_exercise')
          .select('id')
          .eq('lesson_id', lessonId);
      
      for (final existing in existingExercises as List) {
        final existingId = existing['id'] as int;
        // Delete equipment relationships (CASCADE should handle this, but being explicit)
        await _sqlService!.client
            .from('lesson_exercise_equipment_item')
            .delete()
            .eq('lesson_exercise_id', existingId);
      }
      
      // Delete lesson exercises
      await _sqlService!.client
          .from('lesson_exercise')
          .delete()
          .eq('lesson_id', lessonId);
      
      // Insert new exercises
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        
        // Insert lesson exercise
        final exerciseResponse = await _sqlService!.client
            .from('lesson_exercise')
            .insert({
              'lesson_id': lessonId,
              'exercise_id': exercise.exerciseId, // FK column name is still exercise_id
              'order_index': i,
              'sets': exercise.sets,
              'reps': exercise.reps,
              'rest_time_seconds': exercise.restTimeSeconds,
              'notes': exercise.notes,
            })
            .select('id')
            .single();
        
        final lessonExerciseId = exerciseResponse['id'] as int;
        
        // Insert equipment relationships
        if (exercise.equipmentIds.isNotEmpty) {
          final equipmentData = exercise.equipmentIds.map((equipmentId) => {
            'lesson_exercise_id': lessonExerciseId,
            'equipment_item_id': equipmentId, // FK column name is equipment_item_id
          }).toList();
          
          await _sqlService!.client
              .from('lesson_exercise_equipment_item')
              .insert(equipmentData);
        }
      }
    } catch (e) {
      print('Failed to save lesson exercises: $e');
      rethrow;
    }
  }
}
