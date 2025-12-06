import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';

class RoomService {
  final SupabaseClient _client;

  RoomService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // Lấy danh sách tất cả phòng (sort theo name)
  Future<List<RoomModel>> getRooms() async {
    final response = await _client
        .from('rooms')
        .select('*')
        .order('name');

    final list = (response as List)
        .map((e) => RoomModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return list;
  }

  // Lấy 1 phòng theo id
  Future<RoomModel?> getRoomById(String id) async {
    final response = await _client
        .from('rooms')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return RoomModel.fromMap(response);
  }

  // Tạo phòng mới, trả về id
  Future<String?> createRoom(RoomModel room) async {
    final insertMap = room.toMap()..remove('id');

    final response = await _client
        .from('rooms')
        .insert(insertMap)
        .select('id')
        .single();

    return response['id'] as String?;
  }

  // Cập nhật thông tin phòng
  Future<bool> updateRoom(RoomModel room) async {
    final updateMap = room.toMap()..remove('id');

    await _client
        .from('rooms')
        .update(updateMap)
        .eq('id', room.id);

    return true;
  }

  // Xoá phòng
  Future<bool> deleteRoom(String id) async {
    await _client
        .from('rooms')
        .delete()
        .eq('id', id);

    return true;
  }
}
