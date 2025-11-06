import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'sql_database_service.dart';
import '../config/supabase_config.dart';

/// Abstract Data Service
/// Supports both Firestore and Supabase
/// Uses Supabase if configured, otherwise falls back to Firestore
class DataService {
  final FirestoreService _firestoreService = FirestoreService();
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

  /// Get user data - tries Supabase first, falls back to Firestore
  Future<UserModel?> getUserData(String userId) async {
    // Try Supabase first if configured
    if (_sqlService != null) {
      try {
        final userModel = await _sqlService!.getUserData(userId);
        if (userModel != null) {
          return userModel;
        }
      } catch (e) {
        // If Supabase fails, fallback to Firestore
        print('Supabase getUserData failed, using Firestore: $e');
      }
    }

    // Fallback to Firestore
    try {
      final doc = await _firestoreService.getUserDocument(userId);
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromFirestore(data, userId);
      }
    } catch (e) {
      print('Firestore getUserData failed: $e');
    }

    return null;
  }

  /// Save user data - tries Supabase first, falls back to Firestore
  Future<bool> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    // Try Supabase first if configured
    if (_sqlService != null) {
      try {
        final success = await _sqlService!.saveUserData(
          userId: userId,
          userData: userData,
        );
        if (success) {
          return true;
        }
      } catch (e) {
        // If Supabase fails, fallback to Firestore
        print('Supabase saveUserData failed, using Firestore: $e');
      }
    }

    // Fallback to Firestore
    try {
      return await _firestoreService.saveUserData(
        userId: userId,
        userData: userData,
      );
    } catch (e) {
      print('Firestore saveUserData failed: $e');
      return false;
    }
  }

  /// Update user data - tries Supabase first, falls back to Firestore
  Future<bool> updateUserData({
    required String userId,
    required Map<String, dynamic> updateData,
  }) async {
    // Try Supabase first if configured
    if (_sqlService != null) {
      try {
        return await _sqlService!.updateUserData(
          userId: userId,
          updateData: updateData,
        );
      } catch (e) {
        // If Supabase fails, fallback to Firestore
        print('Supabase updateUserData failed, using Firestore: $e');
      }
    }

    // Fallback to Firestore
    try {
      await _firestoreService.updateDocument(
        collection: 'users',
        docId: userId,
        data: updateData,
      );
      return true;
    } catch (e) {
      print('Firestore updateUserData failed: $e');
      return false;
    }
  }
}

