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

 31. MARKETPLACE — FUTURE

Khi triển khai thật:


Creator
 ↓
Publish Template
 ↓
Marketplace
 ↓
Buyer purchases
 ↓
Payment
 ↓
Platform commission
 ↓
Creator payout


Cần bổ sung:

 User authentication.
 Creator verification.
 Payment.
 Refund.
 Transaction management.
 Moderation.
 Copyright handling.
 Revenue sharing.
 Security.
 Terms of service.

---

 32. ANDROID / IOS

 Android

Là nền tảng phát triển đầu tiên.

Ưu tiên:

1. Flutter UI.
2. Android Emulator.
3. Android native integration.
4. System Calendar.
5. Notification.
6. Lock Screen.

 iOS

Được triển khai sau Android.

Có thể cần các công nghệ/API riêng của Apple cho:

 Calendar access.
 Notifications.
 Widgets.
 Lock Screen.
 Live Activities.

Không giả định rằng implementation Android có thể copy nguyên sang iOS.

---

 33. KIẾN TRÚC CODE

Prototype được tổ chức theo hướng feature-first: mỗi tính năng là một thư mục riêng trong `features/`, bên trong chia theo tầng.


lib/
│
├── main.dart
│
├── app/                          Cấu hình toàn cục của app
│   ├── app.dart                  MaterialApp và Bottom Navigation
│   ├── routes/                   Điều hướng giữa các tab và màn hình
│   └── theme/                    Colors, typography, theme
│
├── core/                         Phần dùng chung cho mọi tính năng
│   ├── services/                 Nguồn dữ liệu dùng chung (AppState)
│   ├── utils/                    Hàm tiện ích (định dạng ngày...)
│   └── widgets/                  Widget dùng chung (card, checkbox, chip...)
│
└── features/
    │
    ├── dashboard/                Home dashboard
    │   └── presentation/
    │       ├── screens/
    │       └── widgets/
    │
    ├── calendar/                 Month view, Week view, tạo Event, Habits
    │   ├── domain/               Event, Habit
    │   └── presentation/
    │       └── screens/
    │
    ├── todo/                     To-do list, Task details
    │   ├── domain/               Task
    │   └── presentation/
    │       └── screens/
    │
    ├── note/                     Quick Note
    │   └── presentation/
    │       └── screens/
    │
    ├── lock_screen/              Lock Screen
    │   └── presentation/
    │       └── screens/
    │
    ├── vip/                      Template Studio
    │   └── presentation/
    │       └── screens/
    │
    └── settings_screen/          Settings, Edit Your Screen
        └── presentation/
            └── screens/


Mỗi feature có thể có ba tầng:


feature/
├── data/                         Models, datasources, repository implementation
├── domain/                       Entities, usecases, repository interfaces
└── presentation/                 Screens, widgets, state management


Chỉ tạo thư mục khi có code thật để đặt vào.

Các phần sẽ bổ sung ở những phase sau:


core/
├── errors/                       Failure / Exception classes
├── network/                      API client (khi có backend)
└── services/                     Local database, Notification service

features/
├── auth/                         Đăng nhập / Người dùng (khi có backend)
└── <feature>/data/               Repository cho từng feature (Phase 2)


Quy ước:

 Import nội bộ dùng dạng `package:flutter_application/...`.
 Screen không hard-code màu, luôn lấy từ `app/theme/`.
 Trong Phase 1, dữ liệu mẫu nằm trong bộ nhớ tại `core/services/app_state.dart`.


Android native:


android/
└── app/
    └── src/
        └── main/
            └── kotlin/


Kotlin chỉ dùng khi cần Android-specific functionality.

---

 34. DEVELOPMENT ROADMAP

 Phase 0 — Environment

Mục tiêu:


Flutter
VS Code
Android Studio
Android Emulator


Kết quả:


Hello SuperCalendar


---

 Phase 1 — UI

Làm:

 Home.
 Calendar.
 Task.
 Notes.
 Navigation.

Chưa cần database.

---

 Phase 2 — Data

Làm:

 Event model.
 Task model.
 Note model.
 Local database.
 CRUD.

CRUD:


Create
Read
Update
Delete


---

 Phase 3 — Calendar Integration

Làm:

 Calendar permission.
 Read system calendar.
 Display events.

---

 Phase 4 — Notification

Làm:

 Event reminder.
 Task reminder.
 Notification action.
 Done.
 Snooze.

---

 Phase 5 — Lock Screen

Làm:


Schedule
READ ONLY


và:


To-do
INTERACTIVE


Sau đó:

 Complete Task.
 Add Task.
 Open App.

---

 Phase 6 — Theme

Làm:

 Theme system.
 Default pastel theme.
 Theme switching.
 Theme data model.

---

 Phase 7 — VIP Prototype

Làm:

 VIP screen.
 Mock subscription.
 `isVip`.
 Feature gating.

---

 Phase 8 — Template Prototype

Làm:

 Template list.
 Template preview.
 Mock purchase.
 Apply template.
 Create template.
 Publish template.

---

 Phase 9 — Polish

Kiểm tra:

 UI.
 Animation.
 Error handling.
 Empty states.
 Loading states.
 Permission states.
 Accessibility.
 Responsive layout.

---

 35. ACCEPTANCE CRITERIA

Prototype được coi là hoàn thành khi:

 Calendar

 [ ] Có thể xem Calendar.
 [ ] Có thể tạo Event.
 [ ] Có thể sửa Event.
 [ ] Có thể xóa Event.
 [ ] Event được lưu.

 System Calendar

 [ ] Có thể xin quyền.
 [ ] Có thể đọc Event khi được cấp quyền.
 [ ] App xử lý được trường hợp user từ chối quyền.

 Tasks

 [ ] Có thể tạo Task.
 [ ] Có thể hoàn thành Task.
 [ ] Có thể sửa Task.
 [ ] Có thể xóa Task.
 [ ] Task được lưu.

 Notes

 [ ] Có thể tạo Note.
 [ ] Có thể sửa Note.
 [ ] Có thể xóa Note.

 Notification

 [ ] Notification xuất hiện.
 [ ] Event reminder hoạt động.
 [ ] Task reminder hoạt động.
 [ ] Done action cập nhật Task.

 Lock Screen

 [ ] Schedule được hiển thị.
 [ ] Schedule không thể chỉnh sửa trực tiếp.
 [ ] Click Schedule mở app.
 [ ] To-do được hiển thị.
 [ ] To-do có thể complete.
 [ ] Add Task có thể thực hiện theo cơ chế Android cho phép.
 [ ] Dữ liệu Lock Screen đồng bộ với app.

 Theme

 [ ] Default Theme hoạt động.
 [ ] Có thể đổi Theme.
 [ ] Theme áp dụng cho app.

 VIP

 [ ] Mock payment hoạt động.
 [ ] VIP state được lưu.
 [ ] VIP features bị khóa với Free user.
 [ ] VIP user có thể sử dụng Theme Builder.

 Templates

 [ ] Có Template Store.
 [ ] Có Template detail.
 [ ] Mock purchase hoạt động.
 [ ] Template đã mua có thể Apply.
 [ ] VIP user có thể tạo Template.
 [ ] Creator có thể publish Template trong prototype.

---

 36. ĐỊNH HƯỚNG PHÁT TRIỂN SAU PROTOTYPE

Sau khi Prototype hoạt động ổn định, có thể phát triển:


                    PROTOTYPE
                        │
                        ↓
                  Cloud Backend
                        │
            ┌───────────┴───────────┐
            ↓                       ↓
         Account                 Sync
            │                       │
            └───────────┬───────────┘
                        ↓
                   Real Payment
                        │
                        ↓
                 VIP Subscription
                        │
                        ↓
                Template Marketplace
                        │
             ┌──────────┴──────────┐
             ↓                     ↓
          Creator                 Buyer
             │                     │
             └──────────┬──────────┘
                        ↓
                  Revenue System
                        │
                        ↓
                   Public App


---

 37. PRODUCT IDENTITY

SuperCalendar không nên được định vị đơn giản là:

> "Một app giống Google Calendar."

Mà là:

> A personalized productivity app that puts your schedule where you see it first.

Ba yếu tố nhận diện chính:


📅 PLAN
   Calendar

✅ DO
   Tasks

🎨 PERSONALIZE
   Themes & Templates

🔒 SEE IT FIRST
   Lock Screen


Điểm khác biệt cốt lõi:

> Lock Screen là nơi người dùng nhìn thấy lịch trình và xử lý những task nhanh nhất, trong khi ứng dụng chính cung cấp toàn bộ trải nghiệm quản lý Calendar, Tasks và Notes.

---

 38. NGUYÊN TẮC PHÁT TRIỂN

1. Không xây tất cả cùng lúc.
2. Ưu tiên Android trước.
3. Flutter là nền tảng chính.
4. Native Android chỉ dùng khi cần.
5. Prototype trước, production sau.
6. Payment giả trước, payment thật sau.
7. Marketplace giả trước, marketplace thật sau.
8. Local database trước, cloud database sau.
9. UI và data phải tách biệt.
10. Theme phải độc lập với dữ liệu.
11. Lock Screen phải dùng cùng nguồn dữ liệu với app chính.
12. Không lưu thông tin xác thực của hệ điều hành.
13. Chỉ yêu cầu quyền khi thực sự cần.
14. Mỗi tính năng phải được hoàn thiện và test trước khi chuyển sang tính năng tiếp theo.

---

 39. MỤC TIÊU CUỐI CÙNG

SuperCalendar hướng tới một hệ sinh thái:


                 SUPER CALENDAR
                        │
       ┌────────────────┼────────────────┐
       ↓                ↓                ↓
    CALENDAR           TASKS           NOTES
       │                │                │
       └────────────────┼────────────────┘
                        ↓
                  LOCK SCREEN
                        │
              ┌─────────┴─────────┐
              ↓                   ↓
          Schedule              To-do
          Read only           Interactive
                                  │
                                  ↓
                              Quick Add
                        
                        ↓
                     THEMES
                        │
              ┌─────────┴─────────┐
              ↓                   ↓
            Free                 VIP
                                  │
                           Theme Builder
                                  │
                                  ↓
                              Templates
                                  │
                                  ↓
                            Marketplace
                                  │
                       ┌──────────┴──────────┐
                       ↓                     ↓
                    Creator                Buyer


Phiên bản đầu tiên không cần đạt đến toàn bộ hệ thống này.

Mục tiêu đầu tiên chỉ là:

> Xây được một SuperCalendar chạy thật trên Android, có Calendar + To-do + Notes + Notification + Lock Screen, sử dụng giao diện pastel/minimal và lưu dữ liệu trên thiết bị.

Sau khi phần này chạy ổn, VIP và Marketplace sẽ được xây như những lớp tính năng tiếp theo.
