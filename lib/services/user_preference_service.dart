import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing user preferences
class UserPreferenceService {
  static const String _lastLoggedInEmailKey = 'last_logged_in_email';

  /// Save last logged in email (for fingerprint login)
  Future<bool> saveLastLoggedInEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_lastLoggedInEmailKey, email);
    } catch (e) {
      return false;
    }
  }

  /// Get last logged in email
  Future<String?> getLastLoggedInEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLoggedInEmailKey);
    } catch (e) {
      return null;
    }
  }

  /// Clear last logged in email
  Future<bool> clearLastLoggedInEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_lastLoggedInEmailKey);
    } catch (e) {
      return false;
    }
  }
}

