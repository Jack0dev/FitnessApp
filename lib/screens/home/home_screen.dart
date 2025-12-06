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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      // Try to load from Supabase database
      final userModel = await _dataService.getUserData(user.id);
      
      if (userModel != null) {
        setState(() {
          _userModel = userModel;
          _isLoading = false;
        });
        // Redirect to appropriate dashboard based on role
        // RoleService will check if profile is completed
        if (mounted) {
          final route = RoleService.getDashboardRoute(userModel);
          Navigator.of(context).pushReplacementNamed(route);
        }
      } else {
        // If no database data, use Auth data (default to user role)
        setState(() {
          _userModel = UserModel(
            uid: user.id,
            email: user.email,
            displayName: user.userMetadata?['display_name'] as String?,
            photoURL: user.userMetadata?['photo_url'] as String?,
          );
          _isLoading = false;
        });
        // Redirect to user dashboard
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.userDashboard);
        }
      }
    } catch (e) {
      // Fallback to Auth data
      setState(() {
          _userModel = UserModel(
            uid: user.id,
            email: user.email,
            displayName: user.userMetadata?['display_name'] as String?,
            photoURL: user.userMetadata?['photo_url'] as String?,
          );
        _isLoading = false;
      });
      // Redirect to user dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.userDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Home',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const CustomText(
                    text: 'Chào mừng đến với Ứng dụng Fitness',
                    variant: TextVariant.displaySmall,
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 16),
                  if (user != null && _userModel != null) ...[
                    CustomText(
                      text: 'Hello, ${_userModel!.displayName ?? user.userMetadata?['display_name'] ?? "User"}!',
                      variant: TextVariant.headlineSmall,
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      text: 'Email: ${_userModel!.email ?? user.email ?? "N/A"}',
                      variant: TextVariant.bodyLarge,
                      color: DesignTokens.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    CustomCard(
                      variant: CardVariant.gymFresh,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: DesignTokens.success,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          const CustomText(
                            text: 'Database Connected!',
                            variant: TextVariant.titleLarge,
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            text: 'Your data is being synced',
                            variant: TextVariant.bodySmall,
                            color: DesignTokens.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  CustomButton(
                    label: 'Sign Out',
                    icon: Icons.logout,
                    onPressed: () async {
                      try {
                        // Clear all saved data (credentials + tokens) when signing out
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
                    size: ButtonSize.medium,
                    backgroundColor: DesignTokens.error,
                  ),
                ],
              ),
            ),
    );
  }
}

