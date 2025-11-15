import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth Service using Supabase Auth
class AuthService {
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw Exception('Supabase not initialized');
    }
    return Supabase.instance.client;
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Refresh session using refresh token
  /// Returns true if session was refreshed successfully
  Future<bool> refreshSession() async {
    try {
      final session = await _supabase.auth.refreshSession();
      return session.session != null;
    } catch (e) {
      print('Error refreshing session: $e');
      return false;
    }
  }

  /// Refresh session using provided refresh token
  /// Returns AuthResponse if successful
  Future<AuthResponse?> refreshSessionWithToken(String refreshToken) async {
    try {
      final response = await _supabase.auth.setSession(refreshToken);
      return response;
    } catch (e) {
      print('Error refreshing session with token: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to sign in. Please try again.';
    }
  }

  /// Register with email and password
  Future<AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Trim and validate email format
      final trimmedEmail = email.trim().toLowerCase();
      
      // Basic email validation
      if (trimmedEmail.isEmpty) {
        throw 'Email is required';
      }
      
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(trimmedEmail)) {
        throw 'Please enter a valid email address';
      }
      
      final response = await _supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // If it's already a string error message, return it
      if (e is String) {
        throw e;
      }
      throw 'Failed to register. Please try again.';
    }
  }

  /// Sign out
  /// Note: This only signs out from Supabase. 
  /// Call UserPreferenceService.clearAllSavedData() separately to clear saved tokens/credentials.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Update user profile
  Future<UserResponse> updateProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? data,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (displayName != null) {
        updateData['display_name'] = displayName;
      }
      if (photoURL != null) {
        updateData['photo_url'] = photoURL;
      }
      if (data != null) {
        updateData.addAll(data);
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updateData.isNotEmpty ? updateData : null),
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  /// Sign in with Google
  /// 
  /// Initiates OAuth flow with Google provider.
  /// Opens browser for user to sign in with Google.
  /// 
  /// Returns true if OAuth flow was initiated successfully.
  /// 
  /// Throws:
  /// - String error message if OAuth flow fails or is cancelled
  /// - AuthException for authentication errors
  Future<bool> signInWithGoogle() async {
    try {
      // Initiate OAuth flow with Google provider
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.fitness_app://login-callback',
        // Optional: Specify OAuth scopes (default includes email and profile)
        // scopes: 'email profile openid',
        // Optional: Additional query parameters
        // queryParams: {},
      );
      
      // signInWithOAuth returns immediately after opening browser
      // The actual authentication happens asynchronously in the browser
      // The app should listen to authStateChanges stream to detect completion
      return true;
    } on AuthException catch (e) {
      // Handle specific OAuth errors
      final message = e.message.toLowerCase();
      
      // OAuth state parameter missing or callback errors
      if (message.contains('state') || 
          message.contains('bad_oauth_callback') ||
          message.contains('oauth callback')) {
        throw 'OAuth flow was interrupted. Please try again and do not close the browser during sign in.';
      }
      
      // Redirect URI mismatch
      if (message.contains('redirect_uri') || message.contains('redirect uri')) {
        throw 'OAuth configuration error. Please contact support.';
      }
      
      // Use general auth exception handler for other errors
      throw _handleAuthException(e);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      
      // User cancelled the OAuth flow
      if (errorString.contains('cancelled') || errorString.contains('canceled')) {
        throw 'Google sign in was cancelled';
      }
      
      // OAuth flow interruption
      if (errorString.contains('state') || 
          errorString.contains('oauth') || 
          errorString.contains('bad_oauth_callback')) {
        throw 'OAuth flow was interrupted. Please try again and do not close the browser during sign in.';
      }
      
      // Generic error
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  /// Sign in with phone number (OTP)
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send OTP. Please try again.';
    }
  }

  /// Verify phone OTP
  Future<AuthResponse> verifyPhoneOTP({
    required String phoneNumber,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to verify OTP. Please try again.';
    }
  }

  /// Handle AuthException and convert to user-friendly error message
  String _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    
    // Email already registered
    if (message.contains('already registered') || message.contains('user already registered')) {
      return 'Email already registered. Please sign in instead.';
    }
    
    // Invalid email or password
    if (message.contains('invalid login') || message.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    
    // Email not confirmed
    if (message.contains('email not confirmed') || message.contains('email_not_confirmed')) {
      return 'Please verify your email before signing in.';
    }
    
    // Password too weak
    if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
    // Too many requests
    if (message.contains('too many requests') || message.contains('rate limit')) {
      return 'Too many requests. Please try again later.';
    }
    
    // Invalid OTP
    if (message.contains('otp') && (message.contains('invalid') || message.contains('expired'))) {
      return 'Invalid or expired OTP. Please request a new code.';
    }
    
    // Generic error - return original message if available
    return e.message.isNotEmpty ? e.message : 'Authentication failed. Please try again.';
  }
}
