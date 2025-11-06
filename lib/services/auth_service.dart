import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.loginError;
    }
  }

  /// Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.signupError;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      // Also sign out from Google if signed in with Google
      await signOutFromGoogle();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
      await currentUser?.reload();
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  /// Send OTP to phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification completed (Android only)
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            onError(e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          // Check for billing error specifically
          String errorMessage = _handleAuthException(e);
          
          // If error message contains billing info, provide more details
          if (e.code == 'billing-not-enabled' || 
              e.message?.contains('BILLING_NOT_ENABLED') == true ||
              e.message?.contains('billing') == true) {
            // Check if using test number
            final isTestNumber = phoneNumber.contains('650555');
            if (isTestNumber) {
              errorMessage = 'Test phone number requires Phone Auth to be enabled in Firebase Console.\n\n'
                  'Steps:\n'
                  '1. Go to Firebase Console\n'
                  '2. Authentication > Sign-in method\n'
                  '3. Enable "Phone" provider\n'
                  '4. Use verification code: 123456 for built-in test numbers\n\n'
                  'Note: Test numbers don\'t require billing but need Phone provider enabled.';
            } else {
              errorMessage = 'Billing is not enabled for your Firebase project.\n\n'
                  'To enable Phone Authentication:\n'
                  '1. Go to Firebase Console\n'
                  '2. Authentication > Sign-in method > Enable "Phone"\n'
                  '3. For real SMS, enable Billing Account in Project Settings\n'
                  '4. For free testing, use test phone numbers (code: 123456)\n\n'
                  'Real phone numbers require billing to send SMS codes.';
            }
          }
          
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          // SMS code was sent successfully
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // SMS auto-retrieval timed out (common on emulators or devices without SIM)
          // Still allow manual code entry by calling onCodeSent with the verificationId
          // This ensures the user can still enter the code manually
          onCodeSent(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('Failed to send verification code: ${e.toString()}');
    }
  }

  /// Sign in with phone number and OTP
  Future<UserCredential?> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to verify code. Please try again.';
    }
  }

  /// Resend OTP code
  Future<void> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        throw 'Sign in cancelled';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        throw 'Sign in cancelled';
      }
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  /// Sign out from Google (should be called with signOut)
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore Google sign out errors
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'session-expired':
        return 'The SMS code has expired. Please request a new code.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'billing-not-enabled':
      case 'BILLING_NOT_ENABLED':
        return 'Billing is not enabled for your Firebase project. Please enable billing in Firebase Console to use Phone Authentication.';
      case 'second-factor-required':
      case '17089':
        return 'This phone number is already enrolled with Multi-Factor Authentication. Please use a different phone number.';
      case 'network-request-failed':
        return AppConstants.networkError;
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please enable it in Firebase Console.';
      default:
        return e.message ?? AppConstants.unknownError;
    }
  }
}

