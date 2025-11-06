import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../models/user_model.dart';
import '../core/routes/app_routes.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _dataService = DataService();
  UserModel? _userModel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Add cache busting parameter to image URL to force reload
  String _getImageUrlWithCacheBust(String url) {
    if (url.contains('?')) {
      return '$url&t=${DateTime.now().millisecondsSinceEpoch}';
    } else {
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'No user logged in';
      });
      return;
    }

    try {
      // Reload Firebase Auth user to get latest profile data (including photoURL)
      await user.reload();
      final refreshedUser = _authService.currentUser;
      
      // Try to load from Supabase or Firestore (DataService handles fallback)
      final userModel = await _dataService.getUserData(refreshedUser?.uid ?? user.uid);
      
      // Merge data: prioritize Firebase Auth photoURL (most up-to-date)
      // but use database data for other fields
      if (userModel != null) {
        setState(() {
          _userModel = UserModel(
            uid: userModel.uid,
            email: userModel.email ?? refreshedUser?.email,
            displayName: userModel.displayName ?? refreshedUser?.displayName,
            // Prioritize Firebase Auth photoURL (updated immediately after upload)
            photoURL: refreshedUser?.photoURL ?? userModel.photoURL,
            phoneNumber: userModel.phoneNumber,
            createdAt: userModel.createdAt,
            updatedAt: userModel.updatedAt,
          );
          _isLoading = false;
        });
      } else {
        // If no database data, use Auth data
        setState(() {
          _userModel = UserModel(
            uid: refreshedUser?.uid ?? user.uid,
            email: refreshedUser?.email ?? user.email,
            displayName: refreshedUser?.displayName ?? user.displayName,
            photoURL: refreshedUser?.photoURL ?? user.photoURL,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to Auth data
        final currentUser = _authService.currentUser;
        _userModel = UserModel(
          uid: currentUser?.uid ?? user.uid,
          email: currentUser?.email ?? user.email,
          displayName: currentUser?.displayName ?? user.displayName,
          photoURL: currentUser?.photoURL ?? user.photoURL,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(child: Text('No user logged in')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const LoadingWidget(),
      );
    }

    if (_error != null && _userModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: ErrorDisplayWidget(
          message: _error!,
          onRetry: _loadUserData,
        ),
      );
    }

    final displayUser = _userModel ?? UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                AppRoutes.editProfile,
                arguments: displayUser,
              );
              // Reload data if profile was updated
              if (result == true) {
                _loadUserData();
              }
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              backgroundImage: displayUser.photoURL != null
                  ? (displayUser.photoURL!.startsWith('data:image')
                      ? MemoryImage(
                          // Decode base64 data URL asynchronously to avoid blocking
                          base64Decode(
                            displayUser.photoURL!.split(',')[1],
                          ),
                        ) as ImageProvider
                      : NetworkImage(
                          // Add cache busting to force reload of updated images
                          _getImageUrlWithCacheBust(displayUser.photoURL!),
                        ) as ImageProvider)
                  : null,
              onBackgroundImageError: displayUser.photoURL != null
                  ? (exception, stackTrace) {
                      // Handle error - will show initial letter
                      print('Image load error: $exception');
                    }
                  : null,
              child: displayUser.photoURL == null
                  ? Text(
                      displayUser.displayName?.isNotEmpty == true
                          ? displayUser.displayName![0].toUpperCase()
                          : displayUser.email?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              displayUser.displayName ?? 'No name',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayUser.email ?? 'No email',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: Using Auth data. Firestore data may not be available.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 48),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(displayUser.email ?? 'N/A'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Display Name'),
                subtitle: Text(displayUser.displayName ?? 'N/A'),
              ),
            ),
            const SizedBox(height: 16),
            if (displayUser.createdAt != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Member Since'),
                  subtitle: Text(
                    '${displayUser.createdAt!.day}/${displayUser.createdAt!.month}/${displayUser.createdAt!.year}',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                subtitle: const Text('Manage app settings and preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.settings);
                },
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                try {
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
