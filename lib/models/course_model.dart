/// Course model
class CourseModel {
  final String id;
  final String title;
  final String description;
  final String? instructorId; // PT ID
  final String? instructorName;
  final double price;
  final String? imageUrl;
  final int duration; // in days
  final int maxStudents;
  final int currentStudents;
  final DateTime? startDate; // Ngày bắt đầu khóa học
  final DateTime? endDate; // Ngày kết thúc khóa học
  final List<String>? tags;
  final List<String>? equipment; // Dụng cụ tập: tạ đơn, tạ đòn, cáp, dây kháng lực,...
  final CourseLevel level; // Course difficulty level
  final CourseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    this.instructorId,
    this.instructorName,
    required this.price,
    this.imageUrl,
    required this.duration,
    required this.maxStudents,
    this.currentStudents = 0,
    this.startDate,
    this.endDate,
    this.tags,
    this.equipment,
    this.level = CourseLevel.beginner,
    this.status = CourseStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create CourseModel from Firestore document
  factory CourseModel.fromFirestore(Map<String, dynamic> doc, String id) {
    return CourseModel(
      id: id,
      title: doc['title'] as String,
      description: doc['description'] as String,
      instructorId: doc['instructorId'] as String?,
      instructorName: doc['instructorName'] as String?,
      price: (doc['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: doc['imageUrl'] as String?,
      duration: doc['duration'] as int? ?? 0,
      maxStudents: doc['maxStudents'] as int? ?? 0,
      currentStudents: doc['currentStudents'] as int? ?? 0,
      startDate: _parseTimestamp(doc['startDate']),
      endDate: _parseTimestamp(doc['endDate']),
      tags: doc['tags'] != null ? List<String>.from(doc['tags']) : null,
      equipment: doc['equipment'] != null ? List<String>.from(doc['equipment']) : null,
      level: CourseLevel.fromString(doc['level'] as String?),
      status: CourseStatus.fromString(doc['status'] as String?),
      createdAt: _parseTimestamp(doc['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(doc['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Create CourseModel from Supabase response
  factory CourseModel.fromSupabase(Map<String, dynamic> doc) {
    return CourseModel(
      id: doc['id'] as String,
      title: doc['title'] as String,
      description: doc['description'] as String,
      instructorId: doc['instructor_id'] as String?,
      instructorName: doc['instructor_name'] as String?,
      price: (doc['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: doc['image_url'] as String?,
      duration: doc['duration'] as int? ?? 0,
      maxStudents: doc['max_students'] as int? ?? 0,
      currentStudents: doc['current_students'] as int? ?? 0,
      startDate: doc['start_date'] != null
          ? DateTime.parse(doc['start_date'] as String)
          : null,
      endDate: doc['end_date'] != null
          ? DateTime.parse(doc['end_date'] as String)
          : null,
      tags: doc['tags'] != null ? List<String>.from(doc['tags']) : null,
      equipment: doc['equipment'] != null ? List<String>.from(doc['equipment']) : null,
      level: CourseLevel.fromString(doc['level'] as String?),
      status: CourseStatus.fromString(doc['status'] as String?),
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
      updatedAt: doc['updated_at'] != null
          ? DateTime.parse(doc['updated_at'] as String)
          : DateTime.now(),
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    try {
      return timestamp.toDate() as DateTime;
    } catch (e) {
      if (timestamp is Map) {
        final seconds = timestamp['_seconds'] as int?;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
      // Try parsing as ISO string
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      if (instructorId != null) 'instructorId': instructorId,
      if (instructorName != null) 'instructorName': instructorName,
      'price': price,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'duration': duration,
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (tags != null) 'tags': tags,
      if (equipment != null) 'equipment': equipment,
      'level': level.value,
      'status': status.value,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (instructorId != null) 'instructor_id': instructorId,
      if (instructorName != null) 'instructor_name': instructorName,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      'duration': duration,
      'max_students': maxStudents,
      'current_students': currentStudents,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (tags != null) 'tags': tags,
      if (equipment != null) 'equipment': equipment,
      'level': level.value,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? instructorId,
    String? instructorName,
    double? price,
    String? imageUrl,
    int? duration,
    int? maxStudents,
    int? currentStudents,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    List<String>? equipment,
    CourseLevel? level,
    CourseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      equipment: equipment ?? this.equipment,
      level: level ?? this.level,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isFull => currentStudents >= maxStudents;
  bool get isAvailable => status == CourseStatus.active && !isFull;
}

/// Course level enum
enum CourseLevel {
  beginner('beginner', 'Người mới bắt đầu'),
  intermediate('intermediate', 'Trung cấp'),
  advanced('advanced', 'Nâng cao');

  final String value;
  final String displayName;

  const CourseLevel(this.value, this.displayName);

  static CourseLevel fromString(String? value) {
    if (value == null) return CourseLevel.beginner;
    return CourseLevel.values.firstWhere(
      (level) => level.value == value.toLowerCase(),
      orElse: () => CourseLevel.beginner,
    );
  }
}

/// Course status enum
enum CourseStatus {
  active('active', 'Đang hoạt động'),
  inactive('inactive', 'Không hoạt động'),
  completed('completed', 'Hoàn thành'),
  canceled('canceled', 'Đã hủy');

  final String value;
  final String displayName;

  const CourseStatus(this.value, this.displayName);

  static CourseStatus fromString(String? value) {
    if (value == null) return CourseStatus.active;
    return CourseStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => CourseStatus.active,
    );
  }
}


