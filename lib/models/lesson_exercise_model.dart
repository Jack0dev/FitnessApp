/// Exercise model for Course Lesson exercises
class LessonExerciseModel {
  final int? id; // ID của lesson_exercise trong database (null khi chưa lưu)
  final int exerciseId; // ID của exercise từ bảng exercises
  final String exerciseName; // Tên bài tập (for display, loaded from exercises table)
  final List<int> equipmentIds; // IDs của dụng cụ tập
  final List<String> equipment; // Tên dụng cụ tập (for display, loaded from equipment table)
  final int? sets; // Số hiệp
  final int? reps; // Số rep
  final int? restTimeSeconds; // Thời gian nghỉ giữa mỗi hiệp (giây)
  final String? notes; // Ghi chú
  final int orderIndex; // Thứ tự trong bài học

  LessonExerciseModel({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.equipmentIds = const [],
    this.equipment = const [],
    this.sets,
    this.reps,
    this.restTimeSeconds,
    this.notes,
    this.orderIndex = 0,
  });

  /// Create from Map (for backward compatibility with JSONB)
  factory LessonExerciseModel.fromMap(Map<String, dynamic> map) {
    return LessonExerciseModel(
      exerciseId: map['exercise_id'] as int? ?? 0,
      exerciseName: map['exercise_name'] as String? ?? '',
      equipment: map['equipment'] != null
          ? List<String>.from(map['equipment'])
          : [],
      equipmentIds: map['equipment_ids'] != null
          ? List<int>.from(map['equipment_ids'])
          : [],
      sets: map['sets'] as int?,
      reps: map['reps'] as int?,
      restTimeSeconds: map['rest_time_seconds'] as int?,
      notes: map['notes'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }

  /// Create from Supabase response (relational tables)
  factory LessonExerciseModel.fromSupabase(
    Map<String, dynamic> lessonExercise,
    Map<String, dynamic>? exercise,
    List<Map<String, dynamic>>? equipmentList,
  ) {
    final exerciseName = exercise != null
        ? (exercise['name'] as String? ?? '')
        : (lessonExercise['exercise_name'] as String? ?? '');
    
    final equipmentNames = <String>[];
    if (equipmentList != null) {
      for (final e in equipmentList) {
        final name = e['name'] as String?;
        if (name != null) {
          equipmentNames.add(name);
        }
      }
    }
    
    final equipmentIds = <int>[];
    if (equipmentList != null) {
      for (final e in equipmentList) {
        // Support both 'id' (from equipment_item table) and 'equipment_id' (legacy)
        final id = e['id'] as int? ?? e['equipment_id'] as int?;
        if (id != null) {
          equipmentIds.add(id);
        }
      }
    }

    final exerciseIdValue = lessonExercise['exercise_id'] as int? ?? 0;
    
    return LessonExerciseModel(
      id: lessonExercise['id'] as int?,
      exerciseId: exerciseIdValue,
      exerciseName: exerciseName.isNotEmpty ? exerciseName : 'Unknown Exercise',
      equipmentIds: equipmentIds,
      equipment: equipmentNames,
      sets: lessonExercise['sets'] as int?,
      reps: lessonExercise['reps'] as int?,
      restTimeSeconds: lessonExercise['rest_time_seconds'] as int?,
      notes: lessonExercise['notes'] as String?,
      orderIndex: lessonExercise['order_index'] as int? ?? 0,
    );
  }

  /// Convert to Map (for backward compatibility with JSONB)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'equipment': equipment,
      'equipment_ids': equipmentIds,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (restTimeSeconds != null) 'rest_time_seconds': restTimeSeconds,
      if (notes != null) 'notes': notes,
      'order_index': orderIndex,
    };
  }

  LessonExerciseModel copyWith({
    int? id,
    int? exerciseId,
    String? exerciseName,
    List<int>? equipmentIds,
    List<String>? equipment,
    int? sets,
    int? reps,
    int? restTimeSeconds,
    String? notes,
    int? orderIndex,
  }) {
    return LessonExerciseModel(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}


