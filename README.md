 SUPER CALENDAR

 Product & Software Specification — Prototype v0.1

Nền tảng mục tiêu: Android trước, iOS trong giai đoạn sau
Framework: Flutter
Ngôn ngữ chính: Dart
Native Android: Kotlin khi cần truy cập chức năng hệ thống
Trạng thái: Prototype / Test
Mục tiêu: Xây dựng một ứng dụng productivity kết hợp Calendar, To-do, Notes và Lock Screen Quick Actions, với hệ thống Theme/Template có khả năng mở rộng thành VIP và Marketplace trong tương lai.

---

 1. TỔNG QUAN SẢN PHẨM

 1.1. Ý tưởng

SuperCalendar là một ứng dụng quản lý lịch trình và công việc cá nhân, lấy cảm hứng từ các ứng dụng như Google Calendar và Notion nhưng tập trung vào một trải nghiệm đơn giản hơn:

 Quản lý lịch trình.
 Quản lý To-do.
 Ghi chú.
 Nhắc lịch.
 Hiển thị lịch trình trực tiếp trên Lock Screen.
 Cho phép thao tác nhanh với To-do ngay trên Lock Screen.
 Cá nhân hóa giao diện bằng Theme.
 Trong tương lai cho phép người dùng tạo và bán Template.

Điểm khác biệt chính của SuperCalendar là:

> Người dùng có thể nhìn thấy lịch trình của mình ngay trên Lock Screen và thực hiện các thao tác nhanh với To-do mà không cần mở toàn bộ ứng dụng.

---

 2. MỤC TIÊU CỦA PHIÊN BẢN PROTOTYPE

Prototype đầu tiên không nhằm mục đích thương mại hóa ngay.

Mục tiêu là chứng minh các ý tưởng cốt lõi:

1. Người dùng có thể quản lý Calendar.
2. Người dùng có thể quản lý To-do.
3. Người dùng có thể tạo và quản lý Notes.
4. Dữ liệu được lưu trên thiết bị.
5. Ứng dụng có thể đọc lịch hệ thống nếu người dùng cấp quyền.
6. Ứng dụng có thể gửi Notification.
7. Lock Screen có thể hiển thị lịch trình.
8. Lock Screen có khu vực To-do có thể thao tác.
9. Theme có thể thay đổi giao diện.
10. Có thể mô phỏng VIP.
11. Có thể mô phỏng việc mua và áp dụng Template.
12. Có thể mô phỏng Marketplace mà chưa cần thanh toán thật.

---

 3. ĐỐI TƯỢNG NGƯỜI DÙNG

 3.1. Người dùng thông thường

Có thể:

 Xem lịch (dưới dạng tháng/ tuần).
 Tạo lịch.
 Chỉnh sửa lịch.
 Xóa lịch.
 Tạo To-do.
 Hoàn thành To-do.
 Tạo Notes.
 Nhận Notification.
 Xem lịch trên Lock Screen.
 Sử dụng Theme mặc định.
 Mua/sử dụng Template có sẵn trong prototype.

 3.2. VIP User

Có thêm:

 Custom Theme.
 Theme Builder.
 Custom colors.
 Custom typography.
 Custom layout.
 Tùy chỉnh Lock Screen.
 Tạo Template.
 Publish Template.
 Trong tương lai: bán Template.

 3.3. Creator

Trong phiên bản Marketplace tương lai:

 Tạo Template.
 Upload Template.
 Thêm tên, mô tả, preview.
 Đặt giá.
 Publish.
 Theo dõi lượt mua.
 Nhận doanh thu.

---

 4. PHẠM VI PHIÊN BẢN PROTOTYPE

 4.1. Có trong Prototype

 Core

 Calendar
 To-do
 Notes
 Local Database
 Theme
 Notification
 System Calendar Integration
 Lock Screen
 Mock VIP
 Mock Payment
 Mock Template Marketplace

 4.2. Chưa cần triển khai thật

 Real payment.
 Real subscription.
 Real creator payout.
 Cloud synchronization.
 Server authentication.
 Social login.
 Real marketplace transaction.
 Revenue sharing.
 iOS version.
 Multi-device synchronization.

---

 5. NGUYÊN TẮC UI/UX

 5.1. Phong cách mặc định

SuperCalendar sử dụng phong cách:

 Minimalist.
 Clean.
 Modern.
 Soft.
 Premium nhưng không quá cầu kỳ.

 5.2. Màu chủ đạo

Các màu mặc định:

 White.
 Light Gray.
 Pastel Pink.
 Pastel Blue.
 Pastel Green.
 Pastel Purple.
 Pastel Yellow.

Không sử dụng quá nhiều màu mạnh trong Theme mặc định.

 5.3. Typography

Font mặc định:

 Sans-serif.
 Dễ đọc.
 Không chân.
 Hierarchy rõ ràng.

Ví dụ:


Heading
Subheading
Body
Caption


 5.4. UI components

Các component nên có:

 Rounded cards.
 Rounded buttons.
 Soft shadows.
 Minimal icons.
 Large whitespace.
 Clear hierarchy.

---

 6. KIẾN TRÚC TỔNG QUAN

Prototype được chia thành:


SuperCalendar
│
├── Flutter Application
│   ├── UI
│   ├── Business Logic
│   ├── State Management
│   └── Local Data Access
│
├── Local Database
│
└── Android Native Layer
    ├── System Calendar
    ├── Notification
    └── Lock Screen / Quick Actions


Flutter chịu trách nhiệm chính.

Kotlin/Android Native chỉ được sử dụng khi cần giao tiếp với Android OS.

---

 7. CÁC MÀN HÌNH CHÍNH

 7.1. Home

Home là màn hình tổng quan.

Nội dung:


Good morning

Today
October 2

Next event
18:00 — Java

Tasks
☐ Finish assignment
☐ Review Flutter

Quick access
Calendar
Tasks
Notes


---

 8. CALENDAR

 8.1. Chế độ Month View

Hiển thị:


October 2026

Mon Tue Wed Thu Fri Sat Sun
             1   2   3   4
 5   6   7   8   9  10  11


Ngày có lịch có thể được đánh dấu bằng:

 Dot.
 Accent color.
 Highlight.

 8.2. Day View

Ví dụ:


Friday, October 2

18:00 ── Java
         Room A203

20:00 ── Flutter
         SuperCalendar


 8.3. Event

Một Event bao gồm:


Event
├── ID
├── Title
├── Description
├── Start DateTime
├── End DateTime
├── Location
├── Reminder
├── Color
└── Source


Source có thể là:


local
system_calendar


---

 9. TÍCH HỢP SYSTEM CALENDAR

Ứng dụng có thể yêu cầu quyền truy cập Calendar của Android.

Flow:


User opens Calendar
        ↓
Request Calendar Permission
        ↓
Allow?
    ├── Yes
    │    ↓
    │ Read system events
    │    ↓
    │ Display events
    │
    └── No
         ↓
      Use local events


Ứng dụng phải giải thích rõ lý do cần quyền.

Không được giả định rằng người dùng luôn cấp quyền.

---

 10. TO-DO SYSTEM

 10.1. Task

Một Task gồm:


Task
├── ID
├── Title
├── Description
├── Due Date
├── Due Time
├── Priority
├── Completed
├── Created At
└── Updated At


 10.2. Task State


Incomplete
     ↓
Completed


Khi người dùng tick:


completed = true


 10.3. Task UI


MY TASKS

☐ Finish Java exercise
☐ Push Flutter project
☑ Submit assignment


---

 11. NOTES

Notes có thể được thiết kế đơn giản trong Prototype.

Một Note:


Note
├── ID
├── Title
├── Content
├── Created At
└── Updated At


Ví dụ:


School
├── Java notes
├── Flutter notes
└── English notes


Chưa cần xây hệ thống block editor phức tạp như Notion.

---

 12. NOTIFICATION SYSTEM

Notification được sử dụng cho:

 Event reminder


SuperCalendar

Upcoming event

Java
18:00
Room A203


 Task reminder


SuperCalendar

Task reminder

Finish Java exercise


Notification có thể có Action:


[Done]
[Snooze]


Khi người dùng bấm Done:


Notification Action
       ↓
Find Task
       ↓
completed = true
       ↓
Save database
       ↓
Update UI


---

 13. LOCK SCREEN

Đây là tính năng đặc trưng của SuperCalendar.

 13.1. Cấu trúc

Lock Screen gồm hai khu vực:


┌─────────────────────┐
│                            │
│        SYSTEM TIME         │
│                            │
│ ────── SCHEDULE ────── │
│                            │
│ 18:00  Java                │
│        Room A203           │
│                            │
│ 20:00  Flutter             │
│                            │
│─────────────────────│
│                            │
│ ─────── TO-DO ────────│
│                            │
│ ☐ Finish Java          ✓  │
│ ☐ Push code            ✓  │
│                            │
│ + Add Task                 │
│                            │
└─────────────────────┘


---

 14. LOCK SCREEN — SCHEDULE

Schedule chỉ có quyền:

 View.

Không cho phép:

 Edit.
 Delete.
 Drag.
 Reschedule.

Khi người dùng click vào Event:


Lock Screen
     ↓
Click Event
     ↓
Open SuperCalendar
     ↓
System authentication if required
     ↓
Event detail


Ứng dụng không tự thu thập PIN/password của người dùng.

Việc xác thực phải dựa trên cơ chế bảo mật của hệ điều hành.

---

 15. LOCK SCREEN — TO-DO

To-do có quyền tương tác nhanh.

 15.1. Complete


☐ Finish assignment
        ↓
       ✓
        ↓
completed = true


Dữ liệu được lưu vào database.

App chính sẽ phản ánh:


☑ Finish assignment


 15.2. Add Task

Có thể cung cấp Quick Add.

Ví dụ:


+ Add Task


Mở giao diện nhập task tối giản.

Task sau khi tạo phải được lưu vào cùng database với app chính.

---

 16. DATA SYNCHRONIZATION TRONG THIẾT BỊ

Prototype không cần server.

Mọi dữ liệu nằm trên thiết bị:


Flutter
   ↓
Local Database
   ↓
Calendar
Task
Notes


Lock Screen và Notification cũng đọc/ghi dữ liệu từ cùng nguồn dữ liệu.

Mục tiêu:

> Một dữ liệu duy nhất, nhiều giao diện sử dụng.

Ví dụ:


Task:
Finish Java

Database:
completed = false


User tick trên Lock Screen:


completed = true


App chính lập tức hiển thị:


☑ Finish Java


---

 17. THEME SYSTEM

Theme phải được xây dựng như một hệ thống độc lập với dữ liệu.

Không hard-code màu trực tiếp trong từng màn hình.

Theme gồm:


Theme
├── Colors
├── Typography
├── Spacing
├── Border Radius
├── Shadows
├── Icons
└── Component styles


Ví dụ:


Pastel Pink Theme
Primary = Pink
Background = White
Surface = Soft Pink
 = Dark Gray


---

 18. DEFAULT THEME

Prototype có thể bắt đầu với:

 Pastel Minimal


Background: White
Surface: Light Gray
Primary: Pastel Pink
Secondary: Pastel Purple
: Dark Gray
Font: Sans-serif


Có thể bổ sung:

 Pastel Blue.
 Pastel Green.
 Minimal Gray.

---

 19. VIP SYSTEM

Trong Prototype, VIP chỉ là trạng thái giả lập.


User
├── isVip: true/false


 Free User

Có:

 Default Theme.
 Basic customization.
 Marketplace.
 Purchased Templates.

Không có:

 Full Theme Builder.
 Create Template.
 Sell Template.

 VIP User

Có:

 Full Theme Builder.
 Custom Colors.
 Custom Typography.
 Custom Layout.
 Custom Lock Screen.
 Create Template.
 Publish Template.

---

 20. MOCK PAYMENT

Prototype không xử lý tiền thật.

Flow:


VIP
 ↓
Subscribe
 ↓
Test Payment
 ↓
Payment Success
 ↓
isVip = true


Có thể có:


PaymentResult
├── Success
├── Failed
└── Cancelled


Mục tiêu chỉ là kiểm tra business logic.

---

 21. TEMPLATE SYSTEM

Template là một gói thiết lập giao diện.

Một Template có thể chứa:


Template
├── ID
├── Name
├── Description
├── Author
├── Preview
├── Price
├── Colors
├── Typography
├── Layout
├── Lock Screen Style
└── Metadata


Ví dụ:


Sakura Morning

Pastel pink productivity theme.

Price:
29,000đ

[Preview]
[Buy]


---

 22. TEMPLATE MARKETPLACE — PROTOTYPE

Marketplace giả lập:


Template Store

🌸 Sakura Morning
🩵 Ocean Study
🌿 Forest
🩶 Minimal Gray


Click Template:


Preview
Description
Creator
Price

[Buy]


Mock purchase:


Buy
 ↓
Purchase Success
 ↓
Template unlocked
 ↓
Apply


Không cần payment thật.

---

 23. CREATOR SYSTEM — PROTOTYPE

VIP user có thể:


Create Template
       ↓
Design
       ↓
Preview
       ↓
Set Name
       ↓
Set Price
       ↓
Publish


Template được lưu trong database prototype.

Chưa cần server.

---

 24. DATA MODEL

 User


User
├── id
├── name
├── isVip
├── selectedThemeId
└── createdAt


 Event


Event
├── id
├── title
├── description
├── startTime
├── endTime
├── location
├── reminder
├── color
└── source


 Task


Task
├── id
├── title
├── description
├── dueDate
├── dueTime
├── priority
├── completed
├── createdAt
└── updatedAt


 Note


Note
├── id
├── title
├── content
├── createdAt
└── updatedAt


 Theme


Theme
├── id
├── name
├── colors
├── typography
├── spacing
├── radius
└── lockScreenStyle


 Template


Template
├── id
├── name
├── description
├── creatorId
├── price
├── preview
├── themeData
└── published


 Purchase


Purchase
├── id
├── userId
├── templateId
├── price
├── status
└── purchasedAt


---

 25. ĐIỀU HƯỚNG APP

Navigation cơ bản:


Home
│
├── Calendar
│
├── Tasks
│
├── Notes
│
└── Settings
     │
     ├── Appearance
     ├── VIP
     └── Template Store


Có thể dùng Bottom Navigation:


┌─────────────────────────────┐
│                             │
│         CONTENT             │
│                             │
├─────────────────────────────┤
│ Calendar │ Tasks │ Notes │ + │
└─────────────────────────────┘


---

 26. SETTINGS

Settings gồm:

 Appearance

 Theme.
 Light/Dark.
 Accent color.

 Notifications

 Enable/Disable.
 Reminder timing.

 Calendar

 Calendar permission.
 Default calendar.

 VIP

 VIP status.
 Available features.

 Templates

 Purchased templates.
 Created templates.

---

 27. QUYỀN HỆ THỐNG

Prototype có thể cần:

 Calendar permission

Để đọc lịch hệ thống.

 Notification permission

Để gửi notification.

 Các quyền Android khác

Chỉ yêu cầu khi thực sự cần thiết.

Nguyên tắc:

> Không xin quyền nếu tính năng chưa sử dụng.

---

 28. BẢO MẬT

Ứng dụng không được:

 Lưu PIN/password của người dùng.
 Tự tạo màn hình giả mạo hệ thống để lấy password.
 Lưu thông tin xác thực hệ thống.

Khi cần bảo vệ nội dung, sử dụng cơ chế authentication của Android.

Dữ liệu Lock Screen cũng cần được thiết kế sao cho không vô tình hiển thị thông tin nhạy cảm.

---

 29. BACKEND

 Prototype

Không bắt buộc backend.


Flutter
 ↓
Local Database


 Future Production

Có thể chuyển thành:


Flutter
 ↓
API
 ↓
Backend
 ↓
Database


Backend tương lai xử lý:

 Account.
 Login.
 Cloud Sync.
 Templates.
 Marketplace.
 Purchases.
 Creator.
 Revenue.

---

 30. PAYMENT — FUTURE

Payment thật không nằm trong Prototype v0.1.

Trong phiên bản thương mại:


User
 ↓
Purchase VIP / Template
 ↓
Platform Billing / Payment Provider
 ↓
Payment Verification
 ↓
Backend
 ↓
Grant entitlement


Không tự xử lý thông tin thẻ từ đầu.

---

## FR-20 – ANDROID QUICK NOTE NOTIFICATION

**Description:** Notification cố định cho phép xem và cập nhật Quick Note ngay từ khay thông báo.
**Actor:** User, Android OS · **Screens:** SCR-12 · **Priority:** P2

### Preconditions

- Quick Note Notification được bật trong Settings → Lock Screen.

### Main Flow

1. User kéo khay thông báo xuống.
2. System hiển thị notification "SuperCalendar · Quick Note" với nội dung hiện tại.
3. User mở rộng notification và nhập nội dung vào ô nhập.
4. User nhấn **Save note**.
5. System lưu nội dung vào Quick Note.
6. Notification cập nhật nội dung mới và trạng thái "Saved just now".

### Alternative Flows

- **Open app:** User nhấn **Open app** → mở trình sửa Quick Note trong ứng dụng.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-20.01 | Notification dạng ongoing, User có thể tắt trong Settings. |
| FR-20.02 | Ô nhập dùng RemoteInput; nội dung cũ hiển thị dạng văn bản phía trên ô nhập (UI-08). |
| FR-20.03 | Người dùng chọn chế độ ghi: **Replace** (thay thế) hoặc **Append** (nối thêm), mặc định Append. |
| FR-20.04 | Giới hạn 500 ký tự giống Quick Note (FR-11.02). |

---

## FR-21 – SETTINGS

**Description:** Quản lý cấu hình ứng dụng theo nhóm.
**Actor:** Free User, VIP User · **Screens:** SCR-10, SCR-20 · **Priority:** P1

### Main Flow

1. User mở tab Settings.
2. System hiển thị thẻ tài khoản và danh sách nhóm cài đặt, mỗi dòng kèm giá trị hiện tại.
3. User chọn một nhóm.
4. System mở trang con.
5. User thay đổi cài đặt.
6. System lưu ngay và áp dụng.

### Settings Groups

| Group | UI Value | Details |
|---|---|---|
| Account | Tên người dùng | Profile, Avatar, Email, VIP Status |
| Appearance | Light / Dark / System | Theme, màu, phông, kiểu widget |
| Language | English | English, Tiếng Việt |
| Date & Time | Automatic | Định dạng ngày, 12h/24h, ngày bắt đầu tuần, múi giờ |
| Calendar | Personal + Work | Calendar mặc định, calendar hiển thị, quyền System Calendar, thời lượng event mặc định |
| Tasks | — | Priority mặc định, reminder mặc định, hành vi task đã hoàn thành (giữ/ẩn) |
| Notifications | On / Off | Bật/tắt chung và theo loại Event/Task/Habit/Goal, âm thanh |
| Lock Screen | Schedule · To-do · Note | Bật/tắt từng khối, Quick actions, Hide details, Quick Note Notification |
| Data | — | Export/Import backup (JSON), xóa toàn bộ dữ liệu |
| Help | — | User Guide, FAQ, gửi phản hồi |
| About | Phiên bản | Version, Privacy Policy, Terms of Use |

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-21.01 | Mỗi dòng hiển thị giá trị hiện tại bên phải và mở trang con khi chạm. |
| FR-21.02 | Thay đổi cài đặt được lưu ngay, không cần nút Save. |
| FR-21.03 | Đổi Language áp dụng ngay cho toàn ứng dụng. |
| FR-21.04 | Xóa toàn bộ dữ liệu yêu cầu xác nhận hai bước (hộp thoại + nhập "DELETE"). |
| FR-21.05 | Import backup ghi đè dữ liệu hiện tại sau khi người dùng xác nhận. |

---

## FR-22 – SYSTEM CALENDAR INTEGRATION

**Description:** Đọc sự kiện từ lịch hệ thống Android và hiển thị cùng Local Event.
**Actor:** User, Android OS · **Screens:** SCR-20 · **Priority:** P2

### Main Flow

1. User mở Settings → Calendar → "Connect device calendars".
2. System giải thích mục đích sử dụng quyền.
3. Android hiển thị hộp thoại cấp quyền READ_CALENDAR.
4. User cho phép.
5. System đọc danh sách calendar trên thiết bị.
6. User chọn calendar muốn hiển thị.
7. System hiển thị event từ các calendar đã chọn trên Calendar, Home, Lock Screen.

### Alternative Flows

- **4a.** User từ chối → Local Calendar hoạt động bình thường, không hiển thị event hệ thống.
- **Revoke:** User thu hồi quyền trong cài đặt Android → System ẩn toàn bộ event hệ thống ở lần mở tiếp theo.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-22.01 | Event hệ thống có `Source = system_calendar`, chỉ đọc, hiển thị biểu tượng nguồn. |
| FR-22.02 | Event hệ thống không ghi đè và không trùng lặp với Local Event. |
| FR-22.03 | Dữ liệu event hệ thống được đọc lại mỗi lần mở Calendar và khi kéo để làm mới. |

---

# 5. ENTITY AND DATA REQUIREMENTS

## 5.1 User

| Field | Type | Required | Description |
|---|---|---|---|
| UserID | UUID | Yes | Định danh người dùng |
| DisplayName | String(30) | Yes | Tên hiển thị |
| Email | String | No | Email |
| Avatar | String (path) | No | Đường dẫn ảnh đại diện |
| VIPStatus | Enum (Free, VIP) | Yes | Trạng thái gói |
| CreatedAt | DateTime | Yes | Ngày tạo |
| UpdatedAt | DateTime | Yes | Ngày cập nhật |

## 5.2 UserSettings

| Field | Type | Required | Description |
|---|---|---|---|
| UserID | UUID (FK) | Yes | Người dùng |
| ThemeMode | Enum (Light, Dark, System) | Yes | Chế độ giao diện |
| ThemeID | UUID (FK) | Yes | Theme đang dùng |
| Language | String | Yes | Ngôn ngữ |
| DateFormat | String | Yes | Định dạng ngày |
| TimeFormat | Enum (12h, 24h) | Yes | Định dạng giờ |
| WeekStart | Enum (Mon, Sun) | Yes | Ngày bắt đầu tuần |
| DefaultEventDuration | Integer (phút) | Yes | Thời lượng event mặc định |
| DefaultReminderOffset | Integer (phút) | No | Reminder mặc định |
| DefaultPriority | Enum | No | Priority mặc định cho task |
| HideCompletedTasks | Boolean | Yes | Ẩn task đã hoàn thành |
| NotificationConfig | JSON | Yes | Bật/tắt theo loại |
| LockScreenConfig | JSON | Yes | Khối hiển thị, Quick actions, Hide details |

## 5.3 Category

| Field | Type | Required | Description |
|---|---|---|---|
| CategoryID | UUID | Yes | ID |
| Name | String(30) | Yes | Tên (Work, Personal, …) |
| Color | String (hex) | Yes | Màu hiển thị |
| IsDefault | Boolean | Yes | Danh mục hệ thống, không xóa được |

## 5.4 CalendarSource

| Field | Type | Required | Description |
|---|---|---|---|
| CalendarID | UUID | Yes | ID |
| Name | String | Yes | Tên lịch (ví dụ Personal) |
| Owner | String | No | Chủ sở hữu (ví dụ Mia) |
| Color | String (hex) | Yes | Màu |
| Type | Enum (Local, System) | Yes | Nguồn |
| ExternalID | String | No | ID lịch trên Android |
| IsVisible | Boolean | Yes | Có hiển thị hay không |

## 5.5 Event

| Field | Type | Required | Description |
|---|---|---|---|
| EventID | UUID | Yes | ID |
| CalendarID | UUID (FK) | Yes | Lịch chứa event |
| Title | String(100) | Yes | Tên event |
| StartDateTime | DateTime | Yes | Bắt đầu |
| EndDateTime | DateTime | Yes | Kết thúc |
| IsAllDay | Boolean | Yes | Cả ngày |
| Location | String(200) | No | Địa điểm |
| CategoryID | UUID (FK) | No | Danh mục |
| Color | String (hex) | No | Màu riêng |
| ReminderOffset | Integer (phút) | No | Nhắc trước |
| RepeatRule | String (RRULE) | No | Quy tắc lặp |
| Notes | String(1000) | No | Ghi chú |
| Source | Enum (local, system_calendar) | Yes | Nguồn dữ liệu |
| ExternalID | String | No | ID event trên Android |
| CreatedAt | DateTime | Yes | Ngày tạo |
| UpdatedAt | DateTime | Yes | Ngày cập nhật |

## 5.6 EventGuest

| Field | Type | Required | Description |
|---|---|---|---|
| GuestID | UUID | Yes | ID |
| EventID | UUID (FK) | Yes | Event |
| Name | String(50) | Yes | Tên khách |
| Initials | String(2) | Yes | Chữ viết tắt hiển thị |

## 5.7 EventException

| Field | Type | Required | Description |
|---|---|---|---|
| ExceptionID | UUID | Yes | ID |
| EventID | UUID (FK) | Yes | Event lặp gốc |
| OriginalDate | Date | Yes | Ngày của lần lặp bị thay đổi |
| IsDeleted | Boolean | Yes | Lần lặp bị xóa |
| OverrideData | JSON | No | Dữ liệu thay đổi riêng |

## 5.8 Task

| Field | Type | Required | Description |
|---|---|---|---|
| TaskID | UUID | Yes | ID |
| Title | String(200) | Yes | Tên task |
| DueDate | Date | No | Hạn ngày |
| DueTime | Time | No | Hạn giờ |
| Priority | Enum (None, Low, Medium, High) | Yes | Mức ưu tiên |
| ReminderOffset | Integer (phút) | No | Nhắc trước |
| RepeatRule | String (RRULE) | No | Quy tắc lặp |
| CategoryID | UUID (FK) | No | Danh mục |
| Color | String (hex) | No | Màu |
| Notes | String(1000) | No | Ghi chú |
| EstimatedMinutes | Integer | No | Thời gian dự kiến |
| IsCompleted | Boolean | Yes | Trạng thái hoàn thành |
| CompletedAt | DateTime | No | Thời điểm hoàn thành |
| SortOrder | Integer | Yes | Thứ tự hiển thị |
| CreatedAt | DateTime | Yes | Ngày tạo |
| UpdatedAt | DateTime | Yes | Ngày cập nhật |

## 5.9 TaskSubtask

| Field | Type | Required | Description |
|---|---|---|---|
| SubtaskID | UUID | Yes | ID |
| TaskID | UUID (FK) | Yes | Task cha |
| Title | String(200) | Yes | Nội dung |
| IsCompleted | Boolean | Yes | Trạng thái |
| SortOrder | Integer | Yes | Thứ tự |

## 5.10 Tag và TaskTag

| Entity | Field | Type | Description |
|---|---|---|---|
| Tag | TagID | UUID | ID |
| Tag | Name | String(30) | Tên tag, duy nhất |
| TaskTag | TaskID | UUID (FK) | Task |
| TaskTag | TagID | UUID (FK) | Tag |

## 5.11 Goal

| Field | Type | Required | Description |
|---|---|---|---|
| GoalID | UUID | Yes | ID |
| Type | Enum (Weekly, Monthly) | Yes | Loại goal |
| Title | String(60) | Yes | Tên |
| Icon | String | No | Biểu tượng |
| Color | String (hex) | No | Màu |
| Target | Integer | No | Mục tiêu số lần |
| Current | Integer | Yes | Tiến độ hiện tại (mặc định 0) |
| PeriodStart | Date | Yes | Ngày bắt đầu kỳ |
| PeriodEnd | Date | Yes | Ngày kết thúc kỳ |
| Status | Enum (Active, Completed, Missed) | Yes | Trạng thái |
| CreatedAt | DateTime | Yes | Ngày tạo |
| UpdatedAt | DateTime | Yes | Ngày cập nhật |

## 5.12 Habit

| Field | Type | Required | Description |
|---|---|---|---|
| HabitID | UUID | Yes | ID |
| Title | String(60) | Yes | Tên habit |
| Icon | String | No | Biểu tượng |
| Color | String (hex) | No | Màu |
| StartDate | Date | Yes | Ngày bắt đầu |
| EndDate | Date | No | Ngày kết thúc |
| Time | Time | No | Giờ thực hiện |
| RepeatRule | String (RRULE) | Yes | Quy tắc lặp |
| ReminderOffset | Integer (phút) | No | Nhắc trước |
| IsArchived | Boolean | Yes | Đã lưu trữ |
| CreatedAt | DateTime | Yes | Ngày tạo |
| UpdatedAt | DateTime | Yes | Ngày cập nhật |

## 5.13 HabitOccurrence

| Field | Type | Required | Description |
|---|---|---|---|
| OccurrenceID | UUID | Yes | ID |
| HabitID | UUID (FK) | Yes | Habit Rule |
| Date | Date | Yes | Ngày xuất hiện |
| Status | Enum (Pending, Done, Skipped, Deleted) | Yes | Trạng thái |
| OverrideData | JSON | No | Thay đổi riêng cho ngày này |
| CompletedAt | DateTime | No | Thời điểm hoàn thành |

## 5.14 Note

| Field | Type | Required | Description |
|---|---|---|---|
| NoteID | UUID | Yes | ID |
| Title | String(100) | No | Tiêu đề |
| Content | Text | Yes | Nội dung (Quick Note tối đa 500 ký tự) |
| Color | String (hex) | No | Màu |
| IsPinned | Boolean | Yes | Ghim |
| IsQuickNote | Boolean | Yes | Là Quick Note đang hoạt động |
| CreatedAt | DateTime | Yes | Ngày tạo |
| UpdatedAt | DateTime | Yes | Ngày cập nhật |

## 5.15 Theme

| Field | Type | Required | Description |
|---|---|---|---|
| ThemeID | UUID | Yes | ID |
| Name | String | Yes | Tên |
| Colors | JSON | Yes | Bảng màu |
| Typography | JSON | Yes | Phông và cỡ chữ |
| Radius | Integer | Yes | Bo góc |
| ComponentStyle | JSON | Yes | Kiểu thành phần |
| IsVIP | Boolean | Yes | Thuộc gói Premium |

## 5.16 WidgetTemplate

| Field | Type | Required | Description |
|---|---|---|---|
| TemplateID | UUID | Yes | ID |
| Name | String(50) | Yes | Tên |
| Description | String | No | Mô tả |
| WidgetType | Enum | Yes | Loại widget hoặc Dashboard |
| Category | String | No | Danh mục |
| Configuration | JSON | Yes | Layout, màu, phông, kiểu thẻ, kích thước |
| PreviewImage | String (path) | No | Ảnh xem trước |
| CreatorID | UUID (FK) | No | Người tạo (rỗng nếu là mẫu hệ thống) |
| IsSystem | Boolean | Yes | Mẫu có sẵn |
| IsPremium | Boolean | Yes | Thuộc gói Premium |
| Price | Decimal | No | Giá (Marketplace) |
| Status | Enum (Draft, Published, Unpublished) | Yes | Trạng thái |
| CreatedAt | DateTime | Yes | Ngày tạo |
| UpdatedAt | DateTime | Yes | Ngày cập nhật |

## 5.17 DashboardLayout

| Field | Type | Required | Description |
|---|---|---|---|
| LayoutID | UUID | Yes | ID |
| UserID | UUID (FK) | Yes | Người dùng |
| Target | Enum (Home, LockScreen) | Yes | Bố cục cho Home hay Lock Screen |
| ViewMode | Enum (Month, Week) | Yes | Kiểu lịch hiển thị |
| BackgroundType | Enum (Image, Color, Gradient) | Yes | Loại nền |
| BackgroundValue | String | Yes | Đường dẫn ảnh hoặc mã màu |
| FontFamily | String | Yes | Phông chữ |
| TemplateID | UUID (FK) | Yes | Template đang áp dụng |
| IsActive | Boolean | Yes | Bố cục đang dùng |

## 5.18 WidgetPlacement

| Field | Type | Required | Description |
|---|---|---|---|
| PlacementID | UUID | Yes | ID |
| LayoutID | UUID (FK) | Yes | Bố cục |
| WidgetType | Enum | Yes | Loại widget |
| PositionX | Integer | Yes | Cột trên lưới |
| PositionY | Integer | Yes | Hàng trên lưới |
| Size | Enum (S, M, L) | Yes | Kích thước |
| Config | JSON | No | Cấu hình riêng (số dòng, nguồn dữ liệu) |

## 5.19 Purchase

| Field | Type | Required | Description |
|---|---|---|---|
| PurchaseID | UUID | Yes | ID |
| UserID | UUID (FK) | Yes | Người mua |
| ProductType | Enum (VIP, Template) | Yes | Loại sản phẩm |
| ProductID | String | Yes | Gói VIP hoặc TemplateID |
| Price | Decimal | Yes | Giá mô phỏng |
| PurchaseDate | DateTime | Yes | Ngày mua |
| Status | Enum (Completed, Cancelled) | Yes | Trạng thái |

## 5.20 Reminder

| Field | Type | Required | Description |
|---|---|---|---|
| ReminderID | UUID | Yes | ID |
| SourceType | Enum (Event, Task, Habit, Goal) | Yes | Loại dữ liệu nguồn |
| SourceID | UUID | Yes | ID dữ liệu nguồn |
| TriggerAt | DateTime | Yes | Thời điểm nhắc |
| Status | Enum (Scheduled, Fired, Snoozed, Cancelled) | Yes | Trạng thái |

## 5.21 Relationships

```text
User            1 ─ 1  UserSettings
User            1 ─ N  Purchase
User            1 ─ N  DashboardLayout
CalendarSource  1 ─ N  Event
Event           1 ─ N  EventGuest
Event           1 ─ N  EventException
Category        1 ─ N  Event
Category        1 ─ N  Task
Task            1 ─ N  TaskSubtask
Task            N ─ N  Tag            (qua TaskTag)
Habit           1 ─ N  HabitOccurrence
WidgetTemplate  1 ─ N  DashboardLayout
DashboardLayout 1 ─ N  WidgetPlacement
Event | Task | Habit | Goal  1 ─ N  Reminder
```

---

# 6. FUNCTIONAL RELATIONSHIP

## 6.1 Functional Map

```text
                              SUPER CALENDAR
                                    │
      ┌─────────────────┬───────────┴───────────┬──────────────────────┐
      │                 │                       │                      │
     PLAN               DO                PERSONALIZE             SEE IT FIRST
      │                 │                       │                      │
   Calendar           To-do            Theme / Templates      Home / Lock Screen /
      │                 │                       │                 Notification
 ┌────┼─────┐           │            ┌──────────┼──────────┐           │
 │    │     │           │            │          │          │           │
Event Goal Habit       Task     Edit Your   Template    Template   Quick Note
                        │        Screen     (Free)       Studio
                     Subtask                               │
                                                          VIP
```

## 6.2 Data Flow

```text
        ┌────────────── SOURCE OF TRUTH (Local Database) ──────────────┐
        │   Event    Task/Subtask    Goal    Habit/Occurrence    Note   │
        └──────────────────────────────┬────────────────────────────────┘
                                       │  read + write-back
          ┌──────────────┬─────────────┼──────────────┬───────────────┐
          │              │             │              │               │
     Home Widgets   Lock Screen   Notification   Month Snapshot   Calendar /
                                                  (read only)     To-do screens
```

## 6.3 Template Ecosystem

```text
Home ── Create More ──┐
                      ├── Free Templates (3) ── Preview ── Apply
Edit Your Screen ─────┤
                      └── Premium Templates ── Paywall ── Mock Purchase ── Apply
                                                  │
VIP Tab ── Template Studio ── Canvas / Styles / Presets ── Save ── Apply
                                                  │
                         (P3) Marketplace ── Browse / Search / Purchase / Publish
```

---

# 7. BUSINESS RULES

| ID | Rule |
|---|---|
| BR-01 | Event (có thời gian cụ thể) và Task (việc cần hoàn thành) là hai loại dữ liệu riêng, không dùng thay nhau. |
| BR-02 | Habit Rule và Habit Occurrence được quản lý riêng; thao tác trên một occurrence không thay đổi Rule. |
| BR-03 | Weekly Goal và Monthly Goal phân biệt bằng Goal Type và không trộn dữ liệu. |
| BR-04 | Theme điều khiển giao diện toàn ứng dụng. |
| BR-05 | Widget Template và Template Studio chỉ điều khiển phần trình bày widget và bố cục dashboard. |
| BR-06 | Mọi chức năng Premium kiểm tra quyền qua `canAccess(feature)` dựa trên VIP Status. |
| BR-07 | Sở hữu template không đồng nghĩa với đang áp dụng template. |
| BR-08 | Notification, Lock Screen, Widget và Snapshot không là nguồn dữ liệu độc lập. |
| BR-09 | Quick Note dùng chung bảng Note; chỉ có một Quick Note hoạt động. |
| BR-10 | Sửa/xóa event lặp lại phải chọn phạm vi: một lần, từ lần này trở đi, hoặc tất cả. |
| BR-11 | Goal có Current = Target thì chuyển Completed; hết kỳ chưa đạt thì chuyển Missed. |
| BR-12 | Dữ liệu đã lưu phải còn sau khi mở lại ứng dụng hoặc khởi động lại thiết bị. |
| BR-13 | Mọi thao tác xóa phải có xác nhận hoặc Undo. |
| BR-14 | Ứng dụng không yêu cầu và không lưu PIN, mật khẩu, dữ liệu sinh trắc học của thiết bị. |
| BR-15 | Tuần và số tuần tính theo ISO-8601 khi tuần bắt đầu Thứ Hai. |
| BR-16 | Event từ System Calendar chỉ đọc trong Prototype. |
| BR-17 | Đổi Repeat Rule của Habit chỉ ảnh hưởng occurrence từ hôm nay trở đi. |

---

# 8. NON-FUNCTIONAL REQUIREMENTS

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | Performance | Từ lúc mở ứng dụng đến khi Home hiển thị ≤ 2 giây (cold start, thiết bị tầm trung). |
| NFR-02 | Performance | Tạo, sửa, xóa, tick, tìm kiếm phản hồi ≤ 300 ms; chuyển tab ≤ 300 ms. |
| NFR-03 | Performance | Kéo thả widget trong Edit Your Screen đạt ≥ 55 fps. |
| NFR-04 | Reliability | Không mất dữ liệu khi ứng dụng bị buộc dừng giữa chừng (ghi theo transaction). |
| NFR-05 | Reliability | Reminder vẫn hoạt động sau khi khởi động lại thiết bị. |
| NFR-06 | Usability | Thao tác nhanh (thêm task, tick habit, sửa Quick Note) cần ≤ 2 lần chạm. |
| NFR-07 | Usability | Giao diện tối giản, ít menu, không yêu cầu nhập nhiều thông tin khi thao tác nhanh. |
| NFR-08 | Accessibility | Vùng chạm ≥ 48 dp; độ tương phản chữ đạt WCAG AA; hỗ trợ TalkBack và cỡ chữ hệ thống. |
| NFR-09 | Localization | Không hard-code chuỗi; hỗ trợ English và Tiếng Việt. |
| NFR-10 | Security | Dữ liệu lưu trong vùng riêng của ứng dụng; nội dung trên Lock Screen có thể ẩn. |
| NFR-11 | Compatibility | Android 8.0 (API 26) trở lên; xử lý riêng quyền Notification (API 33+) và Exact Alarm (API 31+). |
| NFR-12 | Maintainability | Kiến trúc tách lớp UI – State – Repository – Data Source để mở rộng Backend, Cloud Sync, iOS, Marketplace, thanh toán thật. |

---

# 9. PROTOTYPE SCOPE

| Group | Functions | Priority |
|---|---|---|
| Core | Home, Calendar Month/Week, Event CRUD, Goal, Habit, To-do, Task Details, Subtask, Quick Note | P1 |
| Personalization | Theme, Dark Mode, Edit Your Screen, Widget Template, 3 Free Template, Template Studio | P1 |
| Monetization | VIP Status, Premium Feature Gating, Paywall, Mock Purchase | P1 |
| System Integration | Notification, Reminder, Lock Screen, Settings | P1 |
| Extended | Onboarding, Notes List, Month Snapshot, Quick Note Notification, System Calendar (đọc), Habit streak | P2 |

---

# 10. OUT OF SCOPE

Các chức năng sau không thuộc Prototype và có thể phát triển ở phiên bản Production:

| Group | Functions |
|---|---|
| Backend & Account | Real Backend, Real Account Authentication, Cloud Sync, đồng bộ nhiều thiết bị |
| Payment | Real Payment Gateway, Credit Card Processing, Banking Integration, Google Play Billing |
| Marketplace | Template Marketplace, Publish template, Real Marketplace Backend, Creator Revenue Sharing, Creator Payout, Complex Moderation, Review/Rating System |
| Social | Social Network, Chat, Team Collaboration, gửi lời mời Guests thật, Public Social Sharing trong ứng dụng |
| Calendar | Ghi ngược vào System Calendar, Advanced Third-party Calendar Synchronization (Google/Outlook API) |
| Others | AI Assistant, nhắc nhở theo vị trí hoặc giờ mặt trời, đặt hình nền tự động, phiên bản iOS |

---

# 11. ACCEPTANCE CRITERIA

## 11.1 Navigation & General

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-01 | Given mở ứng dụng – Then Home hiển thị mặc định và có đúng 5 tab: Home, Calendar, To-do, VIP, Settings. |
| AC-02 | Given vừa tạo task – When buộc dừng và mở lại ứng dụng – Then task vẫn còn. |
| AC-03 | Given vừa xóa một mục – When nhấn Undo trong 5 giây – Then mục được khôi phục nguyên vẹn. |

## 11.2 Onboarding & Account

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-04 | Given mở ứng dụng lần đầu – When nhập tên "Mia" – Then Home hiển thị "Good morning, Mia" (trước 12:00). |
| AC-05 | Given từ chối quyền Notification – Then ứng dụng vẫn dùng được và Settings → Notifications có cảnh báo. |
| AC-06 | When đổi Display Name thành "An" – Then lời chào trên Home cập nhật ngay. |

## 11.3 Home & Edit Your Screen

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-07 | Given có 3 task hôm nay – When tick 1 task trên widget Home – Then task gạch ngang trên Home, To-do List và Lock Screen. |
| AC-08 | When kéo widget Habits vào bản xem trước và nhấn Done – Then Home hiển thị widget Habits đúng vị trí sau khi mở lại ứng dụng. |
| AC-09 | When thả widget vào vùng đồng hồ – Then widget tự trở về vị trí hợp lệ gần nhất. |
| AC-10 | Given User Free – When chọn phông Premium – Then Paywall hiển thị. |

## 11.4 Calendar & Event

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-11 | Given Month View tháng 10/2026, tuần bắt đầu Thứ Hai – Then ngày 1 nằm cột Thứ Năm và ngày 5 nằm cột Thứ Hai. |
| AC-12 | Given Week View tuần 5–11/10/2026 – Then dòng phụ hiển thị "Week 41". |
| AC-13 | When chọn ngày 14 rồi chạm lần hai – Then form New event mở với Date = 14/10. |
| AC-14 | When Start = 15:00 và End = 14:00 – Then không lưu được và hiển thị lỗi dưới trường Time. |
| AC-15 | Given event lặp "Every Monday" – When xóa và chọn "Chỉ sự kiện này" – Then chỉ lần đó biến mất. |
| AC-16 | When xóa một event có reminder – Then không còn notification nào cho event đó. |

## 11.5 Goal & Habit

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-17 | Given goal "12 workouts" có Current = 11 – When chạm chip – Then goal chuyển Completed và "x of y" tăng 1. |
| AC-18 | Given Month View – When tạo goal từ thẻ Monthly Goals – Then goal có Type = Monthly và không xuất hiện ở Weekly Goals. |
| AC-19 | When chọn "Skip occurrence" cho "Read 20 minutes" hôm nay – Then hôm nay là Skipped, các ngày lặp kế tiếp vẫn còn. |
| AC-20 | When đổi Repeat Rule của habit – Then occurrence các ngày đã qua giữ nguyên, các ngày từ hôm nay cập nhật. |

## 11.6 To-do & Task

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-21 | When gõ "Mua sữa" vào "Add a new task" và nhấn Enter – Then task xuất hiện đầu danh sách, ô nhập trống và vẫn focus. |
| AC-22 | Given đang ở bộ lọc Today – When thêm task – Then task có DueDate = hôm nay. |
| AC-23 | When kéo task thứ 3 lên đầu – Then thứ tự mới được giữ sau khi mở lại ứng dụng. |
| AC-24 | Given task có 3 subtask – When xóa task – Then 3 subtask bị xóa và reminder bị hủy. |
| AC-25 | Given task lặp "Weekdays" – When hoàn thành vào thứ Sáu – Then lần kế tiếp có DueDate là thứ Hai. |

## 11.7 Notes, Snapshot & Theme

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-26 | When nhập 500 ký tự vào Quick Note – Then không nhập thêm được và bộ đếm hiển thị 500/500. |
| AC-27 | When sửa Quick Note trên Home – Then Lock Screen và Notification hiển thị nội dung mới. |
| AC-28 | When nhấn "Save image" – Then ảnh PNG đúng độ phân giải màn hình xuất hiện trong thư viện ảnh. |
| AC-29 | When chuyển Appearance sang Dark – Then toàn ứng dụng đổi giao diện ngay, không cần khởi động lại. |

## 11.8 Template, VIP & Template Studio

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-30 | Given User Free – Then có đúng 3 Free Template dùng được, các template còn lại có biểu tượng khóa. |
| AC-31 | Given User Free – When mở template Premium và hoàn tất Mock Purchase – Then template mở khóa ngay và có bản ghi Purchase. |
| AC-32 | Given VIP User – When đổi Widget size sang L trong Template Studio – Then bản xem trước cập nhật ngay. |
| AC-33 | When lưu template trong Template Studio – Then template xuất hiện trong tab Presets. |
| AC-34 | Given VIP User có template riêng – When Downgrade to Free – Then template bị khóa và bố cục về Free Template mặc định. |

## 11.9 Notification & Lock Screen

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-35 | When chọn Done trên notification của task – Then task Completed và không phát sinh task mới. |
| AC-36 | Given có reminder lúc 09:00 – When khởi động lại thiết bị lúc 08:00 – Then notification vẫn hiển thị lúc 09:00. |
| AC-37 | When chạm khối Schedule trên Lock Screen – Then Android yêu cầu mở khóa trước khi mở ứng dụng. |
| AC-38 | Given bật Hide details – Then Lock Screen chỉ hiển thị số lượng event/task. |
| AC-39 | When nhập nội dung trong notification Quick Note và nhấn Save note – Then widget Quick Note trên Home hiển thị nội dung mới. |

## 11.10 Settings & System Calendar

| ID | Scenario (Given – When – Then) |
|---|---|
| AC-40 | When đổi ngày bắt đầu tuần sang Chủ Nhật – Then Month View và Week View cập nhật ngay. |
| AC-41 | When đổi Language sang Tiếng Việt – Then toàn bộ giao diện chuyển sang Tiếng Việt. |
| AC-42 | Given cấp quyền Calendar – Then event hệ thống hiển thị với biểu tượng nguồn và không sửa được. |
| AC-43 | Given từ chối quyền Calendar – Then Local Event vẫn tạo và hiển thị bình thường. |

---

# 12. REQUIREMENT TRACEABILITY

## 12.1 Development Flow

```text
FUNCTIONAL REQUIREMENTS (FR)
        ↓
USE CASE SPECIFICATION
        ↓
UI/UX DESIGN (SCR)
        ↓
DATABASE DESIGN (Entity)
        ↓
CLASS / ARCHITECTURE DESIGN
        ↓
FLUTTER IMPLEMENTATION
        ↓
ANDROID NATIVE INTEGRATION
        ↓
TEST CASE (AC)
        ↓
ACCEPTANCE TEST
```

- Mỗi chức năng được triển khai phải có FR tương ứng.
- Mỗi màn hình phải truy ngược được về ít nhất một FR.
- Mỗi Test Case phải ghi rõ FR và AC mà nó kiểm tra.

## 12.2 Traceability Matrix

| FR | Name | Screens | Entities | Acceptance Criteria | Priority |
|---|---|---|---|---|---|
| FR-01 | Onboarding & Permission | SCR-13 | User, UserSettings | AC-04, AC-05 | P2 |
| FR-02 | Account & Profile | SCR-10, SCR-20 | User | AC-06 | P1 |
| FR-03 | Home Dashboard | SCR-01 | DashboardLayout, WidgetPlacement | AC-07 | P1 |
| FR-04 | Edit Your Screen | SCR-02 | DashboardLayout, WidgetPlacement | AC-08, AC-09, AC-10 | P1 |
| FR-05 | Calendar | SCR-03, SCR-04 | Event, Goal | AC-11, AC-12, AC-13 | P1 |
| FR-06 | Event Management | SCR-05 | Event, EventGuest, EventException, Reminder | AC-14, AC-15, AC-16 | P1 |
| FR-07 | Goal Management | SCR-03, SCR-04, SCR-14 | Goal | AC-17, AC-18 | P1 |
| FR-08 | Habit Management | SCR-06, SCR-15 | Habit, HabitOccurrence | AC-19, AC-20 | P1 |
| FR-09 | To-do List | SCR-07, SCR-21 | Task | AC-21, AC-22, AC-23 | P1 |
| FR-10 | Task Details & Subtask | SCR-08 | Task, TaskSubtask, Tag, TaskTag | AC-24, AC-25 | P1 |
| FR-11 | Notes & Quick Note | SCR-01, SCR-11, SCR-12, SCR-16 | Note | AC-26, AC-27 | P1 |
| FR-12 | Month Snapshot & Save Image | SCR-01, SCR-19 | Event, DashboardLayout | AC-28 | P2 |
| FR-13 | Theme & Appearance | SCR-10, SCR-20 | Theme, UserSettings | AC-29 | P1 |
| FR-14 | Widget Template | SCR-01, SCR-02, SCR-09 | WidgetTemplate | AC-30 | P1 |
| FR-15 | VIP & Paywall | SCR-09, SCR-17 | User, Purchase | AC-31, AC-34 | P1 |
| FR-16 | Template Studio | SCR-09 | WidgetTemplate | AC-32, AC-33 | P1 |
| FR-17 | Template Marketplace & Publish | SCR-18 | WidgetTemplate, Purchase | — | P3 |
| FR-18 | Notification & Reminder | System | Reminder | AC-16, AC-35, AC-36 | P1 |
| FR-19 | Lock Screen | SCR-11 | Event, Task, Note, UserSettings | AC-37, AC-38 | P1 |
| FR-20 | Android Quick Note Notification | SCR-12 | Note | AC-39 | P2 |
| FR-21 | Settings | SCR-10, SCR-20 | UserSettings | AC-40, AC-41 | P1 |
| FR-22 | System Calendar Integration | SCR-20 | CalendarSource, Event | AC-42, AC-43 | P2 |

---

# 13. FUNCTIONAL REQUIREMENTS SUMMARY

| ID | Functional Requirement | Main Responsibility |
|---|---|---|
| FR-01 | Onboarding & Permission | Giới thiệu, tạo local account, xin quyền |
| FR-02 | Account & Profile | Quản lý thông tin cá nhân và VIP Status |
| FR-03 | Home Dashboard | Tổng quan trong ngày bằng widget |
| FR-04 | Edit Your Screen | Kéo thả, resize widget, nền, phông |
| FR-05 | Calendar | Month/Week View và điều hướng lịch |
| FR-06 | Event Management | Tạo, sửa, xóa sự kiện |
| FR-07 | Goal Management | Mục tiêu Weekly/Monthly |
| FR-08 | Habit Management | Habit Rule và Occurrence |
| FR-09 | To-do List | Danh sách task, Quick Add, lọc, sắp xếp |
| FR-10 | Task Details & Subtask | Chi tiết task và công việc con |
| FR-11 | Notes & Quick Note | Ghi chú nhanh dùng chung một nguồn |
| FR-12 | Month Snapshot & Save Image | Xuất lịch tháng thành ảnh |
| FR-13 | Theme & Appearance | Giao diện toàn ứng dụng |
| FR-14 | Widget Template | Mẫu trình bày widget |
| FR-15 | VIP & Paywall | Kiểm soát Premium và nâng cấp |
| FR-16 | Template Studio | VIP tự thiết kế template |
| FR-17 | Template Marketplace & Publish | Khám phá và chia sẻ template (P3) |
| FR-18 | Notification & Reminder | Nhắc nhở và thao tác nhanh |
| FR-19 | Lock Screen | Lịch trình, To-do, Quick Note trên màn hình khóa |
| FR-20 | Android Quick Note Notification | Sửa Quick Note từ khay thông báo |
| FR-21 | Settings | Cấu hình ứng dụng |
| FR-22 | System Calendar Integration | Đọc lịch hệ thống Android |

---

# 14. FINAL SYSTEM FUNCTIONAL STRUCTURE

### CORE NAVIGATION

**Home → Calendar → To-do → VIP → Settings**

### CALENDAR MANAGEMENT

**Calendar (Month/Week) → Event → Goal → Habit**

### PRODUCTIVITY

**To-do List → Task Details → Subtask → Reminder**

### QUICK CAPTURE

**Quick Note → Home Widget / Lock Screen / Notification → Note Database**

### PERSONALIZATION

**Theme → Edit Your Screen → Widget Template → Template Studio**

### PREMIUM

**Feature Lock → Paywall → Mock Purchase → VIP → Premium Access**

### SYSTEM INTEGRATION

**Reminder → Notification (Done / Snooze / Skip)**

**Lock Screen → Schedule / To-do / Quick Note**

**System Calendar → Event (read only)**

### FUTURE

**Template Marketplace → Purchase → Ownership → Apply → Publish**

---

# 15. UI REVIEW NOTES

| ID | Screen | Issue | Recommendation |
|---|---|---|---|
| UI-01 | SCR-03 | Lưới tháng 10/2026 lệch một ngày: ngày 5 nằm cột Chủ Nhật, trong khi header ghi "Monday, October 5" và Week View ghi "M 5". Thực tế 1/10/2026 là Thứ Năm. | Hàng đầu sửa thành 28, 29, 30, 1, 2, 3, 4; ngày 31 nằm cột Thứ Bảy. |
| UI-02 | SCR-03 | Month View không có nút "Today" như Week View. | Thêm chip "Today" cạnh mũi tên chuyển tháng. |
| UI-03 | SCR-02 | Mục FONT dùng nhãn "ADD IMAGE". | Đổi thành "Choose font". |
| UI-04 | SCR-02 | Nút "LET MAKE YOURS" sai ngữ pháp. | Đổi thành "Make it yours". |
| UI-05 | SCR-05 | Có hai nút lưu: "Save" ở header và "Create event" ở cuối form. | Giữ một nút chính ở cuối form. |
| UI-06 | SCR-01, SCR-10 | "Saved & synced", "Synced across 3 devices" không đúng khi Prototype chưa có Cloud Sync. | Đổi thành "Saved". |
| UI-07 | SCR-06 | "Custom · sunset" ngụ ý nhắc theo giờ mặt trời lặn, cần quyền vị trí. | Đổi thành giờ cố định. |
| UI-08 | SCR-12 | Ô nhập hiển thị sẵn nội dung cũ để sửa; RemoteInput của Android không hỗ trợ điền sẵn văn bản. Dòng "notification access" không rõ nghĩa. | Hiển thị nội dung cũ dạng text phía trên ô nhập; bỏ dòng "notification access". |
| UI-09 | SCR-10 | Thiếu nhóm Tasks, Data và Privacy/Terms. | Bổ sung theo FR-21. |
| UI-10 | General | Chưa có thiết kế cho SCR-13 → SCR-21. | Thiết kế bổ sung theo mục 3.5. |
| UI-11 | General | Chưa có trạng thái Empty/Loading/Error và Dark Mode. | Bổ sung theo mục 3.4 và FR-13. |

---

# 16. OPEN ISSUES

| ID | Issue | Proposed Solution |
|---|---|---|
| OI-01 | Notes không phải tab chính trên UI. | (a) Giữ như tài liệu: Notes truy cập qua widget Quick Note; (b) thay tab VIP bằng Notes và đưa VIP vào Home/Settings. |
| OI-02 | Nhãn "synced" khi chưa có Cloud Sync. | Prototype dùng "Saved"; Cloud Sync thuộc Production. |
| OI-03 | Guests trong Event dễ hiểu nhầm là mời người khác tham gia. | Lưu Guests như nhãn tên cục bộ, không gửi lời mời. |
| OI-04 | Hai nút lưu trên form Event. | Xem UI-05. |
| OI-05 | Chức năng icon sliders trên Home chưa rõ. | Đề xuất dùng để bật/tắt widget hiển thị; cần designer xác nhận. |
| OI-06 | Lối vào Habits từ Calendar chưa có trên UI. | Thêm tab phụ "Events / Habits" dưới bộ chuyển Month/Week hoặc nút trên header Calendar. |
| OI-07 | Android trên điện thoại không cho ứng dụng bên thứ ba đặt widget tùy ý lên màn hình khóa như thiết kế. | Prototype dùng ongoing notification kết hợp Activity hiển thị trên màn hình khóa (showWhenLocked); kiểm tra thêm hỗ trợ widget màn hình khóa theo phiên bản Android thực tế. |
| OI-08 | Edit Your Screen chỉnh Home hay Lock Screen chưa rõ. | Thêm bộ chuyển "Home / Lock Screen" trong SCR-02 (FR-04.11). |
| OI-09 | App Version 2.8.0 trên UI khác Version tài liệu 1.0. | Thống nhất số phiên bản Prototype là 1.0.0. |

---

# 17. CONCLUSION

Super Calendar được xây dựng như một ứng dụng quản lý năng suất cá nhân có giao diện tối giản nhưng có khả năng mở rộng về chức năng, xoay quanh định hướng:

> **PLAN → DO → PERSONALIZE → SEE IT FIRST**

Trong đó:

- **Calendar** quản lý lịch trình theo tháng và tuần.
- **Event** quản lý hoạt động có thời gian cụ thể.
- **Goal** theo dõi mục tiêu tuần và tháng.
- **Habit** quản lý hành vi lặp lại qua Rule và Occurrence.
- **To-do** quản lý công việc và công việc con.
- **Quick Note** ghi lại ý tưởng nhanh từ bất kỳ đâu.
- **Theme** cá nhân hóa giao diện toàn ứng dụng.
- **Edit Your Screen, Widget Template, Template Studio** cá nhân hóa cách hiển thị.
- **VIP** kiểm soát chức năng Premium.
- **Notification** nhắc nhở và cho phép thao tác nhanh.
- **Lock Screen** đưa thông tin quan trọng đến nơi dễ thấy nhất.
- **Settings** quản lý cấu hình ứng dụng.

Prototype ưu tiên Local Database và Flutter, sử dụng Android Native khi cần tích hợp System Calendar, Notification và Lock Screen. Tài liệu này là cơ sở để chuyển sang các bước tiếp theo:

**Use Case Specification → UI/UX Specification → Database Specification → Class Diagram → Architecture → Implementation → Test Case.**

---

**END OF FUNCTIONAL REQUIREMENTS SPECIFICATION – SUPER CALENDAR v1.0**
