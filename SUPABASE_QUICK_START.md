# Supabase Quick Start Guide - Setup trong 5 phút

## 🚀 Bước 1: Tạo Supabase Account & Project

1. Truy cập: https://supabase.com
2. Click **"Start your project"** hoặc **"Sign up"**
3. Đăng nhập (GitHub/Google/Email)
4. Click **"New Project"**
5. Điền thông tin:
   - **Name**: `fitness-app` (hoặc tên bạn muốn)
   - **Database Password**: Tạo password mạnh ⚠️ **LƯU LẠI PASSWORD NÀY!**
   - **Region**: Chọn gần bạn nhất (ví dụ: `Southeast Asia (Singapore)`)
   - **Pricing Plan**: Chọn **Free**
6. Click **"Create new project"**
7. Đợi 2-3 phút để Supabase setup database

## 🔑 Bước 2: Lấy API Keys

1. Sau khi project đã sẵn sàng, vào **Settings** (⚙️) ở sidebar trái
2. Click **API**
3. Bạn sẽ thấy 2 thông tin quan trọng:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public** key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## 📋 Bước 3: Tạo Database Table

1. Vào **SQL Editor** (biểu tượng `</>` ở sidebar)
2. Click **"New query"**
3. Paste và chạy SQL sau:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,  -- Firebase Auth UID
  email TEXT,
  display_name TEXT,
  photo_url TEXT,
  phone_number TEXT,
  provider TEXT DEFAULT 'email',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);

-- Create function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger
CREATE TRIGGER update_users_updated_at 
BEFORE UPDATE ON users
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();
```

4. Click **"Run"** hoặc `Ctrl+Enter`
5. Bạn sẽ thấy: ✅ Success. No rows returned

## 🔒 Bước 4: Setup Row Level Security (RLS)

Vẫn trong SQL Editor, chạy:

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read/write their own data
-- For now, we'll use a simple policy (you can tighten this later)
CREATE POLICY "Users can access own data"
ON users
FOR ALL
USING (true)
WITH CHECK (true);
```

**Lưu ý**: Policy trên cho phép tất cả authenticated users. Bạn có thể tighten sau khi setup Firebase Auth integration.

## ⚙️ Bước 5: Update App Config

1. Mở file: `lib/config/supabase_config.dart`
2. Thay thế:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

Bằng:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';  // Your Project URL
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';  // Your anon key
```

## ✅ Bước 6: Test App

1. Chạy app:
   ```bash
   flutter run
   ```

2. Kiểm tra logs:
   - Nếu thấy `✅ Connected to Supabase (PostgreSQL)` → Success!
   - Nếu thấy warning → Kiểm tra lại keys

3. Test đăng ký/đăng nhập:
   - Tạo account mới
   - Data sẽ được lưu vào Supabase
   - Vào Supabase Dashboard > Table Editor > users để xem data

## 🎯 Kiểm Tra Data

1. Vào Supabase Dashboard
2. Click **Table Editor** (biểu tượng bảng)
3. Chọn table **users**
4. Bạn sẽ thấy user data đã được lưu!

## 📊 Database Schema

### users table:
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | Firebase Auth UID (Primary Key) |
| email | TEXT | User email |
| display_name | TEXT | Display name |
| photo_url | TEXT | Profile photo URL |
| phone_number | TEXT | Phone number |
| provider | TEXT | Auth provider ('email', 'phone', 'google') |
| created_at | TIMESTAMPTZ | Created timestamp |
| updated_at | TIMESTAMPTZ | Updated timestamp |

## ✅ Checklist

- [ ] Supabase account created
- [ ] Project created
- [ ] API keys copied
- [ ] users table created (SQL script run)
- [ ] RLS enabled and policy created
- [ ] supabase_config.dart updated with keys
- [ ] App tested - data saving to Supabase

## 🎉 Done!

App giờ sẽ:
- ✅ Dùng Firebase Auth cho authentication
- ✅ Dùng Supabase (PostgreSQL) cho data storage
- ✅ Tự động fallback về Firestore nếu Supabase chưa config

## 🔍 Troubleshooting

### Lỗi: "Supabase not initialized"
- Kiểm tra `supabase_config.dart` đã được update chưa
- Kiểm tra keys có đúng không

### Lỗi: "relation 'users' does not exist"
- Chưa chạy SQL script để tạo table
- Vào SQL Editor và chạy script tạo table

### Không thấy data trong Supabase
- Kiểm tra logs trong app
- Kiểm tra Supabase Dashboard > Table Editor
- Kiểm tra RLS policies

---

**Bạn đã sẵn sàng! Chỉ cần setup Supabase project và update keys là xong! 🚀**


