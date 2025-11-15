# Fix: Callback URL thiếu path /auth/v1/callback

## 🔴 Vấn đề

Bạn đang thấy URL callback:
```
https://dittvvfdbeikqbanpudc.supabase.co/?code=07dabae3-a89b-4297-a43c-3ad125dc5f9e
```

**Vấn đề:** URL này **THIẾU** path `/auth/v1/callback`

**URL đúng phải là:**
```
https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback?code=...
```

## ❌ Nguyên nhân

URL callback không có path `/auth/v1/callback` có thể do:

1. **Redirect URI trong Google Cloud Console sai**
   - Có thể bạn đã thêm: `https://dittvvfdbeikqbanpudc.supabase.co` (thiếu `/auth/v1/callback`)
   - Thay vì: `https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback`

2. **Google redirect về root URL thay vì callback path**

## ✅ Giải pháp

### Bước 1: Kiểm tra và sửa Redirect URI trong Google Cloud Console

1. **Vào Google Cloud Console:**
   - https://console.cloud.google.com/
   - Vào **APIs & Services** → **Credentials**

2. **Tìm OAuth 2.0 Client ID (Web application)**
   - Click vào tên để edit

3. **Kiểm tra phần "Authorized redirect URIs"**

4. **Xóa redirect URI sai** (nếu có):
   ```
   https://dittvvfdbeikqbanpudc.supabase.co
   ```

5. **Đảm bảo có redirect URI đúng:**
   ```
   https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback
   ```
   
   **Lưu ý:** Phải có `/auth/v1/callback` ở cuối!

6. **Click SAVE**

7. **Đợi 1-2 phút** để Google cập nhật

### Bước 2: Kiểm tra Supabase Dashboard

1. **Vào Supabase Dashboard:**
   - https://app.supabase.com/
   - Chọn project: `dittvvfdbeikqbanpudc`

2. **Vào Authentication → URL Configuration**

3. **Đảm bảo có 2 redirect URLs:**
   ```
   com.example.fitness_app://login-callback
   https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback
   ```

4. **Nếu thiếu, thêm vào**

### Bước 3: Rebuild app

```bash
flutter clean
flutter pub get
flutter run
```

## 📋 Redirect URIs đúng

### Trong Google Cloud Console:

**Authorized JavaScript origins:**
```
https://dittvvfdbeikqbanpudc.supabase.co
```
(Chỉ domain, không có path)

**Authorized redirect URIs:**
```
https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback
```
(Full URL với path `/auth/v1/callback`)

### Trong Supabase Dashboard → URL Configuration:

```
com.example.fitness_app://login-callback
https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback
```

## ⚠️ Lưu ý quan trọng

### URL đúng format:

- ✅ **JavaScript origin**: `https://dittvvfdbeikqbanpudc.supabase.co` (không có path)
- ✅ **Redirect URI**: `https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback` (có path)

### URL sai format:

- ❌ **Redirect URI**: `https://dittvvfdbeikqbanpudc.supabase.co` (thiếu path)
- ❌ **Redirect URI**: `https://dittvvfdbeikqbanpudc.supabase.co/` (có trailing slash)

## 🔍 Kiểm tra lại

Sau khi sửa, kiểm tra:

1. **Google Cloud Console:**
   - [ ] Redirect URI: `https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback` (có `/auth/v1/callback`)
   - [ ] Không có redirect URI: `https://dittvvfdbeikqbanpudc.supabase.co` (không có path)

2. **Supabase Dashboard:**
   - [ ] URL Configuration có 2 URLs đúng

3. **Đã đợi 1-2 phút** sau khi save trong Google Cloud Console

4. **Đã rebuild app**

## 🎯 Sau khi sửa

Sau khi sửa redirect URI trong Google Cloud Console:

1. Đợi 1-2 phút
2. Rebuild app
3. Test Google Sign In lại
4. URL callback sẽ là: `https://dittvvfdbeikqbanpudc.supabase.co/auth/v1/callback?code=...`

Nếu vẫn thấy URL không có path, kiểm tra lại redirect URI trong Google Cloud Console có đúng format không!

