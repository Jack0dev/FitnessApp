# Khắc phục lỗi Upload Ảnh

## 🔍 Các vấn đề thường gặp

### 1. ❌ Bucket không tồn tại

**Lỗi trong console:**
```
⚠️ Bucket "public" not found!
```

**Giải pháp:**
1. Vào **Supabase Dashboard** > **Storage**
2. Kiểm tra tên bucket bạn đã tạo
3. Mở file `lib/config/supabase_config.dart`
4. Cập nhật `storageBucketName` cho đúng:

```dart
static const String storageBucketName = 'public'; // Đổi thành tên bucket của bạn
```

**Ví dụ:** Nếu bucket của bạn tên là `DataFitnessApp`:
```dart
static const String storageBucketName = 'DataFitnessApp';
```

---

### 2. ❌ Permission Denied (403)

**Lỗi trong console:**
```
⚠️ Permission denied! Check Storage Policies in Supabase Dashboard.
```

**Giải pháp:**

1. Vào **Supabase Dashboard** > **Storage** > Click vào bucket của bạn
2. Click tab **"Policies"**
3. Tạo policy mới cho **INSERT**:

   - **Policy name**: `Allow authenticated uploads`
   - **Allowed operation**: `INSERT`
   - **Policy definition**:
   ```sql
   true
   ```
   (Cho development - cho phép tất cả authenticated users)

   Hoặc an toàn hơn:
   ```sql
   (
     bucket_id = 'public' AND
     auth.role() = 'authenticated'
   )
   ```

4. Tạo policy cho **SELECT** (để đọc ảnh):
   - **Policy name**: `Allow public read`
   - **Allowed operation**: `SELECT`
   - **Policy definition**:
   ```sql
   true
   ```

5. Click **"Save policy"**

---

### 3. ❌ Authentication Failed (401)

**Lỗi trong console:**
```
⚠️ Authentication failed!
```

**Vấn đề:** App đang dùng Firebase Auth, nhưng Supabase Storage cần Supabase Auth.

**Giải pháp:**

Có 2 cách:

#### Cách 1: Cho phép Anonymous Access (Dễ nhất cho development)

1. Vào **Supabase Dashboard** > **Storage** > Bucket > **Policies**
2. Tạo policy cho **INSERT** với:
   ```sql
   true
   ```
   (Cho phép cả anonymous users)

3. Tạo policy cho **SELECT** với:
   ```sql
   true
   ```

#### Cách 2: Sync Firebase Auth với Supabase (Phức tạp hơn)

Cần setup Supabase Auth để sync với Firebase Auth. Xem thêm trong documentation.

---

### 4. ❌ Supabase không được khởi tạo

**Lỗi trong console:**
```
⚠️ Supabase not initialized. Check main.dart initialization.
```

**Giải pháp:**

1. Kiểm tra file `lib/main.dart`
2. Đảm bảo có đoạn code này:

```dart
// Initialize Supabase
if (SupabaseConfig.isConfigured) {
  try {
    await SqlDatabaseService.initialize(
      supabaseUrl: SupabaseConfig.supabaseUrl,
      supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Connected to Supabase (PostgreSQL)');
  } catch (e) {
    print('⚠️ Supabase initialization failed: $e');
  }
}
```

---

### 5. ❌ Fallback sang Base64 nhưng vẫn không hiển thị

**Vấn đề:** Ảnh được lưu dưới dạng Base64 nhưng không hiển thị.

**Giải pháp:**

1. Kiểm tra `profile_screen.dart` có xử lý Base64 đúng không
2. Base64 data URL format: `data:image/jpeg;base64,<base64_string>`
3. Kiểm tra console để xem URL có đúng format không

---

## 🔧 Kiểm tra nhanh

### Bước 1: Kiểm tra Bucket Name

1. Mở `lib/config/supabase_config.dart`
2. Xem `storageBucketName` có đúng với bucket trong Supabase Dashboard không

### Bước 2: Kiểm tra Policies

1. Vào Supabase Dashboard > Storage > Bucket > Policies
2. Đảm bảo có:
   - ✅ INSERT policy (cho upload)
   - ✅ SELECT policy (cho đọc)

### Bước 3: Test Upload

1. Chạy app: `flutter run`
2. Vào Edit Profile
3. Chọn ảnh
4. Click Save
5. Xem console logs để biết lỗi cụ thể

### Bước 4: Kiểm tra Console Logs

Khi upload, bạn sẽ thấy logs như:

```
📤 Uploading image to Supabase Storage...
   Bucket: public
   Path: profile_images/abc123_1234567890.jpg
```

Nếu thành công:
```
✅ Image uploaded successfully!
   URL: https://xxx.supabase.co/storage/v1/object/public/public/profile_images/...
```

Nếu thất bại, sẽ có thông báo lỗi cụ thể.

---

## 📝 Checklist

- [ ] Bucket đã được tạo trong Supabase Dashboard
- [ ] Tên bucket trong code khớp với tên trong Dashboard
- [ ] INSERT policy đã được setup
- [ ] SELECT policy đã được setup
- [ ] Supabase đã được khởi tạo trong main.dart
- [ ] Supabase URL và Key đã được cấu hình đúng
- [ ] Đã test upload và xem console logs

---

## 🆘 Vẫn không được?

1. **Kiểm tra console logs** - sẽ có thông báo lỗi cụ thể
2. **Kiểm tra Supabase Dashboard** - xem có file nào được upload không
3. **Thử với bucket public** - tạo bucket mới tên `public` và test
4. **Kiểm tra network** - đảm bảo có internet connection
5. **Restart app** - đôi khi cần restart để áp dụng thay đổi

---

## 💡 Tips

- **Development**: Dùng policy `true` cho tất cả operations (dễ test)
- **Production**: Dùng policy chặt chẽ hơn (chỉ authenticated users)
- **Fallback**: App sẽ tự động fallback sang Base64 nếu Supabase Storage fail
- **Logs**: Luôn check console logs để biết lỗi cụ thể

