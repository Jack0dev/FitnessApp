import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/role_service.dart';
import '../../core/routes/app_routes.dart';
import '../../utils/validators.dart';
import '../../core/constants/test_phone_numbers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  // Email/Password fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Phone fields
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  // Removed _verificationId - Supabase doesn't need it
  int _resendTimer = 0;

  final _authService = AuthService();
  final _dataService = DataService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _phoneController.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
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

  Future<void> _handleEmailRegister() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      final user = response.user;
      if (user != null) {
        // Đợi một chút để đảm bảo auth state đã được update
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify user đã được authenticate
        final currentUser = _authService.currentUser;
        if (currentUser?.id != user.id) {
          // Nếu user chưa được authenticate, thử lại sau 1 giây
          await Future.delayed(const Duration(seconds: 1));
          final retryUser = _authService.currentUser;
          if (retryUser?.id != user.id) {
            throw 'Authentication failed. Please try logging in.';
          }
        }
        
        // Save user data to database
        final dataSuccess = await _dataService.saveUserData(
          userId: user.id,
          userData: {
            'email': _emailController.text.trim(),
            'displayName': _nameController.text.trim(),
            'role': 'user', // Default role for new users
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          },
        );

        // Update profile with display name
        if (_nameController.text.trim().isNotEmpty) {
          await _authService.updateProfile(
            displayName: _nameController.text.trim(),
          );
        }

        if (mounted) {
          if (!dataSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Account created successfully! Note: Database might not be configured. Please check Supabase setup.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      } else {
        throw 'Registration failed. User was not created.';
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
      subscription = _authService.authStateChanges.listen(
        (AuthState state) async {
          if (state.event == AuthChangeEvent.signedIn && state.session != null) {
            final user = state.session!.user;
            
            if (mounted) {
              // Check if this is a new user (no data in database)
              final userModel = await _dataService.getUserData(user.id);
              final isNewUser = userModel == null;

              if (isNewUser) {
                // Save user data to Supabase for new Google users
                final dataSuccess = await _dataService.saveUserData(
                  userId: user.id,
                  userData: {
                    'email': user.email,
                    'displayName': user.userMetadata?['display_name'] as String?,
                    'photoURL': user.userMetadata?['photo_url'] as String?,
                    'provider': 'google',
                    'role': 'user', // Default role for new Google users
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  },
                );

                if (mounted && !dataSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account created successfully! Note: Database might not be configured.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }

              subscription?.cancel();
              // Get user data to determine role and redirect
              final updatedUserModel = await _dataService.getUserData(user.id);
              final route = updatedUserModel != null 
                  ? RoleService.getDashboardRoute(updatedUserModel)
                  : AppRoutes.userDashboard;
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
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
                final dataSuccess = await _dataService.saveUserData(
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

                if (mounted && !dataSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account created successfully! Note: Database might not be configured.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }

              // Get user data to determine role and redirect
              final updatedUserModel = await _dataService.getUserData(user.id);
              final route = updatedUserModel != null 
                  ? RoleService.getDashboardRoute(updatedUserModel)
                  : AppRoutes.userDashboard;
              
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
        // Check if this is a new user (no data in database)
        final userModel = await _dataService.getUserData(user.id);
        final isNewUser = userModel == null;

        if (isNewUser) {
          // Save user data for new phone users
          final dataSuccess = await _dataService.saveUserData(
            userId: user.id,
            userData: {
              'phoneNumber': _phoneController.text,
              'provider': 'phone',
              'role': 'user',
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            },
          );

          if (mounted && !dataSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully! Note: Database might not be configured.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Update phone number if changed
          await _dataService.updateUserData(
            userId: user.id,
            updateData: {
              'phoneNumber': _phoneController.text,
            },
          );
        }

        // Get user data to determine role and redirect
        if (mounted) {
          final updatedUserModel = await _dataService.getUserData(user.id);
          final route = updatedUserModel != null 
              ? RoleService.getDashboardRoute(updatedUserModel)
              : AppRoutes.userDashboard;
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
      appBar: AppBar(
        title: const Text('Register'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.email),
              text: 'Email',
            ),
            Tab(
              icon: Icon(Icons.phone),
              text: 'Phone',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Email Register Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _emailFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.person_add,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up with Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 16),
                  // Divider with "OR"
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Google Sign In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 20);
                      },
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),

          // Phone Register Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _phoneFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.phone_android,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpSent
                        ? 'Enter the verification code sent to your phone'
                        : 'Sign up with Phone Number',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Account will be created automatically when you verify your phone number',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (!_isOtpSent) ...[
                    // Test Phone Numbers Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Test Phone Numbers (Free)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
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
                              color: Colors.blue[800],
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
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 18, color: Colors.blue),
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
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Code: ${test['code']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[900],
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
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+16505553434',
                        prefixIcon: Icon(Icons.phone),
                        helperText: 'Enter your phone number or use test number above',
                      ),
                      validator: Validators.validatePhone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Verification Code'),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                        hintText: 'Enter 6-digit code',
                        prefixIcon: const Icon(Icons.lock),
                        helperText: TestPhoneNumbers.isTestNumber(_phoneController.text)
                            ? 'Test numbers: Use code 123456'
                            : 'Enter the code sent to your phone',
                        helperMaxLines: 2,
                      ),
                      validator: Validators.validateOTP,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (TestPhoneNumbers.isTestNumber(_phoneController.text))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using Supabase test number.\nVerification code: 123456\n\nIf SMS auto-retrieval timed out, enter code manually.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[900],
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
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'If SMS auto-retrieval timed out, check:\n1. Your SMS messages for the verification code\n2. Supabase Dashboard > Authentication > Users for the code\n3. Enter the code manually in the field above',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify & Register'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (_resendTimer > 0)
                          Text(
                            'Resend in $_resendTimer s',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          TextButton(
                            onPressed: _resendOTP,
                            child: const Text('Resend Code'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isOtpSent = false;
                          _otpController.clear();
                          _resendTimer = 0;
                        });
                      },
                      child: const Text('Change Phone Number'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Divider with "OR"
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Google Sign In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 20);
                      },
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
