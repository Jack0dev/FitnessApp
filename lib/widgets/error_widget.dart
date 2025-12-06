import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';
import 'custom_button.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingLG),
              decoration: BoxDecoration(
                color: DesignTokens.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: DesignTokens.error,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLG),
            if (title != null) ...[
              CustomText(
                text: title!,
                variant: TextVariant.headlineMedium,
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingSM),
            ],
            CustomText(
              text: message,
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DesignTokens.spacingLG),
              CustomButton(
                label: 'Thử lại',
                icon: Icons.refresh,
                onPressed: onRetry,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}








