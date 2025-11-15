import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final _dataService = DataService();
  final _authService = AuthService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _dataService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = _searchQuery.isEmpty ||
            (user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (user.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        final matchesRole = _filterRole == null || user.role == _filterRole;
        
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  Future<void> _changeUserRole(UserModel user, UserRole newRole) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Text(
          'Change role of "${user.displayName ?? user.email}" from ${user.role.displayName} to ${newRole.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _dataService.updateUserData(
        userId: user.uid,
        updateData: {'role': newRole.value},
      );

      if (success) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role changed to ${newRole.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update role'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search users',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _filterUsers();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Filter by role: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<UserRole?>(
                        value: _filterRole,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ...UserRole.values.map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.displayName),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _filterRole = value);
                          _filterUsers();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _filterRole == null
                                  ? 'No users found'
                                  : 'No users match your search',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final currentUser = _authService.currentUser;
                            final isCurrentUser = currentUser?.id == user.uid;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.photoURL != null
                                      ? NetworkImage(user.photoURL!)
                                      : null,
                                  child: user.photoURL == null
                                      ? Icon(user.role.icon)
                                      : null,
                                  backgroundColor: user.role.color.withOpacity(0.2),
                                ),
                                title: Text(
                                  user.displayName ?? user.email ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email ?? 'No email'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          user.role.icon,
                                          size: 16,
                                          color: user.role.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.role.displayName,
                                          style: TextStyle(
                                            color: user.role.color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (isCurrentUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'You',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<UserRole>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (newRole) {
                                    if (user.role != newRole) {
                                      _changeUserRole(user, newRole);
                                    }
                                  },
                                  itemBuilder: (context) => UserRole.values
                                      .where((role) => role != user.role)
                                      .map((role) => PopupMenuItem(
                                            value: role,
                                            child: Row(
                                              children: [
                                                Icon(role.icon, size: 20, color: role.color),
                                                const SizedBox(width: 8),
                                                Text('Change to ${role.displayName}'),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

