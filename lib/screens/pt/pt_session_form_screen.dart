import 'package:flutter/material.dart';
import '../../models/session_model.dart';
import '../../models/room_model.dart';
import '../../services/session/session_service.dart';
import '../../services/chat/room_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/widgets.dart';
import '../../core/constants/design_tokens.dart';

/// Form screen for creating/editing training sessions
/// Session gắn với PT, có thêm chọn phòng học
class PTSessionFormScreen extends StatefulWidget {
  final SessionModel? session;

  /// Nếu tạo session mới từ màn Course Detail
  /// bạn có thể truyền sẵn tên khóa học vào đây
  /// (vd: initialTitle: course.title)
  final String? initialTitle;

  const PTSessionFormScreen({
    super.key,
    this.session,
    this.initialTitle,
  });

  @override
  State<PTSessionFormScreen> createState() => _PTSessionFormScreenState();
}

class _PTSessionFormScreenState extends State<PTSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late final SessionService _sessionService;
  final _authService = AuthService();
  final _roomService = RoomService();

  // Form state
  DateTime _sessionDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  // Room state
  List<RoomModel> _rooms = [];
  RoomModel? _selectedRoom;
  bool _isLoadingRooms = false;

  // Loading state
  bool _isSaving = false;

  // Trong _PTSessionFormScreenState
  @override
  void initState() {
    super.initState();

    _sessionService = SessionService();

    // 1. Ưu tiên dữ liệu edit
    if (widget.session != null) {
      _titleController.text = widget.session!.title;
      _sessionDate = widget.session!.date;
      _startTime = widget.session!.startTime;
      _endTime = widget.session!.endTime;
      _notesController.text = widget.session!.notes ?? '';
    }
    // 2. Nếu là tạo mới và có initialTitle
    else if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    // KIỂM TRA: In giá trị để đảm bảo đã được set
    print('📝 [PTSessionForm] Initial Title Controller text: ${_titleController.text}');

    _loadRooms();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final rooms = await _roomService.getRooms();
      setState(() {
        _rooms = rooms;

        // Nếu session đang edit đã có roomId → chọn sẵn
        final existingRoomId = widget.session?.roomId;
        if (existingRoomId != null) {
          try {
            _selectedRoom =
                rooms.firstWhere((r) => r.id == existingRoomId);
          } catch (_) {
            // room không tìm thấy thì bỏ qua
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Lỗi tải danh sách phòng: $e')),
            ],
          ),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingRooms = false);
      }
    }
  }

  Future<void> _saveSession() async {
    // Ở đây form chỉ có ghi chú cần validate nên _formKey vẫn dùng được
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final title = _titleController.text.trim();

      if (title.isEmpty) {
        // Vì title là read-only, nếu rỗng nghĩa là bạn chưa truyền từ ngoài vào
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tiêu đề session đang trống. Hãy truyền tên khóa học vào initialTitle khi mở form.'),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      final now = DateTime.now();

      final session = SessionModel(
        id: widget.session?.id ??
            now.millisecondsSinceEpoch.toString(),
        trainerId: user.id,
        title: title,
        date: _sessionDate,
        startTime: _startTime,
        endTime: _endTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        roomId: _selectedRoom?.id,
        createdAt: widget.session?.createdAt ?? now,
        updatedAt: now,
      );

      bool success;
      if (widget.session != null) {
        success = await _sessionService.updateSession(session);
      } else {
        final id = await _sessionService.createSession(session);
        success = id != null;
      }

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.session != null
                      ? 'Cập nhật session thành công'
                      : 'Tạo session thành công',
                ),
              ],
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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Không thể lưu session'),
              ],
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Lỗi: $e')),
            ],
          ),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: CustomAppBar(
        title:
        widget.session != null ? 'Chỉnh sửa session' : 'Tạo session mới',
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DesignTokens.primary,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CustomButton(
                label: 'Lưu',
                icon: Icons.check,
                onPressed: _saveSession,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // Tiêu đề Session (read-only)
              // =========================
              CustomCard(
                variant: CardVariant.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.title,
                              size: 18, color: DesignTokens.primary),
                          const SizedBox(width: 8),
                          CustomText(
                            text: 'Tiêu đề session',
                            variant: TextVariant.titleMedium,
                            color: DesignTokens.textPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        enabled: false, // read-only
                        decoration: InputDecoration(
                          hintText: 'Tên khóa học sẽ được tự động điền',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: DesignTokens.surface,
                        ),
                        style: DesignTokens.bodyMedium.copyWith(
                          color: DesignTokens.textPrimary,  // 💡 Đảm bảo màu sắc là Primary
                          fontWeight: FontWeight.bold,      // 💡 Thêm đậm
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: DesignTokens.spacingMD),

              // =========================
              // Ngày Session
              // =========================
              DatePickerInput(
                label: 'Ngày session',
                icon: Icons.calendar_today,
                selectedDate: _sessionDate,
                onDateSelected: (date) {
                  setState(() => _sessionDate = date);
                },
                firstDate:
                DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                formatter: (date) {
                  final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
                  final weekday = weekdays[date.weekday % 7];
                  return '$weekday, ${date.day}/${date.month}/${date.year}';
                },
              ),

              SizedBox(height: DesignTokens.spacingMD),

              // =========================
              // Giờ bắt đầu
              // =========================
              SelectionCard(
                label: 'Thời gian bắt đầu',
                icon: Icons.access_time,
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _startTime = picked;
                        // Auto-update end time nếu start >= end
                        final startMinutes =
                            picked.hour * 60 + picked.minute;
                        final endMinutes =
                            _endTime.hour * 60 + _endTime.minute;
                        if (startMinutes >= endMinutes) {
                          _endTime = TimeOfDay(
                            hour: (picked.hour + 1) % 24,
                            minute: picked.minute,
                          );
                        }
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CustomText(
                      text: _formatTimeOfDay(_startTime),
                      variant: TextVariant.bodyLarge,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: DesignTokens.spacingMD),

              // =========================
              // Giờ kết thúc
              // =========================
              SelectionCard(
                label: 'Thời gian kết thúc',
                icon: Icons.access_time_filled,
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _endTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CustomText(
                      text: _formatTimeOfDay(_endTime),
                      variant: TextVariant.bodyLarge,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: DesignTokens.spacingMD),

              // =========================
              // Chọn phòng học
              // =========================
              CustomCard(
                variant: CardVariant.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.meeting_room,
                              size: 18, color: DesignTokens.primary),
                          const SizedBox(width: 8),
                          CustomText(
                            text: 'Phòng học (tùy chọn)',
                            variant: TextVariant.titleMedium,
                            color: DesignTokens.textPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingRooms)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_rooms.isEmpty)
                        CustomText(
                          text:
                          'Chưa có phòng nào. Hãy thêm dữ liệu vào bảng rooms.',
                          variant: TextVariant.bodyMedium,
                          color: DesignTokens.textSecondary,
                        )
                      else
                        CustomDropdown<RoomModel>(
                          label: 'Phòng',
                          value: _selectedRoom,
                          hint: 'Chọn phòng cho buổi tập',
                          items: _rooms.map((room) {
                            return DropdownMenuItem<RoomModel>(
                              value: room,
                              // ✅ CÁCH KHẮC PHỤC: Bọc Column trong SizedBox để giới hạn chiều cao
                              // hoặc kiểm tra lại CustomText styles.
                              child: Row(
                                children: [
                                  const Icon(Icons.meeting_room, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      // Thêm mainAxisSize: MainAxisSize.min
                                      mainAxisSize: MainAxisSize.min, // Giúp Column không chiếm quá nhiều không gian dọc
                                      children: [
                                        CustomText(
                                          text: room.name,
                                          variant: TextVariant.bodyLarge, // Có thể giảm xuống bodyMedium
                                          color: DesignTokens.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        if (room.capacity != null)
                                        // Đảm bảo bodySmall đủ nhỏ
                                          CustomText(
                                            text:
                                            'Sức chứa: ${room.capacity} người',
                                            variant: TextVariant.bodySmall,
                                            color:
                                            DesignTokens.textSecondary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } ).toList(),
                          onChanged: (room) {
                            setState(() {
                              _selectedRoom = room;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: DesignTokens.spacingMD),

              // =========================
              // Ghi chú
              // =========================
              CustomCard(
                variant: CardVariant.gymFresh,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note,
                              size: 18, color: DesignTokens.primary),
                          const SizedBox(width: 8),
                          CustomText(
                            text: 'Ghi chú (tùy chọn)',
                            variant: TextVariant.titleMedium,
                            color: DesignTokens.textPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Nhập ghi chú...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: DesignTokens.bodyMedium.copyWith(
                          color: DesignTokens.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: DesignTokens.spacingLG),

              // =========================
              // Nút lưu
              // =========================
              CustomButton(
                label: widget.session != null
                    ? 'Cập nhật session'
                    : 'Tạo session',
                icon: Icons.save,
                onPressed: _saveSession,
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                isLoading: _isSaving,
                isFullWidth: true,
              ),

              SizedBox(height: DesignTokens.spacingMD),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
