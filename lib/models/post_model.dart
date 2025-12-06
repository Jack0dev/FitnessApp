/// Post model for social media feed
class PostModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatarUrl;
  final String content;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.content,
    this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create PostModel from Supabase response
  factory PostModel.fromSupabase(Map<String, dynamic> doc) {
    return PostModel(
      id: doc['id'] as String,
      userId: doc['user_id'] as String,
      userName: doc['user_name'] as String?,
      userAvatarUrl: doc['user_avatar_url'] as String?,
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
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      'content': content,
      if (imageUrls != null) 'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

