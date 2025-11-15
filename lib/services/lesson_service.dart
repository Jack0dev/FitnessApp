import '../models/course_lesson_model.dart';
import 'sql_database_service.dart';
import '../config/supabase_config.dart';
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
          .from('course_lessons')
          .select()
          .eq('course_id', courseId)
          .order('lesson_number', ascending: true);
      return (response as List)
          .map((doc) => CourseLessonModel.fromSupabase(doc))
          .toList();
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
          .from('course_lessons')
          .select()
          .eq('id', lessonId)
          .single();
      return CourseLessonModel.fromSupabase(response);
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
      if (lessonData['id'] == null || (lessonData['id'] as String).isEmpty) {
        lessonData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final response = await _sqlService!.client
          .from('course_lessons')
          .insert(lessonData)
          .select()
          .single();
      return response['id'] as String;
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
      await _sqlService!.client
          .from('course_lessons')
          .update(lesson.toSupabase())
          .eq('id', lesson.id);
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
      await _sqlService!.client
          .from('course_lessons')
          .delete()
          .eq('id', lessonId);
      return true;
    } catch (e) {
      print('Failed to delete lesson: $e');
      return false;
    }
  }
}

