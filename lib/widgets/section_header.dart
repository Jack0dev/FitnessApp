import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';
import 'custom_button.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: DesignTokens.primary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: title,
                      variant: TextVariant.titleLarge,
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      CustomText(
                        text: subtitle!,
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
        if (trailing != null)
          trailing!
        else if (actionLabel != null && onAction != null)
          CustomButton(
            label: actionLabel!,
            icon: actionIcon,
            onPressed: onAction,
            variant: ButtonVariant.outline,
            size: ButtonSize.small,
          ),
      ],
    );
  }
}
