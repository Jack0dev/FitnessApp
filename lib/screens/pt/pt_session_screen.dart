import 'package:flutter/material.dart';
import '../../models/session_model.dart';
import '../../services/session/session_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/localization/app_localizations.dart';
import 'pt_session_form_screen.dart';
import 'pt_session_detail_screen.dart';

/// Screen for PT to manage training sessions
/// Replaces PTScheduleScreen - works with SessionModel instead of ScheduleModel
class PTSessionScreen extends StatefulWidget {
  final bool hideAppBar;
  final String? courseTitle;

  const PTSessionScreen({
    super.key,
    this.hideAppBar = false,
    this.courseTitle,
  });

  @override
  State<PTSessionScreen> createState() => _PTSessionScreenState();
}

class _PTSessionScreenState extends State<PTSessionScreen> {
  final _sessionService = SessionService();
  final _authService = AuthService();
  List<SessionModel> _sessions = [];
  List<SessionModel> _filteredSessions = [];
  bool _isLoading = true;
  String? _error;
  DateTime _currentWeekStart = _getStartOfWeek(DateTime.now());

  @override
  void initState() {
    super.initState();
    print('🚨 [PTSessionScreen] Nhận được Course Title: ${widget.courseTitle}');
    _loadSessions();
  }

  // Get start of week (Monday)
  static DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  // Get end of week (Sunday)
  DateTime _getEndOfWeek(DateTime startOfWeek) {
    return startOfWeek.add(const Duration(days: 6));
  }

  // Filter sessions for current week
  void _filterSessionsForWeek() {
    final endOfWeek = _getEndOfWeek(_currentWeekStart);
    final startOfWeekDate = DateTime(
      _currentWeekStart.year,
      _currentWeekStart.month,
      _currentWeekStart.day,
    );
    final endOfWeekDate = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
    ).add(const Duration(days: 1)); // Add 1 day to include the end date

    _filteredSessions = _sessions.where((session) {
      final sessionDate = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      return sessionDate.compareTo(startOfWeekDate) >= 0 &&
          sessionDate.compareTo(endOfWeekDate) < 0;
    }).toList();

    // Sort by date and time
    _filteredSessions.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      final aStart = a.startTime.hour * 60 + a.startTime.minute;
      final bStart = b.startTime.hour * 60 + b.startTime.minute;
      return aStart.compareTo(bStart);
    });
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _filterSessionsForWeek();
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _filterSessionsForWeek();
    });
  }

  String _formatWeekRange() {
    final endOfWeek = _getEndOfWeek(_currentWeekStart);
    final startStr =
        '${_currentWeekStart.day}/${_currentWeekStart.month}/${_currentWeekStart.year}';
    final endStr =
        '${endOfWeek.day}/${endOfWeek.month}/${endOfWeek.year}';
    return '$startStr đến $endStr';
  }

  // Group sessions by day
  Map<DateTime, List<SessionModel>> _groupSessionsByDay() {
    final grouped = <DateTime, List<SessionModel>>{};
    for (final session in _filteredSessions) {
      final dateKey = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(session);
    }
    return grouped;
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final sessions = await _sessionService.getTrainerSessions(user.id);
      setState(() {
        _sessions = sessions;
        _filterSessionsForWeek();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSession(SessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(
          text: 'Xóa session',
          variant: TextVariant.headlineSmall,
          color: DesignTokens.textPrimary,
        ),
        content: CustomText(
          text: 'Bạn có chắc chắn muốn xóa session này?',
          variant: TextVariant.bodyMedium,
          color: DesignTokens.textSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: CustomText(
              text: context.translate('cancel'),
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.error,
            ),
            child: CustomText(
              text: context.translate('delete'),
              variant: TextVariant.bodyMedium,
              color: DesignTokens.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _sessionService.deleteSession(session.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomText(
              text: 'Xóa session thành công',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
            ),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadSessions();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomText(
              text: 'Không thể xóa session',
              variant: TextVariant.bodyMedium,
              color: Colors.white,
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildBody() {
    return _isLoading
        ? const LoadingWidget()
        : _error != null
        ? ErrorDisplayWidget(
      title: context.translate('error'),
      message: _error!,
      onRetry: _loadSessions,
    )
        : RefreshIndicator(
      onRefresh: _loadSessions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab chọn Tuần
          _buildTopTabs(),
          // Bộ chọn tuần
          _buildWeekSelector(),
          const Divider(height: 1),
          // List sessions
          Expanded(
            child: _filteredSessions.isEmpty
                ? EmptyStateWidget(
              icon: Icons.calendar_today_outlined,
              title: 'Chưa có session nào trong tuần này',
              subtitle: widget.hideAppBar
                  ? 'Thêm session đầu tiên!'
                  : 'Nhấn nút + để tạo session mới',
              actionLabel:
              widget.hideAppBar ? 'Thêm session' : null,
              actionIcon:
              widget.hideAppBar ? Icons.add : null,
              onAction: widget.hideAppBar
                  ? () async {
                // BẮT BUỘC THÊM LOG NÀY
                print('*** CHECKPOINT 2: PTSessionScreen.courseTitle = ${widget.courseTitle}');

                final result =
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PTSessionFormScreen(initialTitle: widget.courseTitle,) // ✅ TRUYỀN TÊN KHÓA HỌC
                  ),
                );
                if (result == true) {
                  _loadSessions();
                }
              }
                  : null,
            )
                : _buildSessionList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.hideAppBar) {
      return body;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quản lý Sessions',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                  const PTSessionFormScreen(), // không dùng course ở đây
                ),
              );
              if (result == true) {
                _loadSessions();
              }
            },
            tooltip: 'Thêm session',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: context.translate('refresh'),
          ),
        ],
      ),
      body: body,
    );
  }

  // ============================================================
  // TAB: Tuần / Tháng
  // ============================================================
  Widget _buildTopTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildTab('Tuần', isActive: true),
          const SizedBox(width: 12),
          _buildTab('Tháng', isActive: false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {required bool isActive}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // TODO: Implement month view if needed
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? DesignTokens.primary : Colors.transparent,
            border: Border.all(color: DesignTokens.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: CustomText(
            text: label,
            variant: TextVariant.bodyLarge,
            color: isActive ? Colors.white : DesignTokens.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Bộ chọn tuần (mũi tên trái/phải)
  // ============================================================
  Widget _buildWeekSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToPreviousWeek,
            tooltip: 'Tuần trước',
          ),
          Expanded(
            child: Center(
              child: CustomText(
                text: _formatWeekRange(),
                variant: TextVariant.bodyLarge,
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _goToNextWeek,
                tooltip: 'Tuần sau',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // List sessions nhóm theo ngày
  // ============================================================
  Widget _buildSessionList() {
    final groupedSessions = _groupSessionsByDay();
    final sortedDays = groupedSessions.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sortedDays.length,
      itemBuilder: (context, dayIndex) {
        final day = sortedDays[dayIndex];
        final daySessions = groupedSessions[day]!..sort((a, b) {
          final aStart = a.startTime.hour * 60 + a.startTime.minute;
          final bStart = b.startTime.hour * 60 + b.startTime.minute;
          return aStart.compareTo(bStart);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDayHeader(_formatDayHeader(day)),
            ...daySessions.map((session) => _buildSessionCard(session)),
            if (dayIndex < sortedDays.length - 1)
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ============================================================
  // Header mỗi ngày
  // ============================================================
  Widget _buildDayHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: CustomText(
        text: text,
        variant: TextVariant.bodyLarge,
        color: DesignTokens.error,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatDayHeader(DateTime date) {
    final weekdays = [
      'Chủ nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7'
    ];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // Card session
  // ============================================================
  Widget _buildSessionCard(SessionModel session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: CustomCard(
        variant: CardVariant.white,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PTSessionDetailScreen(
                  session: session,
                ),
              ),
            );
            _loadSessions();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột Thời gian
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Thời gian',
                      variant: TextVariant.bodySmall,
                      color: DesignTokens.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      text: _formatTimeRange(session),
                      variant: TextVariant.bodyLarge,
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Cột Thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: session.title,
                        variant: TextVariant.bodyLarge,
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (session.notes != null &&
                          session.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        CustomText(
                          text: session.notes!,
                          variant: TextVariant.bodySmall,
                          color: DesignTokens.textSecondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PTSessionDetailScreen(
                              session: session,
                            ),
                          ),
                        );
                        _loadSessions();
                      },
                      tooltip: 'Xem chi tiết',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PTSessionFormScreen(
                              session: session,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadSessions();
                        }
                      },
                      tooltip: 'Chỉnh sửa',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteSession(session),
                      tooltip: 'Xóa',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(SessionModel session) {
    final startTime = session.startTime;
    final endTime = session.endTime;

    // Format: "7-11" or "7:00-11:00" depending on minutes
    if (startTime.minute == 0 && endTime.minute == 0) {
      return '${startTime.hour}–${endTime.hour}';
    } else {
      final startStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      return '$startStr–$endStr';
    }
  }
}
