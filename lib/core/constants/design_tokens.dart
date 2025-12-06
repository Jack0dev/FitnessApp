import 'package:flutter/material.dart';

/// Design Tokens từ Figma
/// Cập nhật các giá trị này theo design trong Figma
class DesignTokens {
  // ========== Colors ==========
  // Primary colors - Gym fresh theme
  static const Color primary = Color(0xFF10B981); // Fresh green
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFF6366F1); // Indigo
  static const Color background = Color(0xFFFFFEFE); // Bright white
  static const Color surface = Color(0xFFFFFEFE); // Bright white
  static const Color surfaceLight = Color(0xFFF0FDF4); // Light green background
  
  // Text colors - Light theme
  static const Color textPrimary = Color(0xFF475569); // Slate 600
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400
  static const Color textDark = Color(0xFF334155); // Slate 700
  
  // Status colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Border colors
  static const Color borderLight = Color(0xFFD1FAE5); // Light green border
  static const Color borderDefault = Color(0xFFE2E8F0); // Slate 200
  
  // Shadow colors
  static const Color shadowGreen = Color(0xFF10B981);
  static const Color shadowDefault = Colors.black;

  // Gradient colors
  static const List<Color> gradientPrimary = [primary, secondary];
  static const List<Color> gradientAccent = [accent, Color(0xFF8B5CF6)];
  static const List<Color> gradientAccentExtended = [accent, Color(0xFF8B5CF6), Color(0xFFEC4899)]; // 3-color gradient
  static const List<Color> gradientInfo = [info, Color(0xFF60A5FA)];
  static const List<Color> gradientSuccess = [success, Color(0xFF34D399)];
  static const List<Color> gradientWarning = [warning, Color(0xFFFBBF24)];
  static const List<Color> gradientError = [error, Color(0xFFF87171)];
  static const List<Color> gradientPurple = [Color(0xFF8B5CF6), Color(0xFFA78BFA)];
  static const List<Color> gradientTeal = [Color(0xFF14B8A6), Color(0xFF5EEAD4)];
  static const List<Color> gradientIndigo = [accent, Color(0xFF818CF8)];
  static const List<Color> gradientAmber = [warning, Color(0xFFFCD34D)];

  // ========== Spacing ==========
  /// Extra small spacing: 4px
  static const double spacingXS = 4.0;
  
  /// Small spacing: 8px
  static const double spacingSM = 8.0;
  
  /// Medium spacing: 16px
  static const double spacingMD = 16.0;
  
  /// Large spacing: 24px
  static const double spacingLG = 24.0;
  
  /// Extra large spacing: 32px
  static const double spacingXL = 32.0;
  
  /// Extra extra large spacing: 48px
  static const double spacingXXL = 48.0;

  // Spacing map for easy access
  static const Map<String, double> spacing = {
    'xs': spacingXS,
    'sm': spacingSM,
    'md': spacingMD,
    'lg': spacingLG,
    'xl': spacingXL,
    'xxl': spacingXXL,
  };

  // ========== Border Radius ==========
  /// Small border radius: 8px
  static const double radiusSM = 8.0;
  
  /// Medium border radius: 12px
  static const double radiusMD = 12.0;
  
  /// Large border radius: 16px
  static const double radiusLG = 16.0;
  
  /// Extra large border radius: 20px
  static const double radiusXL = 20.0;
  
  /// Full circle: 999px
  static const double radiusFull = 999.0;

  // Border radius map
  static const Map<String, double> borderRadius = {
    'sm': radiusSM,
    'md': radiusMD,
    'lg': radiusLG,
    'xl': radiusXL,
    'full': radiusFull,
  };

  // ========== Typography ==========
  /// Display Large: 32px, Bold
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -1,
    color: textPrimary,
  );

  /// Display Medium: 28px, Bold
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  /// Display Small: 24px, Bold
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  /// Headline Large: 22px, SemiBold
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  /// Headline Medium: 20px, SemiBold
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  /// Headline Small: 18px, SemiBold
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Title Large: 16px, SemiBold
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Title Medium: 14px, SemiBold
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Body Large: 16px, Regular
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  /// Body Medium: 14px, Regular
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  /// Body Small: 12px, Regular
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textLight,
  );
  
  // Updated typography with lighter colors
  static TextStyle get bodyLargeLight => bodyLarge.copyWith(color: textPrimary);
  static TextStyle get bodyMediumLight => bodyMedium.copyWith(color: textSecondary);
  static TextStyle get titleMediumLight => titleMedium.copyWith(color: textPrimary);

  // Typography map
  static const Map<String, TextStyle> typography = {
    'displayLarge': displayLarge,
    'displayMedium': displayMedium,
    'displaySmall': displaySmall,
    'headlineLarge': headlineLarge,
    'headlineMedium': headlineMedium,
    'headlineSmall': headlineSmall,
    'titleLarge': titleLarge,
    'titleMedium': titleMedium,
    'bodyLarge': bodyLarge,
    'bodyMedium': bodyMedium,
    'bodySmall': bodySmall,
  };

  // ========== Shadows ==========
  /// Small shadow
  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: shadowDefault.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium shadow
  static List<BoxShadow> shadowMD = [
    BoxShadow(
      color: shadowDefault.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Large shadow
  static List<BoxShadow> shadowLG = [
    BoxShadow(
      color: shadowDefault.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  /// Green shadow for gym fresh theme
  static List<BoxShadow> shadowGreenMD = [
    BoxShadow(
      color: shadowGreen.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // Shadow map
  static Map<String, List<BoxShadow>> shadows = {
    'sm': shadowSM,
    'md': shadowMD,
    'lg': shadowLG,
  };

  // ========== Icon Sizes ==========
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // ========== Button Heights ==========
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 48.0;
  static const double buttonHeightLG = 56.0;

  // ========== Input Heights ==========
  static const double inputHeightSM = 40.0;
  static const double inputHeightMD = 48.0;
  static const double inputHeightLG = 56.0;
}

/// Helper class để sử dụng Design Tokens dễ dàng hơn
class DesignTokensHelper {
  /// Get spacing value
  static double spacing(String size) {
    return DesignTokens.spacing[size] ?? DesignTokens.spacingMD;
  }

  /// Get border radius
  static double borderRadius(String size) {
    return DesignTokens.borderRadius[size] ?? DesignTokens.radiusMD;
  }

  /// Get typography style
  static TextStyle typography(String style) {
    return DesignTokens.typography[style] ?? DesignTokens.bodyMedium;
  }

  /// Get shadow
  static List<BoxShadow> shadow(String size) {
    return DesignTokens.shadows[size] ?? DesignTokens.shadowMD;
  }
}



