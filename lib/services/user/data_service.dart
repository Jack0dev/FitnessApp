import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../common/sql_database_service.dart';
import '../../config/supabase_config.dart';

/// Data Service using Supabase PostgreSQL only
/// Firebase/Firestore dependencies removed
class DataService {
  SqlDatabaseService? _sqlService;

  /// Check if Supabase is initialized safely
  /// Returns true only if Supabase is both configured and initialized
  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) {
      return false;
    }
    try {
      // Accessing Supabase.instance may throw if not initialized
      return Supabase.instance.isInitialized;
    } catch (e) {
      // Supabase.instance throws error if not initialized
      return false;
    }
  }

  DataService() {
    // Only create SqlDatabaseService if Supabase is configured and initialized
    if (SupabaseConfig.isConfigured && _isSupabaseInitialized()) {
      _sqlService = SqlDatabaseService();
    } else {
      _sqlService = null;
    }
  }

  /// Get user data from Supabase
  Future<UserModel?> getUserData(String userId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. DataService requires Supabase.');
    }

    try {
      return await _sqlService!.getUserData(userId);
    } catch (e) {
      print('Failed to get user data: $e');
      return null;
    }
  }

  /// Save user data to Supabase
  Future<bool> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. DataService requires Supabase.');
    }

    try {
      return await _sqlService!.saveUserData(
        userId: userId,
        userData: userData,
      );
    } catch (e) {
      print('Failed to save user data: $e');
      return false;
    }
  }

  /// Update user data in Supabase
  Future<bool> updateUserData({
    required String userId,
    required Map<String, dynamic> updateData,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. DataService requires Supabase.');
    }

    try {
      return await _sqlService!.updateUserData(
        userId: userId,
        updateData: updateData,
      );
    } catch (e) {
      print('Failed to update user data: $e');
      return false;
    }
  }

  /// Get all users from Supabase
  Future<List<UserModel>> getAllUsers() async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. DataService requires Supabase.');
    }

    try {
      final response = await _sqlService!.client
          .from('user')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((doc) => UserModel(
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
              ))
          .toList();
    } catch (e) {
      print('Failed to get all users: $e');
      return [];
    }
  }

  /// Get multiple users by IDs in a single batch query (much faster than individual queries)
  Future<Map<String, UserModel>> getUsersByIds(List<String> userIds) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. DataService requires Supabase.');
    }

    try {
      return await _sqlService!.getUsersByIds(userIds);
    } catch (e) {
      print('Failed to get users by IDs: $e');
      return {};
    }
  }
}
