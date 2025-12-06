/// Trainer Attendance model - Represents trainer check-in/check-out for a session
class TrainerAttendanceModel {
  final String id;
  final String trainerId; // FK -> user.id (Trainer)
  final String sessionId; // FK -> session.id
  final DateTime? checkInTime; // When the trainer checked in
  final double? checkInLat; // Latitude of check-in location
  final double? checkInLong; // Longitude of check-in location
  final DateTime? checkOutTime; // When the trainer checked out
  final double? checkOutLat; // Latitude of check-out location
  final double? checkOutLong; // Longitude of check-out location
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerAttendanceModel({
    required this.id,
    required this.trainerId,
    required this.sessionId,
    this.checkInTime,
    this.checkInLat,
    this.checkInLong,
    this.checkOutTime,
    this.checkOutLat,
    this.checkOutLong,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create TrainerAttendanceModel from Supabase response
  factory TrainerAttendanceModel.fromSupabase(Map<String, dynamic> doc) {
    DateTime? parseDateTime(String? value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return TrainerAttendanceModel(
      id: doc['id'] as String,
      trainerId: doc['trainer_id'] as String,
      sessionId: doc['session_id'] as String,
      checkInTime: parseDateTime(doc['check_in_time'] as String?),
      checkInLat: (doc['check_in_lat'] as num?)?.toDouble(),
      checkInLong: (doc['check_in_long'] as num?)?.toDouble(),
      checkOutTime: parseDateTime(doc['check_out_time'] as String?),
      checkOutLat: (doc['check_out_lat'] as num?)?.toDouble(),
      checkOutLong: (doc['check_out_long'] as num?)?.toDouble(),
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
      updatedAt: doc['updated_at'] != null
          ? DateTime.parse(doc['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'session_id': sessionId,
      if (checkInTime != null) 'check_in_time': checkInTime!.toIso8601String(),
      if (checkInLat != null) 'check_in_lat': checkInLat,
      if (checkInLong != null) 'check_in_long': checkInLong,
      if (checkOutTime != null) 'check_out_time': checkOutTime!.toIso8601String(),
      if (checkOutLat != null) 'check_out_lat': checkOutLat,
      if (checkOutLong != null) 'check_out_long': checkOutLong,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TrainerAttendanceModel copyWith({
    String? id,
    String? trainerId,
    String? sessionId,
    DateTime? checkInTime,
    double? checkInLat,
    double? checkInLong,
    DateTime? checkOutTime,
    double? checkOutLat,
    double? checkOutLong,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerAttendanceModel(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      sessionId: sessionId ?? this.sessionId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLong: checkInLong ?? this.checkInLong,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLong: checkOutLong ?? this.checkOutLong,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if trainer is checked in
  bool get isCheckedIn => checkInTime != null;

  /// Check if trainer is checked out
  bool get isCheckedOut => checkOutTime != null;

  /// Get check-in location as string (if available)
  String? get checkInLocationString {
    if (checkInLat != null && checkInLong != null) {
      return 'Lat: $checkInLat, Long: $checkInLong';
    }
    return null;
  }

  /// Get check-out location as string (if available)
  String? get checkOutLocationString {
    if (checkOutLat != null && checkOutLong != null) {
      return 'Lat: $checkOutLat, Long: $checkOutLong';
    }
    return null;
  }
}







