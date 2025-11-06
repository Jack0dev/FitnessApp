# Hướng Dẫn Setup Supabase (PostgreSQL) với Firebase Auth

## 🎯 Kiến Trúc Hybrid

App sẽ sử dụng:
- **Firebase Auth**: Xác thực user (Email, Phone, Google)
- **Supabase (PostgreSQL)**: Lưu trữ data (users, workouts, etc.)

## 📋 Bước 1: Tạo Supabase Project

### 1.1. Đăng ký Supabase
1. Truy cập: https://supabase.com
2. Click **"Start your project"** hoặc **"Sign up"**
3. Đăng nhập bằng GitHub, Google, hoặc Email

### 1.2. Tạo Project Mới
1. Click **"New Project"**
2. Điền thông tin:
   - **Name**: `fitness-app` (hoặc tên bạn muốn)
   - **Database Password**: Tạo password mạnh (lưu lại!)
   - **Region**: Chọn gần bạn nhất
   - **Pricing Plan**: Chọn **Free** (hoặc Pro nếu muốn)
3. Click **"Create new project"**
4. Đợi 2-3 phút để setup database

### 1.3. Lấy API Keys
1. Vào **Settings** (⚙️) > **API**
2. Copy 2 thông tin quan trọng:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## 📋 Bước 2: Tạo Database Schema

### 2.1. Vào SQL Editor
1. Trong Supabase Dashboard, click **SQL Editor** (biểu tượng `</>`)
2. Click **"New query"**

### 2.2. Tạo Users Table
Paste và chạy SQL sau:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,  -- Firebase Auth UID
  email TEXT,
  display_name TEXT,
  photo_url TEXT,
  phone_number TEXT,
  provider TEXT DEFAULT 'email',  -- 'email', 'phone', 'google'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);

-- Create function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 2.3. Setup Row Level Security (RLS)
Chạy SQL sau để bảo mật:

```sql
-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read/update their own data
-- Note: Since we use Firebase Auth, we'll use a custom auth function
-- For now, we'll allow authenticated users to read their own data

-- Allow users to read their own data
CREATE POLICY "Users can read own data"
ON users FOR SELECT
USING (true);  -- We'll validate in the app using Firebase Auth token

-- Allow users to insert their own data
CREATE POLICY "Users can insert own data"
ON users FOR INSERT
WITH CHECK (true);

-- Allow users to update their own data
CREATE POLICY "Users can update own data"
ON users FOR UPDATE
USING (true)
WITH CHECK (true);

-- Allow users to delete their own data
CREATE POLICY "Users can delete own data"
ON users FOR DELETE
USING (true);
```

**Lưu ý**: Vì dùng Firebase Auth, RLS policies trên là tạm thời. Cần setup custom authentication function (xem phần nâng cao).

## 📋 Bước 3: Cấu Hình App

### 3.1. Tạo file config
Tạo file `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  // Thay bằng Supabase URL của bạn
  static const String supabaseUrl = 'https://xxxxx.supabase.co';
  
  // Thay bằng anon key của bạn
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

### 3.2. Update main.dart
Thêm Supabase initialization:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseConfig.initialize(useEmulator: false);
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}
```

## 📋 Bước 4: Update Services

Code đã được tạo trong `lib/services/sql_database_service.dart`. Bạn chỉ cần:
1. Update `lib/config/supabase_config.dart` với URL và key của bạn
2. Update `lib/main.dart` để initialize Supabase
3. Update screens để dùng `SqlDatabaseService` thay vì `FirestoreService`

## 🔐 Bảo Mật (Quan Trọng)

### Option 1: Simple (Tạm thời cho development)
- Dùng RLS policies như trên
- Validate user trong app code

### Option 2: Secure (Cho production)
- Setup custom authentication với Firebase Auth tokens
- Validate tokens trong Supabase functions
- Tighten RLS policies

## 📊 Supabase Free Tier

### Giới hạn:
- **Database**: 500 MB storage
- **Bandwidth**: 5 GB/month
- **API requests**: Unlimited
- **Database size**: Up to 500 MB
- **Project limit**: 2 projects

### Đủ cho:
- ~10,000 users (với ~50KB data/user)
- Hàng trăm nghìn API requests
- **Hoàn toàn đủ** cho app nhỏ đến trung bình

## ✅ Checklist

- [ ] Tạo Supabase account
- [ ] Tạo project mới
- [ ] Lấy API keys (URL + anon key)
- [ ] Tạo users table (chạy SQL)
- [ ] Setup RLS policies
- [ ] Update `supabase_config.dart` với keys
- [ ] Update `main.dart` để initialize Supabase
- [ ] Test database connection

## 🚀 Next Steps

Sau khi setup xong:
1. Update screens để dùng SQL thay Firestore
2. Test CRUD operations
3. Setup additional tables (workouts, etc.)


