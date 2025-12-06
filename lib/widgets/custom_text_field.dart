import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';

/// Custom Text Field Widget với viền đẹp và màu sắc rõ ràng
/// Hợp nhất CustomInput và CustomTextField thành một widget duy nhất
/// Có thể dùng chung cho nhiều page
class CustomTextField extends StatelessWidget {
  final String? label;
  final IconData? icon; // Alias cho prefixIcon để tương thích với CustomInput
  final IconData? prefixIcon;
  final String? suffixText;
  final String? helperText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final String? hintText;
  final String? hint; // Alias cho hintText để tương thích với CustomInput
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    this.label,
    this.icon,
    this.prefixIcon,
    this.suffixText,
    this.helperText,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.hintText,
    this.hint,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng icon nếu có, nếu không thì dùng prefixIcon
    final effectiveIcon = icon ?? prefixIcon;
    // Sử dụng hint nếu có, nếu không thì dùng hintText
    final effectiveHint = hint ?? hintText;
    // Label có thể là required (CustomInput) hoặc optional (CustomTextField)
    final effectiveLabel = label ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (effectiveLabel.isNotEmpty) ...[
          Row(
            children: [
              if (effectiveIcon != null) ...[
                Icon(
                  effectiveIcon,
                  size: icon != null ? 18 : 20,
                  color: icon != null ? DesignTokens.primary : DesignTokens.textSecondary,
                ),
                const SizedBox(width: 8),
              ],
              CustomText(
                text: effectiveLabel,
                variant: TextVariant.titleMedium,
                color: icon != null ? DesignTokens.textPrimary : DesignTokens.textDark,
                fontWeight: icon != null ? FontWeight.normal : FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: icon != null ? DesignTokens.surfaceLight : DesignTokens.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            border: Border.all(
              color: icon != null ? DesignTokens.borderLight : DesignTokens.borderDefault,
              width: 1.5,
            ),
            boxShadow: icon != null
                ? DesignTokens.shadowGreenMD
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            enabled: enabled,
            maxLines: maxLines,
            maxLength: maxLength,
            obscureText: obscureText,
            style: DesignTokens.bodyLarge.copyWith(
              color: DesignTokens.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: effectiveHint,
              hintStyle: DesignTokens.bodyMedium.copyWith(
                color: icon != null ? DesignTokens.textSecondary : DesignTokens.textLight,
              ),
              prefixIcon: effectiveIcon != null && icon == null
                  ? Icon(
                      effectiveIcon,
                      color: DesignTokens.textSecondary,
                      size: 20,
                    )
                  : null,
              suffixIcon: suffixIcon,
              suffixText: suffixText,
              suffixStyle: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              helperText: helperText,
              helperStyle: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.textLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: DesignTokens.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: DesignTokens.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: DesignTokens.error,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: icon != null ? DesignTokens.surfaceLight : DesignTokens.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: (effectiveIcon != null && icon == null) ? 12 : 16,
                vertical: maxLines != null && maxLines! > 1 ? 16 : 18,
              ),
              counterText: maxLength != null ? null : '',
            ),
          ),
        ),
        if (helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

/// Alias để tương thích với code cũ sử dụng CustomInput
@Deprecated('Use CustomTextField instead')
typedef CustomInput = CustomTextField;
