import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/attendance/session_attendance_service.dart';
import '../../services/session/session_service.dart';
import '../../services/auth/auth_service.dart';
import '../../models/session_model.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';
import 'package:intl/intl.dart';

class StudentAttendanceScanScreen extends StatefulWidget {
  const StudentAttendanceScanScreen({super.key});

  @override
  State<StudentAttendanceScanScreen> createState() => _StudentAttendanceScanScreenState();
}

class _StudentAttendanceScanScreenState extends State<StudentAttendanceScanScreen> {
  final _sessionAttendanceService = SessionAttendanceService();
  final _sessionService = SessionService();
  final _authService = AuthService();
  final _mobileScannerController = MobileScannerController();

  bool _isScanning = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _mobileScannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCodeScan(String rawValue) async {
    if (_isProcessing) return;

    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });

    // Parse QR code của Session
    final qrData = _sessionAttendanceService.parseSessionQRCode(rawValue);
    
    if (qrData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomText(
              text: 'QR code không hợp lệ',
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
        setState(() {
          _isProcessing = false;
          _isScanning = true;
        });
      }
      return;
    }

    final sessionId = qrData['session_id'] as String?;
    if (sessionId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomText(
              text: 'QR code không hợp lệ',
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
        setState(() {
          _isProcessing = false;
          _isScanning = true;
        });
      }
      return;
    }

    // Get session info
    try {
      final session = await _sessionService.getSessionById(sessionId);

      if (session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const CustomText(
                text: 'Không tìm thấy session',
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
          setState(() {
            _isProcessing = false;
            _isScanning = true;
          });
        }
        return;
      }

      // Show confirmation dialog
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const CustomText(
            text: 'Xác nhận điểm danh',
            variant: TextVariant.headlineSmall,
            color: DesignTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: session.title,
                variant: TextVariant.titleMedium,
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: DesignTokens.spacingSM),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: DesignTokens.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      text: _formatSessionTime(session),
                      variant: TextVariant.bodyMedium,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.spacingXS),
                Row(
                  children: [
                    Icon(Icons.note, size: 16, color: DesignTokens.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        text: session.notes!,
                        variant: TextVariant.bodyMedium,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const CustomText(
                text: 'Hủy',
                variant: TextVariant.bodyMedium,
                color: DesignTokens.textSecondary,
              ),
            ),
            CustomButton(
              label: 'Xác nhận',
              icon: Icons.check,
              onPressed: () => Navigator.of(context).pop(true),
              variant: ButtonVariant.primary,
              size: ButtonSize.small,
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() {
          _isProcessing = false;
          _isScanning = true;
        });
        return;
      }

      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const CustomText(
                text: 'Vui lòng đăng nhập',
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
        return;
      }

      // Mark attendance
      final result = await _sessionAttendanceService.markAttendanceBySession(
        sessionId: sessionId,
        userId: user.id,
        qrToken: qrData['token'] as String?,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        
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
          // Return after successful attendance
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: result['message'] as String? ?? 'Điểm danh thất bại',
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
          // Resume scanning
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _isScanning = true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
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
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isScanning = true);
          }
        });
      }
    }
  }

  String _formatSessionTime(SessionModel session) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startStr = '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${session.endTime.hour.toString().padLeft(2, '0')}:${session.endTime.minute.toString().padLeft(2, '0')}';
    return '${dateFormat.format(session.date)} • $startStr - $endStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Điểm danh',
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _mobileScannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && _isScanning && !_isProcessing) {
                  _handleQRCodeScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _isScanning ? DesignTokens.success : DesignTokens.textSecondary,
                width: 3,
              ),
            ),
            margin: const EdgeInsets.all(40),
            child: Center(
              child: CustomText(
                text: _isProcessing 
                    ? 'Đang xử lý...'
                    : 'Đưa camera vào QR code của session',
                variant: TextVariant.bodyLarge,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Status indicator
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isProcessing
                    ? DesignTokens.info.withOpacity(0.8)
                    : _isScanning
                        ? DesignTokens.success.withOpacity(0.8)
                        : DesignTokens.textSecondary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      _isScanning ? Icons.check_circle : Icons.pause_circle,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  CustomText(
                    text: _isProcessing
                        ? 'Đang xử lý...'
                        : _isScanning
                            ? 'Đang quét...'
                            : 'Tạm dừng',
                    variant: TextVariant.bodyMedium,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ),
          // Control buttons
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _isProcessing ? null : () {
                    setState(() => _isScanning = !_isScanning);
                    if (_isScanning) {
                      _mobileScannerController.start();
                    } else {
                      _mobileScannerController.stop();
                    }
                  },
                  backgroundColor: _isProcessing
                      ? DesignTokens.textSecondary
                      : _isScanning
                          ? DesignTokens.error
                          : DesignTokens.success,
                  child: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


