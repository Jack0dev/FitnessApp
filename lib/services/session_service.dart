import '../models/session_model.dart';
import 'common/sql_database_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing sessions using Supabase
/// Replaces ScheduleService based on new database schema
class SessionService {
  SqlDatabaseService? _sqlService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  SessionService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  // ========== SESSION CRUD ==========

  /// Get all sessions for a trainer
  Future<List<SessionModel>> getTrainerSessions(String trainerId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('session')
          .select()
          .eq('trainer_id', trainerId)
          .order('date', ascending: true)
          .order('start_time', ascending: true);
      return (response as List)
          .map((doc) => SessionModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get trainer sessions: $e');
      return [];
    }
  }

  /// Get session by ID
  Future<SessionModel?> getSessionById(String sessionId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('session')
          .select()
          .eq('id', sessionId)
          .single();
      return SessionModel.fromSupabase(response);
    } catch (e) {
      print('Failed to get session: $e');
      return null;
    }
  }

  /// Get sessions by date range
  Future<List<SessionModel>> getSessionsByDateRange({
    required String trainerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('session')
          .select()
          .eq('trainer_id', trainerId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true)
          .order('start_time', ascending: true);
      return (response as List)
          .map((doc) => SessionModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get sessions by date range: $e');
      return [];
    }
  }

  /// Get sessions for a specific date
  Future<List<SessionModel>> getSessionsByDate({
    required String trainerId,
    required DateTime date,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _sqlService!.client
          .from('session')
          .select()
          .eq('trainer_id', trainerId)
          .eq('date', dateStr)
          .order('start_time', ascending: true);
      return (response as List)
          .map((doc) => SessionModel.fromSupabase(doc))
          .toList();
    } catch (e) {
      print('Failed to get sessions by date: $e');
      return [];
    }
  }

  /// Create session
  Future<String?> createSession(SessionModel session) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }

    try {
      // Generate UUID if id is empty
      final sessionData = session.toSupabase();
      if (sessionData['id'] == null || (sessionData['id'] as String).isEmpty) {
        sessionData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final response = await _sqlService!.client
          .from('session')
          .insert(sessionData)
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      print('Failed to create session: $e');
      return null;
    }
  }

  /// Update session
  Future<bool> updateSession(SessionModel session) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }

    try {
      final updateData = session.toSupabase();
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      await _sqlService!.client
          .from('session')
          .update(updateData)
          .eq('id', session.id);
      return true;
    } catch (e) {
      print('Failed to update session: $e');
      return false;
    }
  }

  /// Delete session
  Future<bool> deleteSession(String sessionId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. SessionService requires Supabase.');
    }

    try {
      await _sqlService!.client
          .from('session')
          .delete()
          .eq('id', sessionId);
      return true;
    } catch (e) {
      print('Failed to delete session: $e');
      return false;
    }
  }
}







