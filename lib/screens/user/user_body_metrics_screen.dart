import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';

/// Màn hình theo dõi chỉ số cơ thể cho user
class UserBodyMetricsScreen extends StatefulWidget {
  const UserBodyMetricsScreen({super.key});

  @override
  State<UserBodyMetricsScreen> createState() => _UserBodyMetricsScreenState();
}

class _UserBodyMetricsScreenState extends State<UserBodyMetricsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.translate('body_metrics'),
      ),
      body: EmptyStateWidget(
        icon: Icons.monitor_weight,
        title: context.translate('coming_soon'),
        subtitle: context.translate('body_metrics_feature_coming_soon'),
        iconColor: DesignTokens.primary,
      ),
    );
  }
}
