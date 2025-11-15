import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling local authentication (fingerprint/face ID)
class LocalAuthService {
  static const String _fingerprintEnabledKey = 'fingerprint_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if device has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      // First check if device is supported
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return false;
      }
      
      // Check if biometrics can be checked and are available
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        return false;
      }
      
      // Check if there are any enrolled biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking enrolled biometrics: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if fingerprint login is enabled
  Future<bool> isFingerprintEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_fingerprintEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable fingerprint login
  Future<bool> setFingerprintEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setBool(_fingerprintEnabledKey, enabled);
      print('Fingerprint enabled set to $enabled: $result');
      return result;
    } catch (e) {
      print('Error setting fingerprint enabled: $e');
      return false;
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication is successful
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      print('Starting biometric authentication...');
      
      // Check if device supports biometrics
      final isSupported = await isDeviceSupported();
      print('Device supported: $isSupported');
      if (!isSupported) {
        print('Device does not support biometrics');
        return false;
      }

      // Check if biometrics are enrolled
      final hasBiometrics = await hasEnrolledBiometrics();
      print('Has enrolled biometrics: $hasBiometrics');
      if (!hasBiometrics) {
        print('No enrolled biometrics found');
        return false;
      }

      // Authenticate
      print('Calling authenticate...');
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometrics, not device credentials
        ),
      );

      print('Authentication result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors
    }
  }
}

