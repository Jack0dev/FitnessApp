import 'package:flutter/material.dart';
import 'config/firebase_config.dart';
import 'config/supabase_config.dart';
import 'services/sql_database_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'models/user_model.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services asynchronously to avoid blocking UI
  // Run initialization in parallel where possible
  final initFutures = <Future>[];
  
  // Initialize Firebase (for Authentication)
  // Mặc định: Kết nối với Firebase Production
  // Chỉ dùng Emulator khi có flag --dart-define=USE_EMULATOR=true
  const useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
  initFutures.add(
    FirebaseConfig.initialize(useEmulator: useEmulator).catchError((e) {
      print('⚠️ Firebase initialization error: $e');
    }),
  );
  
  // Initialize Supabase (for SQL Database) in parallel
  // Only initialize if Supabase is configured
  if (SupabaseConfig.isConfigured) {
    initFutures.add(
      SqlDatabaseService.initialize(
        supabaseUrl: SupabaseConfig.supabaseUrl,
        supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
      ).then((_) {
        print('✅ Connected to Supabase (PostgreSQL)');
      }).catchError((e) {
        print('⚠️ Supabase initialization failed: $e');
        print('⚠️ App will continue with Firebase Auth only');
      }),
    );
  } else {
    print('⚠️ Supabase not configured. Update lib/config/supabase_config.dart with your keys');
    print('⚠️ App will continue with Firebase Auth only');
  }
  
  // Wait for all initializations to complete (with timeout)
  await Future.wait(initFutures).timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      print('⚠️ Initialization timeout - continuing anyway');
      return <dynamic>[]; // Return empty list on timeout
    },
  );
  
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
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.phoneLogin: (context) => const PhoneLoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.editProfile: (context) {
          final userModel = ModalRoute.of(context)!.settings.arguments as UserModel;
          return EditProfileScreen(userModel: userModel);
        },
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
    );
  }
}
