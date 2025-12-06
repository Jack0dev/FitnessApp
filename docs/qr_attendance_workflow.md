# 📱 Luồng hoạt động chấm công và điểm danh bằng QR Code

## 🎯 Tổng quan

Hệ thống có **2 luồng QR code**:
1. **PT chấm công**: PT quét QR code của học viên (từ điện thoại học viên)
2. **Student điểm danh**: Học viên quét QR code của Schedule (từ màn hình PT hoặc được hiển thị)

**Mỗi Schedule có 1 QR code duy nhất** được tạo tự động khi tạo Schedule mới.

---

## 🔄 Luồng hoạt động chính

### **1. Tạo Schedule và QR Code**

#### Khi PT tạo Schedule mới:
- PT tạo Schedule → Hệ thống tự động tạo QR code duy nhất cho Schedule đó
- QR code chứa: `schedule_id`, `course_id`, `type: "schedule_attendance"`
- QR code được lưu/link với Schedule (có thể generate lại từ schedule_id)

---

### **2. Phía PT (Personal Trainer) - Chấm công**

#### Bước 1: PT chọn Schedule để chấm công
- PT mở app → Vào màn hình "Chấm công"
- Chọn **Khóa học** (Course)
- Chọn **Lịch trình** (Schedule) - dựa trên:
  - Ngày giờ hiện tại
  - Hoặc chọn từ danh sách schedule sắp tới
  - Hiển thị: Ngày, giờ bắt đầu - kết thúc, địa điểm

#### Bước 2: PT xem QR code của Schedule
- Sau khi chọn Schedule, PT có thể:
  - **Xem QR code của Schedule** (để học viên quét - điểm danh)
  - **Mở camera quét QR code của học viên** (để chấm công)

#### Bước 3: PT mở camera quét QR code học viên
- PT bấm nút "Bắt đầu quét"
- Camera mở lên
- Sẵn sàng quét QR code từ điện thoại học viên

#### Bước 4: Quét QR code học viên
- PT đưa camera vào QR code trên điện thoại học viên
- Hệ thống tự động nhận diện và parse QR code
- QR code học viên chứa: `user_id`, `course_id` (optional)

#### Bước 5: Xác nhận và chấm công
- Hệ thống kiểm tra:
  - ✅ User có trong danh sách học viên của course không?
  - ✅ Schedule đang trong khoảng thời gian hợp lệ không?
  - ✅ Đã chấm công cho schedule này chưa? (tránh duplicate)
- Hiển thị thông tin học viên để PT xác nhận:
  - Tên học viên
  - Avatar
  - Trạng thái: Có mặt / Đi muộn
- PT xác nhận → Lưu vào database

#### Bước 6: Kết quả
- ✅ Thành công: Hiển thị "Đã chấm công" + thông tin học viên
- ❌ Lỗi: Hiển thị lý do (đã chấm công, không thuộc course, etc.)
- Tự động tiếp tục quét (sau 2 giây) để quét học viên tiếp theo

---

### **3. Phía Học viên (Student) - Điểm danh**

#### Bước 1: Học viên mở QR Code của mình
- Học viên mở app → Vào "QR Code của tôi"
- Hoặc từ màn hình Schedule → Bấm "Hiển thị QR Code"
- QR code được tạo động với thông tin:
  ```json
  {
    "user_id": "123...",
    "course_id": "456...",  // Optional
    "type": "student_attendance"
  }
  ```

#### Bước 2: Học viên quét QR code của Schedule
- Học viên mở app → Vào "Điểm danh"
- Bấm "Quét QR Code"
- Camera mở lên
- Học viên quét QR code của Schedule (từ màn hình PT hoặc được hiển thị)

#### Bước 3: Xác nhận và điểm danh
- Hệ thống kiểm tra:
  - ✅ Schedule có hợp lệ không?
  - ✅ Học viên có trong danh sách học viên của course không?
  - ✅ Schedule đang trong khoảng thời gian hợp lệ không?
  - ✅ Đã điểm danh cho schedule này chưa? (tránh duplicate)
- Hiển thị thông tin Schedule để học viên xác nhận:
  - Tên khóa học
  - Ngày, giờ
  - Địa điểm
- Học viên xác nhận → Lưu vào database

#### Bước 4: Kết quả
- ✅ Thành công: Hiển thị "Đã điểm danh thành công"
- ❌ Lỗi: Hiển thị lý do (đã điểm danh, không thuộc course, etc.)

---

## 📊 Cấu trúc dữ liệu

### QR Code của Schedule (PT hiển thị)
```json
{
  "schedule_id": "schedule_123",
  "course_id": "course_456",
  "type": "schedule_attendance",
  "timestamp": 1234567890
}
```

### QR Code của Học viên (Student hiển thị)
```json
{
  "user_id": "user_789",
  "course_id": "course_456",  // Optional
  "type": "student_attendance",
  "timestamp": 1234567890
}
```

### Attendance Record
```dart
AttendanceModel {
  id: "attendance_123",
  schedule_id: "schedule_456",  // FK -> schedule
  user_id: "user_789",           // FK -> user (học viên)
  course_id: "course_101",       // FK -> course
  lesson_id: null,               // Optional
  attendance_time: DateTime.now(),
  status: "present" | "late" | "absent" | "excused",
  notes: "Đi muộn 5 phút",
  created_at: DateTime.now(),
  updated_at: DateTime.now()
}
```

---

## 🔐 Bảo mật và Validation

### Khi PT quét QR code học viên:

1. **Validation QR Code:**
   - ✅ Format JSON hợp lệ
   - ✅ Có `user_id` và `type: "student_attendance"`
   - ✅ Timestamp không quá cũ (max 5 phút)

2. **Validation User:**
   - ✅ User tồn tại trong hệ thống
   - ✅ User đã đăng ký (enrolled) vào course
   - ✅ Payment status = "paid"

3. **Validation Schedule:**
   - ✅ Schedule thuộc course đã chọn
   - ✅ Schedule đang trong thời gian hợp lệ:
     - Trong 15 phút trước start_time
     - Đến 30 phút sau end_time
   - ✅ Schedule status = "scheduled" hoặc "in_progress"

4. **Validation Attendance:**
   - ✅ Chưa chấm công cho schedule này (tránh duplicate)
   - ✅ Nếu đã chấm công → Có thể cập nhật (nếu cần)

### Khi Học viên quét QR code Schedule:

1. **Validation QR Code:**
   - ✅ Format JSON hợp lệ
   - ✅ Có `schedule_id` và `type: "schedule_attendance"`
   - ✅ Timestamp không quá cũ (max 5 phút)

2. **Validation Schedule:**
   - ✅ Schedule tồn tại và hợp lệ
   - ✅ Schedule đang trong thời gian hợp lệ

3. **Validation User:**
   - ✅ User đã đăng ký (enrolled) vào course của schedule
   - ✅ Payment status = "paid"

4. **Validation Attendance:**
   - ✅ Chưa điểm danh cho schedule này (tránh duplicate)

---

## ⏰ Logic thời gian chấm công/điểm danh

### Thời gian cho phép:
- **Trước giờ học:** Tối đa 15 phút trước `start_time`
- **Trong giờ học:** Từ `start_time` đến `end_time`
- **Sau giờ học:** Tối đa 30 phút sau `end_time` (chấm bù)

### Trạng thái tự động:
- **Có mặt (present):** Quét trong khoảng start_time ± 15 phút
- **Đi muộn (late):** Quét sau start_time + 15 phút
- **Vắng mặt (absent):** Không quét hoặc PT đánh dấu thủ công
- **Có phép (excused):** PT đánh dấu thủ công

---

## 📱 Màn hình cần thiết

### 1. PT Side:
- ✅ **PTQRAttendanceScreen** (cần update)
  - Chọn Course
  - Chọn Schedule (thay vì Lesson)
  - Hiển thị QR code của Schedule
  - Camera quét QR code học viên
  - Danh sách học viên đã chấm công

- ✅ **PTScheduleQRCodeScreen** (mới)
  - Hiển thị QR code của Schedule
  - Có thể share/export QR code

- ✅ **PTAttendanceListScreen** (mới)
  - Xem danh sách attendance của một schedule
  - Thống kê: Tổng số, có mặt, vắng mặt
  - Chỉnh sửa attendance thủ công

### 2. Student Side:
- ✅ **StudentQRCodeScreen** (mới)
  - Hiển thị QR code của học viên
  - Auto-refresh mỗi 30 giây
  - Toggle flash/screen brightness

- ✅ **StudentAttendanceScanScreen** (mới)
  - Camera quét QR code của Schedule
  - Xác nhận và điểm danh

- ✅ **StudentAttendanceHistoryScreen** (mới)
  - Xem lịch sử chấm công/điểm danh
  - Thống kê attendance rate

---

## 🔄 Cập nhật cần làm

### 1. Update ScheduleModel:
- ✅ Thêm method `generateQRCodeData()` - tạo JSON cho QR code
- ✅ QR code format: `{"schedule_id": "...", "course_id": "...", "type": "schedule_attendance"}`

### 2. Update AttendanceService:
- ✅ Thêm method `markAttendanceBySchedule()` - cho học viên điểm danh
- ✅ Thêm method `markAttendanceByStudentQR()` - cho PT chấm công
- ✅ Thêm validation schedule time window
- ✅ Thêm method `getScheduleAttendance()`
- ✅ Update `markAttendance()` để hỗ trợ schedule_id

### 3. Update PTQRAttendanceScreen:
- ✅ Thay đổi từ chọn Lesson sang chọn Schedule
- ✅ Thêm UI hiển thị QR code của Schedule
- ✅ Thêm validation thời gian
- ✅ Thêm UI hiển thị danh sách đã chấm công

### 4. Tạo màn hình mới:
- ✅ **PTScheduleQRCodeScreen** - Hiển thị QR code của Schedule
- ✅ **StudentQRCodeScreen** - Hiển thị QR code của học viên
- ✅ **StudentAttendanceScanScreen** - Học viên quét QR code Schedule
- ✅ **PTAttendanceListScreen** - Quản lý attendance
- ✅ **StudentAttendanceHistoryScreen** - Lịch sử chấm công

---

## 📋 Use Cases

### Use Case 1: PT chấm công học viên
1. PT chọn schedule "Yoga buổi sáng - 09:00-10:00"
2. PT mở camera quét
3. Học viên A mở QR code của mình trên điện thoại
4. PT quét QR code của học viên A
5. Hệ thống tự động chấm công: "Có mặt"

### Use Case 2: Học viên tự điểm danh
1. PT hiển thị QR code của Schedule trên màn hình lớn/tablet
2. Học viên B mở app → "Điểm danh" → "Quét QR Code"
3. Học viên B quét QR code của Schedule
4. Hệ thống tự động điểm danh: "Có mặt"

### Use Case 3: Chấm công đi muộn
1. PT chọn schedule "Yoga buổi sáng - 09:00-10:00"
2. Học viên C đến muộn (09:20)
3. PT quét QR code của học viên C
4. Hệ thống tự động chấm công: "Đi muộn" (vì quét sau 09:15)

### Use Case 4: Chấm công bù
1. PT chọn schedule "Yoga buổi sáng - 09:00-10:00"
2. Học viên D quên quét trong giờ học
3. Sau giờ học (10:15), học viên nhờ PT chấm bù
4. PT quét QR code của học viên D
5. Hệ thống cho phép chấm bù (trong 30 phút sau end_time)

---

## 🎨 UI/UX Flow

### PT Flow (Chấm công):
```
PT Dashboard
  → Chấm công
    → Chọn Course
    → Chọn Schedule
    → [Hiển thị QR code của Schedule] (để học viên quét)
    → [Camera quét QR code học viên]
      → Quét QR code
      → Xác nhận thông tin học viên
      → ✅ Chấm công thành công
      → Tiếp tục quét...
```

### Student Flow (Điểm danh):
```
Student Dashboard
  → Schedule
    → [Điểm danh]
      → Quét QR Code
        → Camera mở
        → Quét QR code của Schedule
        → Xác nhận thông tin Schedule
        → ✅ Điểm danh thành công
```

### Student Flow (Hiển thị QR code):
```
Student Dashboard
  → [QR Code của tôi]
    → QR Code hiển thị
    → Đưa cho PT quét
    → ✅ Nhận thông báo "Đã chấm công"
```

---

## 📝 Notes

- **QR code của Schedule**: Được tạo tự động khi tạo Schedule, có thể generate lại từ schedule_id
- **QR code của Học viên**: Được tạo động mỗi khi mở màn hình, auto-refresh mỗi 30 giây
- **Bảo mật**: QR code có thời gian sống ngắn (5 phút) để bảo mật
- **Duplicate check**: Mỗi schedule chỉ chấm công/điểm danh 1 lần cho mỗi học viên
- **Real-time**: PT có thể xem danh sách đã chấm công real-time
- **Lịch sử**: Học viên có thể xem lịch sử chấm công/điểm danh của mình
