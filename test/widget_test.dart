import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/main.dart';

void main() {
  Future<void> usePhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const SuperCalendarApp());
  }

  testWidgets('notification, account, consent and calendar permission flow', (
    tester,
  ) async {
    await usePhoneViewport(tester);

    expect(
      find.text('Cho phép Super Calendar\ngửi thông báo cho bạn?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cho phép').first);
    await tester.pumpAndSettle();

    expect(find.text('Chọn một tài khoản'), findsOneWidget);
    expect(find.text('Mia Chen'), findsOneWidget);
    expect(find.text('mia.chen@gmail.com'), findsOneWidget);
    expect(find.textContaining('chocolatematcha'), findsNothing);
    await tester.tap(find.text('mia.chen@gmail.com').first);
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập vào\nSuper Calendar'), findsOneWidget);
    await tester.ensureVisible(find.text('Tiếp tục').last);
    await tester.tap(find.text('Tiếp tục').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Super Calendar muốn truy cập Tài khoản Google của bạn'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Xem, chỉnh sửa').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cho phép'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn đã sẵn sàng!'), findsOneWidget);
    expect(find.text('Đã cho phép truy cập'), findsOneWidget);
    await tester.tap(find.text('Vào Super Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Mia Chen · VIP'), findsOneWidget);
  });

  testWidgets('cancel returns to account selection without demo controls', (
    tester,
  ) async {
    await usePhoneViewport(tester);
    await tester.tap(find.text('Cho phép').first);
    await tester.pumpAndSettle();
    expect(find.text('Chọn một tài khoản'), findsOneWidget);
    expect(find.text('1 / 5'), findsNothing);
    expect(find.text('Quay lại'), findsNothing);

    await tester.tap(find.text('mia.chen@gmail.com').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hủy'));
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn một tài khoản'), findsOneWidget);
  });
}
