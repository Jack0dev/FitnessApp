import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../models/user_model.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import 'dart:async';

class StudentQRCodeScreen extends StatefulWidget {
  final String? courseId;

  const StudentQRCodeScreen({
    super.key,
    this.courseId,
  });

  @override
  State<StudentQRCodeScreen> createState() => _StudentQRCodeScreenState();
}

class _StudentQRCodeScreenState extends State<StudentQRCodeScreen> {
  final _authService = AuthService();
  final _dataService = DataService();
  UserModel? _userModel;
  bool _isLoading = true;
  Timer? _refreshTimer;
  String? _qrCodeData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Auto-refresh QR code every 30 seconds for security
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _generateQRCode();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userModel = await _dataService.getUserData(user.id);
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _isLoading = false;
          });
          _generateQRCode();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generateQRCode() {
    if (_userModel != null) {
      setState(() {
        _qrCodeData = _userModel!.generateQRCodeData(courseId: widget.courseId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'QR Code của tôi',
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _userModel == null
              ? ErrorDisplayWidget(
                  title: 'Lỗi',
                  message: 'Không thể tải thông tin người dùng',
                  onRetry: _loadUserData,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(DesignTokens.spacingLG),
                  child: Column(
                    children: [
                      // User Info Card
                      CustomCard(
                        variant: CardVariant.white,
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.spacingMD),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: _userModel!.photoURL != null
                                    ? NetworkImage(_userModel!.photoURL!)
                                    : null,
                                child: _userModel!.photoURL == null
                                    ? const Icon(Icons.person, size: 30)
                                    : null,
                              ),
                              const SizedBox(width: DesignTokens.spacingMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: _userModel!.displayName ?? 'Người dùng',
                                      variant: TextVariant.titleLarge,
                                      color: DesignTokens.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    if (_userModel!.email != null) ...[
                                      const SizedBox(height: 4),
                                      CustomText(
                                        text: _userModel!.email!,
                                        variant: TextVariant.bodySmall,
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: DesignTokens.spacingXL),

                      // QR Code Card
                      CustomCard(
                        variant: CardVariant.white,
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.spacingLG),
                          child: Column(
                            children: [
                              CustomText(
                                text: 'Đưa QR code này cho PT để chấm công',
                                variant: TextVariant.titleMedium,
                                color: DesignTokens.textPrimary,
                                fontWeight: FontWeight.bold,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingMD),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                  border: Border.all(color: DesignTokens.borderDefault, width: 2),
                                ),
                                child: _qrCodeData != null
                                    ? QrImageView(
                                        data: _qrCodeData!,
                                        version: QrVersions.auto,
                                        size: 250,
                                        backgroundColor: Colors.white,
                                      )
                                    : const CircularProgressIndicator(),
                              ),
                              const SizedBox(height: DesignTokens.spacingMD),
                              CustomText(
                                text: 'QR code tự động làm mới sau 30 giây',
                                variant: TextVariant.bodySmall,
                                color: DesignTokens.textSecondary,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: DesignTokens.spacingMD),

                      // Instructions
                      CustomCard(
                        variant: CardVariant.gymFresh,
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.spacingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: DesignTokens.primary, size: 20),
                                  const SizedBox(width: 8),
                                  CustomText(
                                    text: 'Hướng dẫn',
                                    variant: TextVariant.titleMedium,
                                    color: DesignTokens.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                              const SizedBox(height: DesignTokens.spacingSM),
                              _buildInstructionItem('1. Đưa màn hình này cho PT'),
                              _buildInstructionItem('2. PT sẽ quét QR code của bạn'),
                              _buildInstructionItem('3. Bạn sẽ nhận thông báo "Đã chấm công"'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: '• ',
            variant: TextVariant.bodyMedium,
            color: DesignTokens.textSecondary,
          ),
          Expanded(
            child: CustomText(
              text: text,
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


