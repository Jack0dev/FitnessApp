import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/local_auth_service.dart';
import '../widgets/loading_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _localAuthService = LocalAuthService();
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
      final isEnabled = await _localAuthService.isFingerprintEnabled();
      final isSupported = await _localAuthService.isDeviceSupported();
      final hasBiometrics = await _localAuthService.hasEnrolledBiometrics();
      final biometrics = await _localAuthService.getAvailableBiometrics();

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
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    if (!_isDeviceSupported || !_hasEnrolledBiometrics) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication is not available on this device',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (value) {
      // Test authentication before enabling
      final authenticated = await _localAuthService.authenticate(
        reason: 'Authenticate to enable fingerprint login',
      );

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed. Fingerprint login not enabled.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Save preference
    final success = await _localAuthService.setFingerprintEnabled(value);
    if (success) {
      setState(() {
        _isFingerprintEnabled = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Fingerprint login enabled'
                  : 'Fingerprint login disabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save setting'),
            backgroundColor: Colors.red,
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

