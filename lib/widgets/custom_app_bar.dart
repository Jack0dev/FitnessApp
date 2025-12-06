import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor ?? DesignTokens.background,
      leading: leading ??
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: foregroundColor ?? DesignTokens.textSecondary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
      title: CustomText(
        text: title,
        variant: TextVariant.headlineMedium,
        color: foregroundColor ?? DesignTokens.textPrimary,
      ),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}








