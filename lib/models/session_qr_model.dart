/// Session QR model - QR code tokens generated for each session for attendance scanning
class SessionQRModel {
  final String id;
  final String sessionId; // FK -> session.id
  final String token; // Unique QR token
  final DateTime expiresAt; // When the QR token expires
  final bool isUsed; // Whether this token has been used for attendance
  final DateTime createdAt;

  SessionQRModel({
    required this.id,
    required this.sessionId,
    required this.token,
    required this.expiresAt,
    this.isUsed = false,
    required this.createdAt,
  });

  /// Create SessionQRModel from Supabase response
  factory SessionQRModel.fromSupabase(Map<String, dynamic> doc) {
    return SessionQRModel(
      id: doc['id'] as String,
      sessionId: doc['session_id'] as String,
      token: doc['token'] as String,
      expiresAt: doc['expires_at'] != null
          ? DateTime.parse(doc['expires_at'] as String)
          : DateTime.now().add(const Duration(hours: 1)),
      isUsed: doc['is_used'] as bool? ?? false,
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'session_id': sessionId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SessionQRModel copyWith({
    String? id,
    String? sessionId,
    String? token,
    DateTime? expiresAt,
    bool? isUsed,
    DateTime? createdAt,
  }) {
    return SessionQRModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if token is valid (not expired and not used)
  bool get isValid => !isExpired && !isUsed;
}







