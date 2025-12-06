import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';
import 'custom_card.dart';

class DatePickerInput extends StatelessWidget {
  final String label;
  final IconData? icon;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String Function(DateTime)? formatter;

  const DatePickerInput({
    super.key,
    required this.label,
    this.icon,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.formatter,
  });

  String _formatDate(DateTime date) {
    if (formatter != null) return formatter!(date);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: DesignTokens.primary,
              onPrimary: Colors.white,
              surface: DesignTokens.surface,
              onSurface: DesignTokens.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: DesignTokens.primary),
                const SizedBox(width: 8),
              ],
              CustomText(
                text: label,
                variant: TextVariant.titleMedium,
                color: DesignTokens.textPrimary,
              ),
            ],
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          child: CustomCard(
            variant: CardVariant.gymFresh,
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMD,
              vertical: DesignTokens.spacingMD,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: _formatDate(selectedDate),
                  variant: TextVariant.bodyLarge,
                  color: DesignTokens.textDark,
                  fontWeight: FontWeight.w500,
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: DesignTokens.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}








