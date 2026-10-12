# SUPER CALENDAR – FUNCTIONAL REQUIREMENTS SPECIFICATION

| Item | Detail |
|---|---|
| Project Name | Super Calendar |
| Document Type | Functional Requirements Specification (FRS) |
| Version | 1.0 |
| Platform | Mobile Application |
| Framework | Flutter |
| Programming Language | Dart (Kotlin cho Android Native khi cần) |
| Target Platform | Android – Prototype |
| Future Platform | iOS |
| UI Reference | Figma – SCR-01 → SCR-12 |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Overview](#2-system-overview)
3. [General Functional Requirements](#3-general-functional-requirements)
4. [Functional Requirements](#4-functional-requirements)
5. [Entity and Data Requirements](#5-entity-and-data-requirements)
6. [Functional Relationship](#6-functional-relationship)
7. [Business Rules](#7-business-rules)
8. [Non-Functional Requirements](#8-non-functional-requirements)
9. [Prototype Scope](#9-prototype-scope)
10. [Out of Scope](#10-out-of-scope)
11. [Acceptance Criteria](#11-acceptance-criteria)
12. [Requirement Traceability](#12-requirement-traceability)
13. [Functional Requirements Summary](#13-functional-requirements-summary)
14. [Final System Functional Structure](#14-final-system-functional-structure)
15. [UI Review Notes](#15-ui-review-notes)
16. [Open Issues](#16-open-issues)
17. [Conclusion](#17-conclusion)

---

# 1. INTRODUCTION

## 1.1 Purpose

Tài liệu mô tả đầy đủ các yêu cầu chức năng của Super Calendar, được xây dựng dựa trên định hướng sản phẩm, nghiên cứu các ứng dụng tương tự và thiết kế UI trên Figma.

Tài liệu là cơ sở để:

- Thiết kế UI/UX.
- Xây dựng Use Case.
- Thiết kế Database.
- Thiết kế Class Diagram và Architecture.
- Phát triển ứng dụng Flutter.
- Phát triển các thành phần Android Native khi cần.
- Xây dựng Test Case.
- Kiểm thử và nghiệm thu hệ thống.

## 1.2 Document Conventions

| Ký hiệu | Ý nghĩa |
|---|---|
| `FR-xx` | Nhóm chức năng (module) |
| `FR-xx.yy` | Yêu cầu con – đơn vị nhỏ nhất để viết Test Case |
| `SCR-xx` | Mã màn hình UI |
| `BR-xx` | Quy tắc nghiệp vụ |
| `NFR-xx` | Yêu cầu phi chức năng |
| `AC-xx` | Tiêu chí nghiệm thu |
| `UI-xx` | Ghi chú cần chỉnh trên thiết kế |
| `OI-xx` | Vấn đề mở cần nhóm quyết định |
| **P1** | Bắt buộc trong Prototype |
| **P2** | Nên có trong Prototype |
| **P3** | Giai đoạn sau (Production) |

## 1.3 Terminology

| Thuật ngữ | Định nghĩa |
|---|---|
| Event | Hoạt động có thời gian cụ thể trên lịch (họp, hẹn) |
| Task | Công việc cần hoàn thành, có thể có hạn hoặc không |
| Goal | Mục tiêu theo tuần hoặc theo tháng |
| Habit Rule | Quy tắc lặp của một thói quen |
| Habit Occurrence | Một lần xuất hiện của thói quen vào một ngày cụ thể |
| Quick Note | Ghi chú nhanh đang hoạt động, hiển thị trên Home, Lock Screen và Notification |
| Widget | Khối hiển thị một nhóm dữ liệu trên Home hoặc Lock Screen |
| Widget Template | Mẫu trình bày widget/bố cục (layout, màu, phông, kiểu thẻ) |
| Theme | Giao diện tổng thể của toàn ứng dụng |
| VIP | Trạng thái người dùng trả phí, mở khóa chức năng Premium |
| Mock Purchase | Giao dịch mô phỏng, không thanh toán thật |

---

# 2. SYSTEM OVERVIEW

## 2.1 Product Description

**Super Calendar** là ứng dụng quản lý lịch trình cá nhân trên thiết bị di động, kết hợp:

- Calendar, Event, Goal, Habit.
- To-do List, Task, Subtask.
- Quick Note.
- Notification và Lock Screen.
- Theme, Widget Template, Edit Your Screen, Template Studio.
- VIP và Template Marketplace (giai đoạn sau).

Mục tiêu là giúp người dùng **lập kế hoạch, thực hiện công việc, theo dõi thói quen và cá nhân hóa trải nghiệm** trong một hệ thống thống nhất.

## 2.2 Product Pillars

> **PLAN – DO – PERSONALIZE – SEE IT FIRST**

| Pillar | Ý nghĩa | Màn hình chính |
|---|---|---|
| PLAN | Lập lịch trình, mục tiêu, thói quen | Calendar, Habits |
| DO | Thực hiện và hoàn thành công việc | To-do List, Task Details |
| PERSONALIZE | Cá nhân hóa dashboard và widget | Edit Your Screen, Template Studio |
| SEE IT FIRST | Đưa thông tin quan trọng đến nơi dễ thấy nhất | Home, Lock Screen, Notification |

## 2.3 Actors

| Actor | Mô tả |
|---|---|
| Free User | Người dùng miễn phí, dùng toàn bộ chức năng cốt lõi và 3 Free Template |
| VIP User | Người dùng đã nâng cấp, dùng thêm Template Studio và nội dung Premium |
| System | Ứng dụng Super Calendar (xử lý dữ liệu, lập lịch nhắc nhở, hiển thị) |
| Android OS | Hệ điều hành: cấp quyền, gửi Notification, hiển thị Lock Screen, cung cấp System Calendar |

---

# 3. GENERAL FUNCTIONAL REQUIREMENTS

## 3.1 Application Navigation

Ứng dụng có thanh điều hướng cố định ở cuối màn hình (**Bottom Navigation Bar**) gồm 5 tab:

| No. | Tab | Root Screen | Chức năng |
|---|---|---|---|
| 1 | Home | SCR-01 | Dashboard widget, Edit Your Screen, Snapshot |
| 2 | Calendar | SCR-03 / SCR-04 | Event, Goal, Habit |
| 3 | To-do | SCR-07 | Task, Subtask |
| 4 | VIP | SCR-09 | Template Studio, Paywall |
| 5 | Settings | SCR-10 | Cấu hình ứng dụng |

| ID | Requirement |
|---|---|
| G-01 | Home là màn hình mặc định khi mở ứng dụng. |
| G-02 | Tab đang chọn được tô nền và đổi màu icon/nhãn. |
| G-03 | Notes không là tab riêng; Quick Note được truy cập qua widget trên Home, Lock Screen và Notification (OI-01). |
| G-04 | Màn hình Habits được mở từ tab Calendar; tab Calendar vẫn được tô sáng khi ở SCR-06. |
| G-05 | Chuyển tab giữ nguyên vị trí cuộn và bộ lọc của tab trước trong cùng phiên sử dụng. |

## 3.2 Data Consistency

Hệ thống áp dụng nguyên tắc **Single Source of Truth**.

| ID | Requirement |
|---|---|
| G-06 | Mỗi dữ liệu nghiệp vụ chỉ được lưu tại một bảng chính: Event, Task, Goal, Habit/HabitOccurrence, Note. |
| G-07 | Home, Widget, Lock Screen, Notification và Snapshot chỉ **đọc** từ nguồn chính; mọi thao tác ghi (tick, lưu note) đều ghi vào bảng gốc. |
| G-08 | Không tạo bản sao dữ liệu chỉ để phục vụ hiển thị. |
| G-09 | Thay đổi ở một nơi phải phản ánh lên mọi nơi hiển thị trong ≤ 1 giây khi ứng dụng đang mở. |

## 3.3 Local Data Storage

| ID | Requirement |
|---|---|
| G-10 | Local Database (SQLite qua Drift, hoặc Isar) là nguồn dữ liệu chính trong Prototype. |
| G-11 | Không bắt buộc Backend và Cloud Synchronization. |
| G-12 | Dữ liệu được lưu ngay khi người dùng nhấn Save/Done hoặc tick checkbox. |
| G-13 | Dữ liệu còn nguyên sau khi đóng ứng dụng, buộc dừng ứng dụng hoặc khởi động lại thiết bị. |
| G-14 | Nhãn trạng thái lưu hiển thị "Saved" khi ghi cục bộ thành công (OI-02). |

## 3.4 Standard Screen States

Mọi màn hình danh sách và widget phải có đủ các trạng thái sau:

| State | Requirement |
|---|---|
| Loading | Skeleton hoặc indicator khi đang tải dữ liệu |
| Empty | Thông điệp ngắn kèm nút hành động (ví dụ: "Chưa có task nào – Thêm task") |
| Error | Thông báo lỗi dễ hiểu kèm nút "Thử lại" |
| Success | Snackbar ngắn sau khi lưu, xóa, hoàn thành |
| Undo | Mọi thao tác xóa có Snackbar "Undo" trong 5 giây |
| Unsaved changes | Thoát form khi có thay đổi chưa lưu phải hỏi xác nhận |

## 3.5 Screen Inventory

| ID | Screen Name | Design Status | Related FR |
|---|---|---|---|
| SCR-01 | Home Dashboard | Designed | FR-03 |
| SCR-02 | Edit Your Screen | Designed | FR-04 |
| SCR-03 | Calendar – Month View | Designed | FR-05, FR-07 |
| SCR-04 | Calendar – Week View | Designed | FR-05, FR-07 |
| SCR-05 | New Event / Edit Event | Designed | FR-06 |
| SCR-06 | Habits + Occurrence Action Sheet | Designed | FR-08 |
| SCR-07 | To-do List | Designed | FR-09 |
| SCR-08 | Task Details | Designed | FR-10 |
| SCR-09 | VIP – Template Studio | Designed | FR-15, FR-16 |
| SCR-10 | Settings | Designed | FR-02, FR-21 |
| SCR-11 | Lock Screen | Designed | FR-19 |
| SCR-12 | Android Quick Note Notification | Designed | FR-11, FR-20 |
| SCR-13 | Onboarding & Permission | Not designed | FR-01 |
| SCR-14 | Goal Create / Edit | Not designed | FR-07 |
| SCR-15 | Habit Create / Manage Habits | Not designed | FR-08 |
| SCR-16 | Notes List / Note Editor | Not designed | FR-11 |
| SCR-17 | VIP Paywall / Mock Purchase | Not designed | FR-15 |
| SCR-18 | Template Marketplace / Template Detail | Not designed | FR-17 |
| SCR-19 | Snapshot Preview / Share | Not designed | FR-12 |
| SCR-20 | Settings Sub-pages | Not designed | FR-02, FR-13, FR-21, FR-22 |
| SCR-21 | Task Filter / Sort Sheet | Not designed | FR-09 |

---

# 4. FUNCTIONAL REQUIREMENTS

---

## FR-01 – ONBOARDING & PERMISSION

**Description:** Giới thiệu ứng dụng ở lần mở đầu tiên, tạo local account và xin các quyền cần thiết.
**Actor:** Free User, Android OS · **Screens:** SCR-13 · **Priority:** P2

### Preconditions

- Ứng dụng vừa được cài đặt và mở lần đầu.

### Main Flow

1. User mở ứng dụng lần đầu.
2. System hiển thị 2–3 màn hình giới thiệu PLAN – DO – PERSONALIZE – SEE IT FIRST.
3. User nhấn Next hoặc Skip.
4. System yêu cầu nhập Display Name.
5. User nhập tên và xác nhận.
6. System giải thích mục đích quyền Notification, sau đó hiện hộp thoại xin quyền của Android.
7. System giải thích mục đích quyền Calendar (tùy chọn), sau đó hiện hộp thoại xin quyền.
8. System tạo local account và mở Home.

### Alternative Flows

- **6a.** User từ chối quyền Notification → ứng dụng vẫn hoạt động, Settings → Notifications hiển thị cảnh báo "Notification đang tắt" kèm nút mở cài đặt hệ thống.
- **7a.** User từ chối quyền Calendar → chỉ dùng Local Calendar.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-01.01 | Onboarding chỉ hiển thị một lần; có thể xem lại tại Settings → Help → User Guide. |
| FR-01.02 | Display Name bắt buộc, 1–30 ký tự, không chỉ gồm khoảng trắng. |
| FR-01.03 | Quyền Notification chỉ được xin trên Android 13 (API 33) trở lên; bản thấp hơn bật mặc định. |
| FR-01.04 | Mỗi quyền phải có màn hình giải thích trước hộp thoại hệ thống. |

### Postconditions

- Local account được tạo; Home hiển thị lời chào với Display Name.

---

## FR-02 – ACCOUNT & PROFILE

**Description:** Xem và quản lý thông tin cá nhân và trạng thái VIP. Prototype dùng local account, không đăng nhập online.
**Actor:** Free User, VIP User · **Screens:** SCR-10, SCR-20 · **Priority:** P1

### Preconditions

- Local account đã được tạo (FR-01).

### Main Flow

1. User mở Settings.
2. User chọn thẻ tài khoản hoặc dòng Account.
3. System hiển thị Avatar, Display Name, Email, VIP Status.
4. User chỉnh sửa thông tin.
5. User nhấn Save.
6. System kiểm tra dữ liệu và lưu.
7. System cập nhật Settings và lời chào trên Home.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-02.01 | Settings hiển thị avatar (ảnh hoặc chữ viết tắt, ví dụ "MC") ở góc trên phải. |
| FR-02.02 | Thẻ tài khoản hiển thị Display Name và gói (Free/VIP); chạm vào mở trang Account. |
| FR-02.03 | User sửa được Display Name, Avatar (chọn từ thư viện ảnh), Email (tùy chọn, kiểm tra định dạng). |
| FR-02.04 | Không có avatar thì System tạo avatar chữ viết tắt từ Display Name. |
| FR-02.05 | Thay đổi Display Name cập nhật ngay lời chào trên Home. |

### Business Rules

- Không yêu cầu Login/Logout online trong Prototype.
- Không lưu PIN, mật khẩu hoặc dữ liệu sinh trắc học của thiết bị (BR-14).
- VIP Status là căn cứ duy nhất để kiểm soát chức năng Premium (BR-06).

---

## FR-03 – HOME DASHBOARD

**Description:** Màn hình mặc định, hiển thị tổng quan trong ngày bằng các widget có thể tùy biến.
**Actor:** Free User, VIP User · **Screens:** SCR-01 · **Priority:** P1

### Preconditions

- Ứng dụng khởi chạy thành công.

### Main Flow

1. User mở ứng dụng.
2. System hiển thị Home với tên ứng dụng, ngày hiện tại và lời chào.
3. System tải dữ liệu hôm nay từ Task, HabitOccurrence, Event, Goal, Note.
4. System hiển thị các widget theo DashboardLayout đang áp dụng.
5. User tương tác trực tiếp trên widget (tick task, tick habit) hoặc chạm để mở màn hình chi tiết.
6. User có thể mở Edit Your Screen hoặc Create More để tùy biến.

### Detailed Requirements

**Header**

| ID | Requirement |
|---|---|
| FR-03.01 | Hiển thị "SuperCalendar" và ngày hiện tại theo định dạng trong Settings (ví dụ "Monday, October 5"). |
| FR-03.02 | Lời chào theo giờ: Good morning (05:00–11:59), Good afternoon (12:00–17:59), Good evening (18:00–04:59), kèm Display Name. |
| FR-03.03 | Nút "Edit Your Screen" mở SCR-02. |
| FR-03.04 | Icon sliders ở góc phải mở bảng bật/tắt widget hiển thị trên Home (OI-05). |

**Default Widgets**

| ID | Widget | Content | Actions |
|---|---|---|---|
| FR-03.05 | To-do | Tối đa 3 task của hôm nay, nhãn "today"/"done" | Tick hoàn thành; "Edit" mở SCR-07 |
| FR-03.06 | Habits | Habit occurrence hôm nay, icon check khi Done | Tick Done; "Edit" mở SCR-06 |
| FR-03.07 | This week | Dải 7 ngày của tuần hiện tại, chấm màu theo category có event | Chạm một ngày mở Week View tại ngày đó |
| FR-03.08 | Goals | Goal đang theo dõi, % tiến độ, thanh progress | Chạm mở Calendar tại thẻ Goals |
| FR-03.09 | Quick Note | Nội dung Quick Note, trạng thái lưu | "Edit" mở trình sửa note |
| FR-03.10 | Month snapshot | Dải ngày của tháng với chấm sự kiện, nhãn "Display-only" | "Save image" (FR-12); chạm để chia sẻ |

**Templates & Extensions**

| ID | Requirement |
|---|---|
| FR-03.11 | Hiển thị dòng "3 free layouts · More templates with VIP". |
| FR-03.12 | Nút "+ CREATE MORE" mở danh sách widget/template có thể thêm; mục Premium có biểu tượng khóa. |
| FR-03.13 | Widget không có dữ liệu hiển thị trạng thái rỗng kèm nút tạo mới. |
| FR-03.14 | Kéo xuống (pull-to-refresh) tải lại dữ liệu và ngày hiện tại. |
| FR-03.15 | Khi sang ngày mới trong lúc ứng dụng đang mở, Home tự cập nhật ngày và dữ liệu. |

### Business Rules

- Home không phải là Calendar đầy đủ; mọi thao tác phức tạp mở màn hình chuyên trách.
- Widget chỉ đọc từ nguồn chính (G-07).

### Postconditions

- Thao tác trên widget được ghi vào bảng gốc và phản ánh ở To-do, Calendar, Lock Screen.

---

## FR-04 – EDIT YOUR SCREEN

**Description:** Cho phép sắp xếp, thay đổi kích thước widget và tùy chỉnh nền, phông chữ của bố cục hiển thị.
**Actor:** Free User, VIP User · **Screens:** SCR-02 · **Priority:** P1

### Preconditions

- User đang ở Home.

### Main Flow

1. User nhấn "Edit Your Screen" trên Home.
2. System hiển thị bản xem trước thiết bị ở giữa và khay widget hai bên.
3. User chọn chế độ lịch Month hoặc Week.
4. User nhấn giữ một widget và kéo vào vùng xem trước.
5. User kéo góc widget để đổi kích thước.
6. User chọn Background và Font.
7. User nhấn "Done".
8. System lưu DashboardLayout và WidgetPlacement, quay về Home.

### Alternative Flows

- **4a.** User kéo widget ra ngoài vùng xem trước → widget bị gỡ khỏi bố cục.
- **6a.** User Free chọn nền/phông Premium → System hiển thị Paywall (FR-15).
- **7a.** User thoát khi chưa nhấn Done → System hỏi "Hủy thay đổi?".

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-04.01 | Hiển thị tiêu đề "Edit Your Screen", mô tả "Drag, resize and make it yours", nút "Done". |
| FR-04.02 | Gợi ý thao tác: "Press and hold any widget, then drag. Pull a corner to resize." |
| FR-04.03 | Khay widget hai bên cuộn ngang được, gồm tất cả loại widget ở FR-14.02. |
| FR-04.04 | Kích thước widget co giãn theo lưới S/M/L. |
| FR-04.05 | Widget không được chồng lên vùng đồng hồ và vùng "Swipe up to unlock" (safe zone); thả vào vùng cấm thì widget tự trở về vị trí hợp lệ gần nhất. |
| FR-04.06 | Nút "EDIT" mở chế độ sửa nội dung widget đang chọn (nguồn dữ liệu, số dòng hiển thị). |
| FR-04.07 | Nút "Make it yours" (VIP) mở Template Studio; User Free thấy khóa và Paywall. |
| FR-04.08 | **Background:** chọn ảnh từ thư viện, màu trơn hoặc gradient; "See more" mở bộ nền có sẵn (một phần Premium). |
| FR-04.09 | **Font:** chọn phông từ danh sách; "See more" mở toàn bộ phông (phông Premium có khóa). |
| FR-04.10 | Có nút "Reset to default" khôi phục bố cục mặc định. |
| FR-04.11 | Có bộ chuyển "Home / Lock Screen" để chọn bố cục đang chỉnh (OI-08). |

### Postconditions

- Home (hoặc Lock Screen) hiển thị đúng bố cục đã lưu, kể cả sau khi mở lại ứng dụng.

---

## FR-05 – CALENDAR

**Description:** Trung tâm quản lý lịch trình với hai chế độ Month View và Week View; hiển thị Event và Goal, là lối vào Habits.
**Actor:** Free User, VIP User · **Screens:** SCR-03, SCR-04 · **Priority:** P1

### Preconditions

- User mở tab Calendar.

### Main Flow

1. User mở tab Calendar.
2. System hiển thị chế độ xem được dùng lần cuối (mặc định Month).
3. System tải Event và Goal của khoảng thời gian đang xem.
4. User chuyển Month/Week, chuyển tháng/tuần, hoặc quay về Today.
5. User chọn một ngày để xem danh sách event của ngày đó.
6. User tạo event bằng nút "+" hoặc chạm vào ngày/ô giờ (FR-06).

### Detailed Requirements

**Common Elements**

| ID | Requirement |
|---|---|
| FR-05.01 | Bộ chuyển Month/Week ở góc trên trái; nút "+" tròn ở góc trên phải mở SCR-05. |
| FR-05.02 | Chế độ xem cuối cùng được ghi nhớ cho lần mở sau. |
| FR-05.03 | Ngày bắt đầu tuần theo Settings (Thứ Hai/Chủ Nhật); ngày được tính đúng theo lịch Gregorian. |
| FR-05.04 | Có lối vào màn hình Habits (SCR-06) từ Calendar (OI-06). |

**Month View**

| ID | Requirement |
|---|---|
| FR-05.05 | Tiêu đề "Tháng Năm" (ví dụ "October 2026"); mũi tên và thao tác vuốt ngang để chuyển tháng. |
| FR-05.06 | Lưới 7 cột; ngày của tháng trước/sau hiển thị màu nhạt; ngày hôm nay có nền nổi bật. |
| FR-05.07 | Dưới mỗi ngày hiển thị tối đa 3 chấm màu theo Category của event trong ngày. |
| FR-05.08 | Chạm một ngày: chọn ngày đó và hiển thị agenda bên dưới (giờ, tiêu đề, địa điểm · category). |
| FR-05.09 | Chạm lần hai vào ngày đã chọn hoặc nhấn giữ: mở SCR-05 với Date điền sẵn. Gợi ý "Tap a date to create an event" hiển thị dưới tiêu đề. |
| FR-05.10 | Thẻ **Monthly Goals** hiển thị "x of y" và chip goal của tháng đang xem. |
| FR-05.11 | Có nút "Today" quay về tháng hiện tại và chọn ngày hôm nay (UI-02). |

**Week View**

| ID | Requirement |
|---|---|
| FR-05.12 | Tiêu đề khoảng ngày (ví dụ "October 5–11") và dòng phụ "Week 41 · 7 events" (số tuần theo ISO-8601). |
| FR-05.13 | Nút "Today" quay về tuần hiện tại; vuốt ngang để chuyển tuần. |
| FR-05.14 | Dải 7 ngày phía trên, ngày hôm nay được đánh dấu. |
| FR-05.15 | Lưới thời gian theo giờ, mặc định cuộn tới 08:00; event là khối màu theo thời lượng, có tiêu đề và giờ bắt đầu. |
| FR-05.16 | Event trùng giờ hiển thị cạnh nhau, chia đều chiều ngang cột. |
| FR-05.17 | Chạm vùng trống trên lưới: mở SCR-05 với Date và Start Time điền sẵn. |
| FR-05.18 | Chạm vào event: mở chi tiết/chỉnh sửa event. |
| FR-05.19 | Thẻ **Weekly Goals** hiển thị "x of y" và chip goal của tuần; goal hoàn thành có dấu tick. |

---

## FR-06 – EVENT MANAGEMENT

**Description:** Tạo, xem, sửa, xóa Event – hoạt động có thời gian cụ thể trên lịch.
**Actor:** Free User, VIP User · **Screens:** SCR-05 · **Priority:** P1

### Preconditions

- User đang ở Calendar hoặc Home.

### Main Flow – Create Event

1. User nhấn "+" (hoặc chọn ngày/ô giờ trên Calendar).
2. System mở form "New event"; Event Title được focus; Date/Time điền sẵn nếu đã chọn.
3. User nhập Title, kiểm tra Date và Time.
4. User nhập các trường tùy chọn: Color, Category, Location, Reminder, Repeat, Notes, Guests, Calendar.
5. User nhấn "Create event".
6. System kiểm tra dữ liệu.
7. System lưu Event và lập lịch Reminder.
8. System đóng form; Calendar, Home, Lock Screen được cập nhật.

### Alternative Flows

- **6a.** Dữ liệu không hợp lệ → System hiển thị lỗi ngay dưới trường tương ứng, không lưu.
- **Edit:** User chạm vào event → form mở với dữ liệu sẵn → sửa → "Save changes".
- **Delete:** Trong form sửa, User nhấn Delete → xác nhận → Event bị xóa, Reminder bị hủy, Snackbar Undo hiển thị 5 giây.
- **Recurring:** Sửa/xóa event lặp lại → System hỏi phạm vi: "Chỉ sự kiện này" / "Sự kiện này và các sự kiện sau" / "Tất cả sự kiện".

### Form Fields

| Field | Required | Default | Notes |
|---|---|---|---|
| Event Title | Yes | Rỗng, tự focus | 1–100 ký tự |
| Date | Yes | Ngày được chọn hoặc hôm nay | |
| Time (Start–End) | Yes | Giờ tròn kế tiếp, thời lượng mặc định trong Settings | Có tùy chọn All-day |
| Color | No | Màu của Category | 4 màu cơ bản; VIP có màu tùy chỉnh |
| Category | No | Personal | Work, Personal, Finance, Shopping, … |
| Location | No | Rỗng | Văn bản tự do, tối đa 200 ký tự |
| Reminder | No | Theo Settings | None, 5, 10, 15, 30 phút, 1 giờ, 1 ngày trước |
| Repeat | No | None | None, Daily, Weekly (chọn thứ), Monthly, Yearly, Custom |
| Notes | No | Rỗng | Tối đa 1.000 ký tự |
| Guests | No | Rỗng | Chỉ lưu tên, không gửi lời mời (OI-03) |
| Calendar | Yes | Calendar mặc định | Ví dụ "Mia · Personal" |

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-06.01 | Event được tạo từ nút "+", từ việc chọn ngày (Month View) hoặc ô giờ (Week View). |
| FR-06.02 | Form có một hành động lưu chính: "Create event" khi tạo mới, "Save changes" khi sửa (UI-05). |
| FR-06.03 | Nút "X" đóng form; có thay đổi chưa lưu thì hỏi xác nhận. |
| FR-06.04 | Validate: Title không rỗng; End > Start (trừ All-day); Repeat hợp lệ; Reminder không trỏ về thời điểm đã qua. |
| FR-06.05 | Sau khi lưu/xóa, Calendar, Home, Lock Screen, Snapshot và Reminder được cập nhật đồng thời. |
| FR-06.06 | Event có `Source = system_calendar` chỉ được xem, không được sửa/xóa (FR-22). |

### Postconditions

- Event tồn tại trong bảng Event; Reminder tương ứng đã được lên lịch hoặc hủy.

---

## FR-07 – GOAL MANAGEMENT

**Description:** Thiết lập và theo dõi mục tiêu theo tuần (Weekly) hoặc theo tháng (Monthly).
**Actor:** Free User, VIP User · **Screens:** SCR-03, SCR-04, SCR-01, SCR-14 · **Priority:** P1

### Preconditions

- User đang ở Calendar (Month hoặc Week View).

### Main Flow – Create Goal

1. User nhấn "+" trên thẻ Monthly Goals hoặc Weekly Goals.
2. System mở form Goal với Type mặc định theo chế độ đang xem (Month → Monthly, Week → Weekly).
3. User nhập Title và tùy chọn Target, Icon, Color.
4. User nhấn Save.
5. System kiểm tra dữ liệu và lưu Goal cho kỳ hiện tại.
6. Goal xuất hiện trên thẻ Goals và widget Goals của Home.

### Alternative Flows

- **Update progress:** User chạm chip goal → Current tăng 1 (goal có Target) hoặc chuyển Completed (goal không có Target).
- **Edit/Delete:** User nhấn giữ chip goal → chọn Edit hoặc Delete.
- **End of period:** Hết kỳ mà goal chưa đạt → Status = Missed; User có thể chọn "Carry over" sang kỳ kế tiếp.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-07.01 | Goal có hai loại: Weekly (gắn với tuần ISO) và Monthly (gắn với tháng). |
| FR-07.02 | Trường: Title (bắt buộc, 1–60 ký tự), Type, Target (số nguyên dương, tùy chọn), Icon, Color. |
| FR-07.03 | Goal có Target: tiến độ = Current / Target. Goal không có Target: chỉ có trạng thái Done/Not done. |
| FR-07.04 | Thẻ Goals hiển thị "x of y" = số goal Completed / tổng goal trong kỳ. |
| FR-07.05 | Widget Goals trên Home hiển thị % tiến độ của goal đang theo dõi. |
| FR-07.06 | Monthly Goals chỉ hiển thị ở Month View; Weekly Goals chỉ hiển thị ở Week View. |

### Business Rules

- Current ≥ 0 và không vượt Target.
- Current = Target thì goal tự chuyển Completed (BR-11).
- Weekly Goal và Monthly Goal không trộn dữ liệu (BR-03).

---

## FR-08 – HABIT MANAGEMENT

**Description:** Tạo hành động lặp lại (Habit Rule) và theo dõi từng lần thực hiện (Habit Occurrence).
**Actor:** Free User, VIP User · **Screens:** SCR-06, SCR-15 · **Priority:** P1

### Preconditions

- User mở màn hình Habits từ Calendar.

### Main Flow – Create Habit

1. User nhấn "+" trên màn hình Habits.
2. System mở form Habit.
3. User nhập Name, chọn Icon, Color, Start Date, End Date (tùy chọn), Time (tùy chọn), Repeat Rule, Reminder.
4. User nhấn Save.
5. System lưu Habit Rule.
6. System sinh các Occurrence theo Repeat Rule.
7. Occurrence hiển thị trên màn hình Habits và widget Habits của Home.

### Main Flow – Manage Single Occurrence

1. User nhấn "⋮" trên thẻ occurrence.
2. System hiển thị Action Sheet: Edit this occurrence, Skip occurrence, Delete occurrence.
3. User chọn hành động và xác nhận.
4. System chỉ thay đổi occurrence đó; Habit Rule giữ nguyên.

### Alternative Flows

- **Edit Habit Rule:** User mở "Manage habits" → chọn habit → sửa → System cập nhật occurrence **từ hôm nay trở đi**.
- **Delete Habit Rule:** System hỏi xác nhận và cho chọn "Archive" (giữ lịch sử) hoặc "Delete" (xóa hẳn).

### Detailed Requirements

**Habits Screen**

| ID | Requirement |
|---|---|
| FR-08.01 | Tiêu đề "Habits", mô tả "Generated automatically from your rhythm" (occurrence sinh tự động từ Repeat Rule). |
| FR-08.02 | Bộ lọc Daily / Weekly / Custom theo loại Repeat Rule. |
| FR-08.03 | Dải 7 ngày, chấm màu cho ngày có occurrence; chạm để xem occurrence của ngày đó. |
| FR-08.04 | Tiêu đề nhóm "Today · n occurrences" và liên kết "Manage habits". |
| FR-08.05 | Thẻ occurrence: icon, tên, lịch lặp + giờ (ví dụ "Mon, Wed, Fri · 19:30"), nhãn "auto-generated", nút tick, menu "⋮". |
| FR-08.06 | Banner: "Future occurrences update when you change a habit's repetition." |

**Repeat Rule**

| ID | Requirement |
|---|---|
| FR-08.07 | Hỗ trợ: Every day; Specific days of week; Every N days hoặc Every N weeks (Custom). |
| FR-08.08 | Occurrence được sinh trước tối đa 60 ngày và sinh tiếp khi người dùng xem các ngày xa hơn. |

**Occurrence Actions**

| ID | Action | Result |
|---|---|---|
| FR-08.09 | Edit this occurrence | Đổi giờ/ghi chú chỉ cho ngày đó (lưu OverrideData) |
| FR-08.10 | Skip occurrence | Status = Skipped; không tính là bỏ lỡ; các lần sau giữ nguyên |
| FR-08.11 | Delete occurrence | Status = Deleted; ẩn khỏi mọi màn hình |
| FR-08.12 | Mark done / Undo | Status = Done ↔ Pending; cập nhật Home và Lock Screen |

**Tracking**

| ID | Requirement |
|---|---|
| FR-08.13 | System tính streak (số lần hoàn thành liên tiếp, bỏ qua Skipped) và hiển thị trong chi tiết habit. *(P2)* |

### Business Rules

- Habit Rule và Habit Occurrence được quản lý riêng (BR-02).
- Đổi Repeat Rule chỉ ảnh hưởng occurrence từ hôm nay trở đi (BR-17).

---

## FR-09 – TO-DO LIST

**Description:** Quản lý danh sách công việc cần hoàn thành với thao tác thêm nhanh.
**Actor:** Free User, VIP User · **Screens:** SCR-07, SCR-21 · **Priority:** P1

### Preconditions

- User mở tab To-do.

### Main Flow – Quick Add

1. User mở tab To-do.
2. User chạm vào ô "Add a new task".
3. User nhập tiêu đề task.
4. User nhấn Enter hoặc "+".
5. System tạo Task và đưa lên đầu danh sách.
6. Ô nhập được xóa trống và giữ focus để thêm task tiếp.

### Alternative Flows

- **Complete:** User tick checkbox → task gạch ngang, meta đổi thành "Completed", task chuyển xuống cuối danh sách.
- **Reorder:** User nhấn giữ và kéo task → System lưu SortOrder mới.
- **Delete:** User vuốt trái → task bị xóa, Snackbar Undo 5 giây.
- **Edit:** User nhấn "Edit" hoặc chạm vào task → mở Task Details (FR-10).

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-09.01 | Tiêu đề "TO-DO LIST", dòng phụ "Ngày hiện tại · n remaining" (số task chưa hoàn thành trong bộ lọc hiện tại). |
| FR-09.02 | Bộ lọc dạng chip: **All (n)**, **Today (n)**, **Upcoming**. Today = DueDate là hôm nay hoặc quá hạn; Upcoming = DueDate sau hôm nay. |
| FR-09.03 | Task tạo khi đang ở bộ lọc Today được gán DueDate = hôm nay. |
| FR-09.04 | Mỗi dòng: checkbox, tiêu đề, thanh màu category, dòng meta (ngày · priority/category/thời lượng ước tính), nút "Edit". |
| FR-09.05 | Task quá hạn hiển thị meta màu cảnh báo. |
| FR-09.06 | Icon bộ lọc (góc phải) mở sheet: sắp xếp theo Manual / Due date / Priority; ẩn/hiện task đã hoàn thành. |
| FR-09.07 | Danh sách cuộn liên tục, không giới hạn số dòng. |
| FR-09.08 | Gợi ý cuối danh sách: "Tap + to add another row · drag tasks to reorder". |

### Postconditions

- Mọi thay đổi được ghi vào bảng Task và phản ánh lên Home, Lock Screen, Notification.

---

## FR-10 – TASK DETAILS & SUBTASK

**Description:** Xem và chỉnh sửa đầy đủ thông tin của một task, quản lý subtask.
**Actor:** Free User, VIP User · **Screens:** SCR-08 · **Priority:** P1

### Preconditions

- Task đã tồn tại (tạo bằng Quick Add hoặc từ nơi khác).

### Main Flow

1. User nhấn "Edit" trên một task.
2. System mở Task Details với dữ liệu hiện có.
3. User chỉnh sửa các trường.
4. User thêm/tick/sửa subtask.
5. User nhấn "Save changes".
6. System kiểm tra và lưu Task cùng Subtask.
7. System cập nhật Reminder và quay về To-do List.

### Alternative Flows

- **Delete:** User nhấn thùng rác → xác nhận → Task và toàn bộ Subtask bị xóa, Reminder bị hủy.
- **Back:** User nhấn "←" khi có thay đổi chưa lưu → System hỏi xác nhận.

### Task Fields

| Field | Required | Notes |
|---|---|---|
| Task Title (kèm checkbox) | Yes | 1–200 ký tự |
| Time (Due Date + Due Time) | No | Ví dụ "Today · 4:00 PM" |
| Priority | No | None, Low, Medium, High |
| Reminder | No | Chỉ bật được khi có Time |
| Repeat | No | None, Daily, Weekdays, Weekly, Monthly, Custom |
| Category | No | Dùng chung danh sách với Event |
| Estimated Time | No | Phút hoặc giờ |
| Color | No | Mặc định theo Category |
| Tags | No | Nhiều tag, thêm bằng "+" |
| Notes | No | Tối đa 1.000 ký tự |
| Subtasks | No | Danh sách có checkbox |

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-10.01 | Tiêu đề nhóm "Subtasks · x/y"; "+ Add" thêm subtask với ô nhập tự focus. |
| FR-10.02 | Subtask có thể tick, sửa, xóa và kéo để sắp xếp. |
| FR-10.03 | Khi tất cả subtask hoàn thành, System gợi ý đánh dấu task cha hoàn thành (không tự động). |
| FR-10.04 | Task lặp lại: khi hoàn thành, System tạo lần kế tiếp với DueDate mới, subtask được đặt lại trạng thái chưa hoàn thành. |
| FR-10.05 | Bật Reminder khi chưa có Time thì System yêu cầu chọn Time trước. |

### Business Rules

- Quan hệ Task 1 → N TaskSubtask; xóa Task thì xóa toàn bộ Subtask (Cascade Delete).

---

## FR-11 – NOTES & QUICK NOTE

**Description:** Ghi chú nhanh, xem và cập nhật từ Home, Lock Screen và Notification; mọi note dùng chung một bảng dữ liệu.
**Actor:** Free User, VIP User · **Screens:** SCR-01, SCR-11, SCR-12, SCR-16 · **Priority:** P1

### Preconditions

- Không có.

### Main Flow – Edit Quick Note

1. User nhấn "Edit" trên widget Quick Note (Home) hoặc "Tap to type" (Lock Screen).
2. System mở trình sửa với nội dung Quick Note hiện tại.
3. User nhập nội dung.
4. System tự động lưu sau 1 giây ngừng gõ.
5. System hiển thị trạng thái "Saved · just now".
6. Home, Lock Screen và Notification hiển thị nội dung mới.

### Alternative Flows

- **Chưa có Quick Note:** System tạo Note mới với `IsQuickNote = true` ở lần lưu đầu tiên.
- **Notes List (P2):** Từ widget Quick Note → "View all" → danh sách note: tìm kiếm, ghim/bỏ ghim, xóa, "Set as Quick Note".

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-11.01 | Note gồm Title (tùy chọn), Content (bắt buộc), Color, IsPinned, IsQuickNote. |
| FR-11.02 | Quick Note giới hạn 500 ký tự; bộ đếm "n/500"; đạt giới hạn thì không nhập thêm được. |
| FR-11.03 | Tại mọi thời điểm chỉ có một Quick Note hoạt động; đặt note khác làm Quick Note thì note cũ trở thành note thường. |
| FR-11.04 | Notes List hỗ trợ tìm kiếm theo Title và Content, note ghim nằm trên cùng. *(P2)* |

### Business Rules

- Quick Note dùng chung bảng Note, không có nguồn dữ liệu riêng (BR-09).

---

## FR-12 – MONTH SNAPSHOT & SAVE IMAGE

**Description:** Xuất lịch tháng (kèm chấm sự kiện) thành ảnh để lưu, chia sẻ hoặc làm hình nền.
**Actor:** Free User, VIP User · **Screens:** SCR-01, SCR-19 · **Priority:** P2

### Preconditions

- Widget Month snapshot đang hiển thị trên Home.

### Main Flow

1. User nhấn "Save image" trên widget snapshot.
2. System dựng ảnh lịch tháng hiện tại theo Background, Font và Template đang dùng.
3. System xin quyền lưu ảnh nếu Android yêu cầu.
4. System lưu ảnh PNG vào thư viện ảnh.
5. System hiển thị "Đã lưu ảnh".

### Alternative Flows

- **Share:** User chạm vào snapshot → System mở xem trước và Android Share Sheet.
- **3a.** User từ chối quyền → System hiển thị hướng dẫn cấp quyền, không lưu ảnh.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-12.01 | Widget snapshot chỉ hiển thị (display-only), không sửa dữ liệu. |
| FR-12.02 | Ảnh xuất ra có kích thước đúng độ phân giải màn hình thiết bị. |
| FR-12.03 | Mặc định ảnh chỉ chứa chấm sự kiện, không chứa tiêu đề event; User có thể bật tùy chọn hiển thị tiêu đề. |
| FR-12.04 | Tùy chọn "Set as lock screen wallpaper" qua WallpaperManager nếu thiết bị cho phép. *(P3)* |

---

## FR-13 – THEME & APPEARANCE

**Description:** Quản lý giao diện tổng thể của toàn ứng dụng.
**Actor:** Free User, VIP User · **Screens:** SCR-10, SCR-20 · **Priority:** P1

### Main Flow

1. User mở Settings → Appearance.
2. System hiển thị chế độ giao diện và Theme hiện tại.
3. User chọn Light / Dark / System hoặc Theme khác.
4. System áp dụng ngay cho toàn ứng dụng.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-13.01 | Chế độ giao diện: Light / Dark / System. |
| FR-13.02 | Default Theme (Free): tông lavender, tối giản, bo góc mềm, dễ đọc, ít hiệu ứng. |
| FR-13.03 | VIP mở khóa màu chủ đạo tùy chỉnh, phông chữ tùy chỉnh và kiểu thành phần. |
| FR-13.04 | Đổi Theme áp dụng ngay, không cần khởi động lại ứng dụng. |

### Business Rules

- Theme điều khiển toàn ứng dụng; Widget Template chỉ điều khiển widget (BR-04, BR-05).

---

## FR-14 – WIDGET TEMPLATE

**Description:** Mẫu trình bày cho widget hoặc toàn bộ bố cục dashboard.
**Actor:** Free User, VIP User · **Screens:** SCR-01, SCR-02, SCR-09 · **Priority:** P1

### Main Flow – Apply Template

1. User mở "Create more" trên Home hoặc tab Presets trong Template Studio.
2. System hiển thị danh sách template (Free và Premium).
3. User chọn một template.
4. System hiển thị Preview.
5. Nếu template Free hoặc User là VIP: User nhấn Apply.
6. System áp dụng template cho bố cục hiện tại.
7. Home/Lock Screen cập nhật giao diện.

### Alternative Flows

- **5a.** Template Premium và User Free → System hiển thị Paywall (FR-15).

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-14.01 | Template xác định layout, màu, phông, kiểu thẻ và kích thước widget. |
| FR-14.02 | Loại widget hỗ trợ: To-do, Habits, This week, Month, Goals, Quick Note, Schedule. |
| FR-14.03 | Prototype có sẵn 3 Free Template; Premium Template có biểu tượng khóa. |
| FR-14.04 | Mỗi bố cục chỉ áp dụng một template tại một thời điểm; đổi template không làm mất dữ liệu. |

---

## FR-15 – VIP & PAYWALL

**Description:** Cơ chế kiểm soát quyền truy cập chức năng Premium và quy trình nâng cấp mô phỏng.
**Actor:** Free User, VIP User · **Screens:** SCR-09, SCR-17 · **Priority:** P1

### Main Flow – Upgrade

1. User Free mở tab VIP hoặc chạm vào một chức năng có biểu tượng khóa.
2. System hiển thị Paywall: quyền lợi VIP, gói tháng/năm (giá mô phỏng).
3. User chọn gói và nhấn "Upgrade".
4. System hiển thị hộp thoại xác nhận Mock Purchase.
5. User xác nhận.
6. System tạo bản ghi Purchase và đặt VIP Status = VIP.
7. System mở khóa chức năng Premium ngay lập tức và quay về màn hình trước.

### Alternative Flows

- **2a.** User là VIP → tab VIP mở thẳng Template Studio.
- **5a.** User hủy → quay về màn hình trước, không thay đổi trạng thái.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-15.01 | Mọi chức năng Premium kiểm tra quyền qua một hàm dùng chung `canAccess(feature)`. |
| FR-15.02 | Chức năng Premium với User Free luôn hiển thị biểu tượng khóa. |
| FR-15.03 | Có tùy chọn "Downgrade to Free" trong chế độ Debug để kiểm thử. |
| FR-15.04 | Khi về Free, template và nội dung VIP đã tạo được giữ nhưng bị khóa; bố cục quay về Free Template mặc định. |

### Free vs VIP

| Free | VIP |
|---|---|
| Calendar, Event, Goal, Habit, To-do, Quick Note | Tất cả chức năng Free |
| Default Theme, 3 Free Template | Template Studio, Premium Template |
| Ảnh nền cá nhân, phông cơ bản | Phông Premium, màu tùy chỉnh, nền Premium |
| Notification, Lock Screen cơ bản | Tùy biến Lock Screen nâng cao |

---

## FR-16 – TEMPLATE STUDIO

**Description:** Công cụ dành cho VIP để tự thiết kế template dashboard.
**Actor:** VIP User · **Screens:** SCR-09 · **Priority:** P1

### Preconditions

- User có VIP Status = VIP.

### Main Flow

1. VIP User mở tab VIP.
2. System hiển thị Template Studio ở tab Canvas với bản xem trước.
3. User đặt tên template.
4. User chỉnh Colors, Layout, Typography, Widget style, Widget size.
5. System cập nhật bản xem trước ngay sau mỗi thay đổi.
6. User nhấn "Save".
7. System lưu template và hỏi "Apply now?".
8. User chọn Apply hoặc Later.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-16.01 | Tiêu đề "Template Studio", mô tả "Build a dashboard that feels like you", nút "Save". |
| FR-16.02 | Ba tab: **Canvas** (chỉnh trực tiếp), **Styles** (bộ phong cách có sẵn), **Presets** (template đã lưu và mẫu hệ thống). |
| FR-16.03 | Bản xem trước có tên template (sửa được) và khoảng ngày hiện tại. |
| FR-16.04 | **Colors:** bảng màu có tên (ví dụ Lavender) và màu tùy chỉnh. |
| FR-16.05 | **Layout:** tối thiểu 3 kiểu chia cột. |
| FR-16.06 | **Typography:** chọn phông (ví dụ "Inter · Clean"). |
| FR-16.07 | **Widget style:** kiểu thẻ (ví dụ Soft cards) và bán kính bo góc (ví dụ Round 16). |
| FR-16.08 | **Widget size:** S / M / L. |
| FR-16.09 | Không giới hạn số template người dùng lưu; có thể đổi tên, nhân bản, xóa, áp dụng từ tab Presets. |

---

## FR-17 – TEMPLATE MARKETPLACE & PUBLISH

**Description:** Khám phá, sở hữu và chia sẻ template trong cộng đồng. Chưa có UI, thuộc giai đoạn sau.
**Actor:** Free User, VIP User · **Screens:** SCR-18 · **Priority:** P3

### Main Flow – Browse & Purchase

1. User mở Marketplace.
2. System hiển thị danh sách template.
3. User tìm kiếm hoặc lọc.
4. User chọn template → System mở Template Detail.
5. Template Free: User nhấn Apply.
6. Template Premium chưa sở hữu: User nhấn Purchase → Mock Purchase → template được đánh dấu Owned → User Apply.

### Main Flow – Publish

1. VIP User chọn một template trong Presets → "Publish".
2. System yêu cầu Name, Description, Category, Preview.
3. User xác nhận → Status chuyển Draft → Published.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-17.01 | Tìm kiếm theo tên, từ khóa, category; lọc theo Free, Premium, Category, New, Popular. |
| FR-17.02 | Template Detail: tên, preview, mô tả, loại widget, người tạo, Free/Premium, giá, nút Apply/Purchase. |
| FR-17.03 | Template có thể chuyển Published → Unpublished bởi người tạo. |

### Business Rules

- Sở hữu template khác với đang áp dụng template (BR-07).

---

## FR-18 – NOTIFICATION & REMINDER

**Description:** Nhắc nhở cho Event, Task, Habit và Goal.
**Actor:** System, Android OS, User · **Screens:** Hệ thống · **Priority:** P1

### Preconditions

- Quyền Notification đã được cấp.

### Main Flow

1. User đặt Reminder khi tạo/sửa Event, Task, Habit hoặc Goal.
2. System lưu bản ghi Reminder.
3. System lập lịch thông báo với Android.
4. Đến thời điểm nhắc, Android hiển thị Notification.
5. User chạm vào Notification.
6. System mở đúng màn hình chi tiết của dữ liệu nguồn.

### Alternative Flows

- **Task:** User chọn **Done** → Task gốc chuyển Completed; chọn **Snooze** → nhắc lại sau 10 phút hoặc 1 giờ.
- **Habit:** User chọn **Done** hoặc **Skip** → Occurrence cập nhật tương ứng.

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-18.01 | Goal Reminder nhắc vào ngày cuối kỳ nếu goal chưa đạt. |
| FR-18.02 | Notification hiển thị tiêu đề, thời gian, địa điểm (nếu có). |
| FR-18.03 | Dữ liệu nguồn bị xóa → hủy Reminder; đổi thời gian → lên lịch lại; hoàn thành → hủy Reminder còn lại. |
| FR-18.04 | Reminder được khôi phục sau khi khởi động lại thiết bị (BOOT_COMPLETED). |
| FR-18.05 | Dùng exact alarm khi được cấp quyền (Android 12+); nếu không, dùng inexact alarm và thông báo cho User. |
| FR-18.06 | Tôn trọng cài đặt bật/tắt theo từng loại trong Settings → Notifications. |

### Business Rules

- Notification chỉ tham chiếu dữ liệu nguồn, không tạo dữ liệu nghiệp vụ mới (BR-08).

---

## FR-19 – LOCK SCREEN

**Description:** Hiển thị lịch trình, công việc và Quick Note để xem nhanh mà không cần mở ứng dụng.
**Actor:** User, Android OS · **Screens:** SCR-11 · **Priority:** P1

### Preconditions

- Lock Screen được bật trong Settings → Lock Screen.

### Main Flow

1. User bật màn hình khi thiết bị đang khóa.
2. System hiển thị đồng hồ, ngày và các khối Schedule, To-do, Quick Note.
3. User xem lịch trình hôm nay (chỉ đọc).
4. User tick task trên khối To-do (nếu Quick actions bật).
5. System cập nhật Task gốc.
6. User chạm "Tap to type" để cập nhật Quick Note.

### Alternative Flows

- **Open app:** User chạm vào Schedule → Android yêu cầu mở khóa → ứng dụng mở Calendar.
- **Privacy mode:** Nếu bật "Hide details when locked", các khối chỉ hiển thị số lượng (ví dụ "3 events, 2 tasks").

### Detailed Requirements

| ID | Requirement |
|---|---|
| FR-19.01 | Mỗi khối (Schedule, To-do, Quick Note) bật/tắt riêng trong Settings. |
| FR-19.02 | **Schedule:** tối đa 5 event sắp tới hôm nay (giờ, tiêu đề, thanh màu); nhãn "Read only"; không sửa, xóa, kéo, dời lịch. |
| FR-19.03 | **To-do:** tối đa 5 task chưa hoàn thành, ưu tiên theo Due Time rồi Priority; nhãn "Quick actions on" khi bật thao tác nhanh. |
| FR-19.04 | Icon báo thức trên mỗi task dùng để Snooze reminder của task đó. |
| FR-19.05 | **Quick Note:** hiển thị nội dung Quick Note; "Tap to type" mở ô nhập. |
| FR-19.06 | Cách triển khai kỹ thuật theo OI-07. |

### Business Rules

- Lock Screen không là nguồn dữ liệu độc lập (BR-08).
- Không yêu cầu hoặc lưu PIN/mật khẩu/sinh trắc học; xác thực dùng cơ chế của hệ điều hành (BR-14).

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
