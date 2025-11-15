import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/local_auth_service.dart';
import '../../services/user_preference_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _localAuthService = LocalAuthService();
  final _userPreferenceService = UserPreferenceService();
  final _authService = AuthService();
  bool _isFingerprintEnabled = false;
  bool _isDeviceSupported = false;
  bool _hasEnrolledBiometrics = false;
  bool _isLoading = true;
  List<String> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading fingerprint settings...');
      final isEnabled = await _localAuthService.isFingerprintEnabled();
      final isSupported = await _localAuthService.isDeviceSupported();
      final hasBiometrics = await _localAuthService.hasEnrolledBiometrics();
      final biometrics = await _localAuthService.getAvailableBiometrics();

      print('Settings loaded:');
      print('  Enabled: $isEnabled');
      print('  Supported: $isSupported');
      print('  Has Biometrics: $hasBiometrics');
      print('  Available Biometrics: ${biometrics.map((b) => _getBiometricTypeName(b)).join(", ")}');

      setState(() {
        _isFingerprintEnabled = isEnabled;
        _isDeviceSupported = isSupported;
        _hasEnrolledBiometrics = hasBiometrics;
        _availableBiometrics = biometrics
            .map((type) => _getBiometricTypeName(type))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      case BiometricType.iris:
        return 'Iris';
      default:
        return 'Biometric';
    }
  }

  Future<void> _toggleFingerprint(bool value) async {
    print('Toggle fingerprint: $value');
    print('Device supported: $_isDeviceSupported');
    print('Has enrolled biometrics: $_hasEnrolledBiometrics');
    
    if (!_isDeviceSupported || !_hasEnrolledBiometrics) {
      String errorMessage = '';
      if (!_isDeviceSupported) {
        errorMessage = 'Your device does not support biometric authentication';
      } else if (!_hasEnrolledBiometrics) {
        errorMessage = 'No biometrics enrolled. Please set up fingerprint or face ID in device settings.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (value) {
      print('Testing authentication before enabling...');
      // Test authentication before enabling
      final authenticated = await _localAuthService.authenticate(
        reason: 'Authenticate to enable fingerprint login',
      );

      print('Authentication test result: $authenticated');

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed or cancelled. Fingerprint login not enabled.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    print('Saving preference...');
    // Save preference
    final success = await _localAuthService.setFingerprintEnabled(value);
    print('Save preference result: $success');
    
    if (success) {
      setState(() {
        _isFingerprintEnabled = value;
      });
      
      if (value) {
        // If enabling fingerprint, save current user credentials
        final currentUser = _authService.currentUser;
        if (currentUser != null && currentUser.email != null) {
          // Get provider from user metadata or default to 'email'
          final provider = currentUser.appMetadata?['provider'] as String? ?? 'email';
          
          print('💾 [SettingsScreen] Preparing to save credentials: email=${currentUser.email}, provider=$provider');
          
          // Get saved password if exists (for email provider)
          final savedPassword = await _userPreferenceService.getLastLoggedInPassword();
          print('💾 [SettingsScreen] Retrieved saved password: ${savedPassword != null ? "exists" : "null"}');
          
          // Save credentials for fingerprint login
          final saveResult = await _userPreferenceService.saveLastLoggedInCredentials(
            email: currentUser.email!,
            password: savedPassword, // Use saved password if exists
            provider: provider,
          );
          
          print('✅ [SettingsScreen] Save credentials result: $saveResult');
          
          // Verify credentials were saved correctly
          final verifyCredentials = await _userPreferenceService.getLastLoggedInCredentials();
          print('✅ [SettingsScreen] Verification - Email: ${verifyCredentials['email']}, Has Password: ${verifyCredentials['password'] != null}, Provider: ${verifyCredentials['provider']}');
        } else {
          print('⚠️ [SettingsScreen] No current user found, cannot save credentials');
        }
      } else {
        // If disabling fingerprint, clear saved credentials for security
        await _userPreferenceService.clearLastLoggedInCredentials();
        print('✅ [SettingsScreen] Cleared saved credentials');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Fingerprint login enabled successfully!'
                  : 'Fingerprint login disabled. Saved credentials cleared.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save setting. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Section
                  const Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: const Text('Fingerprint Login'),
                      subtitle: _isDeviceSupported && _hasEnrolledBiometrics
                          ? Text(
                              _availableBiometrics.isNotEmpty
                                  ? 'Available: ${_availableBiometrics.join(", ")}'
                                  : 'Use biometric authentication to login quickly',
                            )
                          : const Text(
                              'Not available on this device',
                              style: TextStyle(color: Colors.grey),
                            ),
                      trailing: Switch(
                        value: _isFingerprintEnabled,
                        onChanged: _isDeviceSupported && _hasEnrolledBiometrics
                            ? _toggleFingerprint
                            : null,
                      ),
                    ),
                  ),
                  if (!_isDeviceSupported || !_hasEnrolledBiometrics) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              !_isDeviceSupported
                                  ? 'Your device does not support biometric authentication'
                                  : 'No biometrics enrolled. Please set up fingerprint or face ID in device settings.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // About Section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('App Version'),
                          subtitle: const Text('1.0.0'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.security),
                          title: const Text('Privacy Policy'),
                          subtitle: const Text('View our privacy policy'),
                          onTap: () {
                            // TODO: Navigate to privacy policy
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy policy coming soon'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

