import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/user_preference_service.dart';
import '../../services/course_service.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/loading_widget.dart';
import 'pt_courses_management_screen.dart';

class PTDashboardScreen extends StatefulWidget {
  const PTDashboardScreen({super.key});

  @override
  State<PTDashboardScreen> createState() => _PTDashboardScreenState();
}

class _PTDashboardScreenState extends State<PTDashboardScreen> {
  final _authService = AuthService();
  final _dataService = DataService();
  final _userPreferenceService = UserPreferenceService();
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
      appBar: AppBar(
        title: const Text('PT Dashboard'),
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
          : RefreshIndicator(
              onRefresh: () async {
                await _loadStatistics();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: _userModel?.photoURL != null
                                  ? NetworkImage(_userModel!.photoURL!)
                                  : null,
                              child: _userModel?.photoURL == null
                                  ? const Icon(Icons.fitness_center, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${_userModel?.displayName ?? "Trainer"}!',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        UserRole.pt.icon,
                                        size: 16,
                                        color: UserRole.pt.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        UserRole.pt.displayName,
                                        style: TextStyle(
                                          color: UserRole.pt.color,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Clients',
                            value: _totalClients.toString(),
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Active Sessions',
                            value: _activeSessions.toString(),
                            icon: Icons.event,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Courses',
                            value: '$_totalCourses',
                            icon: Icons.school,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Active Courses',
                            value: '$_activeSessions',
                            icon: Icons.check_circle,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _ActionCard(
                          title: 'My Courses',
                          icon: Icons.school,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PTCoursesManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: 'My Clients',
                          icon: Icons.people_outline,
                          color: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('My Clients - Coming soon')),
                            );
                          },
                        ),
                        _ActionCard(
                          title: 'Settings',
                          icon: Icons.settings,
                          color: Colors.grey,
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.settings);
                          },
                        ),
                        _ActionCard(
                          title: 'Profile',
                          icon: Icons.person,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.profile);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

