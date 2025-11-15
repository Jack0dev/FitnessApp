import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/sql_database_service.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/user_preference_service.dart';
import 'services/role_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (required for all services)
  if (SupabaseConfig.isConfigured) {
    try {
      await SqlDatabaseService.initialize(
        supabaseUrl: SupabaseConfig.supabaseUrl,
        supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
      );
      print('✅ Connected to Supabase (PostgreSQL)');
    } catch (e) {
      print('⚠️ Supabase initialization failed: $e');
      print('⚠️ App may not work correctly without Supabase');
    }
  } else {
    print('⚠️ Supabase not configured. Update lib/config/supabase_config.dart with your keys');
    print('⚠️ App will not work without Supabase');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Use builder to wrap with AuthGate
      builder: (context, child) {
        return AuthGate(child: child ?? const SizedBox());
      },
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
    );
  }
}

/// AuthGate widget to listen to auth state changes globally
/// This ensures the app responds to OAuth callbacks even when not on LoginScreen
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _authService = AuthService();
  final _dataService = DataService();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToAuthChanges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 [AuthGate] App lifecycle changed: $state');
    
    // Sign out when app goes to background or is closed
    // This ensures user must authenticate again (via fingerprint) when reopening app
    // Note: We DON'T clear refresh_token or credentials, so fingerprint login can still work
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached) {
      print('🔄 [AuthGate] App going to background/closed, signing out...');
      _signOutOnAppClose();
    }
  }

  /// Sign out from Supabase when app is closed or backgrounded
  /// This ensures user must authenticate again (via fingerprint) when reopening app
  /// Note: We DON'T clear refresh_token or credentials, so fingerprint login can still work
  /// User will need to authenticate with fingerprint, then auto-login with saved credentials
  Future<void> _signOutOnAppClose() async {
    try {
      // Only sign out if user is currently logged in
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('🔄 [AuthGate] Signing out user: ${currentUser.email}');
        
        // Verify credentials are still saved before signing out
        final userPreferenceService = UserPreferenceService();
        final credentialsBefore = await userPreferenceService.getLastLoggedInCredentials();
        print('🔄 [AuthGate] Credentials before sign out: email=${credentialsBefore['email'] != null ? "exists" : "null"}, provider=${credentialsBefore['provider']}');
        
        await _authService.signOut();
        print('✅ [AuthGate] Successfully signed out from Supabase');
        
        // Verify credentials are still saved after signing out
        final credentialsAfter = await userPreferenceService.getLastLoggedInCredentials();
        print('✅ [AuthGate] Credentials after sign out: email=${credentialsAfter['email'] != null ? "exists" : "null"}, provider=${credentialsAfter['provider']}');
        
        if (credentialsAfter['email'] == null) {
          print('⚠️ [AuthGate] WARNING: Credentials were cleared after sign out!');
        } else {
          print('✅ [AuthGate] Session cleared, but refresh_token and credentials are kept');
          print('✅ [AuthGate] Next time user opens app, fingerprint authentication will be required');
        }
      } else {
        print('ℹ️ [AuthGate] No user logged in, no need to sign out');
      }
    } catch (e) {
      print('❌ [AuthGate] Error signing out: $e');
    }
  }

  void _listenToAuthChanges() {
    // Listen to auth state changes globally
    // This will catch OAuth callbacks even when app is reopened via deep link
    _authSubscription = _authService.authStateChanges.listen(
      (AuthState state) async {
        if (state.event == AuthChangeEvent.signedIn && state.session != null) {
          final user = state.session!.user;
          
          // Handle new user registration (save to database)
          if (mounted) {
            try {
              final userModel = await _dataService.getUserData(user.id);
              final isNewUser = userModel == null;

              if (isNewUser) {
                // Save user data for new Google/Phone users
                await _dataService.saveUserData(
                  userId: user.id,
                  userData: {
                    'email': user.email,
                    'displayName': user.userMetadata?['display_name'] as String?,
                    'photoURL': user.userMetadata?['photo_url'] as String?,
                    'phoneNumber': user.phone,
                    'provider': user.appMetadata?['provider'] as String? ?? 'email',
                    'role': 'user',
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  },
                );
              }

              // Navigate to dashboard if user is on login/register screen
              if (mounted) {
                final currentRoute = ModalRoute.of(context)?.settings.name;
                
                // Only navigate if currently on login/register/splash screens
                if (currentRoute == AppRoutes.login || 
                    currentRoute == AppRoutes.register ||
                    currentRoute == AppRoutes.splash) {
                  final updatedUserModel = await _dataService.getUserData(user.id);
                  final route = updatedUserModel != null 
                      ? RoleService.getDashboardRoute(updatedUserModel)
                      : AppRoutes.userDashboard;
                  
                  // Use navigator to push replacement
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      route,
                      (route) => false, // Remove all previous routes
                    );
                  }
                }
              }
            } catch (e) {
              print('Error in AuthGate: $e');
            }
          }
        }
      },
      onError: (error) {
        print('AuthGate error: $error');
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
