# Backlog sửa logic và trải nghiệm SuperCalendar

Ngày ghi nhận: 21/11/2026.

Trạng thái: **Chưa triển khai các mục dưới đây. Người dùng muốn lưu lại để ưu tiên xử lý vấn đề khác trước.** Không tự tick hoàn thành dựa trên số lượng test hiện có.

## Phạm vi và bằng chứng

- Rà soát code trong workspace sau các thay đổi reminder nhiều mốc, editor, Home và Schedule.
- Ba probe độc lập đã xác nhận hành vi hiện tại: sự kiện lặp chỉ lập lần gần nhất cho mỗi mốc, Habit ngày mai chưa có lịch nhắc sẵn, sự kiện qua đêm thiếu ở ngày thứ hai.
- Probe tạm nằm trong `.dart_tool/usability_review_test.dart` (thư mục bị Git bỏ qua). Khi triển khai, đưa các case cần thiết vào test hồi quy có quản lý phiên bản.
- Các mục còn lại được ghi nhận qua code; chưa phải kết quả nghiệm thu lại trên máy thật.
- 29 test liên quan Schedule/frame/export đã pass ở lượt sửa gần nhất, nhưng không chứng minh wallpaper luôn hiển thị đủ mọi nội dung hoặc reminder hoạt động ổn định nhiều ngày.

## P1 — Nhắc nhiều ngày chưa đầy đủ

- [ ] Lập lịch trước cho nhiều occurrence hợp lệ của sự kiện lặp và Habit, thay vì phụ thuộc người dùng mở app hoặc phát sinh đồng bộ tiếp theo.
- [ ] Giữ các mốc nhắc người dùng chọn; tôn trọng ngày bắt đầu/kết thúc, lịch lặp, exception, trạng thái Done/Skipped/Deleted và công tắc theo loại.
- [ ] Giữ giới hạn số notification chờ của nền tảng; không sinh trùng hoặc giữ lịch mồ côi khi sửa/xóa nguồn.
- [ ] Test qua nhiều ngày mà không mở app; reboot trước giờ nhắc; ghi thời điểm nhận thực tế.

Hiện trạng: `buildReminderPlan` chọn occurrence gần nhất cho mỗi mốc event; Habit chỉ xét ngày hiện tại. Probe Habit bắt đầu ngày mai cho danh sách reminder rỗng. Đây là giới hạn lập lịch đã xác nhận, chưa phải bằng chứng thiết bị chắc chắn mất mọi reminder ngày sau.

Code: `lib/core/services/reminder_plan.dart`, `local_notification_service.dart` và luồng sync liên quan.

## P1 — Sự kiện qua đêm thiếu ở ngày tiếp theo

- [ ] Hiển thị sự kiện trên mọi ngày giao với khoảng thời gian của nó, thống nhất quy tắc mốc kết thúc đúng 00:00.
- [ ] Kiểm tra lịch ngày/tuần, Schedule, sự kiện nhiều ngày, all-day, lặp và exception.
- [ ] Thêm test hồi quy: 21/11 23:00 → 22/11 01:00 phải xuất hiện ở cả hai ngày.

Hiện trạng: `CalendarEvent.isOn` của sự kiện không lặp chỉ so sánh ngày bắt đầu. Probe xác nhận không xuất hiện ngày 22/11.

Code: `lib/features/calendar/domain/event.dart`, `lib/features/calendar/data/event_repository.dart`.

## P1 — Wallpaper có thể chứa lịch cũ

- [ ] Chốt cơ chế: cập nhật tự động theo khả năng nền tảng, hoặc cho biết ảnh đã cũ và cung cấp thao tác cập nhật nhanh.
- [ ] Nhận biết thay đổi dữ liệu lịch/task/note và chuyển ngày/tuần sau lần xuất hoặc đặt wallpaper.
- [ ] Không ngầm hứa ảnh PNG có thể tương tác hoặc tự cập nhật.
- [ ] Test sửa/xóa lịch sau khi đặt wallpaper và chuyển sang tuần mới.

Hiện trạng qua code: wallpaper là ảnh tĩnh; các lệnh đặt wallpaper nằm trong luồng xuất/đặt thủ công, chưa thấy cơ chế tự render và đặt lại khi dữ liệu đổi.

Code: `edit_screen.dart`, `wallpaper_export_screen.dart`, `lib/core/services/wallpaper_service.dart`.

## P2 — Schedule đầy chiều ngang nhưng ô thấp vẫn che nội dung

- [ ] **Giữ cả hàng lịch tuần và danh sách hôm nay** theo quyết định mới nhất của người dùng.
- [ ] Giữ hai thẻ ôm chiều ngang, không quay lại thu nhỏ cả cụm khi nội dung cao.
- [ ] Thay phụ thuộc vùng cuộn bằng cách hiển thị phù hợp với ảnh tĩnh: giới hạn dòng có chỉ báo `+N mục`, chiều cao tối thiểu hoặc cảnh báo trước khi xuất.
- [ ] Kiểm tra PNG với ô thấp/cao, nhiều sự kiện và task, cỡ chữ lớn, Hide details và các tỷ lệ màn hình.

Hiện trạng: hai phần Schedule đang nằm trong các vùng cuộn riêng. Khi xuất PNG, người dùng không thể vuốt ảnh để xem phần ngoài vùng hiển thị. Test chiều rộng/không overflow không đủ để kết luận nội dung ảnh đã đầy đủ.

Code: `lib/features/lock_screen/presentation/widgets/lock_widgets.dart`, `widget_grid.dart`, `widget_style_screen.dart`.

## P2 — Home giới hạn task nhưng thiếu chỉ báo

- [ ] Hiện tổng số hoặc “Xem tất cả · còn N việc” khi danh sách rút gọn.
- [ ] Làm rõ thứ tự ưu tiên: hôm nay, quá hạn, chưa có hạn; bộ đếm nhất quán với hideCompletedTasks.
- [ ] Test thêm task thứ tư, hoàn thành task, xóa/Undo và mở lại app.

Hiện trạng: `TaskRepository.dashboard` trả tối đa 3 task. Widget chưa báo rõ số task bị ẩn nên người dùng có thể tưởng task mới chưa được lưu.

Code: `lib/features/todo/data/task_repository.dart`, `lib/features/dashboard/presentation/widgets/home_widgets.dart`.

## P2 — Widget mẫu và tên gọi chưa đúng dữ liệu

- [ ] Month snapshot: hiển thị đúng tháng hoặc đổi nhãn rõ ràng thành khoảng 14 ngày.
- [ ] Weather: ẩn mặc định hoặc giữ nhãn mẫu rõ ràng cho đến khi có dữ liệu thời tiết thật.
- [ ] Chấm màu lịch tuần: lấy từ sự kiện thật thay vì bảng màu cố định; đồng bộ với cài đặt ngày đầu tuần.
- [ ] Test không có dữ liệu, dữ liệu mới, đổi tháng và đổi Monday/Sunday.

Hiện trạng: Month snapshot hiện 14 ngày tính từ hôm nay; Weather dùng mẫu San Francisco; `weekDotColors` là danh sách màu cố định.

Code: `lib/features/dashboard/presentation/widgets/home_widgets.dart`, các wallpaper widget trong `lock_widgets.dart`.

## P2 — Sync status đang mô phỏng

- [ ] Trước khi có cloud sync thật, ghi rõ dữ liệu lưu trên thiết bị; không hiển thị trạng thái kết nối hoặc số thiết bị như dữ liệu thực.
- [ ] Khi triển khai sync, nối trạng thái thật và nút Try again với thao tác thật.
- [ ] Phân biệt đăng nhập Google với đồng bộ dữ liệu lịch; kiểm tra dữ liệu giữa các tài khoản và thiết bị.

Hiện trạng: SyncStatusScreen hiển thị cố định Offline, 3 devices và Try again chỉ hiện snackbar. Không dùng các nhãn này làm bằng chứng Firebase sync đã hoạt động.

Code: `lib/features/settings_screen/presentation/screens/sync_status_screen.dart`, luồng auth/data liên quan.

## P1 — Quick Note khi tiến trình app đã đóng: cần điều tra tiếp

- [ ] Điều tra receiver ANR và ghi chú không được lưu trong lần native test trước.
- [ ] Chạy lại trên release APK và máy thật: RemoteInput Save khi app ở nền và khi process không còn.
- [ ] Phân biệt process kill với Force stop; xác nhận nội dung trong database sau khi mở lại.
- [ ] Kiểm tra cold Open app, Append/Replace, quyền thông báo và lỗi có thể phục hồi.

Bằng chứng cũ: `docs/ANDROID_ACCEPTANCE_2026-11-19.md` ghi ANR của ActionBroadcastReceiver trên debug APK/API 33. Chưa được coi là đã sửa hoặc đã tái hiện trên mọi thiết bị. Quick Note khi app đang chạy đã từng lưu thành công.

## Thứ tự xử lý gợi ý khi quay lại

1. Reminder nhiều ngày và cold Quick Note.
2. Sự kiện qua đêm.
3. Schedule xuất ảnh đủ nội dung và nhận biết wallpaper cũ.
4. Home và widget phản ánh dữ liệu thật.
5. Trạng thái sync rõ ràng; đồng bộ Firebase theo phạm vi riêng.

## Điều kiện đóng từng mục

- Có ca tái hiện trước sửa và test hồi quy phù hợp.
- Test liên quan pass; analyze không có error/warning mới.
- Các mục notification/wallpaper có kết quả trên thiết bị phù hợp: thiết bị/API, Expected/Actual, ảnh hoặc log.
- Mục chưa chạy hoặc bị chặn phải ghi rõ, không tick hoàn thành.
