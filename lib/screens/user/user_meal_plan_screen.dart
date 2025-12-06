import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';

/// Màn hình kế hoạch ăn uống cho user
class UserMealPlanScreen extends StatefulWidget {
  const UserMealPlanScreen({super.key});

  @override
  State<UserMealPlanScreen> createState() => _UserMealPlanScreenState();
}

class _UserMealPlanScreenState extends State<UserMealPlanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.translate('meal_plan'),
      ),
      body: EmptyStateWidget(
        icon: Icons.restaurant_menu,
        title: context.translate('coming_soon'),
        subtitle: context.translate('meal_plan_feature_coming_soon'),
        iconColor: DesignTokens.primary,
      ),
    );
  }
}
