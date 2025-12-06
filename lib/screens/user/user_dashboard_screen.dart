import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/user/user_preference_service.dart';
import '../../models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'user_courses_screen.dart';
import 'user_schedule_screen.dart';
import 'user_attendance_screen.dart';
import 'user_progress_screen.dart';
import 'user_body_metrics_screen.dart';
import 'user_meal_plan_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final _authService = AuthService();
  final _dataService = DataService();
  final _userPreferenceService = UserPreferenceService();
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      } else {
        setState(() {
          _userModel = UserModel(
            uid: user.id,
            email: user.email,
            displayName: user.userMetadata?['display_name'] as String?,
            photoURL: user.userMetadata?['photo_url'] as String?,
          );
        });
      }
    } catch (e) {
      setState(() {
        _userModel = UserModel(
            uid: user.id,
            email: user.email,
            displayName: user.userMetadata?['display_name'] as String?,
            photoURL: user.userMetadata?['photo_url'] as String?,
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: DesignTokens.gradientAccent,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            CustomText(
              text: context.translate('dashboard'),
              variant: TextVariant.headlineMedium,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.profile);
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card with Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: DesignTokens.gradientAccentExtended,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.accent.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            left: -30,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.white.withOpacity(0.25),
                                    backgroundImage: _userModel?.photoURL != null
                                        ? NetworkImage(_userModel!.photoURL!)
                                        : null,
                                    child: _userModel?.photoURL == null
                                        ? const Icon(Icons.person, size: 36, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  CustomText(
                                    text: '${context.translate('hello')}, ${_userModel?.displayName ?? context.translate('user')}! 👋',
                                    variant: TextVariant.displaySmall,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  const SizedBox(height: 8),
                                  CustomText(
                                    text: context.translate('ready_for_workout'),
                                    variant: TextVariant.bodyLarge,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Today's Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: DesignTokens.gradientInfo,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                        CustomText(
                          text: context.translate('today_progress'),
                          variant: TextVariant.headlineMedium,
                          color: DesignTokens.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          label: Text(
                            context.translate('view_all'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ProgressCard(
                            title: context.translate('workouts'),
                            value: '0',
                            icon: Icons.fitness_center,
                            color: DesignTokens.info,
                            gradient: DesignTokens.gradientInfo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProgressCard(
                            title: context.translate('calories'),
                            value: '0',
                            icon: Icons.local_fire_department,
                            color: DesignTokens.warning,
                            gradient: DesignTokens.gradientWarning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ProgressCard(
                            title: context.translate('steps'),
                            value: '0',
                            icon: Icons.directions_walk,
                            color: DesignTokens.success,
                            gradient: DesignTokens.gradientSuccess,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProgressCard(
                            title: context.translate('minutes'),
                            value: '0',
                            icon: Icons.timer,
                            color: DesignTokens.accent,
                            gradient: DesignTokens.gradientPurple,
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
                            gradient: const LinearGradient(
                              colors: DesignTokens.gradientPurple,
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
                          text: context.translate('quick_actions'),
                          variant: TextVariant.headlineMedium,
                          color: DesignTokens.textDark,
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
                      childAspectRatio: 1.4,
                      children: [
                        _ActionCard(
                          title: context.translate('courses'),
                          icon: Icons.school_rounded,
                          color: DesignTokens.info,
                          gradient: DesignTokens.gradientInfo,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserCoursesScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('body_metrics'),
                          icon: Icons.monitor_weight_rounded,
                          color: DesignTokens.secondary,
                          gradient: DesignTokens.gradientTeal,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserBodyMetricsScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('schedule'),
                          icon: Icons.calendar_today_rounded,
                          color: DesignTokens.accent,
                          gradient: DesignTokens.gradientIndigo,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserScheduleScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('progress'),
                          icon: Icons.trending_up_rounded,
                          color: DesignTokens.warning,
                          gradient: DesignTokens.gradientWarning,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserProgressScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('attendance'),
                          icon: Icons.check_circle_rounded,
                          color: DesignTokens.success,
                          gradient: DesignTokens.gradientSuccess,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserAttendanceScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: context.translate('meal_plan'),
                          icon: Icons.restaurant_menu_rounded,
                          color: DesignTokens.accent,
                          gradient: DesignTokens.gradientPurple,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserMealPlanScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Sign Out Button
                    CustomButton(
                      label: context.translate('sign_out'),
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

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.gradient = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Decorative gradient background
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient.isNotEmpty
                      ? gradient.map((c) => c.withOpacity(0.1)).toList()
                      : [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
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
                    gradient: gradient.isNotEmpty
                        ? LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: gradient.isEmpty ? color.withOpacity(0.15) : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: gradient.isNotEmpty
                        ? [
                            BoxShadow(
                              color: gradient.first.withOpacity(0.3),
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
    
    // Default gradients based on color using DesignTokens
    if (widget.color == DesignTokens.info) {
      return DesignTokens.gradientInfo;
    } else if (widget.color == DesignTokens.accent) {
      return DesignTokens.gradientAccent;
    } else if (widget.color == DesignTokens.secondary) {
      return DesignTokens.gradientTeal;
    } else if (widget.color == DesignTokens.warning) {
      return DesignTokens.gradientWarning;
    } else if (widget.color == DesignTokens.success) {
      return DesignTokens.gradientSuccess;
    } else {
      return [widget.color, widget.color.withOpacity(0.7)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient();
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
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
      },
    );
  }
}

