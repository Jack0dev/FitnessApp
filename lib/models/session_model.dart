import 'package:flutter/material.dart';

/// Session model - Represents training sessions created by trainers
/// Replaces ScheduleModel based on new database schema
class SessionModel {
  final String id;
  final String trainerId; // FK -> user.id (PT/Trainer)
  final String title;
  final DateTime date; // Date of the session
  final TimeOfDay startTime; // Start time of the session
  final TimeOfDay endTime; // End time of the session
  final String? notes; // Optional notes
  final String? roomId; // FK -> rooms.id (Supabase)
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionModel({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.roomId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create SessionModel from Supabase response
  factory SessionModel.fromSupabase(Map<String, dynamic> doc) {
    // Parse start_time and end_time from TIME format (HH:MM:SS)
    TimeOfDay parseTime(String? timeStr) {
      if (timeStr == null) return const TimeOfDay(hour: 9, minute: 0);
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 9;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
      return const TimeOfDay(hour: 9, minute: 0);
    }

    final startTime = parseTime(doc['start_time'] as String?);
    final endTime = parseTime(doc['end_time'] as String?);

    return SessionModel(
      id: doc['id'] as String,
      trainerId: doc['trainer_id'] as String,
      title: doc['title'] as String,
      date: doc['date'] != null
          ? DateTime.parse(doc['date'] as String)
          : DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      notes: doc['notes'] as String?,
      roomId: doc['room_id'] as String?, // 👈 LẤY room_id TỪ DB
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
    // Format TimeOfDay to TIME format (HH:MM:SS)
    String formatTime(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    return {
      'id': id,
      'trainer_id': trainerId,
      'title': title,
      'date': date.toIso8601String().split('T')[0], // DATE format yyyy-MM-dd
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
      if (notes != null) 'notes': notes,
      if (roomId != null) 'room_id': roomId, // 👈 ĐẨY room_id LÊN DB
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SessionModel copyWith({
    String? id,
    String? trainerId,
    String? title,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? notes,
    String? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate duration in minutes
  int get durationMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes > startMinutes
        ? endMinutes - startMinutes
        : (24 * 60) - startMinutes + endMinutes; // Handle next day
  }

  /// Check if session is in the past
  bool get isPast {
    final now = DateTime.now();
    final sessionDateTime = DateTime(
      date.year,
      date.month,
      date.day,
    );
    return sessionDateTime.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Check if session is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if session is upcoming
  bool get isUpcoming => !isPast && !isToday;

  /// Generate QR code data for this session (query string format)
  String generateQRCodeData() {
    final qrData = {
      'session_id': id,
      'type': 'session_attendance',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    return qrData.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  /// Generate QR code JSON string
  String generateQRCodeJson() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '{"session_id":"$id","type":"session_attendance","timestamp":$timestamp}';
  }
}


