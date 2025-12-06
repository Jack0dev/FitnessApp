import 'package:flutter/material.dart';
import '../../services/user/user_preference_service.dart';

/// App Localization Service
class AppLocalizations {
  static const Locale vietnamese = Locale('vi', 'VN');
  static const Locale english = Locale('en', 'US');
  
  static const List<Locale> supportedLocales = [vietnamese, english];
  
  static Locale _currentLocale = vietnamese;
  static final UserPreferenceService _prefs = UserPreferenceService();
  
  static Locale get currentLocale => _currentLocale;
  
  /// Initialize localization - load saved language preference
  static Future<void> initialize() async {
    final savedLang = await _prefs.getLanguage();
    if (savedLang != null) {
      _currentLocale = savedLang == 'vi' ? vietnamese : english;
    }
  }
  
  /// Change language
  static Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    await _prefs.saveLanguage(locale.languageCode);
  }
  
  /// Get localized string
  static String translate(String key) {
    return _translations[_currentLocale.languageCode]?[key] ?? key;
  }
  
  /// Translations map
  static final Map<String, Map<String, String>> _translations = {
    'vi': _vietnameseTranslations,
    'en': _englishTranslations,
  };
  
  // Vietnamese translations
  static final Map<String, String> _vietnameseTranslations = {
    // Common
    'app_name': 'Fitness App',
    'loading': 'Đang tải...',
    'error': 'Lỗi',
    'success': 'Thành công',
    'cancel': 'Hủy',
    'confirm': 'Xác nhận',
    'save': 'Lưu',
    'delete': 'Xóa',
    'edit': 'Chỉnh sửa',
    'add': 'Thêm',
    'close': 'Đóng',
    'back': 'Quay lại',
    'next': 'Tiếp theo',
    'done': 'Hoàn thành',
    'retry': 'Thử lại',
    'refresh': 'Làm mới',
    'search': 'Tìm kiếm',
    'filter': 'Lọc',
    'view_all': 'Xem tất cả',
    'and': 'và',
    'to': 'để',
    'user': 'Người dùng',
    'trainer': 'Huấn luyện viên',
    'no_user_logged_in': 'Không có người dùng đăng nhập',
    'manage_app_settings': 'Quản lý cài đặt ứng dụng',
    
    // Auth
    'login': 'Đăng nhập',
    'logout': 'Đăng xuất',
    'sign_out': 'Đăng xuất',
    'register': 'Đăng ký',
    'email': 'Email',
    'password': 'Mật khẩu',
    'confirm_password': 'Xác nhận mật khẩu',
    'forgot_password': 'Quên mật khẩu?',
    'login_with_google': 'Đăng nhập bằng Google',
    'login_with_fingerprint': 'Đăng nhập bằng vân tay',
    'dont_have_account': 'Chưa có tài khoản?',
    'already_have_account': 'Đã có tài khoản?',
    'create_account': 'Tạo tài khoản',
    'phone_login': 'Đăng nhập bằng số điện thoại',
    'phone_number': 'Số điện thoại',
    'send_otp': 'Gửi mã OTP',
    'enter_otp': 'Nhập mã OTP',
    'verify': 'Xác thực',
    
    // Dashboard
    'dashboard': 'Bảng điều khiển',
    'welcome': 'Xin chào',
    'hello': 'Xin chào',
    'ready_for_workout': 'Sẵn sàng cho buổi tập hôm nay?',
    'today_progress': 'Tiến độ hôm nay',
    'quick_actions': 'Thao tác nhanh',
    'statistics': 'Thống kê',
    
    // User Dashboard
    'workouts': 'Buổi tập',
    'calories': 'Calories',
    'steps': 'Bước chân',
    'minutes': 'Phút',
    'courses': 'Khóa học',
    'workout_history': 'Lịch sử tập luyện',
    'body_metrics': 'Chỉ số cơ thể',
    'schedule': 'Lịch trình',
    'progress': 'Tiến độ',
    'find_pt': 'Tìm huấn luyện viên',
    'achievements': 'Thành tích',
    'settings': 'Cài đặt',
    
    // PT Dashboard
    'pt_dashboard': 'Bảng điều khiển PT',
    'total_clients': 'Tổng học viên',
    'active_sessions': 'Buổi học đang hoạt động',
    'my_courses': 'Khóa học của tôi',
    'my_students': 'Học viên của tôi',
    'my_clients': 'Học viên của tôi',
    'qr_attendance': 'Chấm công QR',
    'chat': 'Trò chuyện',
    'profile': 'Hồ sơ',
    
    // Course
    'course': 'Khóa học',
    'course_detail': 'Chi tiết khóa học',
    'enroll': 'Đăng ký',
    'enrolled': 'Đã đăng ký',
    'price': 'Giá',
    'duration': 'Thời lượng',
    'days': 'ngày',
    'students': 'Học viên',
    'level': 'Cấp độ',
    'lessons': 'Bài học',
    'lesson': 'Bài học',
    'description': 'Mô tả',
    'instructor': 'Giảng viên',
    'overview': 'Tổng quan',
    'manage_schedule': 'Quản lý lịch trình',
    'add_lesson': 'Thêm bài học',
    'edit_lesson': 'Chỉnh sửa bài học',
    'delete_lesson': 'Xóa bài học',
    'lesson_title': 'Tiêu đề bài học',
    'lesson_description': 'Mô tả bài học',
    'lesson_date': 'Ngày học',
    'lesson_number': 'Số bài học',
    
    // Enrollment
    'enrollment': 'Đăng ký',
    'enrolled_at': 'Đăng ký lúc',
    'payment_status': 'Trạng thái thanh toán',
    'paid': 'Đã thanh toán',
    'pending': 'Đang chờ',
    'failed': 'Thất bại',
    'refunded': 'Đã hoàn tiền',
    'paid_students': 'Học viên đã thanh toán',
    'pending_payment': 'Chờ thanh toán',
    'no_students': 'Chưa có học viên',
    'no_students_enrolled': 'Chưa có học viên đăng ký',
    
    // Attendance
    'attendance': 'Chấm công',
    'mark_attendance': 'Chấm công',
    'attendance_time': 'Thời gian chấm công',
    'select_course': 'Chọn khóa học',
    'select_lesson': 'Chọn bài học',
    'scanning': 'Đang quét...',
    'paused': 'Tạm dừng',
    'start_scanning': 'Bắt đầu quét',
    'stop_scanning': 'Dừng quét',
    'attendance_marked': 'Chấm công thành công!',
    'invalid_qr_code': 'Mã QR không hợp lệ',
    'qr_code_mismatch': 'Mã QR không khớp với khóa học/bài học đã chọn',
    'current_session': 'Phiên hiện tại',
    'position_qr_code': 'Đặt mã QR ở đây',
    
    // Chat
    'messages': 'Tin nhắn',
    'no_messages': 'Chưa có tin nhắn',
    'start_conversation': 'Bắt đầu trò chuyện!',
    'type_message': 'Nhập tin nhắn...',
    'send': 'Gửi',
    'just_now': 'Vừa xong',
    'today': 'Hôm nay',
    'tomorrow': 'Ngày mai',
    
    // Profile & Settings
    'edit_profile': 'Chỉnh sửa hồ sơ',
    'display_name': 'Tên hiển thị',
    'phone': 'Số điện thoại',
    'address': 'Địa chỉ',
    'date_of_birth': 'Ngày sinh',
    'gender': 'Giới tính',
    'male': 'Nam',
    'female': 'Nữ',
    'other': 'Khác',
    'language': 'Ngôn ngữ',
    'vietnamese': 'Tiếng Việt',
    'english': 'English',
    'change_language': 'Thay đổi ngôn ngữ',
    'fingerprint_auth': 'Xác thực vân tay',
    'enable_fingerprint': 'Bật xác thực vân tay',
    'disable_fingerprint': 'Tắt xác thực vân tay',
    
    // Status
    'active': 'Đang hoạt động',
    'inactive': 'Không hoạt động',
    'completed': 'Hoàn thành',
    'cancelled': 'Đã hủy',
    'beginner': 'Người mới bắt đầu',
    'intermediate': 'Trung cấp',
    'advanced': 'Nâng cao',
    
    // Actions
    'view': 'Xem',
    'view_detail': 'Xem chi tiết',
    'create': 'Tạo mới',
    'update': 'Cập nhật',
    'remove': 'Xóa bỏ',
    'confirm_delete': 'Xác nhận xóa',
    'are_you_sure': 'Bạn có chắc chắn?',
    'cannot_undo': 'Hành động này không thể hoàn tác',
    
    // Errors & Messages
    'error_occurred': 'Đã xảy ra lỗi',
    'try_again': 'Thử lại',
    'no_data': 'Không có dữ liệu',
    'coming_soon': 'Sắp ra mắt',
    'not_available': 'Không khả dụng',
    'success_message': 'Thành công!',
    'failed_message': 'Thất bại!',
    
    'start_date': 'Ngày bắt đầu',
    'end_date': 'Ngày kết thúc',
    'sets': 'Số set',
    'reps': 'Số rep',
    'equipment': 'Dụng cụ',
    'add_images': 'Thêm hình ảnh',
    'add_videos': 'Thêm video',
    'meal_plan': 'Thực đơn',
    'meal_plans': 'Thực đơn',
    'create_meal_plan': 'Tạo thực đơn',
    'edit_meal_plan': 'Chỉnh sửa thực đơn',
    'breakfast': 'Bữa sáng',
    'lunch': 'Bữa trưa',
    'dinner': 'Bữa tối',
    'snack': 'Đồ ăn nhẹ',
    'protein': 'Protein',
    'carbs': 'Carb',
    'fat': 'Chất béo',
    'skipped': 'Đã bỏ qua',
  };
  
  // English translations
  static final Map<String, String> _englishTranslations = {
    // Common
    'app_name': 'Fitness App',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'done': 'Done',
    'retry': 'Retry',
    'refresh': 'Refresh',
    'search': 'Search',
    'filter': 'Filter',
    'view_all': 'View All',
    'and': 'and',
    'to': 'to',
    'user': 'User',
    'trainer': 'Trainer',
    'no_user_logged_in': 'No user logged in',
    'manage_app_settings': 'Manage app settings and preferences',
    
    // Auth
    'login': 'Login',
    'logout': 'Logout',
    'sign_out': 'Sign Out',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'forgot_password': 'Forgot Password?',
    'login_with_google': 'Login with Google',
    'login_with_fingerprint': 'Login with Fingerprint',
    'dont_have_account': "Don't have an account?",
    'already_have_account': 'Already have an account?',
    'create_account': 'Create Account',
    'phone_login': 'Login with Phone',
    'phone_number': 'Phone Number',
    'send_otp': 'Send OTP',
    'enter_otp': 'Enter OTP',
    'verify': 'Verify',
    
    // Dashboard
    'dashboard': 'Dashboard',
    'welcome': 'Welcome',
    'hello': 'Hello',
    'ready_for_workout': 'Ready for your workout today?',
    'today_progress': "Today's Progress",
    'quick_actions': 'Quick Actions',
    'statistics': 'Statistics',
    
    // User Dashboard
    'workouts': 'Workouts',
    'calories': 'Calories',
    'steps': 'Steps',
    'minutes': 'Minutes',
    'courses': 'Courses',
    'workout_history': 'Workout History',
    'body_metrics': 'Body Metrics',
    'schedule': 'Schedule',
    'progress': 'Progress',
    'find_pt': 'Find PT',
    'achievements': 'Achievements',
    'settings': 'Settings',
    
    // PT Dashboard
    'pt_dashboard': 'PT Dashboard',
    'total_clients': 'Total Clients',
    'active_sessions': 'Active Sessions',
    'my_courses': 'My Courses',
    'my_students': 'My Students',
    'my_clients': 'My Clients',
    'qr_attendance': 'QR Attendance',
    'chat': 'Chat',
    'profile': 'Profile',
    
    // Course
    'course': 'Course',
    'course_detail': 'Course Detail',
    'enroll': 'Enroll',
    'enrolled': 'Enrolled',
    'price': 'Price',
    'duration': 'Duration',
    'days': 'days',
    'students': 'Students',
    'level': 'Level',
    'lessons': 'Lessons',
    'lesson': 'Lesson',
    'description': 'Description',
    'instructor': 'Instructor',
    'overview': 'Overview',
    'manage_schedule': 'Manage Schedule',
    'add_lesson': 'Add Lesson',
    'edit_lesson': 'Edit Lesson',
    'delete_lesson': 'Delete Lesson',
    'lesson_title': 'Lesson Title',
    'lesson_description': 'Lesson Description',
    'lesson_date': 'Lesson Date',
    'lesson_number': 'Lesson Number',
    
    // Enrollment
    'enrollment': 'Enrollment',
    'enrolled_at': 'Enrolled At',
    'payment_status': 'Payment Status',
    'paid': 'Paid',
    'pending': 'Pending',
    'failed': 'Failed',
    'refunded': 'Refunded',
    'paid_students': 'Paid Students',
    'pending_payment': 'Pending Payment',
    'no_students': 'No Students',
    'no_students_enrolled': 'No students enrolled yet',
    
    // Attendance
    'attendance': 'Attendance',
    'mark_attendance': 'Mark Attendance',
    'attendance_time': 'Attendance Time',
    'select_course': 'Select Course',
    'select_lesson': 'Select Lesson',
    'scanning': 'Scanning...',
    'paused': 'Paused',
    'start_scanning': 'Start Scanning',
    'stop_scanning': 'Stop Scanning',
    'attendance_marked': 'Attendance marked successfully!',
    'invalid_qr_code': 'Invalid QR code format',
    'qr_code_mismatch': 'QR code does not match selected course/lesson',
    'current_session': 'Current Session',
    'position_qr_code': 'Position QR code here',
    
    // Chat
    'messages': 'Messages',
    'no_messages': 'No messages yet',
    'start_conversation': 'Start a conversation!',
    'type_message': 'Type a message...',
    'send': 'Send',
    'just_now': 'Just now',
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'yesterday': 'Yesterday',
    'upcoming': 'Upcoming',
    'today_schedule': "Today's Schedule",
    'no_courses_enrolled': 'No Courses Enrolled',
    'enroll_course_to_view_schedule': 'Enroll in a course to view schedule',
    'no_lessons_scheduled': 'No Lessons Scheduled',
    'no_lessons_for_selected_date': 'No lessons scheduled for selected date',
    'filter_by_course': 'Filter by Course',
    'all_courses': 'All Courses',
    'no_attendance_recorded': 'No Attendance Recorded',
    'attendance_will_appear_here': 'Your attendance records will appear here',
    'checked_in_at': 'Checked in at',
    'no_progress_data': 'No Progress Data',
    'enroll_course_to_track_progress': 'Enroll in a course to track your progress',
    'body_metrics_feature_coming_soon': 'Body metrics tracking feature will be available soon',
    'meal_plan_feature_coming_soon': 'Meal plan feature will be available soon',
    'manage_pts': 'Manage PTs',
    'total_pts': 'Total PTs',
    'no_pts_found': 'No PTs Found',
    'no_pts_match_search': 'No personal trainers match your search',
    'reports': 'Reports',
    'reports_feature_coming_soon': 'Reports feature will be available soon',
    
    // Profile & Settings
    'edit_profile': 'Edit Profile',
    'display_name': 'Display Name',
    'phone': 'Phone',
    'address': 'Address',
    'date_of_birth': 'Date of Birth',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'other': 'Other',
    'language': 'Language',
    'vietnamese': 'Tiếng Việt',
    'english': 'English',
    'change_language': 'Change Language',
    'fingerprint_auth': 'Fingerprint Authentication',
    'enable_fingerprint': 'Enable Fingerprint',
    'disable_fingerprint': 'Disable Fingerprint',
    
    // Status
    'active': 'Active',
    'inactive': 'Inactive',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
    
    // Actions
    'view': 'View',
    'view_detail': 'View Detail',
    'create': 'Create',
    'update': 'Update',
    'remove': 'Remove',
    'confirm_delete': 'Confirm Delete',
    'are_you_sure': 'Are you sure?',
    'cannot_undo': 'This action cannot be undone',
    
    // Errors & Messages
    'error_occurred': 'An error occurred',
    'try_again': 'Try Again',
    'no_data': 'No Data',
    'not_available': 'Not Available',
    'success_message': 'Success!',
    'failed_message': 'Failed!',
    
    'start_date': 'Start Date',
    'end_date': 'End Date',
    'sets': 'Sets',
    'reps': 'Reps',
    'equipment': 'Equipment',
    'add_images': 'Add Images',
    'add_videos': 'Add Videos',
    'meal_plans': 'Meal Plans',
    'create_meal_plan': 'Create Meal Plan',
    'edit_meal_plan': 'Edit Meal Plan',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
    'protein': 'Protein',
    'carbs': 'Carbs',
    'fat': 'Fat',
    'skipped': 'Skipped',
  };
}

/// Extension to easily access translations
extension AppLocalizationsExtension on BuildContext {
  String translate(String key) => AppLocalizations.translate(key);
}

