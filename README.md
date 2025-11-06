# Fitness App - Flutter với Firebase

Ứng dụng Flutter được xây dựng với cấu trúc chuẩn và tích hợp Firebase để quản lý authentication và database.

## Cấu trúc thư mục

```
lib/
├── config/              # Cấu hình Firebase
│   └── firebase_config.dart
├── core/                # Core functionality
│   ├── constants/       # Constants và các giá trị cố định
│   │   └── app_constants.dart
│   ├── routes/          # Route definitions
│   │   └── app_routes.dart
│   └── theme/           # Theme configuration
│       └── app_theme.dart
├── models/              # Data models
│   └── user_model.dart
├── screens/             # UI Screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   └── profile_screen.dart
├── services/            # Business logic và API services
│   ├── auth_service.dart
│   └── firestore_service.dart
├── utils/               # Helper functions và utilities
│   └── validators.dart
├── widgets/             # Reusable widgets
│   ├── loading_widget.dart
│   └── error_widget.dart
└── main.dart            # Entry point
```

## Tính năng

- ✅ Authentication với Firebase Auth
  - Đăng ký tài khoản
  - Đăng nhập
  - Quản lý session
  - Đăng xuất
  
- ✅ Cloud Firestore Integration
  - Lưu trữ thông tin người dùng
  - Quản lý dữ liệu
  
- ✅ UI/UX
  - Splash screen
  - Login/Register screens
  - Home screen
  - Profile screen
  - Theme (Light/Dark mode)

## Dependencies

### Core Firebase
- `firebase_core: ^3.1.1` - Firebase core
- `firebase_auth: ^5.1.2` - Authentication
- `cloud_firestore: ^5.0.1` - Cloud Firestore

## Cấu hình Firebase

1. **Android**: File `google-services.json` đã được đặt tại `android/app/google-services.json`
2. **Firebase Project**: `fitnessapp-a69ee`

## Cách chạy ứng dụng

1. Cài đặt dependencies:
```bash
flutter pub get
```

2. Đảm bảo bạn đã cấu hình Firebase:
   - File `google-services.json` đã có trong `android/app/`
   - Firebase project đã được thiết lập đúng

3. Chạy ứng dụng:
```bash
flutter run
```

## Cấu trúc chi tiết

### Services
- **AuthService**: Quản lý authentication (login, register, logout)
- **FirestoreService**: Quản lý các thao tác với Firestore database

### Models
- **UserModel**: Model cho user data với các phương thức convert từ/ra Firestore

### Screens
- **SplashScreen**: Màn hình khởi động, kiểm tra auth state
- **LoginScreen**: Màn hình đăng nhập
- **RegisterScreen**: Màn hình đăng ký
- **HomeScreen**: Màn hình chính sau khi đăng nhập
- **ProfileScreen**: Màn hình thông tin người dùng

### Core
- **AppConstants**: Các constants chung cho app
- **AppRoutes**: Định nghĩa các routes
- **AppTheme**: Theme configuration cho light/dark mode

### Utils
- **Validators**: Các hàm validation cho form inputs

### Widgets
- **LoadingWidget**: Widget hiển thị loading state
- **ErrorWidget**: Widget hiển thị error state

## Lưu ý

- Đảm bảo `google-services.json` đã được cấu hình đúng
- Minimum SDK version: theo cấu hình Flutter default
- Internet permission đã được thêm vào AndroidManifest.xml

## Phát triển thêm

Để thêm tính năng mới:
1. Thêm models vào `lib/models/`
2. Thêm services vào `lib/services/`
3. Thêm screens vào `lib/screens/`
4. Thêm widgets vào `lib/widgets/`
5. Cập nhật routes nếu cần trong `lib/core/routes/`
