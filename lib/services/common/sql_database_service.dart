import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

/// SQL Database Service using Supabase (PostgreSQL)
/// This service handles all SQL database operations
/// Uses Supabase Auth for authentication
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

  /// Get current user ID from Supabase Auth
  /// This is a helper to get the Supabase user ID for SQL queries
  String? getCurrentUserId() {
    // Note: This should be called from context where Supabase Auth is available
    // The actual user ID will be passed from Supabase Auth
    return null; // Will be provided by caller
  }

  /// Save user data to SQL database
  Future<bool> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Insert or update user in 'user' table
      final role = userData['role'] is UserRole 
          ? (userData['role'] as UserRole).value 
          : (userData['role'] as String?) ?? 'user';
      
      final response = await _supabase
          .from('user')
          .upsert({
            'id': userId,
            'email': userData['email'],
            'display_name': userData['displayName'],
            'photo_url': userData['photoURL'],
            'phone_number': userData['phoneNumber'],
            'provider': userData['provider'] ?? 'email',
            'role': role,
            'created_at': userData['createdAt']?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'gender': userData['gender'],
            'age': userData['age'],
            'height_cm': userData['heightCm'],
            'weight_kg': userData['weightKg'],
            'job_nature': userData['jobNature'],
            'training_frequency': userData['trainingFrequency'],
            'training_duration_minutes': userData['trainingDurationMinutes'],
            'fitness_goal': userData['fitnessGoal'],
            'profile_completed': userData['profileCompleted'] ?? false,
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
          .from('user')
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
        role: UserRole.fromString(response['role'] as String?),
        createdAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'] as String)
            : null,
        updatedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'] as String)
            : null,
        gender: response['gender'] as String?,
        age: response['age'] as int?,
        heightCm: response['height_cm'] != null ? (response['height_cm'] as num).toDouble() : null,
        weightKg: response['weight_kg'] != null ? (response['weight_kg'] as num).toDouble() : null,
        jobNature: response['job_nature'] as String?,
        trainingFrequency: response['training_frequency'] as int?,
        trainingDurationMinutes: response['training_duration_minutes'] as int?,
        fitnessGoal: response['fitness_goal'] as String?,
        profileCompleted: response['profile_completed'] as bool? ?? false,
      );
    } catch (e) {
      // If user not found, return null
      return null;
    }
  }

  /// Get multiple users by IDs using chunked batch queries for optimal performance
  /// Handles large lists (50-100+ users) by splitting into smaller chunks
  Future<Map<String, UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    
    // Chunk size: 30 users per query (optimal for Supabase)
    // This prevents query size limits and improves performance
    const chunkSize = 30;
    final Map<String, UserModel> users = {};
    
    try {
      // Process in chunks to handle large lists efficiently
      for (int i = 0; i < userIds.length; i += chunkSize) {
        final chunk = userIds.sublist(
          i,
          i + chunkSize > userIds.length ? userIds.length : i + chunkSize,
        );
        
        // Build OR conditions for this chunk
        // Format: (id.eq.userId1,id.eq.userId2,...)
        final orConditions = chunk.map((id) => 'id.eq.$id').join(',');
        
        final response = await _supabase
            .from('user')
            .select()
            .or(orConditions);

        for (final doc in response as List) {
          final user = UserModel(
            uid: doc['id'] as String,
            email: doc['email'] as String?,
            displayName: doc['display_name'] as String?,
            photoURL: doc['photo_url'] as String?,
            phoneNumber: doc['phone_number'] as String?,
            role: UserRole.fromString(doc['role'] as String?),
            createdAt: doc['created_at'] != null
                ? DateTime.parse(doc['created_at'] as String)
                : null,
            updatedAt: doc['updated_at'] != null
                ? DateTime.parse(doc['updated_at'] as String)
                : null,
            gender: doc['gender'] as String?,
            age: doc['age'] as int?,
            heightCm: doc['height_cm'] != null ? (doc['height_cm'] as num).toDouble() : null,
            weightKg: doc['weight_kg'] != null ? (doc['weight_kg'] as num).toDouble() : null,
            jobNature: doc['job_nature'] as String?,
            trainingFrequency: doc['training_frequency'] as int?,
            trainingDurationMinutes: doc['training_duration_minutes'] as int?,
            fitnessGoal: doc['fitness_goal'] as String?,
            profileCompleted: doc['profile_completed'] as bool? ?? false,
          );
          users[user.uid] = user;
        }
      }
      
      return users;
    } catch (e) {
      print('Failed to get users by IDs: $e');
      return users; // Return partial results if available
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
      if (updateData.containsKey('gender')) {
        sqlData['gender'] = updateData['gender'];
      }
      if (updateData.containsKey('age')) {
        sqlData['age'] = updateData['age'];
      }
      if (updateData.containsKey('heightCm')) {
        sqlData['height_cm'] = updateData['heightCm'];
      }
      if (updateData.containsKey('weightKg')) {
        sqlData['weight_kg'] = updateData['weightKg'];
      }
      if (updateData.containsKey('jobNature')) {
        sqlData['job_nature'] = updateData['jobNature'];
      }
      if (updateData.containsKey('trainingFrequency')) {
        sqlData['training_frequency'] = updateData['trainingFrequency'];
      }
      if (updateData.containsKey('trainingDurationMinutes')) {
        sqlData['training_duration_minutes'] = updateData['trainingDurationMinutes'];
      }
      if (updateData.containsKey('fitnessGoal')) {
        sqlData['fitness_goal'] = updateData['fitnessGoal'];
      }
      if (updateData.containsKey('profileCompleted')) {
        sqlData['profile_completed'] = updateData['profileCompleted'];
      }

      await _supabase
          .from('user')
          .update(sqlData)
          .eq('id', userId);

      return true;
    } catch (e) {
      final errorMessage = e.toString();
      // Check if it's a column not found error
      if (errorMessage.contains('column') && errorMessage.contains('schema cache')) {
        throw 'Database columns not found. Please run the SQL migration script (add_user_profile_fields_simple.sql) in Supabase SQL Editor first. Error: $errorMessage';
      }
      throw 'Failed to update user data: $errorMessage';
    }
  }

  /// Delete user data
  Future<bool> deleteUserData(String userId) async {
    try {
      await _supabase
          .from('user')
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
