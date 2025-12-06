import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';

enum CardVariant { default_, gymFresh, white }

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final CardVariant variant;
  final VoidCallback? onTap;
  final double? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.variant = CardVariant.gymFresh,
    this.onTap,
    this.borderRadius,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case CardVariant.default_:
        return DesignTokens.surface;
      case CardVariant.gymFresh:
        return DesignTokens.surfaceLight;
      case CardVariant.white:
        return DesignTokens.surface;
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case CardVariant.default_:
        return DesignTokens.borderDefault;
      case CardVariant.gymFresh:
        return DesignTokens.borderLight;
      case CardVariant.white:
        return DesignTokens.borderDefault;
    }
  }

  List<BoxShadow> _getShadow() {
    switch (variant) {
      case CardVariant.default_:
        return DesignTokens.shadowMD;
      case CardVariant.gymFresh:
        return DesignTokens.shadowGreenMD;
      case CardVariant.white:
        return DesignTokens.shadowSM;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? EdgeInsets.only(bottom: DesignTokens.spacingMD),
      padding: padding ?? EdgeInsets.all(DesignTokens.spacingMD),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(
          borderRadius ?? DesignTokens.radiusMD,
        ),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
        boxShadow: _getShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? DesignTokens.radiusMD,
        ),
        child: card,
      );
    }

    return card;
  }
}








