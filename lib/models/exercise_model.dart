/// Exercise model - Represents a predefined exercise
class ExerciseModel {
  final int id; // Primary key (id from exercise table)
  final String name;
  final String? description;
  final String? category;
  final List<String> muscleGroups;
  final String? difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExerciseModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.muscleGroups = const [],
    this.difficulty,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility getter
  int get exerciseId => id;

  /// Create from Supabase response
  factory ExerciseModel.fromSupabase(Map<String, dynamic> doc) {
    // Support both 'id' (new schema) and 'exercise_id' (old schema)
    final id = doc['id'] as int? ?? doc['exercise_id'] as int? ?? 0;
    
    return ExerciseModel(
      id: id,
      name: doc['name'] as String,
      description: doc['description'] as String?,
      category: doc['category'] as String?,
      muscleGroups: doc['muscle_groups'] != null
          ? List<String>.from(doc['muscle_groups'] as List)
          : [],
      difficulty: doc['difficulty'] as String?,
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
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'muscle_groups': muscleGroups,
      if (difficulty != null) 'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}


