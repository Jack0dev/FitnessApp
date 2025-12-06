import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/common/common_services.dart';
import 'services/auth/auth_services.dart';
import 'services/user/user_services.dart';
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
      title: 'Ứng dụng Fitness',
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
                    'provider': (user.appMetadata['provider'] as String?) ?? 'email',
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
                      : AppRoutes.onboarding;
                  
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