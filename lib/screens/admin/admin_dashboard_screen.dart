import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/user/user_preference_service.dart';
import '../../services/user/role_service.dart';
import '../../models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import 'admin_pts_management_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _dataService = DataService();
  final _userPreferenceService = UserPreferenceService();
  UserModel? _userModel;
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalPTs = 0;
  int _totalAdmins = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
      return;
    }

    try {
      final userModel = await _dataService.getUserData(user.id);
      if (userModel != null) {
        // Kiểm tra role - chỉ admin mới được truy cập
        if (userModel.role != UserRole.admin) {
          if (mounted) {
            final correctRoute = RoleService.getDashboardRoute(userModel);
            Navigator.of(context).pushReplacementNamed(correctRoute);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn không có quyền truy cập trang Admin'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        setState(() {
          _userModel = userModel;
        });
      } else {
        // Không có userModel, redirect về login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  Future<void> _loadStatistics() async {
    // TODO: Load statistics from database
    // For now, using mock data
    setState(() {
      _totalUsers = 150;
      _totalPTs = 12;
      _totalAdmins = 3;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadStatistics();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () async {
                await _loadStatistics();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card with Admin Theme
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade600,
                            Colors.red.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: _userModel?.photoURL != null
                                    ? NetworkImage(_userModel!.photoURL!)
                                    : null,
                                child: _userModel?.photoURL == null
                                    ? const Icon(
                                        Icons.admin_panel_settings,
                                        size: 32,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: 'Welcome, ${_userModel?.displayName ?? "Admin"}!',
                                    variant: TextVariant.headlineMedium,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          UserRole.admin.icon,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        CustomText(
                                          text: UserRole.admin.displayName,
                                          variant: TextVariant.bodyMedium,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Statistics Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade600, Colors.blue.shade400],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomText(
                          text: 'System Statistics',
                          variant: TextVariant.headlineMedium,
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Users',
                            value: _totalUsers.toString(),
                            icon: Icons.people,
                            color: Colors.blue,
                            gradient: [Colors.blue.shade600, Colors.blue.shade400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Personal Trainers',
                            value: _totalPTs.toString(),
                            icon: Icons.fitness_center,
                            color: Colors.orange,
                            gradient: [Colors.orange.shade600, Colors.orange.shade400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Admins',
                            value: _totalAdmins.toString(),
                            icon: Icons.admin_panel_settings,
                            color: Colors.red,
                            gradient: [Colors.red.shade600, Colors.red.shade400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Active Sessions',
                            value: '45',
                            icon: Icons.event,
                            color: Colors.green,
                            gradient: [Colors.green.shade600, Colors.green.shade400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple.shade600, Colors.purple.shade400],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomText(
                          text: 'Quick Actions',
                          variant: TextVariant.headlineMedium,
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _ActionCard(
                          title: 'Manage Courses',
                          icon: Icons.school_rounded,
                          color: Colors.blue,
                          gradient: [Colors.blue.shade600, Colors.blue.shade400],
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.adminCourses);
                          },
                        ),
                        _ActionCard(
                          title: 'Manage Users',
                          icon: Icons.people_rounded,
                          color: Colors.green,
                          gradient: [Colors.green.shade600, Colors.green.shade400],
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.adminUsers);
                          },
                        ),
                        _ActionCard(
                          title: 'Manage PTs',
                          icon: Icons.fitness_center_rounded,
                          color: Colors.orange,
                          gradient: [Colors.orange.shade600, Colors.orange.shade400],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AdminPTsManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: 'System Settings',
                          icon: Icons.settings_rounded,
                          color: Colors.grey,
                          gradient: [Colors.grey.shade600, Colors.grey.shade400],
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.settings);
                          },
                        ),
                        _ActionCard(
                          title: 'Reports',
                          icon: Icons.analytics_rounded,
                          color: Colors.purple,
                          gradient: [Colors.purple.shade600, Colors.purple.shade400],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AdminReportsScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: 'Database',
                          icon: Icons.storage_rounded,
                          color: Colors.teal,
                          gradient: [Colors.teal.shade600, Colors.teal.shade400],
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quản lý cơ sở dữ liệu - Sắp ra mắt')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Sign Out Button
                    CustomButton(
                      label: 'Sign Out',
                      icon: Icons.logout_rounded,
                      onPressed: () async {
                        try {
                          await _userPreferenceService.clearAllSavedData();
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.of(context)
                                .pushReplacementNamed(AppRoutes.login);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: CustomText(
                                  text: e.toString(),
                                  variant: TextVariant.bodyMedium,
                                  color: Colors.white,
                                ),
                                backgroundColor: DesignTokens.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      variant: ButtonVariant.primary,
                      size: ButtonSize.large,
                      isFullWidth: true,
                      backgroundColor: DesignTokens.error,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color>? gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (gradient != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient!.map((c) => c.withOpacity(0.1)).toList(),
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(40),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient != null
                        ? LinearGradient(
                            colors: gradient!,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: gradient == null ? color.withOpacity(0.15) : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: gradient != null
                        ? [
                            BoxShadow(
                              color: gradient!.first.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 18),
                CustomText(
                  text: value,
                  variant: TextVariant.displayMedium,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 6),
                CustomText(
                  text: title,
                  variant: TextVariant.bodySmall,
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Color>? gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _getGradient() {
    if (widget.gradient != null) return widget.gradient!;
    return [widget.color, widget.color.withOpacity(0.7)];
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient();
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: CustomText(
                      text: widget.title,
                      variant: TextVariant.bodySmall,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


