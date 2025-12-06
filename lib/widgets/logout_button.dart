import 'package:flutter/material.dart';
// Thay đổi đường dẫn này cho đúng với file CustomButton của bạn
import 'custom_button.dart';
import '../core/constants/design_tokens.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  final ButtonSize size;
  final ButtonVariant variant;
  final bool isFullWidth;
  final bool showIcon;

  const LogoutButton({
    super.key,
    required this.onLogout,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.outline, // Thường dùng outline/text cho Logout
    this.isFullWidth = true, // Mặc định là full width cho nút action quan trọng
    this.showIcon = true,
  });

  // Tùy chỉnh màu sắc để nổi bật (thường là màu đỏ/cảnh báo)
  Color get _logoutColor => Colors.red.shade700;

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: 'Đăng xuất',
      onPressed: () => _confirmAndLogout(context), // Gọi hàm xác nhận
      icon: showIcon ? Icons.logout : null,
      variant: variant,
      size: size,
      isFullWidth: isFullWidth,

      // Ghi đè màu sắc để tạo màu cảnh báo (thường là đỏ)
      foregroundColor: _logoutColor,
      backgroundColor: variant == ButtonVariant.primary ? _logoutColor : null,

      // Nếu là Outline, cần custom border color
      // Lưu ý: Cấu hình CustomButton của bạn sẽ không cho phép custom BorderSide màu đỏ trực tiếp
      // nếu không phải variant Outline. Nếu là Outline, nó sẽ dùng DesignTokens.primary.
      // Để hiển thị màu đỏ khi dùng Outline, bạn cần sửa CustomButton một chút,
      // hoặc dùng variant Text cho đơn giản:
      // variant: ButtonVariant.text,
    );
  }

  // Hàm hiển thị Dialog xác nhận trước khi đăng xuất (Rất quan trọng về UX)
  void _confirmAndLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Hủy',
                style: TextStyle(color: DesignTokens.textSecondary),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
            ),
            TextButton(
              // Nút xác nhận có màu cảnh báo
              child: Text(
                'Đăng xuất',
                style: TextStyle(color: _logoutColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                onLogout(); // Gọi hàm đăng xuất chính
              },
            ),
          ],
        );
      },
    );
  }
}