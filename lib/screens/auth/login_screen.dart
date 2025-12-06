import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/auth/local_auth_service.dart';
import '../../services/user/user_preference_service.dart';
import '../../services/user/role_service.dart';
import '../../models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../utils/validators.dart';
import '../../core/constants/test_phone_numbers.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  // Email/Password fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  List<String> _loggedInEmails = [];

  // Phone fields
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  // Removed _verificationId - Supabase doesn't need it
  int _resendTimer = 0;

  final _authService = AuthService();
  final _dataService = DataService();
  final _localAuthService = LocalAuthService();
  final _userPreferenceService = UserPreferenceService();
  bool _isLoading = false;
  bool _showFingerprintButton = false;
  String? _savedEmail;
  bool _fingerprintAutoTriggered = false; // Flag to prevent multiple auto-triggers
  bool _isAutoTriggered = false; // Track if current attempt is auto-triggered

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _phoneController.addListener(_formatPhoneNumber);
    _emailController.addListener(_handleEmailInput);
    print('✅ [LoginScreen] initState called');
    _loadSavedCredentials();
    _loadLoggedInEmails();
    _checkFingerprintAvailability();
  }
  
  Future<void> _loadLoggedInEmails() async {
    final emails = await _userPreferenceService.getLoggedInEmails();
    if (mounted) {
      setState(() {
        _loggedInEmails = emails;
      });
    }
  }
  
  Future<void> _handleEmailSelected(String email) async {
    setState(() {
      _emailController.text = email;
    });
    
    // Check if password is saved for this email
    final hasPassword = await _userPreferenceService.hasPasswordForEmail(email);
    
    if (hasPassword) {
      // Get password and auto login
      final password = await _userPreferenceService.getPasswordForEmail(email);
      if (password != null && mounted) {
        setState(() {
          _passwordController.text = password;
          _rememberMe = true;
        });
        
        // Auto login
        await _handleEmailLogin();
      }
    } else {
      // Show message that password is not saved
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mật khẩu chưa được lưu cho email này. Vui lòng nhập mật khẩu.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        // Focus on password field
        FocusScope.of(context).nextFocus();
      }
    }
  }
  
  void _handleEmailInput() {
    final text = _emailController.text;
    // Auto complete @gmail.com if user types something and presses enter/tab
    if (text.isNotEmpty && !text.contains('@')) {
      // This will be handled in onEditingComplete
    }
  }
  
  Future<void> _loadSavedCredentials() async {
    final credentials = await _userPreferenceService.getLastLoggedInCredentials();
    if (mounted && credentials['email'] != null) {
      setState(() {
        _emailController.text = credentials['email']!;
        // Only load password if remember me was previously enabled
        if (credentials['password'] != null) {
          _passwordController.text = credentials['password']!;
          _rememberMe = true;
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 [LoginScreen] App lifecycle changed: $state');
    
    // When app resumes and user is not logged in, check fingerprint again
    if (state == AppLifecycleState.resumed && _authService.currentUser == null) {
      print('🔄 [LoginScreen] App resumed, checking fingerprint again...');
      _fingerprintAutoTriggered = false; // Reset flag to allow auto-trigger again
      _checkFingerprintAvailability();
    }
  }

  Future<void> _checkFingerprintAvailability() async {
    print('🔍 [LoginScreen] Checking fingerprint availability...');
    
    final isEnabled = await _localAuthService.isFingerprintEnabled();
    final isSupported = await _localAuthService.isDeviceSupported();
    final hasBiometrics = await _localAuthService.hasEnrolledBiometrics();
    final credentials = await _userPreferenceService.getLastLoggedInCredentials();
    final currentUser = _authService.currentUser;

    print('🔍 [LoginScreen] Fingerprint check results:');
    print('  - Enabled: $isEnabled');
    print('  - Supported: $isSupported');
    print('  - Has Biometrics: $hasBiometrics');
    print('  - Has Email: ${credentials['email'] != null}');
    print('  - Has Password: ${credentials['password'] != null}');
    print('  - Provider: ${credentials['provider'] ?? 'email'}');
    print('  - Current User: ${currentUser != null ? currentUser.id : 'null'}');
    print('  - Auto-triggered: $_fingerprintAutoTriggered');

    if (mounted) {
      setState(() {
        final provider = credentials['provider'] ?? 'email';
        final hasEmail = credentials['email'] != null;
        // For email provider, need both email and password
        // For google provider, only need email
        final hasCredentials = provider == 'google' 
            ? hasEmail 
            : (hasEmail && credentials['password'] != null);
        
        // Show fingerprint button if enabled, supported, has biometrics, and has saved credentials
        _showFingerprintButton = isEnabled && 
                                 isSupported && 
                                 hasBiometrics && 
                                 hasCredentials;
        _savedEmail = credentials['email'];
        // Auto-fill email if available
        if (_savedEmail != null) {
          _emailController.text = _savedEmail!;
        }
      });
      
      // Auto-trigger fingerprint authentication if enabled and user is not logged in
      final canAutoTrigger = isEnabled && 
                             isSupported && 
                             hasBiometrics && 
                             credentials['email'] != null && 
                             currentUser == null &&
                             !_fingerprintAutoTriggered;
      
      print('🔍 [LoginScreen] Can auto-trigger: $canAutoTrigger');
      
      if (canAutoTrigger) {
        final provider = credentials['provider'] ?? 'email';
        final hasPassword = credentials['password'] != null;
        
        // Check if we have all required credentials
        final canAutoLogin = provider == 'google' 
            ? credentials['email'] != null 
            : (credentials['email'] != null && hasPassword);
        
        print('🔍 [LoginScreen] Can auto-login: $canAutoLogin');
        
        if (canAutoLogin) {
          print('✅ [LoginScreen] Auto-triggering fingerprint authentication...');
          
          // Mark as triggered to prevent multiple triggers
          _fingerprintAutoTriggered = true;
          _isAutoTriggered = true; // Mark as auto-triggered
          
          // Wait a bit for UI to be ready, then trigger fingerprint immediately
          // Show fingerprint dialog right away for better UX
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted && _authService.currentUser == null) {
            print('✅ [LoginScreen] Auto-triggering fingerprint authentication...');
            await _handleFingerprintLogin(isManualTrigger: false);
          } else {
            print('⚠️ [LoginScreen] Skipping auto-trigger: ${!mounted ? "not mounted" : "user already logged in"}');
          }
        } else {
          print('❌ [LoginScreen] Cannot auto-login: Missing credentials');
        }
      } else {
        print('❌ [LoginScreen] Cannot auto-trigger:');
        print('  - Enabled: $isEnabled');
        print('  - Supported: $isSupported');
        print('  - Has Biometrics: $hasBiometrics');
        print('  - Has Email: ${credentials['email'] != null}');
        print('  - Current User: ${currentUser != null ? "exists" : "null"}');
        print('  - Already Triggered: $_fingerprintAutoTriggered');
      }
    }
  }

  Future<void> _handleFingerprintLogin({bool isManualTrigger = false}) async {
    print('🔐 [LoginScreen] _handleFingerprintLogin called (isManualTrigger: $isManualTrigger)');
    
    // Track if this is manual trigger or auto-trigger
    _isAutoTriggered = !isManualTrigger;
    
    // If manually triggered, mark as triggered to prevent auto-trigger during this session
    if (isManualTrigger) {
      _fingerprintAutoTriggered = true;
    }
    
    // Get saved credentials
    final credentials = await _userPreferenceService.getLastLoggedInCredentials();
    print('🔐 [LoginScreen] Got credentials: ${credentials['email'] != null ? "has email" : "no email"}');
    final savedEmail = credentials['email'];
    final savedPassword = credentials['password'];
    final provider = credentials['provider'] ?? 'email';

    if (savedEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thông tin đăng nhập đã lưu. Vui lòng đăng nhập thủ công trước.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // For email provider, need password
    if (provider == 'email' && savedPassword == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy mật khẩu đã lưu. Vui lòng đăng nhập thủ công trước.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate with fingerprint
      final authenticated = await _localAuthService.authenticate(
        reason: 'Xác thực vân tay để đăng nhập',
      );

      if (authenticated) {
        print('✅ [LoginScreen] Fingerprint authenticated successfully!');
        print('🔄 [LoginScreen] Auto-login with saved credentials...');
        
        // After fingerprint authentication succeeds, auto-login with saved credentials
        // This is simpler and more reliable than refreshing session
        if (provider == 'google') {
          // For Google Sign In, automatically sign in with Google
          await _authService.signInWithGoogle();
          
          // Listen to auth state changes to detect when OAuth callback completes
          StreamSubscription<AuthState>? subscription;
          subscription = _authService.authStateChanges.listen(
            (AuthState state) async {
              if (state.event == AuthChangeEvent.signedIn && state.session != null) {
                final user = state.session!.user;
                
                if (mounted) {
                  final userModel = await _dataService.getUserData(user.id);
                  final isNewUser = userModel == null;

                  if (isNewUser) {
                    await _dataService.saveUserData(
                      userId: user.id,
                      userData: {
                        'email': user.email,
                        'displayName': user.userMetadata?['display_name'] as String?,
                        'photoURL': user.userMetadata?['photo_url'] as String?,
                        'provider': 'google',
                        'role': 'user',
                        'createdAt': DateTime.now(),
                        'updatedAt': DateTime.now(),
                      },
                    );
                  }

                  // Save session tokens after successful login
                  await _saveSessionTokens();

                  subscription?.cancel();
                  if (mounted) {
                    final updatedUserModel = await _dataService.getUserData(user.id);
                    final route = updatedUserModel != null 
                        ? RoleService.getDashboardRoute(updatedUserModel)
                        : AppRoutes.userDashboard;
                    setState(() {
                      _isLoading = false;
                      _fingerprintAutoTriggered = false; // Reset flag
                    });
                    Navigator.of(context).pushReplacementNamed(route);
                  }
                }
              }
            },
            onError: (error) {
              subscription?.cancel();
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          );
          
          // Timeout after 60 seconds
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted && _isLoading) {
              subscription?.cancel();
              setState(() {
                _isLoading = false;
              });
            }
          });
          return; // Don't continue to email/password flow
        } else {
          // For email/password, auto-fill and login
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword!;

          final response = await _authService.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );

          // Save session tokens after successful login
          await _saveSessionTokens();

          // Get user data to determine role and redirect
          if (mounted) {
            final user = response.user ?? _authService.currentUser;
            if (user != null) {
              // Đảm bảo userModel được tạo nếu chưa có
              UserModel? userModel = await _dataService.getUserData(user.id);
              
              // Nếu không có userModel, tạo mới với role mặc định 'user'
              if (userModel == null) {
                userModel = UserModel(
                  uid: user.id,
                  email: user.email,
                  displayName: user.userMetadata?['display_name'] as String?,
                  photoURL: user.userMetadata?['photo_url'] as String?,
                  role: UserRole.user, // Default role
                );
                
                // Lưu vào database
                await _dataService.saveUserData(
                  userId: user.id,
                  userData: {
                    'email': user.email,
                    'displayName': user.userMetadata?['display_name'] as String?,
                    'photoURL': user.userMetadata?['photo_url'] as String?,
                    'provider': 'email',
                    'role': 'user',
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  },
                );
              }
              
              final route = RoleService.getDashboardRoute(userModel);
              
              setState(() {
                _isLoading = false;
                _fingerprintAutoTriggered = false; // Reset flag
              });
              Navigator.of(context).pushReplacementNamed(route);
            } else {
              setState(() {
                _isLoading = false;
                _fingerprintAutoTriggered = false; // Reset flag
              });
              // Nếu không có user, redirect về login
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Don't show error message if it was auto-triggered (user might have cancelled intentionally)
          // Only show error if user manually clicked the button
          if (_isAutoTriggered) {
            // Reset flag so user can try manually if auto-trigger failed
            _fingerprintAutoTriggered = false;
          } else {
            // Manual trigger failed, show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xác thực vân tay thất bại hoặc đã hủy'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMessage = e.toString();
        if (errorMessage.contains('cancelled')) {
          // User cancelled, don't show error
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập bằng vân tay thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  /// Ask user if they want to enable fingerprint login
  Future<bool> _askEnableFingerprint() async {
    final isSupported = await _localAuthService.isDeviceSupported();
    final hasBiometrics = await _localAuthService.hasEnrolledBiometrics();
    
    if (!isSupported || !hasBiometrics) {
      return false;
    }
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blue),
              SizedBox(width: 8),
              Text('Bật đăng nhập bằng vân tay?'),
            ],
          ),
          content: const Text(
            'Bạn có muốn bật đăng nhập bằng vân tay để đăng nhập nhanh hơn không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Có'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Save session tokens after successful login
  Future<void> _saveSessionTokens() async {
    try {
      final session = _authService.currentSession;
      if (session != null) {
        await _userPreferenceService.saveSessionTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? '',
        );
        print('✅ [LoginScreen] Session tokens saved');
      }
    } catch (e) {
      print('❌ [LoginScreen] Error saving session tokens: $e');
    }
  }

  void _formatPhoneNumber() {
    final text = _phoneController.text;
    final formatted = Validators.formatPhoneNumber(text);
    if (formatted != text) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _startResendTimer() {
    if (_resendTimer > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendTimer--;
          });
          _startResendTimer();
        }
      });
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final response = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save session tokens (refresh token) for fingerprint login
      await _saveSessionTokens();
      
      // Add email to logged in emails list (handled in saveLastLoggedInCredentials)

      // Get user data to determine role and redirect
      if (mounted) {
        final user = response.user ?? _authService.currentUser;
        if (user != null) {
          // Ask user if they want to enable fingerprint login (if not already enabled)
          final isFingerprintEnabled = await _localAuthService.isFingerprintEnabled();
          if (!isFingerprintEnabled) {
            final wantToEnable = await _askEnableFingerprint();
            if (wantToEnable) {
              // Test fingerprint authentication before enabling
              final authenticated = await _localAuthService.authenticate(
                reason: 'Xác thực vân tay để bật đăng nhập bằng vân tay',
              );
              
              if (authenticated) {
                await _localAuthService.setFingerprintEnabled(true);
                // Save credentials for fingerprint login only if remember me is checked
                if (_rememberMe) {
                  await _userPreferenceService.saveLastLoggedInCredentials(
                    email: email,
                    password: password,
                    provider: 'email',
                  );
                } else {
                  // Only save email, not password
                  await _userPreferenceService.saveLastLoggedInCredentials(
                    email: email,
                    password: null,
                    provider: 'email',
                  );
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã bật đăng nhập bằng vân tay'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xác thực vân tay thất bại. Vui lòng bật lại trong Settings.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            }
          } else {
            // Already enabled, just save credentials if remember me is checked
            if (_rememberMe) {
              await _userPreferenceService.saveLastLoggedInCredentials(
                email: email,
                password: password,
                provider: 'email',
              );
            } else {
              // Only save email, not password
              await _userPreferenceService.saveLastLoggedInCredentials(
                email: email,
                password: null,
                provider: 'email',
              );
            }
          }
          
          // Also save credentials based on remember me checkbox (for non-fingerprint users)
          if (!isFingerprintEnabled && _rememberMe) {
            await _userPreferenceService.saveLastLoggedInCredentials(
              email: email,
              password: password,
              provider: 'email',
            );
          } else if (!isFingerprintEnabled && !_rememberMe) {
            // Only save email if remember me is not checked
            await _userPreferenceService.saveLastLoggedInCredentials(
              email: email,
              password: null,
              provider: 'email',
            );
          }

          // Đảm bảo userModel được tạo nếu chưa có
          UserModel? userModel = await _dataService.getUserData(user.id);
          
          // Nếu không có userModel, tạo mới với role mặc định 'user'
          if (userModel == null) {
            userModel = UserModel(
              uid: user.id,
              email: user.email,
              displayName: user.userMetadata?['display_name'] as String?,
              photoURL: user.userMetadata?['photo_url'] as String?,
              role: UserRole.user, // Default role
            );
            
            // Lưu vào database
            await _dataService.saveUserData(
              userId: user.id,
              userData: {
                'email': user.email,
                'displayName': user.userMetadata?['display_name'] as String?,
                'photoURL': user.userMetadata?['photo_url'] as String?,
                'provider': 'email',
                'role': 'user',
                'createdAt': DateTime.now(),
                'updatedAt': DateTime.now(),
              },
            );
          }
          
          final route = RoleService.getDashboardRoute(userModel);
          
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pushReplacementNamed(route);
        } else {
          setState(() {
            _isLoading = false;
          });
          // Nếu không có user, redirect về login
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    StreamSubscription<AuthState>? subscription;
    
    try {
      // Initiate Google OAuth flow
      await _authService.signInWithGoogle();

      // Listen to auth state changes to detect when OAuth callback completes
      // OAuth flow: User clicks button -> Browser opens -> User signs in -> Redirects to app via deep link
      // Supabase SDK automatically handles the deep link and updates auth state
      subscription = _authService.authStateChanges.listen(
        (AuthState state) async {
          if (state.event == AuthChangeEvent.signedIn && state.session != null) {
            // User successfully signed in via OAuth
            final user = state.session!.user;
            
            if (mounted) {
              // Check if this is a new user (no data in database)
              final userModel = await _dataService.getUserData(user.id);
              final isNewUser = userModel == null;

              if (isNewUser) {
                // Save user data to Supabase for new Google users
                await _dataService.saveUserData(
                  userId: user.id,
                  userData: {
                    'email': user.email,
                    'displayName': user.userMetadata?['display_name'] as String?,
                    'photoURL': user.userMetadata?['photo_url'] as String?,
                    'provider': 'google',
                    'role': 'user',
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  },
                );
              }

              // Save session tokens (refresh token) for fingerprint login
              await _saveSessionTokens();

              // Ask user if they want to enable fingerprint login (if not already enabled)
              final isFingerprintEnabled = await _localAuthService.isFingerprintEnabled();
              if (!isFingerprintEnabled && user.email != null) {
                final wantToEnable = await _askEnableFingerprint();
                if (wantToEnable) {
                  // Test fingerprint authentication before enabling
                  final authenticated = await _localAuthService.authenticate(
                    reason: 'Xác thực vân tay để bật đăng nhập bằng vân tay',
                  );
                  
                  if (authenticated) {
                    await _localAuthService.setFingerprintEnabled(true);
                    // Save credentials for fingerprint login
                    await _userPreferenceService.saveLastLoggedInCredentials(
                      email: user.email!,
                      password: null, // Google doesn't have password
                      provider: 'google',
                    );
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã bật đăng nhập bằng vân tay'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xác thực vân tay thất bại. Vui lòng bật lại trong Settings.'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                }
              } else if (isFingerprintEnabled && user.email != null) {
                // Already enabled, just save credentials
                await _userPreferenceService.saveLastLoggedInCredentials(
                  email: user.email!,
                  password: null, // Google doesn't have password
                  provider: 'google',
                );
              }

              // Get user data to determine role and redirect
              UserModel? updatedUserModel = await _dataService.getUserData(user.id);
              
              // Nếu không có userModel, tạo mới với role mặc định 'user'
              if (updatedUserModel == null) {
                updatedUserModel = UserModel(
                  uid: user.id,
                  email: user.email,
                  displayName: user.userMetadata?['display_name'] as String?,
                  photoURL: user.userMetadata?['photo_url'] as String?,
                  role: UserRole.user, // Default role
                );
                
                // Lưu vào database
                await _dataService.saveUserData(
                  userId: user.id,
                  userData: {
                    'email': user.email,
                    'displayName': user.userMetadata?['display_name'] as String?,
                    'photoURL': user.userMetadata?['photo_url'] as String?,
                    'provider': 'google',
                    'role': 'user',
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  },
                );
              }
              
              final route = RoleService.getDashboardRoute(updatedUserModel);
              
              subscription?.cancel(); // Cancel subscription before navigation
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                Navigator.of(context).pushReplacementNamed(route);
              }
            }
          } else if (state.event == AuthChangeEvent.signedOut) {
            // User signed out (shouldn't happen during OAuth flow, but handle it)
            subscription?.cancel();
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },
        onError: (error) {
          subscription?.cancel();
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Google sign in failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

      // Periodically check if user has been authenticated
      // This handles cases where deep link callback doesn't trigger authStateChanges
      Timer? checkTimer;
      checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (!mounted || !_isLoading) {
          timer.cancel();
          return;
        }
        
        final user = _authService.currentUser;
        if (user != null) {
          // User has been authenticated
          subscription?.cancel();
          timer.cancel();
          
          if (mounted) {
            try {
              // Check if this is a new user
              final userModel = await _dataService.getUserData(user.id);
              final isNewUser = userModel == null;

              if (isNewUser) {
                // Save user data for new Google users
                await _dataService.saveUserData(
                  userId: user.id,
                  userData: {
                    'email': user.email,
                    'displayName': user.userMetadata?['display_name'] as String?,
                    'photoURL': user.userMetadata?['photo_url'] as String?,
                    'provider': 'google',
                    'role': 'user',
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  },
                );
              }

              // Save email and provider for fingerprint login
              final isFingerprintEnabled = await _localAuthService.isFingerprintEnabled();
              if (isFingerprintEnabled && user.email != null) {
                await _userPreferenceService.saveLastLoggedInCredentials(
                  email: user.email!,
                  password: null,
                  provider: 'google',
                );
              }

              // Get user data to determine role and redirect
              UserModel? updatedUserModel = await _dataService.getUserData(user.id);
              
              // Nếu không có userModel, tạo mới với role mặc định 'user'
              if (updatedUserModel == null) {
                updatedUserModel = UserModel(
                  uid: user.id,
                  email: user.email,
                  displayName: user.userMetadata?['display_name'] as String?,
                  photoURL: user.userMetadata?['photo_url'] as String?,
                  role: UserRole.user, // Default role
                );
                
                // Lưu vào database
                await _dataService.saveUserData(
                  userId: user.id,
                  userData: {
                    'email': user.email,
                    'displayName': user.userMetadata?['display_name'] as String?,
                    'photoURL': user.userMetadata?['photo_url'] as String?,
                    'provider': 'google',
                    'role': 'user',
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  },
                );
              }
              
              final route = RoleService.getDashboardRoute(updatedUserModel);
              
              setState(() {
                _isLoading = false;
              });
              Navigator.of(context).pushReplacementNamed(route);
            } catch (e) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        }
      });

      // Set a timeout in case OAuth callback doesn't complete
      Future.delayed(const Duration(seconds: 60), () {
        checkTimer?.cancel();
        if (mounted && _isLoading) {
          subscription?.cancel();
          setState(() {
            _isLoading = false;
          });
          // Don't show error if user might still be in browser
        }
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('cancelled') || errorMessage.contains('canceled')) {
          // User cancelled, don't show error
          setState(() {
            _isLoading = false;
          });
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendOTP() async {
    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = Validators.formatPhoneNumber(_phoneController.text);
    final isTestNumber = TestPhoneNumbers.isTestNumber(phoneNumber);

    try {
      await _authService.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
      );

      setState(() {
        _isOtpSent = true;
        _isLoading = false;
        _resendTimer = 60;
        
        // Auto-fill OTP code for test numbers
        if (isTestNumber) {
          _otpController.text = TestPhoneNumbers.defaultTestCode;
        }
      });
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTestNumber 
                  ? 'Using test number. Code: ${TestPhoneNumbers.defaultTestCode}'
                  : 'Verification code sent to your phone',
            ),
            backgroundColor: isTestNumber ? Colors.blue : Colors.green,
            duration: Duration(seconds: isTestNumber ? 5 : 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    if (!_isOtpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please request a verification code first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyPhoneOTP(
        phoneNumber: _phoneController.text,
        token: _otpController.text,
      );

      final user = response.user;
      if (user != null) {
        // Check if this is a new user
        final userModel = await _dataService.getUserData(user.id);
        final isNewUser = userModel == null;

        if (isNewUser) {
          await _dataService.saveUserData(
            userId: user.id,
            userData: {
              'phoneNumber': _phoneController.text,
              'provider': 'phone',
              'role': 'user',
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            },
          );
        }

        // Get user data to determine role and redirect
        if (mounted) {
          UserModel? updatedUserModel = await _dataService.getUserData(user.id);
          
          // Nếu không có userModel, tạo mới với role mặc định 'user'
          if (updatedUserModel == null) {
            updatedUserModel = UserModel(
              uid: user.id,
              email: user.email,
              displayName: user.userMetadata?['display_name'] as String?,
              photoURL: user.userMetadata?['photo_url'] as String?,
              role: UserRole.user, // Default role
            );
            
            // Lưu vào database
            await _dataService.saveUserData(
              userId: user.id,
              userData: {
                'phoneNumber': _phoneController.text,
                'provider': 'phone',
                'role': 'user',
                'createdAt': DateTime.now(),
                'updatedAt': DateTime.now(),
              },
            );
          }
          
          final route = RoleService.getDashboardRoute(updatedUserModel);
          Navigator.of(context).pushReplacementNamed(route);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Provide helpful message for invalid code error
        if (errorMessage.toLowerCase().contains('invalid') && 
            errorMessage.toLowerCase().contains('code')) {
          final isTestNum = TestPhoneNumbers.isTestNumber(_phoneController.text);
          if (isTestNum) {
            errorMessage = 'Invalid verification code.\n\n'
                'For test numbers, use code: 123456\n'
                'Or check your Supabase Dashboard for custom test number codes.';
          } else {
            errorMessage = 'Invalid verification code.\n\n'
                'Please check:\n'
                '1. SMS message for the correct code\n'
                '2. Supabase Dashboard > Authentication > Users\n'
                '3. Ensure you\'re using the latest code sent.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait ${_resendTimer} seconds before resending'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await _sendOTP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const CustomText(
          text: 'Login',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: DesignTokens.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: DesignTokens.primary,
              unselectedLabelColor: DesignTokens.textSecondary,
              indicatorColor: DesignTokens.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.email_outlined),
                  text: 'Email',
                ),
                Tab(
                  icon: Icon(Icons.phone_outlined),
                  text: 'Phone',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Email Login Tab
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Form(
                key: _emailFormKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: DesignTokens.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const CustomText(
                        text: 'Welcome Back',
                        variant: TextVariant.displayLarge,
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        text: 'Sign in to continue',
                        variant: TextVariant.bodyLarge,
                        color: DesignTokens.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Form Fields
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return _loggedInEmails;
                              }
                              return _loggedInEmails.where((email) {
                                return email.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                );
                              }).toList();
                            },
                            onSelected: (String email) {
                              _handleEmailSelected(email);
                            },
                            fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              // Sync with _emailController
                              if (textEditingController.text != _emailController.text) {
                                textEditingController.text = _emailController.text;
                              }
                              _emailController.addListener(() {
                                if (textEditingController.text != _emailController.text) {
                                  textEditingController.text = _emailController.text;
                                }
                              });
                              
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: DesignTokens.textPrimary, fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(color: DesignTokens.textSecondary),
                                  prefixIcon: const Icon(Icons.email_outlined, color: DesignTokens.textSecondary),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                                validator: Validators.validateEmail,
                                onEditingComplete: () {
                                  // Auto complete @gmail.com if user hasn't entered @
                                  final text = textEditingController.text.trim();
                                  if (text.isNotEmpty && !text.contains('@')) {
                                    textEditingController.text = '$text@gmail.com';
                                    _emailController.text = '$text@gmail.com';
                                  }
                                  // Move focus to password field
                                  FocusScope.of(context).nextFocus();
                                },
                                onFieldSubmitted: (value) {
                                  // Auto complete @gmail.com if user hasn't entered @
                                  final text = textEditingController.text.trim();
                                  if (text.isNotEmpty && !text.contains('@')) {
                                    textEditingController.text = '$text@gmail.com';
                                    _emailController.text = '$text@gmail.com';
                                  }
                                  // Move focus to password field
                                  FocusScope.of(context).nextFocus();
                                },
                                onChanged: (value) {
                                  _emailController.text = value;
                                },
                              );
                            },
                            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                              if (options.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final email = options.elementAt(index);
                                        return InkWell(
                                          onTap: () {
                                            onSelected(email);
                                          },
                                          child: Container(
                                            color: Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.email_outlined, size: 20, color: Colors.black87),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      email,
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: DesignTokens.textPrimary, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: DesignTokens.textSecondary),
                              prefixIcon: const Icon(Icons.lock_outline, color: DesignTokens.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: DesignTokens.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            validator: Validators.validatePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              _handleEmailLogin();
                            },
                          ),
                          const SizedBox(height: 12),
                          // Remember Me Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: DesignTokens.primary,
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: DesignTokens.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Fingerprint Login Button (if available)
                          if (_showFingerprintButton) ...[
                            CustomButton(
                              label: 'Login with Fingerprint',
                              icon: Icons.fingerprint,
                              onPressed: _isLoading ? null : () => _handleFingerprintLogin(isManualTrigger: true),
                              variant: ButtonVariant.outline,
                              size: ButtonSize.large,
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Login Button
                          CustomButton(
                            label: 'Login',
                            icon: Icons.login,
                            onPressed: _isLoading ? null : _handleEmailLogin,
                            variant: ButtonVariant.primary,
                            size: ButtonSize.large,
                            isLoading: _isLoading,
                            isFullWidth: true,
                          ),
                          const SizedBox(height: 32),
                          // Divider with "OR"
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.withOpacity(0.2),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: DesignTokens.textLight,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.withOpacity(0.2),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Google Sign In Button
                          CustomButton(
                            label: 'Continue with Google',
                            icon: Icons.g_mobiledata,
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            variant: ButtonVariant.outline,
                            size: ButtonSize.large,
                            isFullWidth: true,
                          ),
                          const SizedBox(height: 32),
                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: 'Don\'t have an account? ',
                                variant: TextVariant.bodyMedium,
                                color: DesignTokens.textSecondary,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(AppRoutes.register);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const CustomText(
                                  text: 'Sign up',
                                  variant: TextVariant.bodyMedium,
                                  color: DesignTokens.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Phone Login Tab
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Form(
                key: _phoneFormKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          size: 48,
                          color: DesignTokens.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const CustomText(
                        text: 'Login with Phone',
                        variant: TextVariant.displayLarge,
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        text: _isOtpSent
                            ? 'Enter the verification code sent to your phone'
                            : 'Enter your phone number to receive a verification code',
                        variant: TextVariant.bodyLarge,
                        color: DesignTokens.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Form Content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: DesignTokens.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DesignTokens.success.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, color: DesignTokens.success, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'New user? Just enter your phone number - account will be created automatically!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DesignTokens.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_isOtpSent) ...[
                            // Test Phone Numbers Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DesignTokens.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: DesignTokens.info.withOpacity(0.3)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: DesignTokens.info, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Test Phone Numbers (Free)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: DesignTokens.info,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Supabase test numbers work without billing.\nVerification code: ${TestPhoneNumbers.defaultTestCode}\n\nNote: If you added custom test numbers in Supabase Dashboard, use the codes you configured there.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...TestPhoneNumbers.testNumbers.map((test) {
                                    final number = test['formatted']!;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        onTap: () {
                                          _phoneController.text = test['number']!;
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: DesignTokens.info.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.phone, size: 18, color: DesignTokens.info),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    number,
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: DesignTokens.info.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Code: ${test['code']}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: DesignTokens.info,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withOpacity(0.2),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: DesignTokens.textLight,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withOpacity(0.2),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: DesignTokens.textPrimary, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: '+16505553434',
                                labelStyle: const TextStyle(color: DesignTokens.textSecondary),
                                prefixIcon: const Icon(Icons.phone_outlined, color: DesignTokens.textSecondary),
                                helperText: 'Enter your phone number or use test number above',
                                helperStyle: TextStyle(color: DesignTokens.textLight, fontSize: 12),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              validator: Validators.validatePhone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                              ],
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              label: 'Send Verification Code',
                              icon: Icons.send,
                              onPressed: _isLoading ? null : _sendOTP,
                              variant: ButtonVariant.primary,
                              size: ButtonSize.large,
                              isLoading: _isLoading,
                              isFullWidth: true,
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 8,
                                color: DesignTokens.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Verification Code',
                                hintText: '000000',
                                labelStyle: const TextStyle(color: DesignTokens.textSecondary),
                                prefixIcon: const Icon(Icons.lock_outline, color: DesignTokens.textSecondary),
                                helperText: TestPhoneNumbers.isTestNumber(_phoneController.text)
                                    ? 'Test numbers: Use code 123456'
                                    : 'Enter the code sent to your phone',
                                helperStyle: TextStyle(color: DesignTokens.textLight, fontSize: 12),
                                helperMaxLines: 2,
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              validator: Validators.validateOTP,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (TestPhoneNumbers.isTestNumber(_phoneController.text))
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DesignTokens.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: DesignTokens.info.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: DesignTokens.info, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Using Supabase test number.\nVerification code: 123456\n\nIf SMS auto-retrieval timed out, enter code manually.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: DesignTokens.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DesignTokens.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: DesignTokens.warning.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: DesignTokens.warning, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'If SMS auto-retrieval timed out, check:\n1. Your SMS messages for the verification code\n2. Supabase Dashboard > Authentication > Users for the code\n3. Enter the code manually in the field above',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: DesignTokens.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            CustomButton(
                              label: 'Verify Code',
                              icon: Icons.verified,
                              onPressed: _isLoading ? null : _verifyOTP,
                              variant: ButtonVariant.primary,
                              size: ButtonSize.large,
                              isLoading: _isLoading,
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomText(
                                  text: "Didn't receive code? ",
                                  variant: TextVariant.bodyMedium,
                                  color: DesignTokens.textSecondary,
                                ),
                                if (_resendTimer > 0)
                                  CustomText(
                                    text: 'Resend in $_resendTimer s',
                                    variant: TextVariant.bodyMedium,
                                    color: DesignTokens.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  )
                                else
                                  TextButton(
                                    onPressed: _resendOTP,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const CustomText(
                                      text: 'Resend Code',
                                      variant: TextVariant.bodyMedium,
                                      color: DesignTokens.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                  _resendTimer = 0;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const CustomText(
                                text: 'Change Phone Number',
                                variant: TextVariant.bodyMedium,
                                color: DesignTokens.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
