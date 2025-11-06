# Sửa lỗi Storage Permission (403 Unauthorized)

## 🚨 Lỗi hiện tại

```
StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

**Nguyên nhân:** Supabase Storage đang chặn upload vì Row-Level Security (RLS) policies chưa được cấu hình đúng.

## ✅ Giải pháp: Cấu hình Storage Policies

### Bước 1: Vào Supabase Dashboard

1. Mở trình duyệt và vào: https://supabase.com/dashboard
2. Chọn project của bạn
3. Click **Storage** ở sidebar trái
4. Click vào bucket **`DataFitnessApp`** (hoặc bucket bạn đang dùng)

### Bước 2: Tạo INSERT Policy (Cho phép Upload)

1. Click tab **"Policies"** trong bucket
2. Click nút **"New Policy"**
3. Chọn **"Create a policy from scratch"** hoặc **"For full customization"**
4. Điền thông tin:

   - **Policy name**: `Allow public uploads` (hoặc tên bạn muốn)
   - **Allowed operation**: Chọn **`INSERT`**
   - **Policy definition**: Paste SQL sau:

   ```sql
   true
   ```

   ⚠️ **Lưu ý:** Policy `true` cho phép **TẤT CẢ** users (kể cả anonymous) upload. 
   - ✅ **OK cho development/testing**
   - ⚠️ **KHÔNG an toàn cho production** - chỉ dùng để test!

5. Click **"Review"** và sau đó **"Save policy"**

### Bước 3: Tạo SELECT Policy (Cho phép Đọc)

1. Click **"New Policy"** lần nữa
2. Điền thông tin:

   - **Policy name**: `Allow public read`
   - **Allowed operation**: Chọn **`SELECT`**
   - **Policy definition**:

   ```sql
   true
   ```

3. Click **"Save policy"**

### Bước 4: Tạo UPDATE Policy (Optional - cho phép Update)

1. Click **"New Policy"**
2. Điền thông tin:

   - **Policy name**: `Allow public update`
   - **Allowed operation**: Chọn **`UPDATE`**
   - **Policy definition**:

   ```sql
   true
   ```

3. Click **"Save policy"**

### Bước 5: Tạo DELETE Policy (Optional - cho phép Xóa)

1. Click **"New Policy"**
2. Điền thông tin:

   - **Policy name**: `Allow public delete`
   - **Allowed operation**: Chọn **`DELETE`**
   - **Policy definition**:

   ```sql
   true
   ```

3. Click **"Save policy"**

## 📋 Tóm tắt Policies cần tạo

| Operation | Policy Name | Policy Definition |
|-----------|-------------|-------------------|
| **INSERT** | `Allow public uploads` | `true` |
| **SELECT** | `Allow public read` | `true` |
| **UPDATE** | `Allow public update` | `true` (optional) |
| **DELETE** | `Allow public delete` | `true` (optional) |

## ✅ Kiểm tra

Sau khi tạo policies:

1. **Refresh app** hoặc **restart app**
2. Thử upload ảnh lại
3. Kiểm tra console - không còn lỗi 403

## 🔒 Production Security (Quan trọng!)

⚠️ **CẢNH BÁO:** Policy `true` cho phép **BẤT KỲ AI** upload/đọc/xóa files!

### Cho Production, bạn nên:

1. **Giới hạn theo user ID:**
   ```sql
   -- Chỉ cho phép user upload file của chính họ
   (bucket_id = 'DataFitnessApp' AND (storage.foldername(name))[1] = auth.uid()::text)
   ```

2. **Hoặc giới hạn theo folder:**
   ```sql
   -- Chỉ cho phép upload vào folder profile_images
   bucket_id = 'DataFitnessApp' AND (storage.foldername(name))[1] = 'profile_images'
   ```

3. **Hoặc kết hợp cả hai:**
   ```sql
   -- Chỉ cho phép user upload file của chính họ trong folder profile_images
   (
     bucket_id = 'DataFitnessApp' 
     AND (storage.foldername(name))[1] = 'profile_images'
     AND (storage.foldername(name))[2] LIKE auth.uid()::text || '%'
   )
   ```

**Lưu ý:** Vì app đang dùng Firebase Auth (không phải Supabase Auth), các policies dựa trên `auth.uid()` sẽ không hoạt động. Bạn cần:

- **Option 1:** Dùng policy `true` cho development (như trên)
- **Option 2:** Setup Supabase Auth và sync với Firebase Auth (phức tạp hơn)
- **Option 3:** Tạo custom authentication middleware

## 🎯 Quick Fix (Cho Development)

Nếu bạn chỉ muốn test nhanh, tạo 2 policies đơn giản:

1. **INSERT policy:** `true`
2. **SELECT policy:** `true`

Đó là đủ để upload và đọc ảnh!

## 📝 Checklist

- [ ] Vào Supabase Dashboard > Storage > Bucket `DataFitnessApp`
- [ ] Tạo INSERT policy với `true`
- [ ] Tạo SELECT policy với `true`
- [ ] Test upload ảnh lại
- [ ] Kiểm tra không còn lỗi 403

---

**Sau khi setup xong, thử upload ảnh lại và cho tôi biết kết quả!** 🚀

