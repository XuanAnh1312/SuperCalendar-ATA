# Backlog sửa logic và trải nghiệm SuperCalendar

Ngày ghi nhận: 21/11/2026.

Trạng thái: **Backlog chưa được nghiệm thu hoàn tất. Riêng tự cập nhật wallpaper Android đã có triển khai và bằng chứng thử nghiệm ở phần cập nhật bên dưới.** Các mục khác vẫn được lưu để xử lý sau. Không tự tick hoàn thành dựa trên số lượng test hiện có.

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

Hiện trạng tại thời điểm audit ban đầu: wallpaper là ảnh tĩnh; các lệnh đặt wallpaper nằm trong luồng xuất/đặt thủ công. Triển khai hằng ngày mới được mô tả bên dưới; cập nhật ngay khi mọi dữ liệu đổi chưa nằm trong nghiệm thu này.

Code: `edit_screen.dart`, `wallpaper_export_screen.dart`, `lib/core/services/wallpaper_service.dart`.

### Cập nhật triển khai Android ngày 21/11/2026

Đã triển khai tự cập nhật wallpaper hằng ngày, mặc định tắt và chỉ bật sau đồng ý. Sau khi đặt lock wallpaper thành công, app hỏi một lần; chọn Để sau không tự bật và không hỏi lại ở các lần đặt tiếp theo. Settings → Lock Screen có công tắc, Xem trước ngày mai và Cập nhật hình nền ngay. Thiết kế đã áp dụng được lưu riêng, không tự áp dụng bản nháp chưa đặt wallpaper.

Dùng JobScheduler persisted, thời điểm sớm nhất là nửa đêm theo múi giờ thiết bị, điều kiện pin không thấp và retry giãn cách từ 30 phút. Có cập nhật bù khi mở app và tính lại lịch khi đổi giờ/múi giờ. Không xin Exact Alarm cho việc cập nhật wallpaper và không cam kết chạy chính xác 00:00. iOS chưa có tính năng tự động này.

Bằng chứng máy ảo Android 13/API 33:

- Engine nền tạo PNG 1080×2280 qua nút Preview tomorrow. Kiểm tra ảnh có ngày 22 được tô sáng và tiêu đề Sunday, November 22; không chỉ kiểm tra kích thước file.
- Tự cập nhật vẫn tắt khi dùng preview; wallpaper thật không bị thay đổi trong bài thử.
- Bật công tắc hiện hộp thoại đồng ý. Sau xác nhận, Android có job 8301 PERSISTED, batteryNotLow=true, thời gian chờ đến nửa đêm và backoff 30 phút.
- Tắt công tắc: job 8301 và 8302 không còn tồn tại.
- Đã khôi phục cấu hình fixture. So sánh nội dung SQLite trước/sau cho kết quả không thay đổi.
- Lỗi crash Impeller khi engine không có surface đã được phát hiện trong thử native và sửa bằng ImageReader off-screen; ca preview đã chạy lại thành công.

Còn phải nghiệm thu trên máy thật: cập nhật wallpaper thực tế qua nửa đêm, Doze/tiết kiệm pin, reboot trước giờ chạy, đổi múi giờ, ảnh cá nhân và nhiều hãng máy. Không tick các mục này chỉ vì preview hoặc unit test pass. Ảnh và dump thử nghiệm để riêng trong `.dart_tool/`; không đưa bản sao database/preferences vào Git.

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

## Cập nhật triển khai 27/11/2026

| Phạm vi | Thay đổi |
| --- | --- |
| Lưu dữ liệu | Lỗi ghi của một mục không chặn những mục tiếp theo. App hiển thị nút thử lưu lại. Trình sửa hình nền giữ ảnh cũ đến khi ghi xong thiết kế mới. |
| Sao lưu | Settings → Data → Planner backup lưu JSON và khôi phục các mục còn thiếu. Sao lưu gồm lịch nội bộ, việc cần làm, ghi chú, thói quen, mục tiêu và ngoại lệ lặp. Cài đặt, tài khoản, giao dịch, ảnh nền và lịch đọc từ hệ thống nằm ngoài phạm vi bản sao. |
| Lịch và nhắc | Sự kiện qua nửa đêm xuất hiện trên những ngày liên quan, dùng cùng ngày gốc khi sửa hoặc xóa một lần lặp. Kế hoạch nhắc lập trước 14 ngày trong hạn mức nền tảng, giữ các lịch tương đương và Snooze từng mốc 10 phút. Mở app hoặc đồng bộ lại làm mới kế hoạch. |
| Màn hình khóa | Tôn trọng bộ lọc lịch; Hide details ẩn nội dung ghi chú và tiêu đề thói quen. Schedule giữ hàng tuần và danh sách hôm nay, báo số mục vượt chỗ. Android báo khi lịch đã đổi kể từ lần đặt wallpaper. Người dùng cần cập nhật ảnh đã đặt để áp dụng thay đổi quyền riêng tư. |
| Home | Ưu tiên việc hôm nay, quá hạn, chưa có hạn; hiển thị số còn lại và tôn trọng ẩn việc đã hoàn thành. Tổng quan ghi đúng 14 ngày, màu tuần lấy từ sự kiện thật. Weather vẫn ghi rõ dữ liệu mẫu. |
| Onboarding và đăng nhập | Cài mới mặc định bắt đầu với dữ liệu trống, có lựa chọn dữ liệu mẫu. Dữ liệu cũ được giữ. Khởi tạo Firebase diễn ra sau khi mở planner local. Settings ghi rõ dữ liệu lưu trên thiết bị. |
| Quick Note | Lưu trực tiếp qua repository với ít thao tác nền hơn. Kết quả ổn định của RemoteInput khi tiến trình đã tắt cần được xác nhận riêng trên Android. |

Google Authentication, đồng bộ planner và thanh toán VIP là ba phần độc lập. Bản này dùng Google Authentication nếu đã cấu hình, lưu planner trên thiết bị và giữ mô phỏng giao dịch VIP. Chưa triển khai Firestore sync, tài khoản VIP mua thật hoặc phân tách planner cục bộ khi đổi tài khoản.

Kiểm thử trên workspace: 164 bài Flutter mặc định và 23 probe audit pass. Phân tích tĩnh không có lỗi hoặc cảnh báo. Script kiểm tra cấu hình iOS pass.

APK release được ký và cài thành công trên Pixel 4 emulator, Android 13/API 33. Android ghi nhận đã hiển thị MainActivity. Hộp thoại “Process system isn't responding” vẫn che giao diện sau khi chọn Wait. Log của máy ảo có lỗi hệ thống từ trước lúc cài APK, vì vậy lượt thử này chưa nghiệm thu được Onboarding, RemoteInput hoặc các thao tác màn hình khóa. Cần ghi lại kết quả trên thiết bị khác trước khi đánh dấu các mục đó hoàn thành.

Các ca nghiệm thu còn phụ thuộc Android thật gồm Quick Note RemoteInput và khởi động lạnh, nhắc sau reboot, Schedule với PIN, cùng wallpaper chạy qua nửa đêm. Thử bằng dữ liệu mẫu, ghi API, giờ dự kiến và giờ thực tế. Khi thử tiến trình đã dừng, đưa app về nền rồi dùng `adb shell am kill com.supercalendar.app`; Force stop là trạng thái hệ thống khác.

### Nghiệm thu trên máy Android

1. **Quick Note.** Cài APK, cấp quyền thông báo khi app hỏi. Trong Settings → Lock Screen, bật **Quick Note in notifications** và chọn Append hoặc Replace. Về Home, chạy lệnh dừng tiến trình ở trên nếu đang thử khởi động lạnh, khóa máy rồi mở thông báo Quick Note. Nhập một chuỗi dễ nhận biết, chọn gửi, sau đó chọn **Open app**. Xác nhận app vào trình soạn Quick Note và nội dung đã được lưu theo chế độ chọn.
2. **Reminder sau reboot.** Tạo sự kiện cách giờ hiện tại đủ để có mốc nhắc trong vài phút tới. Kiểm tra Settings → Notifications đã bật nhắc sự kiện và Android Settings → Special app access → Alarms & reminders nếu máy có mục này. Khởi động lại trước mốc nhắc, mở khóa lần đầu bằng PIN rồi giữ ở Home. Ghi lại mốc đã đặt và giờ thiết bị thực sự nhận thông báo.
3. **Schedule và quyền.** Bật **Show on lock screen**, khóa máy bằng PIN rồi chọn **Schedule** từ thông báo. Xác nhận Android yêu cầu mở khóa trước khi hiện lịch. Sau đó thu hồi quyền thông báo trong cài đặt Android, quay lại SuperCalendar và xác nhận Settings báo quyền đang tắt trong khi tạo việc hoặc ghi chú vẫn hoạt động.
4. **Wallpaper qua ngày.** Trong Edit Your Screen, đặt hình nền có Schedule và đồng ý tự cập nhật hằng ngày. Dùng **Preview tomorrow** để xác nhận bố cục ngày kế tiếp. Để máy qua nửa đêm với pin đủ, sáng hôm sau kiểm tra ngày trên màn hình khóa và **Last wallpaper update**. Ghi lại thời điểm thực tế vì Android điều phối thời điểm chạy nền.
