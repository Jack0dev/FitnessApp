import '../models/user_model.dart';
import '../core/routes/app_routes.dart';

/// Service to manage user roles and permissions
class RoleService {
  /// Check if user has admin role
  static bool isAdmin(UserModel? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user has PT role
  static bool isPT(UserModel? user) {
    return user?.role == UserRole.pt;
  }

  /// Check if user is regular user
  static bool isUser(UserModel? user) {
    return user?.role == UserRole.user;
  }

  /// Get dashboard route based on user role
  /// If profile is not completed, redirects to onboarding
  static String getDashboardRoute(UserModel? user) {
    if (user == null) return AppRoutes.login;
    
    // Check if profile is completed (only for regular users)
    // Admin and PT can skip onboarding
    if (user.role == UserRole.user && !user.isProfileCompleted) {
      return AppRoutes.onboarding;
    }
    
    switch (user.role) {
      case UserRole.admin:
        return AppRoutes.adminDashboard;
      case UserRole.pt:
        return AppRoutes.ptDashboard;
      case UserRole.user:
        return AppRoutes.userDashboard;
    }
  }

  /// Check if user can access admin features
  static bool canAccessAdmin(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can manage other users
  static bool canManageUsers(UserModel? user) {
    return isAdmin(user) || isPT(user);
  }

  /// Check if user can view all users
  static bool canViewAllUsers(UserModel? user) {
    return isAdmin(user) || isPT(user);
  }
}





