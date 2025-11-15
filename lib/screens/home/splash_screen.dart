import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_preference_service.dart';
import '../../services/role_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _dataService = DataService();
  final _authService = AuthService();
  final _userPreferenceService = UserPreferenceService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Reduced delay for faster app startup
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    // Check if user is already logged in (session still valid)
    // Note: After closing app, user should be logged out, so this check will usually fail
    // and redirect to LoginScreen where fingerprint authentication will be triggered
    final user = _authService.currentUser;
    
    if (user != null) {
      // User is still logged in (session still valid)
      print('✅ [SplashScreen] User still logged in, redirecting to dashboard...');
      
      // Load user data to get role
      try {
        final userModel = await _dataService.getUserData(user.id);
        if (userModel != null) {
          // Redirect based on role
          final route = RoleService.getDashboardRoute(userModel);
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        } else {
          // If no user data, go to home (will redirect from there)
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          }
        }
      } catch (e) {
        // On error, go to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      }
    } else {
      // No user session - redirect to LoginScreen
      // LoginScreen will auto-trigger fingerprint authentication if enabled
      print('⚠️ [SplashScreen] No user session, redirecting to LoginScreen for fingerprint authentication...');
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Fitness App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}


