import 'package:flutter/material.dart';
import '../../services/chat/chat_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';

class PTChatScreen extends StatefulWidget {
  final String? studentId;
  final CourseModel? course;

  const PTChatScreen({
    super.key,
    this.studentId,
    this.course,
  });

  @override
  State<PTChatScreen> createState() => _PTChatScreenState();
}

class _PTChatScreenState extends State<PTChatScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _dataService = DataService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  UserModel? _student;
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      _currentUser = await _dataService.getUserData(user.id);

      if (widget.studentId != null) {
        _student = await _dataService.getUserData(widget.studentId!);
        await _loadMessages();
        // Mark messages as read
        if (widget.course != null) {
          await _chatService.markMessagesAsRead(
            userId: user.id,
            senderId: widget.studentId!,
            courseId: widget.course!.id,
          );
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (widget.studentId == null || widget.course == null) return;

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final messages = await _chatService.getMessages(
        userId1: user.id,
        userId2: widget.studentId!,
        courseId: widget.course!.id,
      );

      setState(() {
        _messages = messages.reversed.toList();
      });

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print('Failed to load messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (widget.studentId == null || widget.course == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    final success = await _chatService.sendMessage(
      senderId: user.id,
      receiverId: widget.studentId!,
      courseId: widget.course!.id,
      message: message,
    );

    if (success) {
      await _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: context.translate('failed_message'),
            variant: TextVariant.bodyMedium,
            color: Colors.white,
          ),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: _student?.displayName ?? context.translate('chat'),
              variant: TextVariant.titleLarge,
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            if (widget.course != null)
              CustomText(
                text: widget.course!.title,
                variant: TextVariant.bodySmall,
                color: DesignTokens.textSecondary,
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      CustomText(
                        text: '${context.translate('error')}: $_error',
                        variant: TextVariant.bodyMedium,
                        color: DesignTokens.error,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: context.translate('retry'),
                        icon: Icons.refresh,
                        onPressed: _loadData,
                        variant: ButtonVariant.primary,
                        size: ButtonSize.medium,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Messages List
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  CustomText(
                                    text: context.translate('no_messages'),
                                    variant: TextVariant.headlineSmall,
                                    color: DesignTokens.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  CustomText(
                                    text: context.translate('start_conversation'),
                                    variant: TextVariant.bodyMedium,
                                    color: DesignTokens.textLight,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMessages,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isMe = message['sender_id'] == _authService.currentUser?.id;
                                  final sender = message['sender'] as Map<String, dynamic>?;
                                  final senderName = sender?['display_name'] ?? 'Unknown';
                                  final senderPhoto = sender?['photo_url'] as String?;

                                  return Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (!isMe) ...[
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundImage: senderPhoto != null
                                                  ? NetworkImage(senderPhoto)
                                                  : null,
                                              child: senderPhoto == null
                                                  ? CustomText(
                                                      text: senderName[0].toUpperCase(),
                                                      variant: TextVariant.bodySmall,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? DesignTokens.accent
                                                    : DesignTokens.borderDefault,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (!isMe)
                                                    CustomText(
                                                      text: senderName,
                                                      variant: TextVariant.bodySmall,
                                                      color: DesignTokens.textSecondary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  if (!isMe) const SizedBox(height: 4),
                                                  CustomText(
                                                    text: message['message'] as String,
                                                    variant: TextVariant.bodyLarge,
                                                    color: isMe ? Colors.white : DesignTokens.textPrimary,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  CustomText(
                                                    text: _formatTime(message['created_at'] as String),
                                                    variant: TextVariant.bodySmall,
                                                    color: isMe ? Colors.white70 : DesignTokens.textLight,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 8),
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundImage: _currentUser?.photoURL != null
                                                  ? NetworkImage(_currentUser!.photoURL!)
                                                  : null,
                                              child: _currentUser?.photoURL == null
                                                  ? CustomText(
                                                      text: (_currentUser?.displayName ?? 'U')[0]
                                                          .toUpperCase(),
                                                      variant: TextVariant.bodySmall,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),

                    // Message Input
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: context.translate('type_message'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: DesignTokens.gradientAccent,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inHours > 0) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inMinutes > 0) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return AppLocalizations.translate('just_now');
      }
    } catch (e) {
      return '';
    }
  }
}

