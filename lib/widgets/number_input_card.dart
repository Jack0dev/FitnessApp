import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/design_tokens.dart';
import 'custom_card.dart';
import 'custom_text.dart';

class NumberInputCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final String? suffix;
  final String? Function(String?)? validator;
  final bool useExpanded;

  const NumberInputCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    this.suffix,
    this.validator,
    this.useExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = CustomCard(
      variant: CardVariant.gymFresh,
      padding: EdgeInsets.all(DesignTokens.spacingMD),
      margin: EdgeInsets.only(bottom: DesignTokens.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomText(
                  text: label,
                  variant: TextVariant.titleMedium,
                  color: DesignTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              color: DesignTokens.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: TextStyle(
                fontSize: 14,
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );

    return useExpanded ? Expanded(child: card) : card;
  }
}

