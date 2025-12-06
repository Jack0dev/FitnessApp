import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth/auth_service.dart';
import '../../services/content/post_service.dart';
import '../../services/common/storage_service.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/widgets.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _authService = AuthService();
  PostService? _postService;
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  
  bool _isUploading = false;
  bool _isCreating = false;
  List<File> _selectedMedia = [];
  List<bool> _isMediaVideo = []; // Track which files are videos
  int _maxMediaCount = 10;

  @override
  void initState() {
    super.initState();
    _initializePostService();
  }

  void _initializePostService() {
    try {
      _postService = PostService();
    } catch (e) {
      print('PostService initialization failed: $e');
      _postService = null;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images != null && images.isNotEmpty) {
        final remainingSlots = _maxMediaCount - _selectedMedia.length;
        if (remainingSlots <= 0) {
          _showError('Bạn chỉ có thể thêm tối đa $_maxMediaCount ảnh/video');
          return;
        }

        final imagesToAdd = images.take(remainingSlots).toList();
        setState(() {
          for (var image in imagesToAdd) {
            _selectedMedia.add(File(image.path));
            _isMediaVideo.add(false);
          }
        });
      }
    } catch (e) {
      _showError('Lỗi khi chọn ảnh: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        if (_selectedMedia.length >= _maxMediaCount) {
          _showError('Bạn chỉ có thể thêm tối đa $_maxMediaCount ảnh/video');
          return;
        }

        setState(() {
          _selectedMedia.add(File(video.path));
          _isMediaVideo.add(true);
        });
      }
    } catch (e) {
      _showError('Lỗi khi chọn video: ${e.toString()}');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      // Show dialog to choose between camera and video
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn loại'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Quay video'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        ),
      );

      if (choice == null) return;

      XFile? media;
      bool isVideo = false;

      if (choice == 'photo') {
        media = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
      } else if (choice == 'video') {
        media = await _imagePicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 10),
        );
        isVideo = true;
      }

      if (media != null) {
        if (_selectedMedia.length >= _maxMediaCount) {
          _showError('Bạn chỉ có thể thêm tối đa $_maxMediaCount ảnh/video');
          return;
        }

        final filePath = media.path;
        setState(() {
          _selectedMedia.add(File(filePath));
          _isMediaVideo.add(isVideo);
        });
      }
    } catch (e) {
      _showError('Lỗi khi chụp ảnh/quay video: ${e.toString()}');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      _isMediaVideo.removeAt(index);
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<List<String>?> _uploadMediaFiles() async {
    final user = _authService.currentUser;
    if (user == null) {
      _showError('Vui lòng đăng nhập');
      return null;
    }

    if (_selectedMedia.isEmpty) {
      return [];
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadedUrls = <String>[];

      for (int i = 0; i < _selectedMedia.length; i++) {
        final file = _selectedMedia[i];
        final isVideo = _isMediaVideo[i];

        String? url;
        if (isVideo) {
          url = await _storageService.uploadVideo(
            videoFile: file,
            userId: user.id,
            folder: 'post_media',
          );
        } else {
          url = await _storageService.uploadImage(
            imageFile: file,
            userId: user.id,
            folder: 'post_media',
          );
        }

        if (url != null) {
          uploadedUrls.add(url);
        } else {
          // Upload failed for this file, continue with others
          _showError('Không thể upload một số file. Vui lòng thử lại.');
        }
      }

      setState(() {
        _isUploading = false;
      });

      // Return uploaded URLs, even if some failed
      return uploadedUrls.isNotEmpty ? uploadedUrls : null;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showError('Lỗi khi upload: ${e.toString()}');
      return null;
    }
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    
    if (content.isEmpty && _selectedMedia.isEmpty) {
      _showError('Vui lòng nhập nội dung hoặc thêm ảnh/video');
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _showError('Vui lòng đăng nhập');
      return;
    }

    if (_postService == null) {
      _showError('Dịch vụ chưa sẵn sàng. Vui lòng thử lại sau.');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Upload media files first
      List<String>? uploadedUrls;
      if (_selectedMedia.isNotEmpty) {
        uploadedUrls = await _uploadMediaFiles();
        if (uploadedUrls == null) {
          setState(() {
            _isCreating = false;
          });
          return;
        }
      }

      // Create post
      final postId = await _postService!.createPost(
        userId: user.id,
        content: content.isEmpty ? 'Đã đăng một bài viết' : content,
        imageUrls: (uploadedUrls != null && uploadedUrls.isNotEmpty) ? uploadedUrls : null,
      );

      if (postId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng bài thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        _showError('Không thể tạo bài viết. Vui lòng thử lại.');
      }
    } catch (e) {
      _showError('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: DesignTokens.primary),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: DesignTokens.primary),
                title: const Text('Chọn video từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: DesignTokens.primary),
                title: const Text('Chụp ảnh / Quay video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isUploading || _isCreating;

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Tạo bài viết',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _createPost,
              child: const CustomText(
                text: 'Đăng',
                variant: TextVariant.titleMedium,
                color: DesignTokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Content Input
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: DesignTokens.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: DesignTokens.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: _authService.currentUser?.userMetadata?['display_name'] as String? ?? 'User',
                              variant: TextVariant.titleMedium,
                              color: DesignTokens.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                            CustomText(
                              text: 'Đang chia sẻ với mọi người',
                              variant: TextVariant.bodySmall,
                              color: DesignTokens.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Text Input
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì?',
                      hintStyle: TextStyle(color: DesignTokens.textLight),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: DesignTokens.textDark,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Media Preview Grid
                  if (_selectedMedia.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        final file = _selectedMedia[index];
                        final isVideo = _isMediaVideo[index];
                        
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: isVideo
                                  ? Container(
                                      color: Colors.grey[300],
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Try to show video thumbnail if possible
                                          Image.file(
                                            file,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.video_library, size: 40, color: Colors.grey),
                                            ),
                                          ),
                                          Container(
                                            color: Colors.black.withOpacity(0.4),
                                            child: const Center(
                                              child: Icon(
                                                Icons.play_circle_filled,
                                                color: Colors.white,
                                                size: 50,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeMedia(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (isVideo)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'VIDEO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: DesignTokens.borderDefault,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _showMediaPicker,
                    icon: const Icon(Icons.add_photo_alternate, size: 20),
                    label: Text(
                      'Thêm ảnh/video (${_selectedMedia.length}/$_maxMediaCount)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: DesignTokens.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

