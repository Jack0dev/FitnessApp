import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/auth/local_auth_service.dart';
import '../../services/user/user_preference_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/loading_widget.dart';
import '../../core/localization/app_localizations.dart';
import '../../screens/auth/login_screen.dart';

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

  // --- LOGIC XỬ LÝ BIOMETRICS (Giữ nguyên) ---

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
            content: Text('Lỗi khi tải cài đặt: ${e.toString()}'),
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
    }
  }

  Future<void> _toggleFingerprint(bool value) async {
    print('Toggle fingerprint: $value');
    print('Device supported: $_isDeviceSupported');
    print('Has enrolled biometrics: $_hasEnrolledBiometrics');

    if (!_isDeviceSupported || !_hasEnrolledBiometrics) {
      String errorMessage = '';
      if (!_isDeviceSupported) {
        errorMessage = 'Thiết bị của bạn không hỗ trợ xác thực sinh trắc học';
      } else if (!_hasEnrolledBiometrics) {
        errorMessage = 'Chưa đăng ký sinh trắc học. Vui lòng thiết lập vân tay hoặc Face ID trong cài đặt thiết bị.';
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
        reason: 'Xác thực để bật đăng nhập bằng vân tay',
      );

      print('Authentication test result: $authenticated');

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực thất bại hoặc đã hủy. Đăng nhập bằng vân tay chưa được bật.'),
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
          final provider = (currentUser.appMetadata['provider'] as String?) ?? 'email';

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
                  ? 'Đăng nhập bằng vân tay đã được bật thành công!'
                  : 'Đăng nhập bằng vân tay đã tắt. Thông tin đăng nhập đã được xóa.',
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
            content: Text('Không thể lưu cài đặt. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleLogout() {
    // Lấy sẵn ScaffoldMessenger từ context của SettingsScreen
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
            ),
            TextButton(
              child: Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                // Đóng dialog trước
                Navigator.of(dialogContext).pop();

                // 1. Thực hiện Đăng xuất
                await _authService.signOut();
                await _userPreferenceService.clearLastLoggedInCredentials();

                // Kiểm tra lại SettingsScreen còn mounted không
                if (!mounted) return;

                // 2. Hiển thị SnackBar bằng messenger đã cache
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Đăng xuất thành công!'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );

                // 3. Điều hướng về màn hình đăng nhập và xoá history
                Navigator.of(context).pushAndRemoveUntil(
                  // TODO: thay LoginScreen bằng màn login thật + import file đó
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }


  // --- BUILD METHOD CẬP NHẬT ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar tiêu chuẩn
      appBar: AppBar(
        title: Text(context.translate('settings')),
        elevation: 0,
        // Thêm nút Back tiêu chuẩn nếu có thể quay lại
        leading: Navigator.of(context).canPop()
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        )
            : null,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Section
            Text(
              'Bảo mật',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.fingerprint),
                title: Text(context.translate('fingerprint_auth')),
                subtitle: _isDeviceSupported && _hasEnrolledBiometrics
                    ? Text(
                  _availableBiometrics.isNotEmpty
                      ? 'Có sẵn: ${_availableBiometrics.join(", ")}'
                      : context.translate('enable_fingerprint'),
                )
                    : Text(
                  'Không khả dụng trên thiết bị này',
                  style: const TextStyle(color: Colors.grey),
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
                            ? 'Thiết bị của bạn không hỗ trợ xác thực sinh trắc học'
                            : 'Chưa đăng ký sinh trắc học. Vui lòng thiết lập vân tay hoặc Face ID trong cài đặt thiết bị.',
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
              'Giới thiệu',
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
                    title: const Text('Phiên bản ứng dụng'),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Chính sách bảo mật'),
                    subtitle: const Text('Xem chính sách bảo mật của chúng tôi'),
                    onTap: () {
                      // TODO: Navigate to privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chính sách bảo mật sắp ra mắt'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // 💡 NÚT ĐĂNG XUẤT ĐÃ THÊM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: _handleLogout, // Gọi hàm xử lý đăng xuất
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(double.infinity, 50), // Full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}