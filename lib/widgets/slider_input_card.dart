import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_card.dart';
import 'custom_text.dart';

class SliderInputCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? formatter;
  final Color? color;

  const SliderInputCard({
    super.key,
    required this.label,
    this.icon,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.formatter,
    this.color,
  });

  String _formatValue(double val) {
    if (formatter != null) return formatter!(val);
    return val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final sliderColor = color ?? DesignTokens.primary;
    
    return CustomCard(
      variant: CardVariant.gymFresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sliderColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: sliderColor),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: CustomText(
                  text: label,
                  variant: TextVariant.titleMedium,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sliderColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomText(
                  text: _formatValue(value),
                  variant: TextVariant.titleMedium,
                  color: sliderColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: sliderColor,
            inactiveColor: sliderColor.withOpacity(0.2),
            label: _formatValue(value),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}








