import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/user_preference_service.dart';
import '../../services/role_service.dart';
import '../../models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/loading_widget.dart';

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
        title: const Text('Home'),
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
                  const Text(
                    'Welcome to Fitness App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user != null && _userModel != null) ...[
                    Text(
                      'Hello, ${_userModel!.displayName ?? user.userMetadata?['display_name'] ?? "User"}!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${_userModel!.email ?? user.email ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Database Connected!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your data is being synced',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  ElevatedButton(
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
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }
}

