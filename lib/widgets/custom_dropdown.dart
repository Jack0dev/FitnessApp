import 'package:flutter/material.dart';
import '../core/constants/design_tokens.dart';
import 'custom_text.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final IconData? icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final String? hint;

  const CustomDropdown({
    super.key,
    required this.label,
    this.icon,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.hint,
  });

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
                color: DesignTokens.textDark,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            border: Border.all(
              color: DesignTokens.borderDefault,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              hoverColor: Colors.grey.withOpacity(0.05),
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<T>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: DesignTokens.primary,
                ),
                dropdownColor: Colors.white,
                hint: hint != null
                    ? Text(
                        hint!,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      )
                    : null,
                style: DesignTokens.bodyLarge.copyWith(
                  color: DesignTokens.textDark,
                  fontWeight: FontWeight.w500,
                ),
                items: items.map((item) {
                  // Wrap existing child with proper styling
                  Widget child = item.child;
                  if (child is Text) {
                    child = Text(
                      child.data ?? '',
                      style: DesignTokens.bodyLarge.copyWith(
                        color: DesignTokens.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return DropdownMenuItem<T>(
                    value: item.value,
                    child: child,
                  );
                }).toList(),
                onChanged: onChanged,
                validator: validator,
              decoration: InputDecoration(
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
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                isDense: true,
              ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

