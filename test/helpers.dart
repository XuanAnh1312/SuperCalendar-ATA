import 'package:flutter/material.dart';
import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monday, October 5 2026, 9:41: the moment shown in the design.
final testNow = DateTime(2026, 10, 5, 9, 41);
final testToday = DateTime(2026, 10, 5);

/// A loaded [AppState] on an in-memory database. Passing the same [store]
/// again simulates closing and reopening the app.
Future<AppState> loadApp({
  DocumentStore? store,
  NotificationService? notifications,
  SystemCalendarService? systemCalendar,
  DateTime? now,
}) async {
  final app = AppState(
    store: store ?? MemoryDocumentStore(),
    notifications: notifications,
    systemCalendar: systemCalendar,
    clock: () => now ?? testNow,
  );
  await app.load();
  return app;
}

/// Pumps the app on a 390x844 phone, the frame size used in the design.
Future<AppState> pumpApp(WidgetTester tester, {AppState? app}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = app ?? await loadApp();
  await tester.pumpWidget(SuperCalendarApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

/// Taps the bottom navigation item labelled [label].
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
