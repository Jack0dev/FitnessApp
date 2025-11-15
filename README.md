# Fitness App - Flutter với Supabase

Ứng dụng Flutter quản lý fitness và khóa học được xây dựng với Supabase để quản lý authentication, database và storage.

## 🚀 Tính năng chính

### 🔐 Authentication
- ✅ Đăng ký/Đăng nhập với Email & Password
- ✅ Đăng nhập với Google OAuth
- ✅ Đăng nhập với Số điện thoại (OTP)
- ✅ Xác thực vân tay (Fingerprint/Face ID)
- ✅ Quản lý session và refresh token
- ✅ Auto-logout khi đóng app

### 👥 Role-Based Access Control
- **Admin**: Quản lý users, courses, PTs
- **PT (Personal Trainer)**: Quản lý courses, lịch dạy, students
- **User**: Xem và đăng ký courses, thanh toán, xem tài liệu

### 📚 Course Management
- ✅ Tạo và quản lý khóa học
- ✅ Phân loại theo level (Beginner, Intermediate, Advanced)
- ✅ Quản lý số lượng học viên (max/current students)
- ✅ Trạng thái khóa học (Active, Inactive, Completed, Cancelled)
- ✅ Upload hình ảnh khóa học

### 📖 Lesson Management
- ✅ PT upload tài liệu (images/videos) cho từng buổi học
- ✅ Đăng ký lịch dạy với date/time
- ✅ Xem lessons theo course
- ✅ Hiển thị schedule của khóa học

### 💳 Enrollment & Payment
- ✅ Đăng ký khóa học
- ✅ QR Code payment
- ✅ Quản lý trạng thái thanh toán (Pending, Paid, Failed)
- ✅ Database triggers tự động cập nhật `current_students` sau thanh toán

### 📱 UI/UX
- ✅ Material Design
- ✅ Light/Dark mode
- ✅ Responsive design
- ✅ Loading states
- ✅ Error handling

## 📁 Cấu trúc thư mục

```
lib/
├── config/              # Cấu hình Supabase
│   └── supabase_config.dart
├── core/                # Core functionality
│   ├── constants/       # Constants và các giá trị cố định
│   │   ├── app_constants.dart
│   │   └── test_phone_numbers.dart
│   ├── routes/          # Route definitions
│   │   └── app_routes.dart
│   └── theme/           # Theme configuration
│       └── app_theme.dart
├── models/              # Data models
│   ├── course_model.dart
│   ├── course_lesson_model.dart
│   ├── enrollment_model.dart
│   ├── user_model.dart
│   └── user_role.dart
├── screens/             # UI Screens
│   ├── admin/           # Admin screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── courses_management_screen.dart
│   │   ├── course_detail_screen.dart
│   │   ├── course_form_screen.dart
│   │   └── users_management_screen.dart
│   ├── auth/            # Authentication screens
│   │   ├── login_screen.dart
│   │   ├── phone_login_screen.dart
│   │   └── register_screen.dart
│   ├── home/            # Home screens
│   │   ├── home_screen.dart
│   │   └── splash_screen.dart
│   ├── profile/         # Profile screens
│   │   ├── edit_profile_screen.dart
│   │   ├── profile_screen.dart
│   │   └── settings_screen.dart
│   ├── pt/              # Personal Trainer screens
│   │   ├── pt_dashboard_screen.dart
│   │   ├── pt_courses_management_screen.dart
│   │   ├── pt_course_form_screen.dart
│   │   ├── pt_course_detail_screen.dart
│   │   ├── pt_schedule_screen.dart
│   │   └── pt_lesson_form_screen.dart
│   └── user/            # User screens
│       ├── user_dashboard_screen.dart
│       ├── courses_screen.dart
│       ├── course_enroll_screen.dart
│       ├── my_enrolled_courses_screen.dart
│       ├── user_course_detail_screen.dart
│       ├── user_course_lessons_screen.dart
│       └── user_course_schedule_screen.dart
├── services/            # Business logic và API services
│   ├── auth_service.dart
│   ├── course_service.dart
│   ├── data_service.dart
│   ├── lesson_service.dart
│   ├── local_auth_service.dart
│   ├── payment_service.dart
│   ├── role_service.dart
│   ├── sql_database_service.dart
│   ├── storage_service.dart
│   └── user_preference_service.dart
├── utils/               # Helper functions và utilities
│   └── validators.dart
├── widgets/             # Reusable widgets
│   ├── loading_widget.dart
│   └── error_widget.dart
└── main.dart            # Entry point
```

## 📦 Dependencies

### Core
- `supabase_flutter: ^2.5.6` - Supabase client cho Flutter
- `http: ^1.2.2` - HTTP requests

### Authentication & Security
- `local_auth: ^2.3.0` - Fingerprint/Face ID authentication
- `flutter_secure_storage: ^9.2.2` - Secure storage cho credentials
- `shared_preferences: ^2.3.2` - Local preferences

### UI & Media
- `image_picker: ^1.1.2` - Pick images/videos từ gallery
- `qr_flutter: ^4.1.0` - Generate QR codes
- `url_launcher: ^6.3.1` - Open URLs và deep links

## ⚙️ Cấu hình Supabase

### 1. Tạo Supabase Project
- Đăng ký tại [supabase.com](https://supabase.com)
- Tạo project mới

### 2. Cấu hình trong app
Cập nhật `lib/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
static const String storageBucketName = 'DataFitnessApp';
```

### 3. Database Setup
Chạy các SQL scripts trong Supabase SQL Editor:
- `database_migrations.sql` - Tạo tables và columns
- `database_triggers.sql` - Tạo triggers cho tự động cập nhật `current_students`

### 4. Storage Setup
- Tạo bucket `DataFitnessApp` trong Supabase Storage
- Thiết lập Storage Policies để cho phép authenticated users upload/read files
- Tạo folder `course_lessons` trong bucket

### 5. Authentication Providers
Trong Supabase Dashboard > Authentication > Providers:
- Enable Email provider
- Enable Google OAuth (cấu hình OAuth credentials)
- Enable Phone provider

### 6. Google OAuth Setup
1. Tạo OAuth 2.0 Client ID trong [Google Cloud Console](https://console.cloud.google.com)
2. Thêm Authorized JavaScript origins:
   - `https://your-project.supabase.co`
3. Thêm Authorized redirect URIs:
   - `https://your-project.supabase.co/auth/v1/callback`
4. Copy Client ID và Secret vào Supabase Dashboard > Authentication > Providers > Google

### 7. Deep Linking (Android)
Cấu hình trong `android/app/src/main/AndroidManifest.xml`:
```xml
<activity>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.example.fitness_app" android:host="login-callback" />
    </intent-filter>
</activity>
```

## 🚀 Cách chạy ứng dụng

### 1. Cài đặt dependencies
```bash
flutter pub get
```

### 2. Cấu hình Supabase
- Cập nhật `lib/config/supabase_config.dart` với credentials của bạn
- Chạy SQL migrations trong Supabase Dashboard
- Thiết lập Storage bucket và policies

### 3. Chạy ứng dụng
```bash
flutter run
```

## 📚 Cấu trúc chi tiết

### Services

#### Authentication
- **AuthService**: Quản lý authentication (login, register, OAuth, logout)
- **LocalAuthService**: Xác thực vân tay/Face ID
- **UserPreferenceService**: Lưu trữ credentials và preferences

#### Database
- **SqlDatabaseService**: Service chính để kết nối Supabase PostgreSQL
- **DataService**: Quản lý user data trong database
- **CourseService**: CRUD operations cho courses và enrollments
- **LessonService**: CRUD operations cho course lessons

#### Storage
- **StorageService**: Upload/download files từ Supabase Storage

#### Business Logic
- **PaymentService**: Xử lý payment logic
- **RoleService**: Quản lý role-based routing

### Models

- **UserModel**: User data với role, profile info
- **CourseModel**: Course data (title, description, price, level, instructor, etc.)
- **CourseLessonModel**: Lesson data (title, file URL, type, scheduled date)
- **EnrollmentModel**: Enrollment data (user, course, payment status)
- **UserRole**: Enum cho roles (admin, pt, user)

### Screens

#### Admin
- **AdminDashboardScreen**: Dashboard tổng quan cho admin
- **CoursesManagementScreen**: Quản lý tất cả courses
- **UsersManagementScreen**: Quản lý users và PTs

#### PT (Personal Trainer)
- **PTDashboardScreen**: Dashboard cho PT với statistics
- **PTCoursesManagementScreen**: Quản lý courses của PT
- **PTCourseFormScreen**: Tạo/sửa course
- **PTCourseDetailScreen**: Chi tiết course và danh sách students
- **PTScheduleScreen**: Quản lý lịch dạy (lessons)
- **PTLessonFormScreen**: Thêm/sửa lesson với upload image/video

#### User
- **UserDashboardScreen**: Dashboard cho user
- **CoursesScreen**: Xem tất cả courses với search và filter
- **CourseEnrollScreen**: Đăng ký course và QR payment
- **MyEnrolledCoursesScreen**: Khóa học đã đăng ký
- **UserCourseDetailScreen**: Chi tiết course đã đăng ký
- **UserCourseLessonsScreen**: Xem lessons/documents
- **UserCourseScheduleScreen**: Xem lịch học

#### Authentication
- **LoginScreen**: Đăng nhập (Email, Google, Fingerprint)
- **RegisterScreen**: Đăng ký
- **PhoneLoginScreen**: Đăng nhập bằng OTP

#### Profile
- **ProfileScreen**: Thông tin user
- **EditProfileScreen**: Chỉnh sửa profile
- **SettingsScreen**: Cài đặt (enable/disable fingerprint)

### Core

- **AppRoutes**: Định nghĩa tất cả routes trong app
- **AppTheme**: Theme configuration cho light/dark mode
- **AppConstants**: Constants chung

### Widgets

- **LoadingWidget**: Loading indicator
- **ErrorWidget**: Error display widget

## 🔧 Database Schema

### Tables
- `users`: Thông tin users
- `courses`: Thông tin khóa học
- `course_lessons`: Lessons/documents của course
- `enrollments`: Đăng ký khóa học và payment status

### Triggers
- `trigger_update_course_students`: Tự động tăng `current_students` khi payment thành công
- `decrease_course_students_on_enrollment_delete`: Giảm `current_students` khi xóa enrollment

## 🔐 Security

- Row Level Security (RLS) policies cho tất cả tables
- Secure storage cho credentials
- Fingerprint authentication cho quick login
- OAuth 2.0 cho Google login

## 📝 Lưu ý

- Minimum SDK version: Android API 21+
- Internet permission đã được thêm vào AndroidManifest.xml
- Deep linking cần được cấu hình cho OAuth callbacks
- Supabase Storage bucket cần được tạo và cấu hình policies
- Database triggers cần được chạy để tự động cập nhật `current_students`

## 🛠️ Phát triển thêm

Để thêm tính năng mới:
1. Thêm models vào `lib/models/`
2. Thêm services vào `lib/services/`
3. Thêm screens vào `lib/screens/{role}/` hoặc `lib/screens/`
4. Thêm widgets vào `lib/widgets/`
5. Cập nhật routes trong `lib/core/routes/app_routes.dart`
6. Cập nhật database schema nếu cần (SQL migrations)

## 📄 License

This project is private and proprietary.
