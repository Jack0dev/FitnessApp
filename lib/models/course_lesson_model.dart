import 'package:flutter/material.dart';
import 'lesson_exercise_model.dart';

/// Course Lesson model - Represents a lesson/document in a course
class CourseLessonModel {
  final String id;
  final String courseId;
  final int lessonNumber; // Lesson order number (1, 2, 3, ...)
  final String title;
  final String? description;
  final String? backgroundImageUrl; // URL to background image
  final List<LessonExerciseModel> exercises; // Danh sách bài tập
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseLessonModel({
    required this.id,
    required this.courseId,
    required this.lessonNumber,
    required this.title,
    this.description,
    this.backgroundImageUrl,
    this.exercises = const [],
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
      backgroundImageUrl: doc['background_image_url'] as String? ?? doc['file_url'] as String?, // Backward compatibility
      exercises: doc['exercises'] != null
          ? (doc['exercises'] is List
              ? (doc['exercises'] as List)
                  .map((e) => LessonExerciseModel.fromMap(e as Map<String, dynamic>))
                  .toList()
              : [])
          : [],
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
      updatedAt: doc['updated_at'] != null
          ? DateTime.parse(doc['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Map for Supabase
  /// Note: exercises are now saved separately in relational tables, 
  /// but we include them here for backward compatibility if needed
  Map<String, dynamic> toSupabase({bool includeExercises = false}) {
    return {
      'id': id,
      'course_id': courseId,
      'lesson_number': lessonNumber,
      'title': title,
      if (description != null) 'description': description,
      if (backgroundImageUrl != null) 'background_image_url': backgroundImageUrl,
      if (includeExercises) 'exercises': exercises.map((e) => e.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CourseLessonModel copyWith({
    String? id,
    String? courseId,
    int? lessonNumber,
    String? title,
    String? description,
    String? backgroundImageUrl,
    List<LessonExerciseModel>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseLessonModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

