import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_card.dart';
import 'custom_text.dart';

/// Widget để hiển thị thông tin học viên đã đăng ký
class StudentEnrollmentCard extends StatelessWidget {
  final String displayName;
  final String? email;
  final String? photoURL;
  final DateTime enrolledAt;
  final bool isPaid;
  final bool isLoading;
  final VoidCallback? onChatPressed;

  const StudentEnrollmentCard({
    super.key,
    required this.displayName,
    this.email,
    this.photoURL,
    required this.enrolledAt,
    required this.isPaid,
    this.isLoading = false,
    this.onChatPressed,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      variant: CardVariant.white,
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DesignTokens.spacingMD),
        leading: _buildAvatar(),
        title: CustomText(
          text: displayName,
          variant: TextVariant.titleMedium,
          color: DesignTokens.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email != null) ...[
              const SizedBox(height: DesignTokens.spacingXS),
              CustomText(
                text: email!,
                variant: TextVariant.bodyMedium,
                color: DesignTokens.textSecondary,
              ),
            ],
            const SizedBox(height: DesignTokens.spacingXS),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: DesignTokens.textSecondary,
                ),
                const SizedBox(width: DesignTokens.spacingXS),
                CustomText(
                  text: 'Đăng ký: ${_formatDate(enrolledAt)}',
                  variant: TextVariant.bodySmall,
                  color: DesignTokens.textSecondary,
                ),
              ],
            ),
          ],
        ),
        // ⭐ FIX: trailing gây overflow – bọc bằng FittedBox
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildTrailing(context),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (isLoading) {
      return SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaid ? DesignTokens.success : DesignTokens.warning,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
      backgroundColor: isPaid ? DesignTokens.success : DesignTokens.warning,
      child: photoURL == null
          ? Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: Colors.white,
              size: 28,
            )
          : null,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingSM,
            vertical: DesignTokens.spacingXS,
          ),
          decoration: BoxDecoration(
            color: isPaid
                ? DesignTokens.success.withOpacity(0.1)
                : DesignTokens.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            border: Border.all(
              color: isPaid
                  ? DesignTokens.success.withOpacity(0.3)
                  : DesignTokens.warning.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: CustomText(
            text: isPaid ? 'Đã thanh toán' : 'Chờ thanh toán',
            variant: TextVariant.bodySmall,
            color: isPaid ? DesignTokens.success : DesignTokens.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isPaid && onChatPressed != null) ...[
          const SizedBox(width: DesignTokens.spacingSM),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DesignTokens.accent, DesignTokens.secondary],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              boxShadow: DesignTokens.shadowSM,
            ),
            child: IconButton(
              icon: const Icon(Icons.chat, color: Colors.white, size: 20),
              onPressed: onChatPressed,
              tooltip: 'Nhắn tin',
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ],
    );
  }
}

