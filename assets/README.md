# Assets Folder

Thư mục này chứa các assets từ Figma design.

## Cấu trúc

```
assets/
├── images/     # Hình ảnh, photos, illustrations
├── icons/      # Icons, logos
└── fonts/      # Custom font files (nếu có)
```

## Cách sử dụng

### 1. Export từ Figma

**Images:**
- Chọn element trong Figma
- Click Export panel (bên phải)
- Chọn format: PNG hoặc JPG
- Export và lưu vào `assets/images/`

**Icons:**
- Export dưới dạng SVG hoặc PNG
- Lưu vào `assets/icons/`
- Nên export ở nhiều sizes: 1x, 2x, 3x

**Fonts:**
- Nếu có custom fonts trong Figma
- Export font files (.ttf, .otf)
- Lưu vào `assets/fonts/`
- Cập nhật `pubspec.yaml` để sử dụng

### 2. Sử dụng trong Code

```dart
// Images
Image.asset('assets/images/logo.png')

// Icons
Image.asset('assets/icons/home.png')

// Custom fonts (sau khi config trong pubspec.yaml)
Text(
  'Hello',
  style: TextStyle(fontFamily: 'CustomFont'),
)
```

### 3. Naming Convention

- Sử dụng snake_case: `user_profile.png`
- Thêm size suffix nếu cần: `icon_24.png`, `icon_48.png`
- Rõ ràng, dễ hiểu: `login_background.jpg`

## Lưu ý

- Tất cả assets đã được khai báo trong `pubspec.yaml`
- Sau khi thêm assets mới, chạy `flutter pub get`
- Nên optimize images trước khi thêm vào project
- Sử dụng SVG cho icons khi có thể (cần package `flutter_svg`)



