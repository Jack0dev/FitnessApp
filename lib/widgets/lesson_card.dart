import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import '../models/course_lesson_model.dart';
import 'custom_card.dart';
import 'custom_text.dart';

/// Widget để hiển thị thông tin bài học
class LessonCard extends StatelessWidget {
  final CourseLessonModel lesson;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDescription = lesson.description != null && lesson.description!.isNotEmpty;
    final hasImage = lesson.backgroundImageUrl != null;
    final hasExercises = lesson.exercises.isNotEmpty;

    return CustomCard(
      variant: CardVariant.white,
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DesignTokens.spacingMD),
        leading: _buildLessonNumber(),
        title: CustomText(
          text: lesson.title,
          variant: TextVariant.titleMedium,
          color: DesignTokens.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasDescription) ...[
              const SizedBox(height: DesignTokens.spacingXS),
              CustomText(
                text: lesson.description!,
                variant: TextVariant.bodyMedium,
                color: DesignTokens.textSecondary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: DesignTokens.spacingSM),
            Wrap(
              spacing: DesignTokens.spacingSM,
              runSpacing: DesignTokens.spacingXS,
              children: [
                if (hasImage) _buildInfoChip(
                  Icons.image,
                  'Có hình ảnh',
                  DesignTokens.info,
                ),
                if (hasExercises) _buildInfoChip(
                  Icons.fitness_center,
                  '${lesson.exercises.length} bài tập',
                  DesignTokens.primary,
                ),
              ],
            ),
          ],
        ),
        trailing: _buildActions(context),
        isThreeLine: hasDescription || hasImage || hasExercises,
      ),
    );
  }

  Widget _buildLessonNumber() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary,
            DesignTokens.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        boxShadow: DesignTokens.shadowSM,
      ),
      child: Center(
        child: CustomText(
          text: '${lesson.lessonNumber}',
          variant: TextVariant.titleLarge,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSM,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: DesignTokens.spacingXS),
          CustomText(
            text: text,
            variant: TextVariant.bodySmall,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
            ),
            child: IconButton(
              icon: Icon(Icons.edit, size: 20, color: DesignTokens.info),
              onPressed: onEdit,
              tooltip: 'Chỉnh sửa',
              padding: const EdgeInsets.all(8),
            ),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: DesignTokens.spacingXS),
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
            ),
            child: IconButton(
              icon: Icon(Icons.delete, size: 20, color: DesignTokens.error),
              onPressed: onDelete,
              tooltip: 'Xóa',
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ],
    );
  }
}








