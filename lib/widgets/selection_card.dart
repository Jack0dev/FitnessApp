import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_card.dart';
import 'custom_text.dart';

class SelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const SelectionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      variant: CardVariant.gymFresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: DesignTokens.primary),
              const SizedBox(width: 8),
              CustomText(
                text: label,
                variant: TextVariant.titleMedium,
                color: DesignTokens.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}








