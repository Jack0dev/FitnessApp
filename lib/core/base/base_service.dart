import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../services/common/sql_database_service.dart';

/// Base service class để tránh code trùng lặp check Supabase initialization
abstract class BaseService {
  SqlDatabaseService? _sqlService;

  /// Check if Supabase is initialized safely
  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) {
      return false;
    }
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Initialize service với Supabase check
  BaseService() {
    if (SupabaseConfig.isConfigured && _isSupabaseInitialized()) {
      _sqlService = SqlDatabaseService();
    } else {
      _sqlService = null;
    }
  }

  /// Get SQL service instance
  SqlDatabaseService? get sqlService => _sqlService;

  /// Check if service is ready
  bool get isReady => _sqlService != null;

  /// Throw exception if service is not ready
  void ensureReady() {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized. ${runtimeType} requires Supabase.');
    }
  }
}
