import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/course/course_service.dart';
import '../../services/content/post_service.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../models/post_model.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _dataService = DataService();
  final _courseService = CourseService();
  PostService? _postService;
  UserModel? _userModel;
  bool _isLoading = true;
  String? _error;
  ImageProvider? _cachedImageProvider;
  bool _isFollowing = false;
  List<CourseModel> _ptCourses = [];
  bool _isLoadingCourses = false;
  List<PostModel> _posts = [];
  bool _isLoadingPosts = false;
  
  // Post details (counts and likes) - Map<postId, Map<String, dynamic>>
  final Map<String, Map<String, dynamic>> _postDetails = {};
  
  // Stats
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _initializePostService();
    _loadUserData();
  }

  void _initializePostService() {
    try {
      _postService = PostService();
    } catch (e) {
      print('PostService initialization failed: $e');
      _postService = null;
    }
  }

  /// Add cache busting parameter to image URL to force reload
  String _getImageUrlWithCacheBust(String url) {
    if (url.contains('?')) {
      return '$url&t=${DateTime.now().millisecondsSinceEpoch}';
    } else {
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'No user logged in';
      });
      return;
    }

    try {
      // Load user data from Supabase
      final userModel = await _dataService.getUserData(user.id);
      
      // Merge data: prioritize database data, fallback to Auth metadata
      if (userModel != null) {
        // Pre-decode base64 image to avoid blocking main thread during build
        _preloadImage(userModel.photoURL);
        setState(() {
          _userModel = userModel;
          _isLoading = false;
        });
        
        // Load PT courses if user is PT
        if (userModel.role == UserRole.pt) {
          _loadPTCourses(user.id);
        }
        
        // Load posts and stats after userModel is set
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadPosts(user.id);
          _loadStats(user.id);
        });
      } else {
        // If no database data, use Auth data
        final photoURL = user.userMetadata?['photo_url'] as String?;
        _preloadImage(photoURL);
        setState(() {
          _userModel = UserModel(
            uid: user.id,
            email: user.email,
            displayName: user.userMetadata?['display_name'] as String?,
            photoURL: photoURL,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to Auth data
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          final photoURL = currentUser.userMetadata?['photo_url'] as String?;
          _preloadImage(photoURL);
          _userModel = UserModel(
            uid: currentUser.id,
            email: currentUser.email,
            displayName: currentUser.userMetadata?['display_name'] as String?,
            photoURL: photoURL,
          );
        }
      });
    }
  }

  Future<void> _loadPTCourses(String instructorId) async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final courses = await _courseService.getCoursesByInstructor(instructorId);
      setState(() {
        _ptCourses = courses.where((c) => c.status == CourseStatus.active).take(10).toList();
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _loadPosts(String userId) async {
    if (_postService == null) {
      setState(() {
        _isLoadingPosts = false;
        _posts = [];
        _postDetails.clear();
      });
      return;
    }

    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final currentUserId = _authService.currentUser?.id;
      final posts = await _postService!.getPostsByUserId(userId, currentUserId: currentUserId);
      
      // Load counts and likes for each post
      final Map<String, Map<String, dynamic>> postDetails = {};
      for (final post in posts) {
        final likesCount = await _postService!.getLikeCount(post.id);
        final commentsCount = await _postService!.getCommentCount(post.id);
        final sharesCount = await _postService!.getShareCount(post.id);
        final isLiked = currentUserId != null 
            ? await _postService!.isLikedByUser(post.id, currentUserId)
            : false;
        
        postDetails[post.id] = {
          'likesCount': likesCount,
          'commentsCount': commentsCount,
          'sharesCount': sharesCount,
          'isLiked': isLiked,
        };
      }
      
      setState(() {
        _posts = posts;
        _postDetails.clear();
        _postDetails.addAll(postDetails);
        _isLoadingPosts = false;
        _postsCount = posts.length;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isLoadingPosts = false;
        _posts = [];
        _postDetails.clear();
      });
    }
  }

  Future<void> _loadStats(String userId) async {
    if (_postService == null) {
      setState(() {
        _postsCount = 0;
        _followersCount = 0;
        _followingCount = 0;
      });
      return;
    }

    try {
      final postsCount = await _postService!.getPostCount(userId);
      final followersCount = await _postService!.getFollowerCount(userId);
      final followingCount = await _postService!.getFollowingCount(userId);
      
      setState(() {
        _postsCount = postsCount;
        _followersCount = followersCount;
        _followingCount = followingCount;
      });
    } catch (e) {
      print('Error loading stats: $e');
      // Keep current values on error
    }
  }
  
  bool get _isOwnProfile {
    final currentUser = _authService.currentUser;
    return currentUser?.id == _userModel?.uid;
  }

  /// Pre-load image asynchronously to avoid blocking main thread
  void _preloadImage(String? photoURL) {
    if (photoURL == null || photoURL.isEmpty) {
      _cachedImageProvider = null;
      return;
    }

    // Decode base64 images in background to avoid blocking UI
    if (photoURL.startsWith('data:image')) {
      Future.microtask(() {
        try {
          final base64String = photoURL.split(',')[1];
          final bytes = base64Decode(base64String);
          if (mounted) {
            setState(() {
              _cachedImageProvider = MemoryImage(bytes);
            });
          }
        } catch (e) {
          print('Error preloading base64 image: $e');
          if (mounted) {
            setState(() {
              _cachedImageProvider = null;
            });
          }
        }
      });
    } else {
      // Network images - use cache busting
      _cachedImageProvider = NetworkImage(_getImageUrlWithCacheBust(photoURL));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: context.translate('profile'),
            variant: TextVariant.headlineMedium,
            color: DesignTokens.textPrimary,
          ),
        ),
        body: Center(
          child: CustomText(
            text: context.translate('error'),
            variant: TextVariant.bodyLarge,
            color: DesignTokens.error,
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: context.translate('profile'),
            variant: TextVariant.headlineMedium,
            color: DesignTokens.textPrimary,
          ),
        ),
        body: const LoadingWidget(),
      );
    }

    if (_error != null && _userModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: context.translate('profile'),
            variant: TextVariant.headlineMedium,
            color: DesignTokens.textPrimary,
          ),
        ),
        body: ErrorDisplayWidget(
          message: _error!,
          onRetry: _loadUserData,
        ),
      );
    }

    final displayUser = _userModel ?? UserModel(
      uid: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      photoURL: user.userMetadata?['photo_url'] as String?,
    );

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Hồ sơ',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
            tooltip: 'Cài đặt',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                AppRoutes.editProfile,
                arguments: displayUser,
              );
              // Reload data if profile was updated
              if (result == true) {
                _loadUserData();
              }
            },
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildProfileHeader(displayUser),
            ),
          ];
        },
        body: _buildPostsTab(),
      ),
      floatingActionButton: _isOwnProfile
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed(AppRoutes.createPost);
                if (result == true && _userModel != null) {
                  // Reload posts if post was created successfully
                  _loadPosts(_userModel!.uid);
                  _loadStats(_userModel!.uid);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo bài viết'),
              backgroundColor: DesignTokens.primary,
            )
          : null,
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Avatar
        CircleAvatar(
          radius: 50,
          backgroundColor: DesignTokens.primary.withOpacity(0.1),
          backgroundImage: _cachedImageProvider ?? 
              (user.photoURL != null && !user.photoURL!.startsWith('data:image')
                  ? NetworkImage(_getImageUrlWithCacheBust(user.photoURL!))
                  : null),
          onBackgroundImageError: user.photoURL != null
              ? (exception, stackTrace) {
                  print('Image load error: $exception');
                }
              : null,
          child: user.photoURL == null
              ? Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName![0].toUpperCase()
                      : user.email?[0].toUpperCase() ?? 'U',
                  style: TextStyle(
                    fontSize: 36,
                    color: DesignTokens.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        // Name
        CustomText(
          text: user.displayName ?? 'Chưa có tên',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textDark,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 4),
        // Email
        CustomText(
          text: user.email ?? 'Chưa có email',
          variant: TextVariant.bodyMedium,
          color: DesignTokens.textSecondary,
        ),
        const SizedBox(height: 24),
        // Message and Follow buttons (only show if viewing other's profile)
        if (!_isOwnProfile) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement message functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng nhắn tin đang phát triển')),
                      );
                    },
                    icon: const Icon(Icons.message_outlined, size: 20),
                    label: const Text('Nhắn tin'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: DesignTokens.borderDefault, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isFollowing = !_isFollowing;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFollowing ? 'Đã theo dõi' : 'Đã bỏ theo dõi'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      _isFollowing ? Icons.check : Icons.person_add_outlined,
                      size: 20,
                    ),
                    label: Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing 
                          ? DesignTokens.textSecondary 
                          : DesignTokens.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Stats tabs (bài viết | người theo dõi | đang theo dõi)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Bài viết', _postsCount.toString()),
              _buildStatItem('Người theo dõi', _followersCount.toString()),
              _buildStatItem('Đang theo dõi', _followingCount.toString()),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // About/Bio section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: 'Giới thiệu',
                variant: TextVariant.titleLarge,
                color: DesignTokens.textDark,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.borderLight,
                    width: 1,
                  ),
                ),
                child: CustomText(
                  text: user.role == UserRole.pt
                      ? 'Huấn luyện viên cá nhân chuyên nghiệp với nhiều năm kinh nghiệm trong lĩnh vực thể dục và sức khỏe.'
                      : 'Thành viên của Fitness App. Đang trên hành trình cải thiện sức khỏe và thể chất.',
                  variant: TextVariant.bodyMedium,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // PT Courses section
        if (user.role == UserRole.pt) ...[
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Khóa học nổi bật',
                      variant: TextVariant.titleLarge,
                      color: DesignTokens.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    if (_ptCourses.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Navigate to PT dashboard (which has courses management)
                          Navigator.of(context).pushNamed(AppRoutes.ptDashboard);
                        },
                        child: const Text('Xem tất cả'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingCourses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_ptCourses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignTokens.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: CustomText(
                        text: 'Chưa có khóa học nào',
                        variant: TextVariant.bodyMedium,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _ptCourses.length,
                      itemBuilder: (context, index) {
                        return _buildCourseCard(_ptCourses[index]);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.borderDefault,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to course detail
            Navigator.of(context).pushNamed(
              AppRoutes.courseDetail,
              arguments: course,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: course.imageUrl != null
                    ? Image.network(
                        course.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: DesignTokens.surfaceLight,
                          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 120,
                        color: DesignTokens.surfaceLight,
                        child: const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
                      ),
              ),
              // Course Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: course.title,
                      variant: TextVariant.titleMedium,
                      color: DesignTokens.textDark,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: DesignTokens.textSecondary),
                        const SizedBox(width: 4),
                        CustomText(
                          text: '${course.currentStudents}/${course.maxStudents}',
                          variant: TextVariant.bodySmall,
                          color: DesignTokens.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: DesignTokens.textSecondary),
                        const SizedBox(width: 4),
                        CustomText(
                          text: '${course.duration} ngày',
                          variant: TextVariant.bodySmall,
                          color: DesignTokens.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      text: formatter.format(course.price),
                      variant: TextVariant.titleMedium,
                      color: DesignTokens.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to detail page
      },
      child: Column(
        children: [
          CustomText(
            text: value,
            variant: TextVariant.headlineSmall,
            color: DesignTokens.textDark,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          CustomText(
            text: label,
            variant: TextVariant.bodySmall,
            color: DesignTokens.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_posts.isEmpty) {
      return _buildEmptyState('Bài viết', Icons.article_outlined, 'Chưa có bài viết nào');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_posts[index]);
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    final timeAgo = _getTimeAgo(post.createdAt);
    final details = _postDetails[post.id] ?? {
      'likesCount': 0,
      'commentsCount': 0,
      'sharesCount': 0,
      'isLiked': false,
    };
    final likesCount = details['likesCount'] as int;
    final commentsCount = details['commentsCount'] as int;
    final sharesCount = details['sharesCount'] as int;
    final isLiked = details['isLiked'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: DesignTokens.primary.withOpacity(0.1),
                  backgroundImage: post.userAvatarUrl != null
                      ? NetworkImage(post.userAvatarUrl!)
                      : null,
                  child: post.userAvatarUrl == null
                      ? Text(
                          post.userName?.isNotEmpty == true
                              ? post.userName![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 16,
                            color: DesignTokens.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: post.userName ?? 'User',
                        variant: TextVariant.titleMedium,
                        color: DesignTokens.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      CustomText(
                        text: timeAgo,
                        variant: TextVariant.bodySmall,
                        color: DesignTokens.textLight,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () {
                    // TODO: Show post options
                  },
                  color: DesignTokens.textSecondary,
                ),
              ],
            ),
          ),
          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomText(
              text: post.content,
              variant: TextVariant.bodyLarge,
              color: DesignTokens.textDark,
            ),
          ),
          // Post Images (if any)
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: post.imageUrls!.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post.imageUrls![index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Post Actions (Like, Comment, Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(likesCount),
                  isActive: isLiked,
                  onTap: () async {
                    if (_postService == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dịch vụ chưa sẵn sàng')),
                      );
                      return;
                    }
                    
                    try {
                      final currentUserId = _authService.currentUser?.id;
                      if (currentUserId == null) return;
                      
                      final newIsLiked = await _postService!.toggleLike(post.id, currentUserId);
                      final newLikesCount = await _postService!.getLikeCount(post.id);
                      
                      setState(() {
                        _postDetails[post.id] = {
                          'likesCount': newLikesCount,
                          'commentsCount': commentsCount,
                          'sharesCount': sharesCount,
                          'isLiked': newIsLiked,
                        };
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: ${e.toString()}')),
                      );
                    }
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(commentsCount),
                  onTap: () {
                    // TODO: Show comments
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng bình luận đang phát triển')),
                    );
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: _formatCount(sharesCount),
                  onTap: () {
                    // TODO: Share post
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng chia sẻ đang phát triển')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? DesignTokens.error : DesignTokens.textSecondary,
            ),
            const SizedBox(width: 4),
            CustomText(
              text: label,
              variant: TextVariant.bodySmall,
              color: isActive ? DesignTokens.error : DesignTokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Widget _buildEmptyState(String title, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: DesignTokens.textLight,
            ),
            const SizedBox(height: 16),
            CustomText(
              text: title,
              variant: TextVariant.titleLarge,
              color: DesignTokens.textDark,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            CustomText(
              text: message,
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
