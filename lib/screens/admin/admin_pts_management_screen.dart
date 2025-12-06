import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user/data_service.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';

/// Màn hình quản lý Personal Trainers cho Admin
class AdminPTsManagementScreen extends StatefulWidget {
  const AdminPTsManagementScreen({super.key});

  @override
  State<AdminPTsManagementScreen> createState() => _AdminPTsManagementScreenState();
}

class _AdminPTsManagementScreenState extends State<AdminPTsManagementScreen> {
  final _dataService = DataService();
  List<UserModel> _pts = [];
  List<UserModel> _filteredPTs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPTs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterPTs();
  }

  Future<void> _loadPTs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _dataService.getAllUsers();
      final pts = users.where((user) => user.role == UserRole.pt).toList();
      
      setState(() {
        _pts = pts;
        _filteredPTs = pts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterPTs() {
    final query = _searchController.text;
    setState(() {
      _filteredPTs = _pts.where((pt) {
        final matchesSearch = query.isEmpty ||
            (pt.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (pt.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false);
        return matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.translate('manage_pts'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorDisplayWidget(
                  message: _error!,
                  onRetry: _loadPTs,
                )
              : Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingMD),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceLight,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomInput(
                        controller: _searchController,
                        label: context.translate('search'),
                        icon: Icons.search,
                      ),
                    ),

                    // Stats
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingMD),
                      color: DesignTokens.surfaceLight,
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: context.translate('total_pts'),
                              value: _pts.length.toString(),
                              color: DesignTokens.info,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: DesignTokens.borderDefault,
                          ),
                          Expanded(
                            child: _StatItem(
                              label: context.translate('active'),
                              value: _pts.where((pt) => pt.role == UserRole.pt).length.toString(),
                              color: DesignTokens.success,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // PTs List
                    Expanded(
                      child: _filteredPTs.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.fitness_center,
                              title: context.translate('no_pts_found'),
                              subtitle: context.translate('no_pts_match_search'),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadPTs,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(DesignTokens.spacingLG),
                                itemCount: _filteredPTs.length,
                                itemBuilder: (context, index) {
                                  final pt = _filteredPTs[index];
                                  return CustomCard(
                                    variant: CardVariant.white,
                                    margin: const EdgeInsets.only(bottom: DesignTokens.spacingMD),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(DesignTokens.spacingMD),
                                      leading: CircleAvatar(
                                        radius: 28,
                                        backgroundImage: pt.photoURL != null
                                            ? NetworkImage(pt.photoURL!)
                                            : null,
                                        backgroundColor: DesignTokens.primary.withOpacity(0.1),
                                        child: pt.photoURL == null
                                            ? Icon(
                                                Icons.person,
                                                color: DesignTokens.primary,
                                              )
                                            : null,
                                      ),
                                      title: CustomText(
                                        text: pt.displayName ?? pt.email ?? 'Unknown',
                                        variant: TextVariant.titleMedium,
                                        color: DesignTokens.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (pt.email != null) ...[
                                            const SizedBox(height: DesignTokens.spacingXS),
                                            CustomText(
                                              text: pt.email!,
                                              variant: TextVariant.bodySmall,
                                              color: DesignTokens.textSecondary,
                                            ),
                                          ],
                                          const SizedBox(height: DesignTokens.spacingXS),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: DesignTokens.spacingSM,
                                              vertical: DesignTokens.spacingXS,
                                            ),
                                            decoration: BoxDecoration(
                                              color: DesignTokens.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                                            ),
                                            child: CustomText(
                                              text: UserRole.pt.displayName,
                                              variant: TextVariant.bodySmall,
                                              color: DesignTokens.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomText(
          text: value,
          variant: TextVariant.displaySmall,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: DesignTokens.spacingXS),
        CustomText(
          text: label,
          variant: TextVariant.bodySmall,
          color: DesignTokens.textSecondary,
        ),
      ],
    );
  }
}
