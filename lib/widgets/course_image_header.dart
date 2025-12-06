import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';

/// Widget để hiển thị hình ảnh header của khóa học
class CourseImageHeader extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double borderRadius;

  const CourseImageHeader({
    super.key,
    this.imageUrl,
    this.height = 200,
    this.borderRadius = DesignTokens.radiusLG,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.primary.withOpacity(0.1),
                DesignTokens.secondary.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              size: 64,
              color: DesignTokens.textLight,
            ),
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.primary.withOpacity(0.1),
                  DesignTokens.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: DesignTokens.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}








