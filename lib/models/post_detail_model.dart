/// Post detail model for storing likes, comments, and shares
enum PostDetailActionType {
  like('like'),
  comment('comment'),
  share('share');

  final String value;
  const PostDetailActionType(this.value);

  static PostDetailActionType fromString(String value) {
    return PostDetailActionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PostDetailActionType.like,
    );
  }
}

class PostDetailModel {
  final String id;
  final String postId;
  final String userId;
  final String? userName;
  final String? userAvatarUrl;
  final PostDetailActionType actionType;
  final String? commentText; // Only for comments
  final String? shareTarget; // Platform name or user_id for shares
  final DateTime createdAt;

  PostDetailModel({
    required this.id,
    required this.postId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.actionType,
    this.commentText,
    this.shareTarget,
    required this.createdAt,
  });

  /// Create PostDetailModel from Supabase response
  factory PostDetailModel.fromSupabase(Map<String, dynamic> doc) {
    return PostDetailModel(
      id: doc['id'] as String,
      postId: doc['post_id'] as String,
      userId: doc['user_id'] as String,
      userName: doc['user_name'] as String?,
      userAvatarUrl: doc['user_avatar_url'] as String?,
      actionType: PostDetailActionType.fromString(doc['action_type'] as String),
      commentText: doc['comment_text'] as String?,
      shareTarget: doc['share_target'] as String?,
      createdAt: doc['created_at'] != null
          ? DateTime.parse(doc['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'action_type': actionType.value,
      if (commentText != null) 'comment_text': commentText,
      if (shareTarget != null) 'share_target': shareTarget,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PostDetailModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    PostDetailActionType? actionType,
    String? commentText,
    String? shareTarget,
    DateTime? createdAt,
  }) {
    return PostDetailModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      actionType: actionType ?? this.actionType,
      commentText: commentText ?? this.commentText,
      shareTarget: shareTarget ?? this.shareTarget,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}








