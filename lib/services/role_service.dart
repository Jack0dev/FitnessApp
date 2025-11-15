import '../models/user_model.dart';
import '../models/user_role.dart';

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
  static String getDashboardRoute(UserModel? user) {
    if (user == null) return '/login';
    
    switch (user.role) {
      case UserRole.admin:
        return '/admin-dashboard';
      case UserRole.pt:
        return '/pt-dashboard';
      case UserRole.user:
      default:
        return '/user-dashboard';
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


