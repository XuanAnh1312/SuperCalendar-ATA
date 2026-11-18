# Chuẩn bị SuperCalendar để thử trên iPhone

Đã chuẩn bị cấu hình iOS cho bundle ID **`com.supercalendar.app`**, minimum iOS **15.0**, Firebase project **`super-calendar-e4e6e`**. Nhánh dùng để xuất bản thử: **`build/ios-iphone-test`**. Nhánh này chứa bản tích hợp các thay đổi local hiện tại để build, không thay thế PR riêng của từng người.

## Build qua GitHub

Workflow hiện có được cập nhật tại [`.github/workflows/dart.yml`](../.github/workflows/dart.yml).

1. Đưa bản code hiện tại, bao gồm `ios`, các file Firebase và workflow, lên nhánh dùng để test. Không chỉ chép workflow sang bản code cũ.
2. Vào **Actions → workflow `dart.yml` → Run workflow**, chọn nhánh **`build/ios-iphone-test`**. Trên default branch workflow có thể còn mang tên cũ **iOS-ipa-build**; nhánh test dùng tên **iPhone test IPA (unsigned)**.
3. Phiên bản Flutter mặc định là **3.50.0**, khớp SDK đang dùng để kiểm tra local. SDK thay thế phải đáp ứng Dart `>=3.13.4` và hỗ trợ `FlutterImplicitEngineDelegate`/UIScene của dự án.
4. Workflow chạy kiểm tra cấu hình, analyze, test, rồi build iOS release trên máy macOS của GitHub. Swift Package Manager được bật; Podfile cung cấp CocoaPods cho các plugin cần fallback.
5. Khi job thành công, tải artifact **SuperCalendar-iPhone-unsigned**, giải nén lấy **SuperCalendar-unsigned.ipa**.
6. Dùng cách ký/cài IPA bạn đang có. Đây là IPA **chưa ký**; workflow không chứa chứng chỉ hay provisioning profile, không xuất bản App Store/TestFlight và không tự cài lên iPhone.

Nếu công cụ ký thay bundle ID, cấu hình Firebase/Google Login cũng phải đăng ký lại cho bundle ID mới. Bản hiện tại dùng `com.supercalendar.app` nhất quán trong Xcode, Firebase options và GoogleService-Info.plist.

## Phần đã chuẩn bị

| Phần | Cấu hình / hành vi |
| --- | --- |
| Thư viện Flutter | Các package hiện có có triển khai iOS; không thêm package iOS trùng lặp vào pubspec. Native dependencies được giải quyết trên macOS khi build. |
| Database local | `sqflite` trên iOS, giữ repository và dữ liệu local. |
| Firebase / Google | App iOS đã đăng ký; có GoogleService-Info.plist trong Resources, FirebaseOptions iOS, GIDClientID và URL callback tương ứng. Firebase được khởi tạo trên iOS. Không bổ sung đồng bộ cloud hay entitlement VIP trong công việc này. |
| Ảnh | Khai báo quyền chọn ảnh và thêm ảnh vào Photos cho `image_picker` và `gal`. |
| Wallpaper | Trên iPhone, nút ở editor lưu ảnh vào Photos rồi hiển thị hướng dẫn đặt hình nền thủ công. Không gọi API wallpaper Android và không báo đã đặt hình nền khi mới lưu ảnh. |
| Lịch thiết bị | Native EventKit đọc sự kiện qua cùng channel của app; xin full access trên iOS 17+, quyền calendar cũ trên iOS 15/16. App chỉ đọc dữ liệu, không ghi/xóa sự kiện thiết bị. |
| Notification | Darwin initialization và quyền iOS; không tự xin quyền lúc mở app. Có category Task Done/Snooze, Habit Snooze/Skip, Quick Note nhập chữ/Open app, Schedule/Add task. |
| Action nền | Đăng ký plugin callback trong AppDelegate theo UIScene để background action có thể dùng database/plugin. |
| Settings | Channel mở trang cài đặt notification iOS, có fallback trang cài đặt app trên iOS 15. |
| Số lượng reminder | iOS chỉ giữ tối đa 64 local notification đang chờ; scheduler chọn tối đa 62 reminder gần nhất, dành chỗ cho hai thẻ. Cần mở/sync app để bổ sung những lịch còn lại. |

## Khác biệt cần biết khi test

- Quick Note trên iOS là notification có text-input action. Nhấn giữ/mở rộng notification để tìm **Save note**. iOS cho phép người dùng xóa notification; đây không phải thẻ ghim vĩnh viễn như Android.
- Việc hiển thị nội dung và nhập liệu trên màn khóa phụ thuộc cài đặt Show Previews và xác thực của iPhone.
- Muốn đặt hình nền: **Cài đặt → Hình nền → Thêm hình nền mới → Ảnh**, chọn ảnh đã xuất. iOS không cung cấp public API để app tự đặt wallpaper.
- Calendar, ảnh và notification đều phải thử cả trường hợp cấp quyền và từ chối quyền.
- Giữ giới hạn scheduler hiện tại: Habit được lập lịch cho hôm nay và bổ sung khi sync; event tìm lần hợp lệ trong tối đa 366 ngày. Không coi đây là cam kết nhắc liên tục nhiều ngày không mở app.

## Kiểm tra trước / sau khi xuất IPA

Kiểm tra có thể chạy trên Windows:

```text
python tool/check_ios_configuration.py
flutter analyze --no-fatal-infos
flutter test
```

Kết quả local: **119 test pass**, gồm 5 test riêng iOS. `python tool/check_ios_configuration.py` pass. Test riêng `test/ios_preparation_test.dart` dùng mock method channel để kiểm tra hợp đồng iOS, không thay thế kiểm thử native.

Chưa xác nhận build Swift, pod/SPM resolution, ký IPA hay chạy trên iPhone trong môi trường Windows. Sau khi cài, cần kiểm tra:

- Khởi động, tạo/sửa/xóa task/note, đóng/mở lại còn dữ liệu.
- Đăng nhập Google, đăng xuất, khôi phục phiên.
- Chọn ảnh Photos, quay lại editor, lưu ảnh, mở Photos kiểm tra kích thước và đặt wallpaper thủ công.
- Kết nối Calendar, cấp/từ chối quyền, kiểm tra sự kiện all-day và sự kiện lặp.
- Nhắc task/event/habit đúng giờ; Done/Snooze/Skip khi app ở nền; mở app kiểm tra trạng thái.
- Quick Note nhập/lưu qua notification, Append/Replace, mở đúng composer khi app chưa chạy.
- Tắt notification trong Settings iOS rồi quay về app; Schedule trên khóa bảo mật.

Nguồn cấu hình: [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios), [UIScene](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate), [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications), [Google Sign-In iOS](https://pub.dev/packages/google_sign_in_ios), [EventKit](https://developer.apple.com/documentation/eventkit/accessing-calendar-using-eventkit-and-eventkitui).
