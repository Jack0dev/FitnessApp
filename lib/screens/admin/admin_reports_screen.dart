import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';

/// Màn hình báo cáo cho Admin
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.translate('reports'),
      ),
      body: EmptyStateWidget(
        icon: Icons.analytics,
        title: context.translate('coming_soon'),
        subtitle: context.translate('reports_feature_coming_soon'),
        iconColor: DesignTokens.primary,
      ),
    );
  }
}
