import 'common/sql_database_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing chat messages between PT and students
class ChatService {
  SqlDatabaseService? _sqlService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  ChatService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. ChatService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  /// Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String courseId,
    required String message,
    String? messageType, // 'text', 'image', 'file'
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      await _sqlService!.client.from('chat_messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'course_id': courseId,
        'message': message,
        'message_type': messageType ?? 'text',
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
      });

      return true;
    } catch (e) {
      print('Failed to send message: $e');
      return false;
    }
  }

  /// Get messages between two users for a course
  Future<List<Map<String, dynamic>>> getMessages({
    required String userId1,
    required String userId2,
    required String courseId,
    int? limit,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      var query = _sqlService!.client
          .from('chat_messages')
          .select('''
            *,
            sender:sender_id (
              id,
              display_name,
              email,
              photo_url
            ),
            receiver:receiver_id (
              id,
              display_name,
              email,
              photo_url
            )
          ''')
          .eq('course_id', courseId)
          .or('(sender_id.eq.$userId1,receiver_id.eq.$userId1)')
          .or('(sender_id.eq.$userId2,receiver_id.eq.$userId2)')
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to get messages: $e');
      return [];
    }
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead({
    required String userId,
    required String senderId,
    required String courseId,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      await _sqlService!.client
          .from('chat_messages')
          .update({'read': true})
          .eq('receiver_id', userId)
          .eq('sender_id', senderId)
          .eq('course_id', courseId)
          .eq('read', false);

      return true;
    } catch (e) {
      print('Failed to mark messages as read: $e');
      return false;
    }
  }

  /// Get chat conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      // Get distinct conversations
      final response = await _sqlService!.client
          .from('chat_messages')
          .select('''
            course_id,
            sender_id,
            receiver_id,
            course:course_id (
              id,
              title
            ),
            sender:sender_id (
              id,
              display_name,
              photo_url
            ),
            receiver:receiver_id (
              id,
              display_name,
              photo_url
            )
          ''')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      // Group by course and other user
      final Map<String, Map<String, dynamic>> conversations = {};
      
      for (final msg in response) {
        final courseId = msg['course_id'] as String;
        final senderId = msg['sender_id'] as String;
        final receiverId = msg['receiver_id'] as String;
        final otherUserId = senderId == userId ? receiverId : senderId;
        final key = '$courseId|$otherUserId';

        if (!conversations.containsKey(key)) {
          conversations[key] = {
            'course_id': courseId,
            'course': msg['course'],
            'other_user_id': otherUserId,
            'other_user': senderId == userId ? msg['receiver'] : msg['sender'],
            'last_message': msg,
          };
        }
      }

      return conversations.values.toList();
    } catch (e) {
      print('Failed to get conversations: $e');
      return [];
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(String userId) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _sqlService!.client
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', userId)
          .eq('read', false);

      return (response as List).length;
    } catch (e) {
      print('Failed to get unread count: $e');
      return 0;
    }
  }
}











