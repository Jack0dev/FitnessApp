import 'package:flutter/material.dart';
import '../../screens/home/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/phone_login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/user/user_dashboard_screen.dart';
import '../../screens/pt/pt_dashboard_screen.dart';
import '../../screens/admin/courses_management_screen.dart';
import '../../screens/admin/users_management_screen.dart';
import '../../models/user_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String phoneLogin = '/phone-login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  
  // Dashboard routes
  static const String adminDashboard = '/admin-dashboard';
  static const String userDashboard = '/user-dashboard';
  static const String ptDashboard = '/pt-dashboard';
  
  // Admin routes
  static const String adminCourses = '/admin/courses';
  static const String adminUsers = '/admin/users';
  static const String adminPTs = '/admin/pts';
  
  // User routes
  static const String coursesList = '/courses';
  static const String courseDetail = '/course-detail';
  static const String myCourses = '/my-courses';
  
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
      // Dashboard routes
      adminDashboard: (context) => const AdminDashboardScreen(),
      userDashboard: (context) => const UserDashboardScreen(),
      ptDashboard: (context) => const PTDashboardScreen(),
      // Admin routes
      adminCourses: (context) => const CoursesManagementScreen(),
      adminUsers: (context) => const UsersManagementScreen(),
    };
  }
}

