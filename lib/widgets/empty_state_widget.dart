import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';
import 'custom_button.dart';

/// Widget để hiển thị trạng thái rỗng với icon, message và action button
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor,
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
                color: (iconColor ?? DesignTokens.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? DesignTokens.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLG),
            CustomText(
              text: title,
              variant: TextVariant.headlineSmall,
              color: DesignTokens.textPrimary,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.spacingSM),
              CustomText(
                text: subtitle!,
                variant: TextVariant.bodyMedium,
                color: DesignTokens.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spacingLG),
              CustomButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
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








