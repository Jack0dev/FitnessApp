import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/local_auth_service.dart';
import '../services/user_preference_service.dart';
import '../core/routes/app_routes.dart';
import '../utils/validators.dart';
import '../core/constants/test_phone_numbers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Email/Password fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Phone fields
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  String? _verificationId;
  int _resendTimer = 0;

  final _authService = AuthService();
  final _dataService = DataService();
  final _localAuthService = LocalAuthService();
  final _userPreferenceService = UserPreferenceService();
  bool _isLoading = false;
  bool _showFingerprintButton = false;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _phoneController.addListener(_formatPhoneNumber);
    _checkFingerprintAvailability();
  }

  Future<void> _checkFingerprintAvailability() async {
    final isEnabled = await _localAuthService.isFingerprintEnabled();
    final isSupported = await _localAuthService.isDeviceSupported();
    final hasBiometrics = await _localAuthService.hasEnrolledBiometrics();
    final savedEmail = await _userPreferenceService.getLastLoggedInEmail();

    if (mounted) {
      setState(() {
        _showFingerprintButton = isEnabled && isSupported && hasBiometrics && savedEmail != null;
        _savedEmail = savedEmail;
        if (_savedEmail != null) {
          _emailController.text = _savedEmail!;
        }
      });
    }
  }

  Future<void> _handleFingerprintLogin() async {
    if (_savedEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved email found. Please login manually first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authenticated = await _localAuthService.authenticate(
        reason: 'Authenticate to login quickly',
      );

      if (authenticated) {
        // Auto-fill email
        _emailController.text = _savedEmail!;
        // Show message that user still needs to enter password
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint verified! Please enter your password.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      // Save email for fingerprint login
      await _userPreferenceService.saveLastLoggedInEmail(email);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
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

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential?.user != null) {
        final isNewUser = userCredential!.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          // Save user data to Firestore for new Google users
          await _dataService.saveUserData(
            userId: userCredential.user!.uid,
            userData: {
              'email': userCredential.user!.email,
              'displayName': userCredential.user!.displayName,
              'photoURL': userCredential.user!.photoURL,
              'provider': 'google',
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            },
          );
        }

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('cancelled')) {
          // User cancelled, don't show error
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
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

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = Validators.formatPhoneNumber(_phoneController.text);
    final isTestNumber = TestPhoneNumbers.isTestNumber(phoneNumber);

    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
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
                    ? 'Using Firebase test number. Code: ${TestPhoneNumbers.defaultTestCode}'
                    : 'Verification code sent to your phone',
              ),
              backgroundColor: isTestNumber ? Colors.blue : Colors.green,
              duration: Duration(seconds: isTestNumber ? 5 : 3),
            ),
          );
        }
      },
      onError: (String error) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_verificationId == null) {
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
      final userCredential = await _authService.signInWithPhoneNumber(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      if (userCredential?.user != null) {
        final isNewUser = userCredential!.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          await _dataService.saveUserData(
            userId: userCredential.user!.uid,
            userData: {
              'phoneNumber': _phoneController.text,
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            },
          );
        }

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
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
                'Or check your Firebase Console for custom test number codes.';
          } else {
            errorMessage = 'Invalid verification code.\n\n'
                'Please check:\n'
                '1. SMS message for the correct code\n'
                '2. Firebase Console > Authentication > Users\n'
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
        title: const Text('Login'),
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
          // Email Login Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.email,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
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
                  const SizedBox(height: 24),
                  // Fingerprint Login Button (if available)
                  if (_showFingerprintButton) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleFingerprintLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Login with Fingerprint'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
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
                      Navigator.of(context).pushNamed(AppRoutes.register);
                    },
                    child: const Text('Don\'t have an account? Sign up'),
                  ),
                ],
              ),
            ),
          ),

          // Phone Login Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
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
                    'Login with Phone',
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
                        : 'Enter your phone number to receive a verification code',
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'New user? Just enter your phone number - account will be created automatically!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
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
                            'Firebase test numbers work without billing.\nVerification code: ${TestPhoneNumbers.defaultTestCode}\n\nNote: If you added custom test numbers in Firebase Console, use the codes you configured there.',
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
                                'Using Firebase test number.\nVerification code: 123456\n\nIf SMS auto-retrieval timed out, enter code manually.',
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
                                'If SMS auto-retrieval timed out, check:\n1. Your SMS messages for the verification code\n2. Firebase Console > Authentication > Users for the code\n3. Enter the code manually in the field above',
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
                          : const Text('Verify Code'),
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
                          _verificationId = null;
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
                      Navigator.of(context).pushNamed(AppRoutes.register);
                    },
                    child: const Text('Want to register with email instead?'),
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
