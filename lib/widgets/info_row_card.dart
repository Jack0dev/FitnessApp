import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';

/// Widget để hiển thị một dòng thông tin với icon, label và value
class InfoRowCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;

  const InfoRowCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingSM),
            decoration: BoxDecoration(
              color: (iconColor ?? DesignTokens.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
            ),
            child: Icon(
              icon,
              size: DesignTokens.iconMD,
              color: iconColor ?? DesignTokens.primary,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: label,
                  variant: TextVariant.bodySmall,
                  color: DesignTokens.textSecondary,
                ),
                const SizedBox(height: DesignTokens.spacingXS),
                CustomText(
                  text: value,
                  variant: TextVariant.bodyLarge,
                  color: valueColor ?? DesignTokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}








