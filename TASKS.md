# TASKS — SuperCalendar Back-end

> **Back-end** ở đây = tầng **domain + data + services** trong Flutter (không có server).
> Front-end (presentation/) đã được làm riêng.
>
> Package name: `flutter_application`
> Kiến trúc: feature-first, mỗi feature có `domain/` → `data/` → `presentation/`

---

## Trạng thái domain models (đã hoàn thiện ✅)

| File | Trạng thái |
|---|---|
| `calendar/domain/event.dart` | ✅ CalendarEvent — thêm isAllDay, calendarId, categoryId, repeatRule, externalId, notes |
| `calendar/domain/habit.dart` | ✅ Habit + HabitOccurrence entity |
| `calendar/domain/goal.dart` | ✅ Goal + GoalType + GoalStatus (MỚI) |
| `todo/domain/task.dart` | ✅ Task + Subtask |
| `note/domain/note.dart` | ✅ Note — thêm isPinned, isQuickNote, color |
| `settings_screen/domain/user.dart` | ✅ User — thêm email, avatar, updatedAt |
| `settings_screen/domain/app_settings.dart` | ✅ AppSettings (tách ra file riêng, MỚI) |
| `vip/domain/template.dart` | ✅ Template — thêm isSystem, isPremium, status, category |
| `vip/domain/purchase.dart` | ✅ Purchase + ProductType + PaymentResult (tách ra file riêng, MỚI) |
| `core/data/document_store.dart` | ✅ Collections thêm `goals`, `habit_occurrences` |
| `calendar/data/goal_repository.dart` | ✅ GoalRepository (MỚI) |

---

## 👤 Người 1 — Core Data · Calendar · Event · Habit · Goal

### Mô tả
Chịu trách nhiệm lớp database và toàn bộ tầng data của Calendar feature.
**Phải làm trước** vì Người 2 và 3 phụ thuộc vào các model này.

### Files phụ trách

```
lib/core/data/
    sqlite_document_store.dart     ← mở rộng schema SQLite: thêm bảng goals, habit_occurrences
    document_store.dart            ← ĐÃ CẬP NHẬT (collections mới đã có)
    repository.dart                ← không cần sửa

lib/core/services/
    system_calendar_service.dart   ← FR-22: đọc lịch Android (READ_CALENDAR)
    seed_data.dart                 ← thêm sample Goals, HabitOccurrences

lib/features/calendar/
    domain/
        event.dart                 ← ĐÃ CẬP NHẬT
        habit.dart                 ← ĐÃ CẬP NHẬT (có HabitOccurrence)
        goal.dart                  ← ĐÃ TẠO MỚI
    data/
        event_repository.dart      ← bổ sung: recurring event (BR-10), delete scope
        habit_repository.dart      ← bổ sung: HabitOccurrence CRUD, BR-02, BR-17
        goal_repository.dart       ← ĐÃ TẠO MỚI (CRUD, increment, recalculate)
```

### Việc cần làm

- [ ] **sqlite_document_store.dart**: thêm bảng `goals` và `habit_occurrences` vào schema SQL `CREATE TABLE IF NOT EXISTS`
- [ ] **event_repository.dart**: thêm `deleteScope(event, scope)` cho BR-10 (one / from-this / all); thêm `EventException` khi xóa một lần lặp
- [ ] **habit_repository.dart**: thêm `HabitOccurrenceRepository` riêng hoặc tích hợp vào `HabitRepository` — lưu/đọc `HabitOccurrence` từ `Collections.habitOccurrences`; implement BR-17 (đổi repeat rule chỉ ảnh hưởng từ hôm nay)
- [ ] **system_calendar_service.dart**: hoàn thiện đọc Android calendar, trả về `List<CalendarEvent>` với `source = system_calendar`
- [ ] **seed_data.dart**: thêm 2–3 Goals mẫu và HabitOccurrences mẫu

### Acceptance criteria liên quan
AC-11, AC-12, AC-15, AC-17, AC-18, AC-19, AC-20, AC-42, AC-43

---

## 👤 Người 2 — Task · Note · Notification · Reminder

### Mô tả
Chịu trách nhiệm To-do system, Notes/Quick Note, và toàn bộ notification/reminder.

### Files phụ trách

```
lib/features/todo/
    domain/
        task.dart                  ← ĐÃ CÓ (Task + Subtask)
    data/
        task_repository.dart       ← bổ sung: recurring task (AC-25), tag CRUD

lib/features/note/
    domain/
        note.dart                  ← ĐÃ CẬP NHẬT (isPinned, isQuickNote, color)
    data/
        note_repository.dart       ← bổ sung: pin/unpin, 500-char limit (FR-11.02)

lib/core/services/
    notification_service.dart      ← FR-18: schedule reminder cho Event/Task/Habit
    notification_actions.dart      ← Done/Snooze action (AC-35)
    local_notification_service.dart ← Android notification channel setup
    app_state.dart                 ← kết nối task repository và note repository
```

### Việc cần làm

- [ ] **task_repository.dart**: thêm `nextOccurrence(task)` cho recurring task (AC-25 — khi tick Weekday task vào thứ Sáu, DueDate kế tiếp là thứ Hai); thêm `addTag(task, tag)` / `removeTag`
- [ ] **note_repository.dart**: `pin(note)` / `unpin(note)` cập nhật `isPinned` và persist; `setQuick(text)` enforce 500-char limit (FR-11.02, AC-26)
- [ ] **notification_service.dart**: implement `scheduleForEvent(event)`, `scheduleForTask(task)`, `scheduleForHabit(habit)` — tính `triggerAt` từ `reminderMinutes`; `cancel(sourceId)` khi xóa (AC-16, AC-24)
- [ ] **notification_actions.dart**: xử lý action `done` → gọi `task_repository.setCompleted` (AC-35); action `snooze` → reschedule +15 phút
- [ ] **Boot receiver** (Android Kotlin): đăng ký lại tất cả reminder sau khi thiết bị khởi động lại (AC-36, NFR-05)

### Acceptance criteria liên quan
AC-21, AC-22, AC-23, AC-24, AC-25, AC-26, AC-27, AC-35, AC-36, AC-39

---

## 👤 Người 3 — User · Settings · Theme · VIP · Template

### Mô tả
Chịu trách nhiệm user profile, app settings, theme switching, VIP gate, mock payment, template store.

### Files phụ trách

```
lib/features/settings_screen/
    domain/
        user.dart                  ← ĐÃ CẬP NHẬT (email, avatar, updatedAt)
        app_settings.dart          ← ĐÃ TẠO MỚI (ThemeMode, TimeFormat, WeekStart...)
    data/
        user_repository.dart       ← bổ sung: load/save AppSettings đầy đủ fields mới

lib/features/vip/
    domain/
        template.dart              ← ĐÃ CẬP NHẬT (isSystem, isPremium, status, timestamps)
        purchase.dart              ← ĐÃ TẠO MỚI (ProductType, PaymentResult, Purchase)
    data/
        template_repository.dart   ← bổ sung: mock purchase flow dùng Purchase mới

lib/app/theme/
    app_colors.dart                ← AppColors token
    app_palette.dart               ← bảng màu pastel
    app_theme_data.dart            ← Light/Dark theme data
    app_theme.dart                 ← ThemeData builder

lib/core/services/
    app_state.dart                 ← VIP gate canAccess(feature), theme state (BR-06)
```

### Việc cần làm

- [ ] **user_repository.dart**: cập nhật `updateSettings` để persist các field mới của `AppSettings` (themeMode, weekStart, timeFormat, etc.); thêm `updateProfile(email, avatar)` cho User
- [ ] **template_repository.dart**: cập nhật `recordPurchase` dùng `Purchase` mới từ `purchase.dart` với `ProductType`; thêm `hasPurchased(userId, productId)` convenience method
- [ ] **app_state.dart**: implement `canAccess(VipFeature feature)` check `user.isVip` (BR-06); expose `weekStart` từ settings cho Calendar widget; expose `darkMode` và `themeMode` cho MaterialApp
- [ ] **app_theme_data.dart**: đảm bảo Light/Dark theme đều hoạt động, không hard-code màu (AC-29); thêm 3 Free Themes: `pastel_minimal`, `pastel_blue`, `minimal_gray`
- [ ] **seed_data.dart**: phối hợp với Người 1 để thêm sample templates (3 free + 2 premium)

### Acceptance criteria liên quan
AC-04, AC-06, AC-29, AC-30, AC-31, AC-32, AC-33, AC-34, AC-40, AC-41

---

## Quy ước chung

- Import nội bộ: `package:flutter_application/...`
- Không hard-code màu trong repository hay service — chỉ trong `app/theme/`
- Mọi write phải đi qua `DocumentStore` (không dùng SharedPreferences riêng)
- Mọi delete phải có khả năng undo trong 5 giây (BR-13) — repository expose `delete()` trả về object đã xóa để presenter có thể undo
- Ghi theo transaction để không mất dữ liệu khi force-quit (NFR-04)
- Không xin quyền cho tính năng chưa dùng (§27)

## Phụ thuộc giữa các người

```
Người 1 (domain models xong trước)
    ↓
Người 2 (dùng Event, Habit, Task)      Người 3 (dùng User, AppSettings)
    ↓                                       ↓
                    app_state.dart (tích hợp cả 3)
```

Người 1 cần hoàn thành ít nhất `event.dart`, `habit.dart`, `goal.dart` trước khi Người 2 bắt đầu `notification_service.dart`.
