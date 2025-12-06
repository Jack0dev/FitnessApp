import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/common/location_service.dart';
import '../../services/attendance/session_attendance_service.dart';
import '../../services/session/session_service.dart';
import '../../services/auth/auth_service.dart';
import '../../models/session_model.dart';
import '../../models/session_qr_model.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import '../../config/gym_location_config.dart';


class PTAttendanceScreen extends StatefulWidget {
  final SessionModel? session;

  const PTAttendanceScreen({
    super.key,
    this.session,
  });

  @override
  State<PTAttendanceScreen> createState() => _PTAttendanceScreenState();
}

class _PTAttendanceScreenState extends State<PTAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final _sessionAttendanceService = SessionAttendanceService();
  final _sessionService = SessionService();
  final _authService = AuthService();
  final _mobileScannerController = MobileScannerController();
  final _locationService = LocationService(); // 👈 THÊM DÒNG NÀY


  SessionModel? _selectedSession;
  List<SessionModel> _sessions = [];
  List<Map<String, dynamic>> _attendanceList = [];
  bool _isLoading = false;
  bool _isScanning = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedSession = widget.session;
    _loadSessions();
    if (_selectedSession != null) {
      _loadAttendanceList();
    }
  }

  @override
  void dispose() {
    _mobileScannerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final sessions = await _sessionService.getTrainerSessions(user.id);
        if (mounted) {
          setState(() {
            _sessions = sessions;
            _isLoading = false;
            if (_selectedSession == null && sessions.isNotEmpty) {
              final today = DateTime.now();
              _selectedSession = sessions.firstWhere(
                    (s) =>
                s.date.year == today.year &&
                    s.date.month == today.month &&
                    s.date.day == today.day,
                orElse: () => sessions.first,
              );
              if (_selectedSession != null) {
                _loadAttendanceList();
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText(
              text: 'Lỗi: $e',
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

  Future<void> _loadAttendanceList() async {
    if (_selectedSession == null) return;

    setState(() => _isLoading = true);
    try {
      final attendance = await _sessionAttendanceService
          .getSessionAttendanceWithUsers(_selectedSession!.id);
      if (mounted) {
        setState(() {
          _attendanceList = attendance;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleQRCodeScan(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) {
      return;
    }
    final rawValue = barcodes.first.rawValue!;

    if (_selectedSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            text: 'Vui lòng chọn một buổi tập',
            variant: TextVariant.bodyMedium,
            color: Colors.white,
          ),
          backgroundColor: DesignTokens.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isScanning = false;
    });

    // 👇👇👇  ĐOẠN MỚI: LẤY GPS + ĐỐI CHIẾU VỚI TỌA ĐỘ PHÒNG GYM
    final position = await _locationService.getCurrentPosition();

    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            text:
            'Không thể lấy vị trí. Hãy bật GPS và cho phép ứng dụng truy cập vị trí để điểm danh.',
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
      // Cho phép quét lại sau 2 giây
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isScanning = true);
        }
      });
      return;
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      GymLocationConfig.gymLatitude,
      GymLocationConfig.gymLongitude,
    );

    if (distance > GymLocationConfig.maxDistanceMeters) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text:
            'Bạn đang ở ngoài khu vực phòng gym (cách khoảng ${distance.toStringAsFixed(1)}m). Không thể điểm danh.',
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
      // Cho phép quét lại
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isScanning = true);
        }
      });
      return;
    }

    final qrData = _sessionAttendanceService.parseSessionQRCode(rawValue);

    if (qrData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            text: 'Mã QR không hợp lệ',
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
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isScanning = true);
        }
      });
      return;
    }

    final userId = qrData['userId'] as String?;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            text: 'Mã QR không chứa thông tin học viên',
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
      return;
    }

    final result = await _sessionAttendanceService.markAttendanceBySession(
      sessionId: _selectedSession!.id,
      userId: userId,
      qrToken: qrData['token'] as String?,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: result['message'] as String,
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
      _loadAttendanceList();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isScanning = true);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text:
            result['message'] as String? ?? 'Điểm danh thất bại',
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
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isScanning = true);
        }
      });
    }
  }

  String _formatSessionTime(SessionModel session) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startStr =
        '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${session.endTime.hour.toString().padLeft(2, '0')}:${session.endTime.minute.toString().padLeft(2, '0')}';
    return '${dateFormat.format(session.date)} • $startStr - $endStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        actions: [
          if (_selectedSession != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAttendanceList,
              tooltip: 'Làm mới',
            ),
        ],
      ),
      body: _isLoading && _sessions.isEmpty
          ? const LoadingWidget()
          : Column(
        children: [
          Container(
            padding:
            const EdgeInsets.all(DesignTokens.spacingMD),
            color: DesignTokens.surface,
            child: Column(
              children: [
                CustomDropdown<SessionModel>(
                  label: 'Buổi tập',
                  value: _selectedSession,
                  hint: 'Chọn một buổi tập',
                  items: _sessions.map((session) {
                    return DropdownMenuItem(
                      value: session,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: session.title,
                            variant: TextVariant.bodyLarge,
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          CustomText(
                            text: _formatSessionTime(session),
                            variant: TextVariant.bodySmall,
                            color: DesignTokens.textSecondary,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (session) {
                    setState(() {
                      _selectedSession = session;
                      _attendanceList = [];
                    });
                    if (session != null) {
                      _loadAttendanceList();
                    }
                  },
                ),
              ],
            ),
          ),
          if (_selectedSession != null)
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.qr_code),
                  text: 'Mã QR',
                ),
                Tab(
                  icon: Icon(Icons.qr_code_scanner),
                  text: 'Quét',
                ),
                Tab(
                  icon: Icon(Icons.list),
                  text: 'Danh sách',
                ),
              ],
            ),
          Expanded(
            child: _selectedSession == null
                ? Center(
              child: EmptyStateWidget(
                icon: Icons.calendar_today,
                title: 'Chưa chọn buổi tập',
                subtitle:
                'Vui lòng chọn một buổi tập để tiếp tục',
              ),
            )
                : TabBarView(
              controller: _tabController,
              children: [
                _buildQRCodeTab(),
                _buildScannerTab(),
                _buildAttendanceListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab() {
    return FutureBuilder<SessionQRModel?>(
      future: _sessionAttendanceService
          .getActiveSessionQR(_selectedSession!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Lỗi khi tải mã QR',
                  subtitle:
                  'Đã xảy ra lỗi khi tải mã QR. Vui lòng thử lại.',
                ),
                const SizedBox(
                    height: DesignTokens.spacingMD),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final qrModel = snapshot.data;
        final qrData = qrModel?.token ?? '';

        if (qrData.isEmpty) {
          return const Center(
            child: EmptyStateWidget(
              icon: Icons.qr_code_2,
              title: 'Không có mã QR',
              subtitle:
              'Không thể tạo hoặc lấy mã QR cho buổi tập này.',
            ),
          );
        }

        return SingleChildScrollView(
          padding:
          const EdgeInsets.all(DesignTokens.spacingLG),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CustomText(
                  text: 'Cho học viên quét mã này để điểm danh',
                  variant: TextVariant.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                    height: DesignTokens.spacingLG),
                Container(
                  padding: const EdgeInsets.all(
                      DesignTokens.spacingMD),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMD),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                ),
                const SizedBox(
                    height: DesignTokens.spacingMD),
                const CustomText(
                  text: 'Mã sẽ tự động làm mới.',
                  variant: TextVariant.bodyMedium,
                  color: DesignTokens.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScannerTab() {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _mobileScannerController,
          onDetect: _isScanning ? _handleQRCodeScan : null,
        ),
        if (_isScanning)
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: DesignTokens.primary,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(
                  DesignTokens.radiusMD),
            ),
          ),
        Positioned(
          bottom: DesignTokens.spacingLG,
          child: FloatingActionButton(
            onPressed: () =>
                setState(() => _isScanning = !_isScanning),
            child: Icon(
              _isScanning ? Icons.stop : Icons.play_arrow,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceListTab() {
    if (_isLoading) return const LoadingWidget();

    if (_attendanceList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people,
        title: 'Chưa có ai điểm danh',
        subtitle:
        'Danh sách sẽ được cập nhật khi có học viên điểm danh thành công.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendanceList,
      child: ListView.builder(
        itemCount: _attendanceList.length,
        itemBuilder: (context, index) {
          final attendance = _attendanceList[index];
          final user =
          attendance['user'] as Map<String, dynamic>?;
          final attendanceTime =
          attendance['attendedAt'] as DateTime?;

          if (user == null) {
            return const ListTile(
              title: Text('Học viên không xác định'),
            );
          }

          return ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage:
              (user['avatarUrl'] as String?) != null
                  ? NetworkImage(
                user['avatarUrl'] as String,
              )
                  : null,
              child:
              (user['avatarUrl'] as String?) == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: CustomText(
              text: user['name'] as String? ?? 'Chưa có tên',
              variant: TextVariant.bodyLarge,
              fontWeight: FontWeight.w600,
            ),
            subtitle: attendanceTime != null
                ? CustomText(
              text:
              'Điểm danh lúc: ${DateFormat('HH:mm:ss').format(attendanceTime)}',
              variant: TextVariant.bodyMedium,
              color: DesignTokens.textSecondary,
            )
                : null,
            trailing: const Icon(
              Icons.check_circle,
              color: DesignTokens.success,
            ),
          );
        },
      ),
    );
  }
}
