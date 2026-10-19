import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/strings.dart';

void main() {
  testWidgets(
    'first run shows onboarding, then every tab renders in Vietnamese',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final app = AppState(store: MemoryDocumentStore());
      await app.load();
      app.setLanguage(AppStrings.vietnamese);
      await tester.pumpWidget(SuperCalendarApp(state: app));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Chào mừng đến với SuperCalendar'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Mia');
      // Skip the permission prompt in tests.
      await tester.tap(find.text('Nhắc tôi về sự kiện và công việc'));
      await tester.pump();
      await tester.ensureVisible(find.text('Bắt đầu'));
      await tester.pump();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Mia'), findsWidgets);

      for (final tab in [
        'Lịch',
        'Việc cần làm',
        'VIP',
        'Cài đặt',
        'Trang chủ',
      ]) {
        await tester.tap(find.text(tab).last);
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull, reason: tab);
      }
    },
  );
}
