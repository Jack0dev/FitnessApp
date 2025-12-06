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

class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Profile fields
  final String? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? jobNature;
  final int? trainingFrequency;
  final int? trainingDurationMinutes;
  final String? fitnessGoal;
  final bool profileCompleted;

  UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
    UserRole? role,
    this.createdAt,
    this.updatedAt,
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
    this.jobNature,
    this.trainingFrequency,
    this.trainingDurationMinutes,
    this.fitnessGoal,
    this.profileCompleted = false,
  }) : role = role ?? UserRole.user;
  
  /// Check if profile is completed
  bool get isProfileCompleted => profileCompleted;

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> doc, String id) {
    // Handle Timestamp conversion
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is DateTime) return timestamp;
      // If it's a Firestore Timestamp
      try {
        return timestamp.toDate() as DateTime;
      } catch (e) {
        // If it's already a Map, try to parse
        if (timestamp is Map) {
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
        return null;
      }
    }

    return UserModel(
      uid: id,
      email: doc['email'] as String?,
      phoneNumber: doc['phoneNumber'] as String?,
      displayName: doc['displayName'] as String?,
      photoURL: doc['photoURL'] as String?,
      role: UserRole.fromString(doc['role'] as String?),
      createdAt: parseTimestamp(doc['createdAt']),
      updatedAt: parseTimestamp(doc['updatedAt']),
    );
  }

  /// Create UserModel from Firestore DocumentSnapshot
  factory UserModel.fromDocument(dynamic snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return UserModel.fromFirestore(data, snapshot.id);
  }

  /// Create UserModel from Supabase response
  factory UserModel.fromSupabase(Map<String, dynamic> doc) {
    return UserModel(
      uid: doc['id'] as String,
      email: doc['email'] as String?,
      phoneNumber: doc['phone_number'] as String?,
      displayName: doc['display_name'] as String?,
      photoURL: doc['photo_url'] as String?,
      role: UserRole.fromString(doc['role'] as String?),
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : null,
      updatedAt: doc['updated_at'] != null
          ? DateTime.parse(doc['updated_at'] as String)
          : null,
      gender: doc['gender'] as String?,
      age: doc['age'] as int?,
      heightCm: doc['height_cm'] != null ? (doc['height_cm'] as num).toDouble() : null,
      weightKg: doc['weight_kg'] != null ? (doc['weight_kg'] as num).toDouble() : null,
      jobNature: doc['job_nature'] as String?,
      trainingFrequency: doc['training_frequency'] as int?,
      trainingDurationMinutes: doc['training_duration_minutes'] as int?,
      fitnessGoal: doc['fitness_goal'] as String?,
      profileCompleted: doc['profile_completed'] as bool? ?? false,
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      'role': role.value,
      if (createdAt != null) 'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  /// Convert UserModel to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': uid,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (displayName != null) 'display_name': displayName,
      if (photoURL != null) 'photo_url': photoURL,
      'role': role.value,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (jobNature != null) 'job_nature': jobNature,
      if (trainingFrequency != null) 'training_frequency': trainingFrequency,
      if (trainingDurationMinutes != null) 'training_duration_minutes': trainingDurationMinutes,
      if (fitnessGoal != null) 'fitness_goal': fitnessGoal,
      'profile_completed': profileCompleted,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoURL,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    String? jobNature,
    int? trainingFrequency,
    int? trainingDurationMinutes,
    String? fitnessGoal,
    bool? profileCompleted,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      jobNature: jobNature ?? this.jobNature,
      trainingFrequency: trainingFrequency ?? this.trainingFrequency,
      trainingDurationMinutes: trainingDurationMinutes ?? this.trainingDurationMinutes,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  /// Generate QR code data for student attendance
  /// Used for PT to scan and mark attendance
  String generateQRCodeData({String? courseId}) {
    final qrData = {
      'user_id': uid,
      if (courseId != null) 'course_id': courseId,
      'type': 'student_attendance',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    return qrData.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  /// Generate QR code JSON string (alternative format)
  String generateQRCodeJson({String? courseId}) {
    final qrData = {
      'user_id': uid,
      if (courseId != null) 'course_id': courseId,
      'type': 'student_attendance',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    final jsonParts = [
      '"user_id":"${qrData['user_id']}"',
      if (courseId != null) '"course_id":"${qrData['course_id']}"',
      '"type":"${qrData['type']}"',
      '"timestamp":${qrData['timestamp']}',
    ];
    return '{${jsonParts.join(',')}}';
  }
}

