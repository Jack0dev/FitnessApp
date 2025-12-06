import 'package:flutter/foundation.dart';

@immutable
class RoomModel {
  final String id;          // uuid trong Supabase
  final String name;        // tên phòng
  final String? code;       // mã phòng (R101, YG-01, ...)
  final String? location;   // vị trí: Tầng 2, khu A...
  final int? capacity;      // sức chứa
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomModel({
    required this.id,
    required this.name,
    this.code,
    this.location,
    this.capacity,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  RoomModel copyWith({
    String? id,
    String? name,
    String? code,
    String? location,
    int? capacity,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      location: map['location'] as String?,
      capacity: map['capacity'] as int?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'capacity': capacity,
      'description': description,
      // created_at & updated_at thường để DB handle (default now(), trigger...)
    };
  }
}
