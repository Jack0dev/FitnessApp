import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';

enum TextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  bodyLarge,
  bodyMedium,
  bodySmall,
}

class CustomText extends StatelessWidget {
  final String text;
  final TextVariant variant;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText({
    super.key,
    required this.text,
    this.variant = TextVariant.bodyMedium,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  TextStyle _getStyle() {
    TextStyle baseStyle;
    switch (variant) {
      case TextVariant.displayLarge:
        baseStyle = DesignTokens.displayLarge;
        break;
      case TextVariant.displayMedium:
        baseStyle = DesignTokens.displayMedium;
        break;
      case TextVariant.displaySmall:
        baseStyle = DesignTokens.displaySmall;
        break;
      case TextVariant.headlineLarge:
        baseStyle = DesignTokens.headlineLarge;
        break;
      case TextVariant.headlineMedium:
        baseStyle = DesignTokens.headlineMedium;
        break;
      case TextVariant.headlineSmall:
        baseStyle = DesignTokens.headlineSmall;
        break;
      case TextVariant.titleLarge:
        baseStyle = DesignTokens.titleLarge;
        break;
      case TextVariant.titleMedium:
        baseStyle = DesignTokens.titleMedium;
        break;
      case TextVariant.bodyLarge:
        baseStyle = DesignTokens.bodyLarge;
        break;
      case TextVariant.bodyMedium:
        baseStyle = DesignTokens.bodyMedium;
        break;
      case TextVariant.bodySmall:
        baseStyle = DesignTokens.bodySmall;
        break;
    }

    return baseStyle.copyWith(
      color: color ?? baseStyle.color,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getStyle(),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}








