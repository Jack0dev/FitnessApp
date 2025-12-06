import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/user/role_service.dart';
import '../../models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/loading_widget.dart';

/// Route Guard để bảo vệ routes dựa trên role
/// 
/// Sử dụng:
/// ```dart
/// RouteGuard.protectedRoute(
///   requiredRole: UserRole.admin,
///   child: const AdminDashboardScreen(),
/// )
/// ```
class RouteGuard {
  /// Wrapper widget để bảo vệ route
  /// 
  /// [requiredRole]: Role cụ thể được yêu cầu
  /// [allowedRoles]: Danh sách roles được phép (nếu không dùng requiredRole)
  /// [child]: Widget cần được bảo vệ
  static Widget protectedRoute({
    required Widget child,
    UserRole? requiredRole,
    List<UserRole>? allowedRoles,
  }) {
    return _ProtectedRouteWidget(
      child: child,
      requiredRole: requiredRole,
      allowedRoles: allowedRoles,
    );
  }
}

class _ProtectedRouteWidget extends StatefulWidget {
  final Widget child;
  final UserRole? requiredRole;
  final List<UserRole>? allowedRoles;

  const _ProtectedRouteWidget({
    required this.child,
    this.requiredRole,
    this.allowedRoles,
  });

  @override
  State<_ProtectedRouteWidget> createState() => _ProtectedRouteWidgetState();
}

class _ProtectedRouteWidgetState extends State<_ProtectedRouteWidget> {
  final _authService = AuthService();
  final _dataService = DataService();
  bool _isChecking = true;
  bool _hasAccess = false;
  String? _redirectRoute;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    // Kiểm tra user đã đăng nhập chưa
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasAccess = false;
          _redirectRoute = AppRoutes.login;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        });
      }
      return;
    }

    // Lấy userModel từ database
    UserModel? userModel;
    try {
      userModel = await _dataService.getUserData(currentUser.id);
    } catch (e) {
      print('Error loading user data: $e');
    }

    // Nếu không có userModel, tạo default user với role 'user'
    if (userModel == null) {
      userModel = UserModel(
        uid: currentUser.id,
        email: currentUser.email,
        displayName: currentUser.userMetadata?['display_name'] as String?,
        photoURL: currentUser.userMetadata?['photo_url'] as String?,
        role: UserRole.user, // Default role
      );
    }

    // Kiểm tra role
    bool hasPermission = true;

    if (widget.requiredRole != null) {
      hasPermission = userModel.role == widget.requiredRole;
    } else if (widget.allowedRoles != null && widget.allowedRoles!.isNotEmpty) {
      hasPermission = widget.allowedRoles!.contains(userModel.role);
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
        _hasAccess = hasPermission;
        if (!hasPermission) {
          _redirectRoute = RoleService.getDashboardRoute(userModel);
        }
      });

      if (!hasPermission) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(_redirectRoute!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không có quyền truy cập trang này'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: LoadingWidget(),
      );
    }

    if (!_hasAccess) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}

