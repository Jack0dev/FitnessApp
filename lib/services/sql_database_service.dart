import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// SQL Database Service using Supabase (PostgreSQL)
/// This service handles all SQL database operations
/// Firebase Auth is still used for authentication
class SqlDatabaseService {
  /// Check if Supabase is initialized safely
  /// Returns true only if Supabase instance exists and is initialized
  static bool _isInitialized() {
    try {
      // Accessing Supabase.instance may throw if not initialized
      return Supabase.instance.isInitialized;
    } catch (e) {
      // Supabase.instance throws error if not initialized
      return false;
    }
  }

  SupabaseClient get _supabase {
    if (!_isInitialized()) {
      throw Exception('Supabase not initialized. Call SqlDatabaseService.initialize() first.');
    }
    return Supabase.instance.client;
  }

  /// Initialize Supabase (should be called in main.dart)
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (!_isInitialized()) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    }
  }
  
  /// Get Supabase client instance
  SupabaseClient get client {
    if (!_isInitialized()) {
      throw Exception('Supabase not initialized. Call SqlDatabaseService.initialize() first.');
    }
    return Supabase.instance.client;
  }

  /// Get current user ID from Firebase Auth
  /// This is a helper to get the Firebase UID for SQL queries
  String? getCurrentUserId() {
    // Note: This should be called from context where Firebase Auth is available
    // The actual user ID will be passed from Firebase Auth
    return null; // Will be provided by caller
  }

  /// Save user data to SQL database
  Future<bool> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Insert or update user in 'users' table
      final response = await _supabase
          .from('users')
          .upsert({
            'id': userId,
            'email': userData['email'],
            'display_name': userData['displayName'],
            'photo_url': userData['photoURL'],
            'phone_number': userData['phoneNumber'],
            'provider': userData['provider'] ?? 'email',
            'created_at': userData['createdAt']?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select();

      return response.isNotEmpty;
    } catch (e) {
      throw 'Failed to save user data: ${e.toString()}';
    }
  }

  /// Get user data from SQL database
  Future<UserModel?> getUserData(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      // .single() returns Map<String, dynamic> or throws
      return UserModel(
        uid: response['id'] as String,
        email: response['email'] as String?,
        displayName: response['display_name'] as String?,
        photoURL: response['photo_url'] as String?,
        phoneNumber: response['phone_number'] as String?,
        createdAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'] as String)
            : null,
        updatedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'] as String)
            : null,
      );
    } catch (e) {
      // If user not found, return null
      return null;
    }
  }

  /// Update user data
  Future<bool> updateUserData({
    required String userId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final sqlData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Map Flutter field names to SQL column names
      if (updateData.containsKey('displayName')) {
        sqlData['display_name'] = updateData['displayName'];
      }
      if (updateData.containsKey('photoURL')) {
        sqlData['photo_url'] = updateData['photoURL'];
      }
      if (updateData.containsKey('phoneNumber')) {
        sqlData['phone_number'] = updateData['phoneNumber'];
      }

      await _supabase
          .from('users')
          .update(sqlData)
          .eq('id', userId);

      return true;
    } catch (e) {
      throw 'Failed to update user data: ${e.toString()}';
    }
  }

  /// Delete user data
  Future<bool> deleteUserData(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
      return true;
    } catch (e) {
      throw 'Failed to delete user data: ${e.toString()}';
    }
  }

  /// Generic method to insert data into any table
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(table)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw 'Failed to insert data: ${e.toString()}';
    }
  }

  /// Generic method to update data in any table
  Future<bool> update({
    required String table,
    required String column,
    required dynamic value,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase
          .from(table)
          .update(data)
          .eq(column, value);
      return true;
    } catch (e) {
      throw 'Failed to update data: ${e.toString()}';
    }
  }

  /// Generic method to get data from any table
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String? whereColumn,
    dynamic whereValue,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from(table).select();

      if (whereColumn != null && whereValue != null) {
        query = query.eq(whereColumn, whereValue);
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: !descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to select data: ${e.toString()}';
    }
  }

  /// Generic method to delete data from any table
  Future<bool> delete({
    required String table,
    required String column,
    required dynamic value,
  }) async {
    try {
      await _supabase
          .from(table)
          .delete()
          .eq(column, value);
      return true;
    } catch (e) {
      throw 'Failed to delete data: ${e.toString()}';
    }
  }
}

