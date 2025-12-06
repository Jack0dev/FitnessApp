import 'package:flutter/material.dart';
import '../../screens/home/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/phone_login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/profile/create_post_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/user/user_dashboard_screen.dart';
import '../../screens/pt/pt_dashboard_screen.dart';
import '../../screens/admin/courses_management_screen.dart';
import '../../screens/admin/users_management_screen.dart';
import '../../models/user_model.dart';
import 'route_guard.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String phoneLogin = '/phone-login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String createPost = '/create-post';
  static const String onboarding = '/onboarding';
  
  // Dashboard routes
  static const String adminDashboard = '/admin-dashboard';
  static const String userDashboard = '/user-dashboard';
  static const String ptDashboard = '/pt-dashboard';
  
  // Admin routes
  static const String adminCourses = '/admin/courses';
  static const String adminUsers = '/admin/users';
  static const String adminPTs = '/admin/pts';
  
  // User routes
  static const String courseDetail = '/course-detail';
  
  // PT routes
  static const String ptStudents = '/pt/students';
  static const String ptSchedule = '/pt/schedule';
  static const String ptMaterials = '/pt/materials';

  /// Get all routes for the app
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      home: (context) => const HomeScreen(),
      login: (context) => const LoginScreen(),
      phoneLogin: (context) => const PhoneLoginScreen(),
      register: (context) => const RegisterScreen(),
      profile: (context) => const ProfileScreen(),
      editProfile: (context) {
        final userModel = ModalRoute.of(context)!.settings.arguments as UserModel;
        return EditProfileScreen(userModel: userModel);
      },
      settings: (context) => const SettingsScreen(),
      createPost: (context) => const CreatePostScreen(),
      onboarding: (context) => const OnboardingScreen(),
      
      // Dashboard routes - Protected by role
      adminDashboard: (context) => RouteGuard.protectedRoute(
        requiredRole: UserRole.admin,
        child: const AdminDashboardScreen(),
      ),
      userDashboard: (context) => RouteGuard.protectedRoute(
        requiredRole: UserRole.user,
        child: const UserDashboardScreen(),
      ),
      ptDashboard: (context) => RouteGuard.protectedRoute(
        requiredRole: UserRole.pt,
        child: const PTDashboardScreen(),
      ),
      
      // Admin routes - Protected by admin role
      adminCourses: (context) => RouteGuard.protectedRoute(
        requiredRole: UserRole.admin,
        child: const CoursesManagementScreen(),
      ),
      adminUsers: (context) => RouteGuard.protectedRoute(
        requiredRole: UserRole.admin,
        child: const UsersManagementScreen(),
      ),
    };
  }
}

