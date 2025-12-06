import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/course/course_service.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/widgets.dart';
import '../../core/localization/app_localizations.dart';
import 'pt_courses_management_screen.dart';
import 'pt_students_screen.dart';
import 'pt_qr_attendance_screen.dart';

class PTDashboardScreen extends StatefulWidget {
  const PTDashboardScreen({super.key});

  @override
  State<PTDashboardScreen> createState() => _PTDashboardScreenState();
}

class _PTDashboardScreenState extends State<PTDashboardScreen> {
  final _authService = AuthService();
  final _dataService = DataService();
  UserModel? _userModel;
  bool _isLoading = true;
  int _totalClients = 0;
  int _activeSessions = 0;
  int _totalCourses = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userModel = await _dataService.getUserData(user.id);
      if (userModel != null) {
        setState(() {
          _userModel = userModel;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load courses by instructor
      final courseService = CourseService();
      final courses = await courseService.getCoursesByInstructor(user.id);
      
      // Count total enrollments (clients) across all courses
      int totalClients = 0;
      int activeSessions = 0;
      
      for (final course in courses) {
        final enrollments = await courseService.getCourseEnrollments(course.id);
        final paidEnrollments = enrollments.where((e) => e.paymentStatus == PaymentStatus.paid).toList();
        totalClients += paidEnrollments.length;
        
        // Count active courses (with paid students)
        if (paidEnrollments.isNotEmpty && course.status == CourseStatus.active) {
          activeSessions++;
        }
      }

      setState(() {
        _totalClients = totalClients;
        _activeSessions = activeSessions;
        _totalCourses = courses.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: DesignTokens.surface,
        title: CustomText(
          text: context.translate('pt_dashboard'),
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: DesignTokens.textPrimary),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
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
                    // Welcome Card with Gradient
                    Container(
                      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [DesignTokens.primary, DesignTokens.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                        boxShadow: DesignTokens.shadowLG,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(DesignTokens.spacingLG),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: _userModel?.photoURL != null
                                    ? NetworkImage(_userModel!.photoURL!)
                                    : null,
                                child: _userModel?.photoURL == null
                                    ? const Icon(Icons.fitness_center, size: 32, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: '${context.translate('welcome')}, ${_userModel?.displayName ?? context.translate('profile')}!',
                                    variant: TextVariant.headlineMedium,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          UserRole.pt.icon,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CustomText(
                                        text: UserRole.pt.displayName,
                                        variant: TextVariant.bodyMedium,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Statistics
                    CustomText(
                      text: context.translate('statistics'),
                      variant: TextVariant.headlineMedium,
                      color: DesignTokens.textPrimary,
                    ),
                    const SizedBox(height: DesignTokens.spacingMD),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: context.translate('total_clients'),
                            value: _totalClients.toString(),
                            icon: Icons.people,
                            color: DesignTokens.info,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingSM),
                        Expanded(
                          child: _StatCard(
                            title: context.translate('active_sessions'),
                            value: _activeSessions.toString(),
                            icon: Icons.event,
                            color: DesignTokens.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingSM),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: context.translate('courses'),
                            value: '$_totalCourses',
                            icon: Icons.school,
                            color: DesignTokens.warning,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingSM),
                        Expanded(
                          child: _StatCard(
                            title: context.translate('active'),
                            value: '$_activeSessions',
                            icon: Icons.check_circle,
                            color: DesignTokens.accent,
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
                              colors: [DesignTokens.primary, DesignTokens.secondary],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingSM),
                        CustomText(
                          text: context.translate('quick_actions'),
                          variant: TextVariant.headlineMedium,
                          color: DesignTokens.textPrimary,
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
                          title: context.translate('my_courses'),
                          icon: Icons.school_rounded,
                          color: DesignTokens.info,
                          gradient: [DesignTokens.info, DesignTokens.accent],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PTCoursesManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('my_students'),
                          icon: Icons.people_rounded,
                          color: DesignTokens.success,
                          gradient: [DesignTokens.primary, DesignTokens.secondary],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PTStudentsScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('attendance'),
                          icon: Icons.qr_code_scanner_rounded,
                          color: DesignTokens.warning,
                          gradient: [DesignTokens.warning, DesignTokens.accent],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PTAttendanceScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('chat'),
                          icon: Icons.chat_rounded,
                          color: DesignTokens.secondary,
                          gradient: [DesignTokens.secondary, DesignTokens.accent],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PTStudentsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      variant: CardVariant.white,
      padding: const EdgeInsets.all(DesignTokens.spacingLG),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: DesignTokens.spacingMD),
          CustomText(
            text: value,
            variant: TextVariant.displaySmall,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          CustomText(
            text: title,
            variant: TextVariant.bodySmall,
            color: DesignTokens.textSecondary,
            fontWeight: FontWeight.w500,
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
            onTapDown: (_) {
              _controller.forward();
            },
            onTapUp: (_) {
              _controller.reverse();
            },
            onTapCancel: () {
              _controller.reverse();
            },
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
                      borderRadius: BorderRadius.circular(16),
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
                      variant: TextVariant.bodyMedium,
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

