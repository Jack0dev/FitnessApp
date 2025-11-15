import 'user_role.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
    UserRole? role,
    this.createdAt,
    this.updatedAt,
  }) : role = role ?? UserRole.user;

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
    );
  }
}

