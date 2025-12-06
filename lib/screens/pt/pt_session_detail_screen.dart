import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/session_model.dart';
import '../../models/trainer_attendance_model.dart';
import '../../models/session_qr_model.dart';
import '../../services/attendance/session_attendance_service.dart';
import '../../services/common/location_service.dart';
import '../../services/auth/auth_service.dart';
import '../../config/gym_location_config.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';

/// Screen for PT to view session details with check-in/check-out and QR code generation
class PTSessionDetailScreen extends StatefulWidget {
  final SessionModel session;

  const PTSessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  State<PTSessionDetailScreen> createState() => _PTSessionDetailScreenState();
}

class _PTSessionDetailScreenState extends State<PTSessionDetailScreen> {
  final _attendanceService = SessionAttendanceService();
  final _locationService = LocationService();
  final _authService = AuthService();

  TrainerAttendanceModel? _trainerAttendance;
  SessionQRModel? _activeQR;
  bool _isLoading = true;
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  bool _isGeneratingQR = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Load trainer attendance
      await _loadTrainerAttendance();

      // Load active QR code
      await _loadActiveQR();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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

  Future<void> _loadTrainerAttendance() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final attendance = await _attendanceService.getTrainerAttendance(
        sessionId: widget.session.id,
        trainerId: user.id,
      );

      setState(() {
        _trainerAttendance = attendance;
      });
    } catch (e) {
      print('Failed to load trainer attendance: $e');
    }
  }

  Future<void> _loadActiveQR() async {
    try {
      final qr = await _attendanceService.getActiveSessionQR(widget.session.id);
      setState(() {
        _activeQR = qr;
      });
    } catch (e) {
      print('Failed to load active QR: $e');
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _isCheckingIn = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get GPS location
      final location = await _locationService.getCurrentLocation();
      double? latitude = location?['latitude'];
      double? longitude = location?['longitude'];

      if (location == null) {
        // Show warning but still allow check-in without location
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: CustomText(
                text: 'Không lấy được vị trí',
                variant: TextVariant.headlineSmall,
                color: DesignTokens.textPrimary,
              ),
              content: CustomText(
                text: 'Không thể lấy được vị trí GPS. Bạn có muốn tiếp tục check-in mà không có vị trí không?',
                variant: TextVariant.bodyMedium,
                color: DesignTokens.textSecondary,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: CustomText(
                    text: 'Hủy',
                    variant: TextVariant.bodyMedium,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: CustomText(
                    text: 'Tiếp tục',
                    variant: TextVariant.bodyMedium,
                    color: DesignTokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

          if (proceed != true) {
            setState(() {
              _isCheckingIn = false;
            });
            return;
          }
        }
      } else {
        // Check if location is within gym radius
        final isWithinRadius = GymLocationConfig.isWithinRadius(latitude!, longitude!);
        final distance = GymLocationConfig.getDistanceFromGym(latitude, longitude);
        
        if (!isWithinRadius) {
          // Show warning that location is outside gym
          if (mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: CustomText(
                  text: 'Vị trí ngoài phòng gym',
                  variant: TextVariant.headlineSmall,
                  color: DesignTokens.warning,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Vị trí hiện tại của bạn cách phòng gym khoảng ${distance?.toStringAsFixed(0) ?? 'N/A'} mét.',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textPrimary,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      text: 'Bạn có muốn tiếp tục check-in không?',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textSecondary,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: CustomText(
                      text: 'Hủy',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: CustomText(
                      text: 'Tiếp tục',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );

            if (proceed != true) {
              setState(() {
                _isCheckingIn = false;
              });
              return;
            }
          }
        }
      }

      // Perform check-in
      final result = await _attendanceService.checkInTrainer(
        sessionId: widget.session.id,
        trainerId: user.id,
        latitude: latitude,
        longitude: longitude,
      );

      if (mounted) {
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
          await _loadTrainerAttendance();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: result['message'] as String? ?? 'Check-in thất bại',
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
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get GPS location
      final location = await _locationService.getCurrentLocation();
      double? latitude = location?['latitude'];
      double? longitude = location?['longitude'];

      if (location == null) {
        // Show warning but still allow check-out without location
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: CustomText(
                text: 'Không lấy được vị trí',
                variant: TextVariant.headlineSmall,
                color: DesignTokens.textPrimary,
              ),
              content: CustomText(
                text: 'Không thể lấy được vị trí GPS. Bạn có muốn tiếp tục check-out mà không có vị trí không?',
                variant: TextVariant.bodyMedium,
                color: DesignTokens.textSecondary,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: CustomText(
                    text: 'Hủy',
                    variant: TextVariant.bodyMedium,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: CustomText(
                    text: 'Tiếp tục',
                    variant: TextVariant.bodyMedium,
                    color: DesignTokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

          if (proceed != true) {
            setState(() {
              _isCheckingOut = false;
            });
            return;
          }
        }
      } else {
        // Check if location is within gym radius
        final isWithinRadius = GymLocationConfig.isWithinRadius(latitude!, longitude!);
        final distance = GymLocationConfig.getDistanceFromGym(latitude, longitude);
        
        if (!isWithinRadius) {
          // Show warning that location is outside gym
          if (mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: CustomText(
                  text: 'Vị trí ngoài phòng gym',
                  variant: TextVariant.headlineSmall,
                  color: DesignTokens.warning,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Vị trí hiện tại của bạn cách phòng gym khoảng ${distance?.toStringAsFixed(0) ?? 'N/A'} mét.',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textPrimary,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      text: 'Bạn có muốn tiếp tục check-out không?',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textSecondary,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: CustomText(
                      text: 'Hủy',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: CustomText(
                      text: 'Tiếp tục',
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );

            if (proceed != true) {
              setState(() {
                _isCheckingOut = false;
              });
              return;
            }
          }
        }
      }

      // Perform check-out
      final result = await _attendanceService.checkOutTrainer(
        sessionId: widget.session.id,
        trainerId: user.id,
        latitude: latitude,
        longitude: longitude,
      );

      if (mounted) {
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
          await _loadTrainerAttendance();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: result['message'] as String? ?? 'Check-out thất bại',
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
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  Future<void> _handleGenerateQR() async {
    setState(() {
      _isGeneratingQR = true;
    });

    try {
      // Generate QR code with 2 hours expiration
      final qr = await _attendanceService.generateSessionQR(
        widget.session.id,
        expiration: const Duration(hours: 2),
      );

      if (mounted) {
        if (qr != null) {
          setState(() {
            _activeQR = qr;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const CustomText(
                text: 'Tạo mã QR thành công',
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const CustomText(
                text: 'Tạo mã QR thất bại',
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
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingQR = false;
        });
      }
    }
  }

  String _formatTimeRange() {
    final startTime = widget.session.startTime;
    final endTime = widget.session.endTime;
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  String _formatDate() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return dateFormat.format(widget.session.date);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa có';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return dateFormat.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chi tiết Buổi học',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Info Card
                    CustomCard(
                      variant: CardVariant.white,
                      child: Padding(
                        padding: const EdgeInsets.all(DesignTokens.spacingMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: widget.session.title,
                              variant: TextVariant.headlineSmall,
                              color: DesignTokens.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: DesignTokens.spacingSM),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: DesignTokens.textSecondary),
                                const SizedBox(width: 8),
                                CustomText(
                                  text: _formatDate(),
                                  variant: TextVariant.bodyMedium,
                                  color: DesignTokens.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: DesignTokens.spacingXS),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: DesignTokens.textSecondary),
                                const SizedBox(width: 8),
                                CustomText(
                                  text: _formatTimeRange(),
                                  variant: TextVariant.bodyMedium,
                                  color: DesignTokens.textSecondary,
                                ),
                              ],
                            ),
                            if (widget.session.notes != null && widget.session.notes!.isNotEmpty) ...[
                              const SizedBox(height: DesignTokens.spacingXS),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.note, size: 16, color: DesignTokens.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomText(
                                      text: widget.session.notes!,
                                      variant: TextVariant.bodyMedium,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacingMD),

                    // Trainer Attendance Section
                    CustomCard(
                      variant: CardVariant.white,
                      child: Padding(
                        padding: const EdgeInsets.all(DesignTokens.spacingMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: 'Chấm Công (PT)',
                              variant: TextVariant.titleLarge,
                              color: DesignTokens.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: DesignTokens.spacingMD),
                            // Check-in/Check-out Status
                            if (_trainerAttendance != null) ...[
                              if (_trainerAttendance!.checkInTime != null) ...[
                                Row(
                                  children: [
                                    Icon(Icons.login, size: 16, color: DesignTokens.success),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            text: 'Check-in: ${_formatDateTime(_trainerAttendance!.checkInTime)}',
                                            variant: TextVariant.bodyMedium,
                                            color: DesignTokens.textPrimary,
                                          ),
                                          if (_trainerAttendance!.checkInLat != null &&
                                              _trainerAttendance!.checkInLong != null)
                                            CustomText(
                                              text: 'Vị trí: ${_trainerAttendance!.checkInLat!.toStringAsFixed(6)}, ${_trainerAttendance!.checkInLong!.toStringAsFixed(6)}',
                                              variant: TextVariant.bodySmall,
                                              color: DesignTokens.textSecondary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: DesignTokens.spacingSM),
                              ],
                              if (_trainerAttendance!.checkOutTime != null) ...[
                                Row(
                                  children: [
                                    Icon(Icons.logout, size: 16, color: DesignTokens.info),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            text: 'Check-out: ${_formatDateTime(_trainerAttendance!.checkOutTime)}',
                                            variant: TextVariant.bodyMedium,
                                            color: DesignTokens.textPrimary,
                                          ),
                                          if (_trainerAttendance!.checkOutLat != null &&
                                              _trainerAttendance!.checkOutLong != null)
                                            CustomText(
                                              text: 'Vị trí: ${_trainerAttendance!.checkOutLat!.toStringAsFixed(6)}, ${_trainerAttendance!.checkOutLong!.toStringAsFixed(6)}',
                                              variant: TextVariant.bodySmall,
                                              color: DesignTokens.textSecondary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: DesignTokens.spacingMD),
                              ],
                            ],
                            // Check-in/Check-out Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    label: _trainerAttendance?.isCheckedIn == true ? 'Đã Check-in' : 'Check-in',
                                    icon: Icons.login,
                                    onPressed: _trainerAttendance?.isCheckedIn == true ? null : _handleCheckIn,
                                    isLoading: _isCheckingIn,
                                    variant: ButtonVariant.primary,
                                    size: ButtonSize.medium,
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.spacingSM),
                                Expanded(
                                  child: CustomButton(
                                    label: _trainerAttendance?.isCheckedOut == true ? 'Đã Check-out' : 'Check-out',
                                    icon: Icons.logout,
                                    onPressed: _trainerAttendance?.isCheckedIn != true ||
                                            _trainerAttendance?.isCheckedOut == true
                                        ? null
                                        : _handleCheckOut,
                                    isLoading: _isCheckingOut,
                                    variant: ButtonVariant.secondary,
                                    size: ButtonSize.medium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacingMD),

                    // QR Code Section
                    CustomCard(
                      variant: CardVariant.white,
                      child: Padding(
                        padding: const EdgeInsets.all(DesignTokens.spacingMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: 'Điểm Danh (Học viên)',
                              variant: TextVariant.titleLarge,
                              color: DesignTokens.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: DesignTokens.spacingMD),
                            CustomButton(
                              label: 'Tạo Mã QR Điểm Danh',
                              icon: Icons.qr_code,
                              onPressed: _handleGenerateQR,
                              isLoading: _isGeneratingQR,
                              variant: ButtonVariant.primary,
                              size: ButtonSize.medium,
                              isFullWidth: true,
                            ),

                            if (_activeQR != null) ...[
                              const SizedBox(height: DesignTokens.spacingMD),
                              // 👇 THAY bằng Center + Container có maxWidth
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  constraints: const BoxConstraints(
                                    maxWidth: 260, // cho card gọn lại, nhìn đẹp
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                                    border: Border.all(
                                      color: DesignTokens.borderDefault,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center, // QR và text căn giữa
                                    children: [
                                      QrImageView(
                                        data: 'session_id=${widget.session.id}&token=${_activeQR!.token}&type=session_attendance',
                                        version: QrVersions.auto,
                                        size: 200,
                                        backgroundColor: Colors.white,
                                      ),
                                      const SizedBox(height: DesignTokens.spacingSM),
                                      const CustomText(
                                        text: 'Mã QR để học viên quét điểm danh',
                                        variant: TextVariant.bodySmall,
                                        color: DesignTokens.textSecondary,
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_activeQR!.expiresAt.isAfter(DateTime.now()))
                                        CustomText(
                                          text: 'Hết hạn: ${_formatDateTime(_activeQR!.expiresAt)}',
                                          variant: TextVariant.bodySmall,
                                          color: DesignTokens.warning,
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

