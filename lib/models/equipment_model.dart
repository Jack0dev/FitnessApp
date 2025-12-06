/// Equipment model - Represents workout equipment
class EquipmentModel {
  final int id; // Primary key (id from equipment_item table)
  final String name;
  final String? description;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  EquipmentModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility getter
  int get equipmentId => id;

  /// Create from Supabase response
  factory EquipmentModel.fromSupabase(Map<String, dynamic> doc) {
    // Support both 'id' (new schema) and 'equipment_id' (old schema)
    final id = doc['id'] as int? ?? doc['equipment_id'] as int? ?? 0;
    
    return EquipmentModel(
      id: id,
      name: doc['name'] as String,
      description: doc['description'] as String?,
      icon: doc['icon'] as String?,
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
      if (icon != null) 'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}


