import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user/data_service.dart';
import '../../services/auth/auth_service.dart';
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
          SnackBar(content: Text('Lỗi khi tải danh sách người dùng: $e')),
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
        title: const Text('Thay đổi vai trò người dùng'),
        content: Text(
          'Thay đổi vai trò của "${user.displayName ?? user.email}" từ ${user.role.displayName} sang ${newRole.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
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
              content: Text('Vai trò đã được thay đổi thành ${newRole.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể cập nhật vai trò'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(colorScheme),
          _buildStatsBar(colorScheme),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredUsers.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user, colorScheme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search users',
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterUsers();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Filter by role:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole?>(
                      value: _filterRole,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'All Roles',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ),
                        ...UserRole.values.map((role) => DropdownMenuItem(
                              value: role,
                              child: Row(
                                children: [
                                  Icon(role.icon, size: 20, color: role.color),
                                  const SizedBox(width: 8),
                                  Text(role.displayName),
                                ],
                              ),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _filterRole = value);
                        _filterUsers();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(ColorScheme colorScheme) {
    final totalUsers = _users.length;
    final adminCount = _users.where((u) => u.role == UserRole.admin).length;
    final ptCount = _users.where((u) => u.role == UserRole.pt).length;
    final userCount = _users.where((u) => u.role == UserRole.user).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatBadge(Icons.people, '$totalUsers', 'Total', colorScheme),
          _buildStatBadge(Icons.admin_panel_settings, '$adminCount', 'Admin', colorScheme),
          _buildStatBadge(Icons.fitness_center, '$ptCount', 'PT', colorScheme),
          _buildStatBadge(Icons.person, '$userCount', 'Users', colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty && _filterRole == null
                  ? 'No users found'
                  : 'No users match your search',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty || _filterRole != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filterRole = null;
                  });
                  _filterUsers();
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, ColorScheme colorScheme) {
    final currentUser = _authService.currentUser;
    final isCurrentUser = currentUser?.id == user.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    backgroundColor: user.role.color.withOpacity(0.2),
                    child: user.photoURL == null
                        ? Icon(
                            user.role.icon,
                            color: user.role.color,
                            size: 28,
                          )
                        : null,
                  ),
                  if (isCurrentUser)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName ?? user.email ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? 'No email',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: user.role.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: user.role.color.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.role.icon,
                            size: 16,
                            color: user.role.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.role.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: user.role.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<UserRole>(
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
                              const SizedBox(width: 12),
                              Text('Đổi thành ${role.displayName}'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

