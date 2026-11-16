# SuperCalendar — Báo cáo kiểm thử hệ thống ngày 16/11/2026

## 1. Bản được kiểm thử và giới hạn kết luận

- Workspace: nhánh `main`, HEAD `9079852`.
- Có các thay đổi Web/SQLite và cấu hình chạy đang được stage sẵn trước đợt audit. Không reset, checkout hay ghi đè những thay đổi này.
- Commit `f9f4a04` (`issue 26 done`) chỉ có trên `feature/person2-todo-note-notifications`, chưa có trong `main`. Các kết quả dưới đây mô tả **bản main đang chạy**, không khẳng định các lỗi đó còn trên nhánh Người 2.
- Chỉ bổ sung test chẩn đoán và tài liệu/bằng chứng; không tự sửa logic sản phẩm, merge nhánh, push hoặc đóng issue.
- Tiêu chí đặc biệt được người dùng xác nhận trong đợt kiểm thử: **ảnh màn hình khóa phải có toàn bộ sự kiện của 7 ngày theo ngày/giờ**, được thiết kế tại Edit Your Screen, xuất ảnh và áp dụng làm hình nền. Quick Note phải nhập/lưu từ notification mà không cần mở màn ghi chú.
- Đây là một đợt audit rộng, không phải chứng nhận đã kiểm thử hết mọi tổ hợp thiết bị, phiên bản Android, dữ liệu và quyền hệ thống.

## 2. Kết quả thực thi

| Kiểm tra | Kết quả | Ý nghĩa |
|---|---|---|
| `flutter analyze --no-pub` | Pass trên bản ban đầu | Không phát hiện lỗi tĩnh; không chứng minh logic nghiệp vụ đúng |
| `flutter test --no-pub --reporter expanded` | **55/55 pass** | Bộ test có sẵn vẫn xanh |
| `test/system_audit_probes.dart` | **23 case: 6 pass, 17 fail** | Các case fail kiểm tra yêu cầu mong đợi và tái hiện các vấn đề ở mục 3 |
| Build Web | Pass | `flutter build web --no-pub --no-wasm-dry-run` |
| Chrome thật, headless, viewport 390×844 | Đã chạy luồng onboarding, Free/VIP, chọn ảnh, Save Image, reload, downgrade | Dùng profile audit riêng, không dùng dữ liệu Chrome cá nhân |
| Build APK debug mặc định | Fail do môi trường | Cache Kotlin khác ổ C/D; sau đó lỗi `JdkImageTransform/jlink` với JDK 26 |
| Build APK bằng JBR và tắt incremental tạm thời | **Pass** | 271 Gradle task, APK cài được; không sửa `gradle.properties` |
| Pixel 4 Android 13 / API 33 | **Bị chặn** | Máy ảo mất kết nối và sau khi khởi động lại liên tục hiện `System UI isn't responding`; không ghi nhận các bài native là pass |
| Điện thoại Android thật | Chưa có thiết bị kết nối | Chưa kiểm chứng notification, reboot, khóa bảo mật và wallpaper trên máy thật |
| Firebase | Chưa kiểm thử được trong bản này | Không thấy dependency Firebase hoặc cấu hình Firebase trong workspace được audit; phần đang làm ở nơi khác không thuộc kết luận này |

**Không được diễn giải 55 test pass thành “toàn hệ thống đã hoàn thiện”.** 17 case chẩn đoán fail và hai lỗi Web đã được tái hiện độc lập.

### Sáu luồng thành công được bổ sung kiểm tra

| Mã | Luồng | Kết quả |
|---|---|---|
| AUD-P01 | Tạo/sửa/hoàn thành task, lưu và đọc lại | Pass |
| AUD-P02 | Xóa task có 3 subtask, Undo và đọc lại | Pass ở tầng repository; chưa xác minh hủy notification native |
| AUD-P03 | Tạo/sửa/ghim/xóa/khôi phục Note | Pass |
| AUD-P04 | Quick Note giới hạn và lưu lại 500 ký tự ASCII | Pass; không bao gồm emoji, xem AUD-Q02 |
| AUD-P05 | Handler Save note với Append và Replace | Pass với database bộ nhớ và NoopNotificationService; không thay thế RemoteInput native |
| AUD-P06 | Thanh toán VIP giả lập Failed/Cancelled | Không cấp VIP, pass |

Trên Chrome còn xác minh được: Free bị chặn ở ảnh VIP; thanh toán giả lập thành công mở VIP; trạng thái VIP còn sau reload; Switch to Free đưa về giao diện Free. Đây là VIP mô phỏng cục bộ, không phải xác thực entitlement trên Firebase.

## 3. Vấn đề đã tái hiện

P1: sai luồng chính, dữ liệu lịch hoặc hành vi reminder. P2: chức năng/thiết lập/hành vi phụ sai. Hiện chưa xác nhận lỗi P0 gây mất toàn bộ dữ liệu.

| ID | Mức | Bước tái hiện và kết quả thực tế | Kết quả cần có | Bằng chứng |
|---|---|---|---|---|
| **AUD-W03** | **P1 — thiếu chức năng** | Thêm sự kiện vào ngày khác trong cùng tuần, render `WallpaperCalendarCard`: không thấy sự kiện đó. Widget chỉ vẽ 7 số ngày và một sự kiện tiếp theo của hôm nay. | Ảnh lịch tuần chứa sự kiện của **đủ 7 ngày theo ngày/giờ** như yêu cầu đã xác nhận. | Widget test W03; `lib/features/lock_screen/presentation/widgets/lock_widgets.dart`, `WallpaperCalendarCard` |
| **AUD-WEB01** | **P1 đối với bản Web** | Có VIP → Edit Your Screen → Background → Wallpaper/Change → Your photo → Use Your photo → chọn JPG hợp lệ. Ảnh không được áp dụng, phát sinh `MissingPluginException(...getApplicationDocumentsDirectory...plugins.flutter.io/path_provider)`. | Chọn và lưu ảnh bằng cơ chế lưu trữ hỗ trợ Web; hoặc thông báo rõ bản Web không hỗ trợ trước thao tác. Không phát sinh exception không được xử lý. | Chrome, ảnh `web-vip-photo-import-no-change.png`; `edit_screen.dart::_pickPhoto` |
| **AUD-WEB02** | **P1 đối với luồng xuất trên Web** | Edit Your Screen → Save Image. Phát sinh `MissingPluginException(No implementation found for method hasAccess on channel gal)`, không có ảnh tải xuống/màn thành công. | Có luồng tải PNG trên Web hoặc chặn có giải thích theo nền tảng. Lỗi phải được hiển thị cho người dùng. | Chrome, ảnh `web-save-image-no-success.png`; `edit_screen.dart::_saveImage` |
| **AUD-W02** | **P1** | Đặt viewport vật lý 1080×2400, gọi Set Wallpaper với service capture. PNG thực tế có kích thước **1080×1702**. | Xuất ảnh đúng kích thước/tỉ lệ màn hình đã quy định; không phụ thuộc canvas cố định 330×520. | Widget test W02 đọc header PNG; `edit_screen.dart::_export`, `_canvasWidth`, `_canvasHeight` |
| **AUD-W01** | **P2** | Settings → Week start = Sunday; render lịch wallpaper ngày 09/10/2026. Vẫn hiển thị tuần Monday 5 → Sunday 11. | Sunday 4 → Saturday 10, nhất quán với Calendar và Settings. | Widget test W01; `WallpaperCalendarCard` tính Monday trực tiếp |
| **AUD-N01** | **P1** | Gửi notification action Snooze cho Habit đang tồn tại. Không đặt lại reminder. `main` cũng chưa có action Skip cho Habit. | Snooze 10 phút; Skip cập nhật occurrence của ngày đó qua HabitRepository, giữ nguyên Rule. | Test N01: danh sách snoozed rỗng; `notification_actions.dart` còn `skip for now`; `NotificationActions`/nút native chưa có Skip |
| **AUD-N02** | **P1** | Tắt Events/Tasks/Habits reminder, tạo task có reminder tương lai rồi `syncNotifications`. Task vẫn được chuyển đi lập lịch. | Loại đang tắt không được lập lịch; loại khác giữ nguyên. | Test N02; `AppState.syncNotifications` và `LocalNotificationService.syncReminders` không dùng cờ theo loại |
| **AUD-N03** | **P1** | Habit bắt đầu ngày mai, có giờ 11:00 và reminder 0; tính reminder lúc 10:00 hôm nay vẫn nhận thời điểm 11:00 hôm nay. | Không nhắc trước startDate hoặc ngoài lịch lặp/ngày hợp lệ; cần kiểm tra cả occurrence Done/Skipped. | Test N03; `notification_service.dart::habitReminderTime` chỉ kiểm tra time/reminder/archive |
| **AUD-N04** | **P1** | Bật Quick Note notification → gọi `disableNotifications()`. Quick Note không bị ẩn. | Tắt thông báo phải ẩn cả notification Quick Note; xử lý nhất quán trạng thái setting. | Test N04 với NoopNotificationService; `app_state.dart::disableNotifications` thiếu `hideQuickNoteNotification` |
| **AUD-N05** | **P2** | Một repository khác ghi Habit occurrence thành Skipped, app gọi `reloadFromDisk()`. UI state vẫn coi ngày đó chưa Skipped. | Nạp lại cả Habit/occurrences khi dữ liệu bị thay đổi ngoài UI. | Test N05; `reloadFromDisk` chỉ load Tasks và Notes |
| **AUD-T01** | **P1** | Task Weekdays đến hạn thứ Sáu → tick checkbox qua `tasks.toggle`. Task được hoàn thành nhưng không có lần kế tiếp thứ Hai. | Checkbox thực hiện luồng hoàn thành và tạo occurrence kế tiếp theo AC-25. | Test T01; `TaskRepository.toggle` chỉ gọi `setCompleted`; TodoScreen dùng hàm này |
| **AUD-T02** | **P2** | Tạo task có hạn hôm qua → mở Upcoming. Task quá hạn vẫn nằm trong tập dữ liệu Upcoming. | Chỉ đưa các mục tương lai theo quy tắc đã chốt; task quá hạn không thuộc Upcoming. Cần chốt thêm vị trí cho task không có hạn. | Test T02; `TaskRepository.notDueOn` hiện chỉ loại task có hạn hôm nay |
| **AUD-T03** | **P2** | Đặt Task reminder default = 15 phút → Quick Add trên Lock Screen. Task mới có `reminderMinutes = null`. | Task mới nhận 15; giữ nguyên `defaultPriority`. Null của setting phải theo quy tắc “đúng hạn”. | Test T03; `AppState.quickAddTask`, `TaskRepository.add` |
| **AUD-T04** | **P2** | Settings `hideCompletedTasks = true` → mở To-do có task completed. Task vẫn xuất hiện. | Bộ lọc dùng thiết lập lưu trong Settings. | Widget test T04; TodoScreen chỉ dùng `_hideCompleted` cục bộ |
| **AUD-T05** | **P2** | Nhập Quick Add và nhấn Enter/Done. Nội dung được xóa nhưng focus mất. | Ô nhập trống và vẫn giữ focus theo AC-21 để thêm liên tục. | Widget test T05; `_submit` chưa yêu cầu focus trở lại |
| **AUD-Q01** | **P2** | Có Quick Note cũ → mở Quick Note notification preview. Ô nhập đã điền nội dung cũ. | Theo UI-08/FR-20.02: nội dung cũ là text phía trên, ô nhập RemoteInput trống. Phân biệt màn preview với notification native. | Widget test Q01; `QuickNoteNotificationScreen.didChangeDependencies` |
| **AUD-Q02** | **P2** | Lưu 499 chữ `a` và một emoji 😀, tổng 500 ký tự người dùng nhìn thấy. Repository cắt theo UTF-16, làm mất/nứt emoji cuối. | Giới hạn ký tự nhất quán giữa TextField, bộ đếm và database; không cắt giữa surrogate/grapheme. | Test Q02; `NoteRepository._clampQuick` dùng `length` và `substring(0, 500)` |
| **AUD-C01** | **P1** | Tạo event 09/10 23:00 → 10/10 01:00. Đọc lịch ngày 10/10 không có event đó. | Sự kiện xuất hiện trên mọi ngày mà khoảng thời gian của nó giao với ngày đó. | Test C01; `CalendarEvent.isOn` cho event thường chỉ so sánh startDate |
| **AUD-C02** | **P1** | Event Daily lúc 11:00, xóa riêng occurrence hôm nay, tính reminder lúc 10:00 vẫn ra 11:00 hôm nay. | Không nhắc occurrence đã xóa; chọn lần hợp lệ kế tiếp và áp dụng overrides. | Test C02; `eventReminderTime` bỏ qua EventException, service nhận danh sách Rule gốc |

Hai lỗi Web trên **không chứng minh nhập ảnh/lưu ảnh Android bị lỗi tương tự**. Android dùng plugin khác và cần kiểm chứng riêng.

## 4. Các điểm thấy qua code, chưa ghi là runtime fail đã xác minh

| ID | Rủi ro/điểm cần kiểm chứng tiếp | Cơ sở và cách kiểm tra |
|---|---|---|
| REVIEW-01 | Không đổi được từ ảnh cá nhân A sang ảnh B | `_openGallery` thoát khi `picked == current`; mọi ảnh cá nhân đều dùng key `photo`. Cần nhập A thành công trên Android rồi chọn Your photo lần nữa, xác nhận picker có mở hay không. |
| REVIEW-02 | File ảnh cũ bị xóa trước khi layout mới được ghi thành công | `_saveAndClose` gọi xóa ảnh cũ trước `layouts.flush()`. Cần giả lập lỗi ghi database và xác nhận ảnh cũ không bị mất. Đây là rủi ro, chưa kết luận đã xảy ra mất dữ liệu thực tế. |
| REVIEW-03 | Nút Open app của Quick Note không mở composer | Native action không bật `showsUserInterface`, handler không xử lý `open_app`; `_openTarget` cũng chưa có nhánh `quick_note`. Cần bấm thật khi app ở nền và khi process không còn. |
| REVIEW-04 | Snooze còn tồn tại sau khi nguồn bị xóa/hoàn thành | Sync giữ mọi payload `snoozed` mà không xác nhận nguồn còn hợp lệ; hàm cancel chỉ hủy ID reminder thường. Cần đặt Snooze rồi xóa/hoàn thành task, kiểm tra pending requests. |
| REVIEW-05 | Default event duration trong Settings có thể không có tác dụng | EventForm khởi tạo `_start = 14:00`, `_end = 15:00`; không đọc `defaultEventDurationMinutes`. Test đặt mặc định 30 phút rồi tạo event mới. |

Nhãn `Saved & synced` cũng vẫn có trên Home/preview của `main`, trong khi quyết định của người dùng là `Saved`. Đây là một phần thay đổi #26 chưa có trên nhánh đang kiểm thử, cần đối chiếu trước khi tạo issue trùng.

## 5. Phạm vi và kết quả theo nhóm tính năng

| Nhóm / FR | Đã có bằng chứng | Chưa thể kết luận hoàn tất |
|---|---|---|
| Onboarding, Profile — FR-01/02 | Smoke test và Chrome onboarding, đổi tên qua test có sẵn | Xác thực tài khoản thật/Firebase; luồng từ chối quyền trên thiết bị thật |
| Home — FR-03 | Mở Home, dữ liệu seed, các tab, widget qua baseline | Ma trận kích thước/cỡ chữ rất lớn, cập nhật qua đổi ngày ở nền |
| Edit Your Screen — FR-04 | Grid/drag/undo có test baseline; photo VIP gate trên Chrome | Nhập ảnh Android, đổi ảnh A→B, crop/rotate, lỗi file, lưu ảnh native; Web đang fail |
| Calendar, Event — FR-05/06 | RRULE cơ bản, xóa occurrence và điều hướng có test | C01/C02 đang fail; toàn bộ ma trận nhiều ngày/all-day/time zone/DST chưa chạy |
| Goal — FR-07 | Hoàn thành goal và ngày cuối kỳ có test baseline | Rollover tuần/tháng trên máy thật và quy tắc đổi kỳ |
| Habit — FR-08 | Rule ngày và occurrence trong repository có test baseline | N01/N03/N05; lịch nhắc nhiều ngày và hành vi qua reboot |
| To-do, Subtask — FR-09/10 | CRUD, subtask delete/undo/reload, priority | T01–T05; reminder thực tế sau khi xóa/Undo |
| Notes, Quick Note — FR-11/20 | CRUD, pin, ASCII limit; handler Append/Replace | Q01/Q02; nhập RemoteInput khi khóa, process chết, quyền bị thu hồi |
| Export/Snapshot — FR-12 | Render/capture PNG từ editor | W02; lưu ảnh Gallery và ảnh hiển thị đúng trên khóa Android; nút Save image của Home cũng dùng Gal nên cần kiểm tra Web riêng |
| Theme/Layout/Template — FR-13/14/16 | Baseline có Dark Mode, Free templates, Studio save/apply/resize | Tính nhất quán draft/font/undo, ảnh cá nhân sau downgrade và mở lại editor |
| VIP — FR-15 | Free gate, mock payment failed/success/cancel, reload và downgrade | Entitlement thật, Firebase security rules và dữ liệu giữa tài khoản |
| Marketplace — FR-17 | Code mock vẫn tồn tại | Theo quyết định dự án: phát triển tương lai, không tính vào nghiệm thu bản hiện tại |
| Reminder/Lock Screen — FR-18/19 | Handler unit tests; native code build được | Native tests ở mục 6 bị chặn; static wallpaper không phải widget Android tương tác |
| Settings/System Calendar — FR-21/22 | Persistence, ngày bắt đầu tuần, language, quyền qua mock, source read-only | N02/T03/W01; lịch hệ thống thật, thu hồi quyền, Exact Alarm trên API 31/32 |
| Firebase | Đã kiểm tra dependency và tìm source trong snapshot này | Chưa có implementation để test ở workspace này; cần audit nhánh Firebase sau khi tích hợp |

## 6. Checklist native bắt buộc trước nghiệm thu

Các mục dưới đây **chưa pass**. Máy ảo API 33 chỉ khởi động/cài được APK; kiểm thử UI bị System UI ANR chặn. Xem ảnh `android-system-ui-blocker.png`.

| Case | Bước kiểm thử | Cần xác nhận |
|---|---|---|
| AND-01 | Free chọn Your photo; sau đó VIP chọn JPG/PNG hợp lệ | Paywall đúng; picker hoạt động sau mở VIP; preview cập nhật |
| AND-02 | Đã có ảnh A → chọn ảnh B → đóng/mở lại app | Picker mở lại, ảnh B tồn tại và không phụ thuộc cache tạm |
| AND-03 | Chọn ảnh rất lớn/ảnh xoay, hủy picker, từ chối quyền nếu có | Không crash, không đổi nền khi hủy, hiển thị lỗi dễ hiểu |
| AND-04 | Thiết kế lịch đủ 7 ngày → Save Image → mở thư viện | PNG đủ sự kiện, đúng kích thước, không lẫn overlay đồng hồ/notification preview |
| AND-05 | Set Wallpaper từ editor và từ màn ảnh đã lưu | Android áp dụng đúng **lock screen**, không vô tình đổi home screen |
| AND-06 | Khóa màn hình và chụp lại | Nội dung lịch không bị crop/che bởi đồng hồ; so sánh nhiều tỉ lệ màn hình |
| AND-07 | Bật Quick Note notification; nhập và Save ở màn hình khóa | Ghi được note mà không phải vào app, cập nhật database và preview; thử Append/Replace |
| AND-08 | Background app, rồi kill process bằng cơ chế không force-stop; Save note/Done/Snooze | Receiver hoạt động và dữ liệu còn sau mở lại. Phân biệt với Force stop trong Settings của Android |
| AND-09 | Bấm Open app từ Quick Note | Mở đúng composer, không chỉ về Home hoặc không phản hồi |
| AND-10 | Tắt notification, thu hồi quyền, quay lại app | Không còn notification không mong muốn, Settings có trạng thái chính xác, app vẫn dùng được |
| AND-11 | Nhắc ở thời điểm T; reboot trước T | Reminder còn và phát đúng; ghi cả thời điểm đặt, reboot và nhận, không chỉ kiểm tra manifest BootReceiver |
| AND-12 | Bấm Schedule khi máy có khóa bảo mật | Android yêu cầu xác thực trước khi vào app; không coi preview “Swipe up” là xác thực hệ điều hành |
| AND-13 | Android 12/12L và 13+ | Exact Alarm và POST_NOTIFICATIONS có kết quả thực tế theo từng API |
| AND-14 | Đổi lịch/event/Quick Note sau khi đặt hình nền | Chốt và kiểm tra cơ chế cập nhật ảnh: thao tác xuất lại, nhắc cập nhật, hay tự cập nhật nếu bổ sung yêu cầu |

**Ảnh PNG đặt làm wallpaper là ảnh tĩnh.** Không có bằng chứng về cơ chế tự render/set lại wallpaper sau mỗi lần đổi lịch hoặc qua tuần mới. Đây là điểm cần đặc tả rõ, không tự suy diễn rằng ảnh phải tương tác như widget.

## 7. Thứ tự xử lý đề xuất

1. Chốt/đưa đúng thay đổi #26 vào nhánh tích hợp; chạy lại audit để tránh sửa trùng. Không merge khi workspace còn các thay đổi stage chưa được phân loại.
2. Hoàn thiện lịch wallpaper đủ 7 ngày và xuất đúng tỉ lệ/kích thước; xác minh crop trên lock screen thật.
3. Tách luồng photo/export theo nền tảng; xử lý lỗi picker/storage/Gal và đổi lại ảnh cá nhân.
4. Sửa reminder theo loại, Rule/occurrence/exception, vòng đời Snooze và tắt Quick Note notification.
5. Sửa task lặp/Upcoming/default reminder/hide completed/focus; sửa Quick Note Unicode và preview.
6. Chạy checklist Android trên máy thật; sau đó kiểm thử Firebase theo phạm vi đã tích hợp và rules thực tế.

## 8. Chạy lại và bằng chứng

```powershell
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter test test/system_audit_probes.dart --reporter expanded --timeout 30s
flutter build web --no-pub --no-wasm-dry-run
```

File chẩn đoán cố ý có đuôi `_probes.dart` để **không** được gộp vào default suite `*_test.dart`. Exit code 1 của lệnh chạy probe thể hiện các yêu cầu chưa đạt. Khi sửa, chạy lại để xác nhận từng case chuyển sang pass; không đổi expectation sang hành vi sai hiện tại chỉ để làm xanh.

Các probe dùng `MemoryDocumentStore`/`NoopNotificationService`; test PNG thay `WallpaperService` bằng capture service. Chúng không đặt wallpaper lên máy người dùng và không gửi notification thật.

Bằng chứng kèm báo cáo trong [qa/2026-11-16](qa/2026-11-16/):

- `diagnostic-probes.txt`: Expected/Actual và stack trace của các probe.
- `web-vip-photo-import-no-change.png`: sau chọn JPG trên Web.
- `web-save-image-no-success.png`: Save Image trên Web không hoàn thành.
- `web-free-photo-vip-gate.png`: Free bị chặn đúng ở tính năng ảnh cá nhân.
- `android-system-ui-blocker.png`: lỗi môi trường máy ảo, không quy thành lỗi app.

Build Android cuối dùng lệnh dưới đây cho riêng phiên audit; các lần thất bại trước là vấn đề toolchain/môi trường, không tính vào 19 vấn đề chức năng đã tái hiện:

```powershell
cd android
.\gradlew.bat assembleDebug '-Dorg.gradle.java.home=D:/AVD/jbr' '-Pkotlin.incremental=false' '-Pkotlin.compiler.execution.strategy=in-process'
```

APK cài bằng `adb install -r`, không xóa dữ liệu. Application ID là `com.supercalendar.app`, còn Activity là `com.example.flutter_application.MainActivity`.
