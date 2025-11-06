import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../core/routes/app_routes.dart';
import '../utils/validators.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  final _dataService = DataService();

  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int _resendTimer = 0;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
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

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = Validators.formatPhoneNumber(_phoneController.text);

    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
          _isLoading = false;
          _resendTimer = 60; // 60s countdown
        });

        _startResendTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your phone'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
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

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

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
        } else {
          await _dataService.saveUserData(
            userId: userCredential.user!.uid,
            userData: {
              'phoneNumber': _phoneController.text,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
        title: const Text('Phone Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.phone_android, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Login with Phone',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpSent
                    ? 'Enter the verification code sent to your phone'
                    : 'Enter your phone number to receive a verification code',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // ====== PHONE STEP ======
              if (!_isOtpSent) ...[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+16505553434',
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'We will send a 6-digit verification code',
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

              // ====== OTP STEP ======
              ] else ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: Validators.validateOTP,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
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
                    Text("Didn't receive code? ", style: TextStyle(color: Colors.grey[600])),
                    if (_resendTimer > 0)
                      Text(
                        'Resend in $_resendTimer s',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                      )
                    else
                      TextButton(onPressed: _resendOTP, child: const Text('Resend Code')),
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

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Email Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
