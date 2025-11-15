import 'package:flutter/material.dart';

/// Course Lesson model - Represents a lesson/document in a course
class CourseLessonModel {
  final String id;
  final String courseId;
  final int lessonNumber; // Lesson order number (1, 2, 3, ...)
  final String title;
  final String? description;
  final String fileUrl; // URL to image or video file
  final LessonFileType fileType; // image or video
  final DateTime? lessonDate; // Optional scheduled date for this lesson
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseLessonModel({
    required this.id,
    required this.courseId,
    required this.lessonNumber,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileType,
    this.lessonDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create CourseLessonModel from Supabase response
  factory CourseLessonModel.fromSupabase(Map<String, dynamic> doc) {
    return CourseLessonModel(
      id: doc['id'] as String,
      courseId: doc['course_id'] as String,
      lessonNumber: doc['lesson_number'] as int? ?? 0,
      title: doc['title'] as String,
      description: doc['description'] as String?,
      fileUrl: doc['file_url'] as String,
      fileType: LessonFileType.fromString(doc['file_type'] as String?),
      lessonDate: doc['lesson_date'] != null
          ? DateTime.parse(doc['lesson_date'] as String)
          : null,
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
      'course_id': courseId,
      'lesson_number': lessonNumber,
      'title': title,
      if (description != null) 'description': description,
      'file_url': fileUrl,
      'file_type': fileType.value,
      if (lessonDate != null) 'lesson_date': lessonDate!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Lesson file type enum
enum LessonFileType {
  image('image', 'Image', Icons.image),
  video('video', 'Video', Icons.video_library);

  final String value;
  final String displayName;
  final IconData icon;

  const LessonFileType(this.value, this.displayName, this.icon);

  static LessonFileType fromString(String? value) {
    if (value == null) return LessonFileType.image;
    return LessonFileType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => LessonFileType.image,
    );
  }
}

