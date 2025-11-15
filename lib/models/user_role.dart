import 'package:flutter/material.dart';

/// User roles in the application
enum UserRole {
  admin('admin', 'Admin'),
  user('user', 'User'),
  pt('pt', 'Personal Trainer');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  /// Get role from string value
  static UserRole fromString(String? value) {
    if (value == null) return UserRole.user;
    return UserRole.values.firstWhere(
      (role) => role.value == value.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }

  /// Check if user is admin
  bool get isAdmin => this == UserRole.admin;

  /// Check if user is Personal Trainer
  bool get isPT => this == UserRole.pt;

  /// Check if user is regular user
  bool get isUser => this == UserRole.user;

  /// Get role icon
  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.pt:
        return Icons.fitness_center;
      case UserRole.user:
        return Icons.person;
    }
  }

  /// Get role color
  Color get color {
    switch (this) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.pt:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }
}

