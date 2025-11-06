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
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
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
      return await prefs.setBool(_fingerprintEnabledKey, enabled);
    } catch (e) {
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
      // Check if device supports biometrics
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return false;
      }

      // Check if biometrics are enrolled
      final hasBiometrics = await hasEnrolledBiometrics();
      if (!hasBiometrics) {
        return false;
      }

      // Authenticate
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometrics, not device credentials
        ),
      );

      return didAuthenticate;
    } catch (e) {
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

