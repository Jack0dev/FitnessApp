/// Main export file for all services
/// This file provides backward compatibility for existing imports
/// 
/// NOTE: Services đã được tổ chức lại theo module. 
/// Các file cũ ở thư mục gốc vẫn được giữ lại để backward compatibility.
/// Nên sử dụng imports từ các module tương ứng:
/// - attendance/attendance_services.dart
/// - auth/auth_services.dart
/// - course/course_services.dart
/// - user/user_services.dart
/// - content/content_services.dart
/// - payment/payment_services.dart
/// - chat/chat_services.dart
/// - session/session_services.dart
/// - common/common_services.dart

// Export từ module mới (ưu tiên)
export 'attendance/attendance_services.dart';
export 'auth/auth_services.dart';
export 'course/course_services.dart';
export 'user/user_services.dart';
export 'content/content_services.dart';
export 'payment/payment_services.dart';
export 'chat/chat_services.dart';
export 'session/session_services.dart';
export 'common/common_services.dart';
