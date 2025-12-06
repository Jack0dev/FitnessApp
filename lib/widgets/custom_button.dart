import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';

enum ButtonVariant { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  double get _height {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.buttonHeightSM;
      case ButtonSize.medium:
        return DesignTokens.buttonHeightMD;
      case ButtonSize.large:
        return DesignTokens.buttonHeightLG;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  Color _getTextColor() {
    if (foregroundColor != null) return foregroundColor!;
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return DesignTokens.primary;
    }
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    switch (variant) {
      case ButtonVariant.primary:
        return DesignTokens.primary;
      case ButtonVariant.secondary:
        return DesignTokens.secondary;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color? _getBorderColor() {
    if (variant == ButtonVariant.outline) {
      return DesignTokens.primary;
    }
    return null;
  }

  TextStyle get _textStyle {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
        );
      case ButtonSize.medium:
        return DesignTokens.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
        );
      case ButtonSize.large:
        return DesignTokens.titleLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? SizedBox(
      width: _height * 0.4,
      height: _height * 0.4,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
      ),
    )
        : Row(
      mainAxisSize:
      isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: _getTextColor()),
          const SizedBox(width: 8),
        ],
        // ✅ FIX OVERFLOW: bọc Text trong Flexible + ellipsis
        Flexible(
          child: Text(
            label,
            style: _textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(),
        foregroundColor: _getTextColor(),
        elevation: 0,
        padding: _padding,
        minimumSize: Size(
          isFullWidth ? double.infinity : 0,
          _height,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          side: _getBorderColor() != null
              ? BorderSide(color: _getBorderColor()!, width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: buttonChild,
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}


