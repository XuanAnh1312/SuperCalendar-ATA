import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/presentation/calendar_visibility.dart';
import 'package:flutter_application/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_detail_screen.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_form_screen.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/calendar_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Wednesday 14 Oct 2026, 10:00.
  final now = DateTime(2026, 10, 14, 10);

  Future<AppState> loadedApp({
    DocumentStore? store,
    SystemCalendarService? systemCalendar,
    NotificationService? notifications,
  }) async {
    final app = AppState(
      store: store ?? MemoryDocumentStore(),
      clock: () => now,
      systemCalendar: systemCalendar ?? FakeSystemCalendarService(),
      notifications: notifications ?? NoopNotificationService(),
    );
    await app.load();
    return app;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    AppState app,
    Widget screen,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pump();
  }

  CalendarEvent localEvent({
    String id = 'local',
    DateTime? start,
    DateTime? end,
    int? reminder,
    String? repeat,
  }) {
    final startTime = start ?? DateTime(2026, 10, 14, 15);
    return CalendarEvent(
      id: id,
      title: 'Standup',
      startTime: startTime,
      endTime: end ?? startTime.add(const Duration(hours: 1)),
      reminderMinutes: reminder,
      repeatRule: repeat,
    );
  }

  test('AC-11: October 2026 with Monday week start places 1 on Thu and 5 on Mon',
      () async {
    final app = await loadedApp();
    expect(app.weekStart, WeekStartSetting.monday);
    final first = DateTime(2026, 10, 1);
    final fifth = DateTime(2026, 10, 5);
    final gridStart = app.weekStartOf(first);
    expect(gridStart.weekday, DateTime.monday);
    expect(first.difference(gridStart).inDays % 7, DateTime.thursday - 1);
    expect(fifth.weekday, DateTime.monday);
    expect(fifth.difference(gridStart).inDays % 7, 0);
  });

  testWidgets('AC-12: Week View for 5–11 Oct 2026 shows Week 41', (
    tester,
  ) async {
    final app = await loadedApp();
    app.selectDay(DateTime(2026, 10, 5));
    app.setWeekView(true);
    await pumpScreen(tester, app, const CalendarScreen());
    expect(find.textContaining('Week 41'), findsOneWidget);
  });

  testWidgets('AC-13: second tap on the 14th opens New event dated 14/10', (
    tester,
  ) async {
    final app = await loadedApp();
    app.selectDay(DateTime(2026, 10, 14));
    await pumpScreen(tester, app, const CalendarScreen());
    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();
    expect(find.text('New event'), findsOneWidget);
    expect(find.textContaining(dayMonth(DateTime(2026, 10, 14))), findsWidgets);
  });

  testWidgets('AC-14: an end before the start is not saved', (tester) async {
    final app = await loadedApp();
    final event = localEvent(
      start: DateTime(2026, 10, 14, 15),
      end: DateTime(2026, 10, 14, 14),
    );
    app.events.add(event);
    await pumpScreen(tester, app, EventFormScreen(event: event));
    expect(find.text('End time must be after the start time'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(app.events.byId('local')!.endTime, DateTime(2026, 10, 14, 14));
  });

  test('AC-15: deleting one repeat of a Monday series keeps the others',
      () async {
    final store = MemoryDocumentStore();
    final app = await loadedApp(store: store);
    app.events.add(
      localEvent(
        id: 'standup',
        start: DateTime(2026, 10, 5, 9),
        end: DateTime(2026, 10, 5, 9, 30),
        repeat: 'FREQ=WEEKLY',
      ),
    );
    app.events.deleteScope(
      app.events.byId('standup')!,
      DeleteScope.one,
      occurrenceDate: DateTime(2026, 10, 12),
    );
    await app.flush();
    final reopened = await loadedApp(store: store);
    expect(reopened.events.on(DateTime(2026, 10, 12)), isEmpty);
    expect(reopened.events.on(DateTime(2026, 10, 19)), hasLength(1));
    expect(reopened.events.on(DateTime(2026, 10, 5)), hasLength(1));
  });

  test('AC-16: deleting an event with a reminder drops its notification',
      () async {
    final notifications = NoopNotificationService();
    final app = await loadedApp(notifications: notifications);
    app.account.updateSettings((s) => s.notificationsEnabled = true);
    final event = localEvent(
      start: DateTime(2026, 10, 14, 16),
      reminder: 15,
    );
    app.events.add(event);
    await app.syncNotifications();
    expect(notifications.scheduled, contains('local'));
    app.events.delete(event);
    await app.syncNotifications();
    expect(notifications.scheduled, isNot(contains('local')));
  });

  testWidgets('1.1 Month View has a Today control', (tester) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const CalendarScreen());
    expect(find.text('Today'), findsWidgets);
    expect(find.textContaining('Today is'), findsOneWidget);
  });

  testWidgets('1.3 New event has no header Save', (tester) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const EventFormScreen());
    expect(find.text('Create event'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('1.4 new event end uses defaultEventDurationMinutes', (
    tester,
  ) async {
    final app = await loadedApp();
    app.account.updateSettings((s) => s.defaultEventDurationMinutes = 30);
    await pumpScreen(tester, app, const EventFormScreen());
    expect(find.textContaining('14:00–14:30'), findsOneWidget);
  });

  testWidgets('Day View empty state follows Figma copy', (tester) async {
    final app = await loadedApp();
    app.selectDay(DateTime(2026, 10, 6));
    await pumpScreen(tester, app, const CalendarScreen());
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('A little open space'), findsOneWidget);
    expect(find.text('Create event'), findsOneWidget);
  });

  test('FR-22 visibleCalendarIds empty shows every device calendar', () {
    final settings = AppSettings();
    expect(isDeviceCalendarVisible(settings, '3'), isTrue);
    settings.visibleCalendarIds = ['3'];
    expect(isDeviceCalendarVisible(settings, '3'), isTrue);
    expect(isDeviceCalendarVisible(settings, '7'), isFalse);
    expect(
      visibleIdsAfterToggle(
        current: const [],
        allIds: const ['3', '7'],
        id: '7',
        visible: false,
      ),
      ['3'],
    );
  });

  testWidgets('AC-42: a granted system event is read-only with a source icon', (
    tester,
  ) async {
    final system = CalendarEvent(
      id: 'system_1',
      calendarId: '3',
      title: 'Dentist',
      startTime: DateTime(2026, 10, 14, 11),
      endTime: DateTime(2026, 10, 14, 12),
      source: CalendarEvent.sourceSystem,
    );
    final fake = FakeSystemCalendarService(
      granted: true,
      events: [system],
      calendars: const [
        DeviceCalendar(id: '3', name: 'Personal', account: 'mia@gmail.com'),
      ],
    );
    final app = await loadedApp(systemCalendar: fake);
    app.account.updateSettings((s) => s.useSystemCalendar = true);
    await app.refreshSystemCalendar();
    expect(app.events.systemEvents, isNotEmpty);
    await pumpScreen(tester, app, EventDetailScreen(event: system));
    expect(find.text('Phone calendar · read only'), findsOneWidget);
    expect(find.text('Edit event'), findsNothing);
  });

  test('AC-43: refusing calendar permission still keeps local events', () async {
    final fake = FakeSystemCalendarService(grantOnRequest: false);
    final app = await loadedApp(systemCalendar: fake);
    app.events.add(localEvent());
    final granted = await app.connectSystemCalendar();
    expect(granted, isFalse);
    expect(app.settings.useSystemCalendar, isFalse);
    expect(
      app.events.on(DateTime(2026, 10, 14)).any((e) => e.title == 'Standup'),
      isTrue,
    );
  });

  testWidgets('1.6 Calendar settings lists device calendars once connected', (
    tester,
  ) async {
    final fake = FakeSystemCalendarService(
      granted: true,
      calendars: const [
        DeviceCalendar(id: '3', name: 'Personal', account: 'mia@gmail.com'),
        DeviceCalendar(id: '7', name: 'Work', account: 'mia@company.com'),
      ],
    );
    final app = await loadedApp(systemCalendar: fake);
    app.account.updateSettings((s) => s.useSystemCalendar = true);
    await pumpScreen(tester, app, const CalendarSettingsScreen());
    await tester.pumpAndSettle();
    expect(find.text('Phone calendars'), findsOneWidget);
    expect(find.text('Personal'), findsWidgets);
    expect(find.text('Work'), findsOneWidget);
  });
}
