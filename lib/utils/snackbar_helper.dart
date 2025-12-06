import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import '../widgets/custom_text.dart';

/// Helper class để hiển thị snackbar messages một cách nhất quán
class SnackbarHelper {
  /// Hiển thị snackbar thành công
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
          text: message,
          variant: TextVariant.bodyMedium,
          color: Colors.white,
        ),
        backgroundColor: DesignTokens.success,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Hiển thị snackbar lỗi
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
          text: message,
          variant: TextVariant.bodyMedium,
          color: Colors.white,
        ),
        backgroundColor: DesignTokens.error,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Hiển thị snackbar cảnh báo
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
          text: message,
          variant: TextVariant.bodyMedium,
          color: Colors.white,
        ),
        backgroundColor: DesignTokens.warning,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Hiển thị snackbar thông tin
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
          text: message,
          variant: TextVariant.bodyMedium,
          color: Colors.white,
        ),
        backgroundColor: DesignTokens.info,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
