import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for storing user preferences and credentials securely
class UserPreferenceService {
  static const String _lastLoggedInEmailKey = 'last_logged_in_email';
  static const String _lastLoggedInPasswordKey = 'last_logged_in_password';
  static const String _lastLoginProviderKey = 'last_login_provider'; // 'email' or 'google'
  static const String _refreshTokenKey = 'refresh_token'; // Refresh token for session refresh
  static const String _accessTokenKey = 'access_token'; // Access token (optional, for reference)
  static const String _languageKey = 'app_language'; // 'vi' or 'en'
  static const String _loggedInEmailsKey = 'logged_in_emails'; // List of emails that have been logged in
  
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Save last logged in email and password (for fingerprint login)
  Future<bool> saveLastLoggedInCredentials({
    required String email,
    String? password,
    String provider = 'email', // 'email' or 'google'
  }) async {
    try {
      print('💾 [UserPreferenceService] Saving credentials: email=$email, hasPassword=${password != null}, provider=$provider');
      
      final prefs = await SharedPreferences.getInstance();
      // Save email in SharedPreferences (not sensitive)
      final emailSaved = await prefs.setString(_lastLoggedInEmailKey, email);
      // Save provider type
      final providerSaved = await prefs.setString(_lastLoginProviderKey, provider);
      
      // Add email to logged in emails list
      await _addLoggedInEmail(email);
      
      print('💾 [UserPreferenceService] Email saved: $emailSaved, Provider saved: $providerSaved');
      
      // Save password securely only if provider is email (Google doesn't have password)
      if (password != null && provider == 'email') {
        // Save password with email as key for multiple email support
        await _secureStorage.write(key: '${_lastLoggedInPasswordKey}_$email', value: password);
        // Also save to the main key for backward compatibility
        await _secureStorage.write(key: _lastLoggedInPasswordKey, value: password);
        print('💾 [UserPreferenceService] Password saved to secure storage');
      } else {
        // Don't clear password if it's Google provider (password is not needed)
        // Only clear if switching from email to Google
        if (provider == 'google') {
        await _secureStorage.delete(key: _lastLoggedInPasswordKey);
          print('💾 [UserPreferenceService] Password cleared (Google provider)');
        } else {
          print('💾 [UserPreferenceService] No password to save (provider: $provider)');
        }
      }
      
      // Verify saved data
      final savedEmail = await getLastLoggedInEmail();
      final savedProvider = await getLastLoginProvider();
      print('💾 [UserPreferenceService] Verification - Saved email: $savedEmail, Saved provider: $savedProvider');
      
      return true;
    } catch (e) {
      print('❌ [UserPreferenceService] Error saving credentials: $e');
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

  /// Get last logged in password (securely stored)
  Future<String?> getLastLoggedInPassword() async {
    try {
      return await _secureStorage.read(key: _lastLoggedInPasswordKey);
    } catch (e) {
      return null;
    }
  }

  /// Get last login provider ('email' or 'google')
  Future<String?> getLastLoginProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLoginProviderKey);
    } catch (e) {
      return null;
    }
  }

  /// Get both email, password, and provider
  Future<Map<String, String?>> getLastLoggedInCredentials() async {
    try {
      final email = await getLastLoggedInEmail();
      final password = await getLastLoggedInPassword();
      final provider = await getLastLoginProvider();
      
      print('📖 [UserPreferenceService] Reading credentials: email=${email != null ? "exists" : "null"}, password=${password != null ? "exists" : "null"}, provider=$provider');
      
      return {
        'email': email,
        'password': password,
        'provider': provider ?? 'email',
      };
    } catch (e) {
      print('❌ [UserPreferenceService] Error reading credentials: $e');
      return {'email': null, 'password': null, 'provider': 'email'};
    }
  }

  /// Clear last logged in credentials
  Future<bool> clearLastLoggedInCredentials() async {
    try {
      print('🗑️ [UserPreferenceService] Clearing credentials...');
      
      // Log what's being cleared before clearing
      final emailBefore = await getLastLoggedInEmail();
      final providerBefore = await getLastLoginProvider();
      print('🗑️ [UserPreferenceService] Before clear - Email: $emailBefore, Provider: $providerBefore');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLoggedInEmailKey);
      await prefs.remove(_lastLoginProviderKey);
      await _secureStorage.delete(key: _lastLoggedInPasswordKey);
      
      print('🗑️ [UserPreferenceService] Credentials cleared');
      return true;
    } catch (e) {
      print('❌ [UserPreferenceService] Error clearing credentials: $e');
      return false;
    }
  }

  /// Clear last logged in email (deprecated - use clearLastLoggedInCredentials)
  Future<bool> clearLastLoggedInEmail() async {
    return await clearLastLoggedInCredentials();
  }

  /// Save refresh token securely (for fingerprint login with session refresh)
  Future<bool> saveRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get refresh token (securely stored)
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Save access token (optional, for reference)
  Future<bool> saveAccessToken(String accessToken) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get access token (optional, for reference)
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Save session tokens (both access and refresh)
  Future<bool> saveSessionTokens({
    String? accessToken,
    String? refreshToken,
  }) async {
    try {
      if (accessToken != null) {
        await saveAccessToken(accessToken);
      }
      if (refreshToken != null) {
        await saveRefreshToken(refreshToken);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear session tokens
  Future<bool> clearSessionTokens() async {
    try {
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _accessTokenKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all saved data (credentials + tokens)
  Future<bool> clearAllSavedData() async {
    try {
      await clearLastLoggedInCredentials();
      await clearSessionTokens();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get information about stored tokens (for debugging)
  /// Returns a map with token information
  Future<Map<String, dynamic>> getTokenInfo() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      
      return {
        'hasAccessToken': accessToken != null,
        'accessTokenLength': accessToken?.length ?? 0,
        'accessTokenPreview': accessToken != null 
            ? '${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...' 
            : null,
        'hasRefreshToken': refreshToken != null,
        'refreshTokenLength': refreshToken?.length ?? 0,
        'refreshTokenPreview': refreshToken != null 
            ? '${refreshToken.substring(0, refreshToken.length > 20 ? 20 : refreshToken.length)}...' 
            : null,
        'storageLocation': 'FlutterSecureStorage (Encrypted SharedPreferences on Android, Keychain on iOS)',
        'accessTokenKey': _accessTokenKey,
        'refreshTokenKey': _refreshTokenKey,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Save language preference ('vi' or 'en')
  Future<bool> saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('❌ [UserPreferenceService] Error saving language: $e');
      return false;
    }
  }

  /// Get saved language preference
  Future<String?> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      return null;
    }
  }

  /// Add email to logged in emails list
  Future<void> _addLoggedInEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emails = await getLoggedInEmails();
      if (!emails.contains(email)) {
        emails.add(email);
        await prefs.setStringList(_loggedInEmailsKey, emails);
      }
    } catch (e) {
      print('❌ [UserPreferenceService] Error adding logged in email: $e');
    }
  }

  /// Get list of emails that have been logged in
  Future<List<String>> getLoggedInEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_loggedInEmailsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get password for a specific email
  Future<String?> getPasswordForEmail(String email) async {
    try {
      // First try to get password with email-specific key
      final password = await _secureStorage.read(key: '${_lastLoggedInPasswordKey}_$email');
      if (password != null) {
        return password;
      }
      // Fallback to main key if email matches last logged in email
      final lastEmail = await getLastLoggedInEmail();
      if (lastEmail == email) {
        return await _secureStorage.read(key: _lastLoggedInPasswordKey);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if password is saved for a specific email
  Future<bool> hasPasswordForEmail(String email) async {
    final password = await getPasswordForEmail(email);
    return password != null;
  }

  /// Remove email from logged in emails list
  Future<bool> removeLoggedInEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emails = await getLoggedInEmails();
      emails.remove(email);
      await prefs.setStringList(_loggedInEmailsKey, emails);
      // Also remove password for this email
      await _secureStorage.delete(key: '${_lastLoggedInPasswordKey}_$email');
      return true;
    } catch (e) {
      return false;
    }
  }
}
