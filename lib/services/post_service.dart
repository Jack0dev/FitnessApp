import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/post_detail_model.dart';
import 'common/sql_database_service.dart';
import '../config/supabase_config.dart';

/// Service for managing posts and social features
class PostService {
  SqlDatabaseService? _sqlService;

  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      return Supabase.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  PostService() {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      throw Exception('Supabase not initialized. PostService requires Supabase.');
    }
    _sqlService = SqlDatabaseService();
  }

  SupabaseClient get _supabase {
    return _sqlService!.client;
  }

  /// Get posts by user ID with counts from post_detail
  Future<List<PostModel>> getPostsByUserId(String userId, {String? currentUserId}) async {
    try {
      final response = await _supabase
          .from('post')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final postsList = response as List;
      if (postsList.isEmpty) return [];

      // Get user info once
      final userResponse = await _supabase
          .from('user')
          .select('display_name, photo_url')
          .eq('id', userId)
          .maybeSingle();

      final userName = userResponse?['display_name'] as String?;
      final userAvatarUrl = userResponse?['photo_url'] as String?;

      // Get all post IDs
      // Build posts list
      final posts = <PostModel>[];
      for (final doc in postsList) {
        final postId = doc['id'] as String;
        posts.add(PostModel(
          id: postId,
          userId: doc['user_id'] as String,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
          content: doc['content'] as String,
          imageUrls: doc['image_urls'] != null
              ? List<String>.from(doc['image_urls'] as List)
              : null,
          createdAt: doc['created_at'] != null
              ? DateTime.parse(doc['created_at'] as String)
              : DateTime.now(),
          updatedAt: doc['updated_at'] != null
              ? DateTime.parse(doc['updated_at'] as String)
              : DateTime.now(),
        ));
      }

      return posts;
    } catch (e) {
      print('Failed to get posts by user ID: $e');
      return [];
    }
  }

  /// Get post count for a user
  Future<int> getPostCount(String userId) async {
    try {
      final response = await _supabase
          .from('post')
          .select('id')
          .eq('user_id', userId);
      
      return (response as List).length;
    } catch (e) {
      print('Failed to get post count: $e');
      return 0;
    }
  }

  /// Get follower count (số người theo dõi)
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _supabase
          .from('follower')
          .select('id')
          .eq('following_id', userId);
      
      return (response as List).length;
    } catch (e) {
      print('Failed to get follower count: $e');
      return 0;
    }
  }

  /// Get following count (số người đang theo dõi)
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .from('follower')
          .select('id')
          .eq('follower_id', userId);
      
      return (response as List).length;
    } catch (e) {
      print('Failed to get following count: $e');
      return 0;
    }
  }

  /// Get like count for a post
  Future<int> getLikeCount(String postId) async {
    try {
      final response = await _supabase
          .from('post_detail')
          .select('id')
          .eq('post_id', postId)
          .eq('action_type', 'like');
      
      return (response as List).length;
    } catch (e) {
      print('Failed to get like count: $e');
      return 0;
    }
  }

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final response = await _supabase
          .from('post_detail')
          .select('id')
          .eq('post_id', postId)
          .eq('action_type', 'comment');
      
      return (response as List).length;
    } catch (e) {
      print('Failed to get comment count: $e');
      return 0;
    }
  }

  /// Get share count for a post
  Future<int> getShareCount(String postId) async {
    try {
      final response = await _supabase
          .from('post_detail')
          .select('id')
          .eq('post_id', postId)
          .eq('action_type', 'share');
      
      return (response as List).length;
    } catch (e) {
      print('Failed to get share count: $e');
      return 0;
    }
  }

  /// Check if a post is liked by a user
  Future<bool> isLikedByUser(String postId, String userId) async {
    try {
      final response = await _supabase
          .from('post_detail')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .eq('action_type', 'like')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Failed to check if liked: $e');
      return false;
    }
  }

  /// Toggle like on a post
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      // Check if already liked
      final existingLike = await _supabase
          .from('post_detail')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .eq('action_type', 'like')
          .maybeSingle();

      if (existingLike != null) {
        // Unlike - delete the like record
        await _supabase
            .from('post_detail')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId)
            .eq('action_type', 'like');
        return false; // Now unliked
      } else {
        // Like - insert new like record
        await _supabase
            .from('post_detail')
            .insert({
              'id': 'detail_${postId}_${userId}_like_${DateTime.now().millisecondsSinceEpoch}',
              'post_id': postId,
              'user_id': userId,
              'action_type': 'like',
            });
        return true; // Now liked
      }
    } catch (e) {
      print('Failed to toggle like: $e');
      throw 'Failed to toggle like: $e';
    }
  }

  /// Add a comment to a post
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String commentText,
  }) async {
    try {
      final detailId = 'detail_${postId}_${userId}_comment_${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabase
          .from('post_detail')
          .insert({
            'id': detailId,
            'post_id': postId,
            'user_id': userId,
            'action_type': 'comment',
            'comment_text': commentText,
          });

      return detailId;
    } catch (e) {
      print('Failed to add comment: $e');
      return null;
    }
  }

  /// Add a share to a post
  Future<String?> addShare({
    required String postId,
    required String userId,
    String? shareTarget, // Platform name or user_id
  }) async {
    try {
      final detailId = 'detail_${postId}_${userId}_share_${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabase
          .from('post_detail')
          .insert({
            'id': detailId,
            'post_id': postId,
            'user_id': userId,
            'action_type': 'share',
            'share_target': shareTarget,
          });

      return detailId;
    } catch (e) {
      print('Failed to add share: $e');
      return null;
    }
  }

  /// Get likes for a post
  Future<List<PostDetailModel>> getLikes(String postId) async {
    try {
      final response = await _supabase
          .from('post_detail')
          .select()
          .eq('post_id', postId)
          .eq('action_type', 'like')
          .order('created_at', ascending: false);

      final detailsList = response as List;
      final likes = <PostDetailModel>[];
      final userIds = detailsList.map((d) => d['user_id'] as String).toSet().toList();

      // Get user info for all users
      Map<String, Map<String, String?>> userInfoMap = {};
      if (userIds.isNotEmpty) {
        try {
          final orConditions = userIds.map((id) => 'id.eq.$id').join(',');
          final usersResponse = await _supabase
              .from('user')
              .select('id, display_name, photo_url')
              .or(orConditions);
          
          final usersList = usersResponse as List;
          for (final user in usersList) {
            userInfoMap[user['id'] as String] = {
              'display_name': user['display_name'] as String?,
              'photo_url': user['photo_url'] as String?,
            };
          }
        } catch (e) {
          print('Error loading user info for likes: $e');
        }
      }

      for (final doc in detailsList) {
        final userId = doc['user_id'] as String;
        final userInfo = userInfoMap[userId];
        likes.add(PostDetailModel(
          id: doc['id'] as String,
          postId: doc['post_id'] as String,
          userId: userId,
          userName: userInfo?['display_name'],
          userAvatarUrl: userInfo?['photo_url'],
          actionType: PostDetailActionType.like,
          createdAt: doc['created_at'] != null
              ? DateTime.parse(doc['created_at'] as String)
              : DateTime.now(),
        ));
      }

      return likes;
    } catch (e) {
      print('Failed to get likes: $e');
      return [];
    }
  }

  /// Get comments for a post
  Future<List<PostDetailModel>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('post_detail')
          .select()
          .eq('post_id', postId)
          .eq('action_type', 'comment')
          .order('created_at', ascending: false);

      final detailsList = response as List;
      final comments = <PostDetailModel>[];
      final userIds = detailsList.map((d) => d['user_id'] as String).toSet().toList();

      // Get user info for all users
      Map<String, Map<String, String?>> userInfoMap = {};
      if (userIds.isNotEmpty) {
        try {
          final orConditions = userIds.map((id) => 'id.eq.$id').join(',');
          final usersResponse = await _supabase
              .from('user')
              .select('id, display_name, photo_url')
              .or(orConditions);
          
          final usersList = usersResponse as List;
          for (final user in usersList) {
            userInfoMap[user['id'] as String] = {
              'display_name': user['display_name'] as String?,
              'photo_url': user['photo_url'] as String?,
            };
          }
        } catch (e) {
          print('Error loading user info for comments: $e');
        }
      }

      for (final doc in detailsList) {
        final userId = doc['user_id'] as String;
        final userInfo = userInfoMap[userId];
        comments.add(PostDetailModel(
          id: doc['id'] as String,
          postId: doc['post_id'] as String,
          userId: userId,
          userName: userInfo?['display_name'],
          userAvatarUrl: userInfo?['photo_url'],
          actionType: PostDetailActionType.comment,
          commentText: doc['comment_text'] as String?,
          createdAt: doc['created_at'] != null
              ? DateTime.parse(doc['created_at'] as String)
              : DateTime.now(),
        ));
      }

      return comments;
    } catch (e) {
      print('Failed to get comments: $e');
      return [];
    }
  }

  /// Get shares for a post
  Future<List<PostDetailModel>> getShares(String postId) async {
    try {
      final response = await _supabase
          .from('post_detail')
          .select()
          .eq('post_id', postId)
          .eq('action_type', 'share')
          .order('created_at', ascending: false);

      final detailsList = response as List;
      final shares = <PostDetailModel>[];
      final userIds = detailsList.map((d) => d['user_id'] as String).toSet().toList();

      // Get user info for all users
      Map<String, Map<String, String?>> userInfoMap = {};
      if (userIds.isNotEmpty) {
        try {
          final orConditions = userIds.map((id) => 'id.eq.$id').join(',');
          final usersResponse = await _supabase
              .from('user')
              .select('id, display_name, photo_url')
              .or(orConditions);
          
          final usersList = usersResponse as List;
          for (final user in usersList) {
            userInfoMap[user['id'] as String] = {
              'display_name': user['display_name'] as String?,
              'photo_url': user['photo_url'] as String?,
            };
          }
        } catch (e) {
          print('Error loading user info for shares: $e');
        }
      }

      for (final doc in detailsList) {
        final userId = doc['user_id'] as String;
        final userInfo = userInfoMap[userId];
        shares.add(PostDetailModel(
          id: doc['id'] as String,
          postId: doc['post_id'] as String,
          userId: userId,
          userName: userInfo?['display_name'],
          userAvatarUrl: userInfo?['photo_url'],
          actionType: PostDetailActionType.share,
          shareTarget: doc['share_target'] as String?,
          createdAt: doc['created_at'] != null
              ? DateTime.parse(doc['created_at'] as String)
              : DateTime.now(),
        ));
      }

      return shares;
    } catch (e) {
      print('Failed to get shares: $e');
      return [];
    }
  }

  /// Create a new post
  Future<String?> createPost({
    required String userId,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final postId = 'post_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabase
          .from('post')
          .insert({
            'id': postId,
            'user_id': userId,
            'content': content,
            'image_urls': imageUrls,
          });

      return postId;
    } catch (e) {
      print('Failed to create post: $e');
      return null;
    }
  }
}
