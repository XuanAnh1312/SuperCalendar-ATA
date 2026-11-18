# Device frame trong Edit Your Screen

- Dependencies: `device_info_plus: ^11.0.0`, `device_frame: ^1.2.0`; lock hiện chọn lần lượt 11.5.0 và 1.4.0.
- `DeviceFrameService` là singleton, khởi tạo một lần ở startup; các lần retry startup dùng chung Future. Lỗi/timeout đọc hardware dùng fallback, không chặn app.
- iOS đọc `utsname.machine`; Android đọc `model` và `manufacturer`. Model có frame được map trực tiếp. Model thiếu dùng frame cùng dòng đã biết (ví dụ iPhone 14 Pro → 15 Pro, Galaxy S24 → S25, Pixel khác → Pixel 9). Galaxy S21 không có trong catalog hiện tại nên không dùng tên frame giả.
- Thiết bị không nhận diện được dùng `DeviceInfo.genericPhone` của package theo platform, với tỷ lệ lấy từ display thật. Generic được cache theo platform và kích thước display. Web/desktop ẩn frame.
- `DevicePreviewFrame` dùng painter/path của thư viện, không tự vẽ. Frame được căn theo tỷ lệ display; canvas giữ nguyên kích thước layout, MediaQuery và theme thực của editor. Metadata `screenSize` không khớp path ở một số catalog entry được hiệu chỉnh trong bản copy dùng cho preview để tránh letterbox.
- Frame nằm ngoài RepaintBoundary của `_exportKey`; `_LockOverlay` vẫn ở trong preview và ngoài ảnh xuất như trước. `_export()`, `_saveImage()`, `_setWallpaper()` và khai báo `_exportKey` không đổi.

Kiểm tra tự động trong `test/device_frame_test.dart`: model exact/same-series, generic theo tỷ lệ display, cache/concurrent initialization, lỗi plugin, web, PNG byte-identical khi có/không frame, resize/drag/Undo trên frame iPhone và export đúng resolution trong cửa sổ app nhỏ hơn display.

Kết quả: 146 test pass, gồm 13 test mới của device frame. Analyze không có error/warning; còn thông báo info về API Material cũ của Flutter. Build web release thành công. Đã đối chiếu nguyên văn ba hàm export với bản trước khi sửa: không thay đổi.

Chưa nghiệm thu trên iPhone/Samsung/Pixel thật trong tác vụ này. Cần khởi động lại app hoàn toàn sau khi thêm native plugin, rồi kiểm tra frame, chọn/resize/kéo widget và Save Image/Set Wallpaper trên thiết bị.
