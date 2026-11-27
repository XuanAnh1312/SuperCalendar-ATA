import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/reminder_plan.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/appearance_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_studio_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/vip_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class _CalendarRequest {
  final started = Completer<void>();
  final response = Completer<List<CalendarEvent>>();
}

class _DelayedCalendar extends FakeSystemCalendarService {
  _DelayedCalendar() : super(granted: true);

  final _pending = Queue<_CalendarRequest>();

  _CalendarRequest queueResponse() {
    final request = _CalendarRequest();
    _pending.add(request);
    return request;
  }

  @override
  Future<List<CalendarEvent>> events(DateTime from, DateTime to) {
    final request = _pending.removeFirst();
    request.started.complete();
    return request.response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 27, 9);

  CalendarEvent deviceEvent(String id, DateTime start) => CalendarEvent(
    id: id,
    title: id,
    source: CalendarEvent.sourceSystem,
    startTime: start,
    endTime: start.add(const Duration(hours: 1)),
  );

  test('disconnected calendar ignores the in-flight system response', () async {
    final calendar = _DelayedCalendar();
    final app = AppState(
      store: MemoryDocumentStore(),
      clock: () => now,
      systemCalendar: calendar,
    );
    addTearDown(app.dispose);
    await app.load(seedDemoData: false);
    app.account.updateSettings((settings) => settings.useSystemCalendar = true);
    final pending = calendar.queueResponse();
    final refresh = app.refreshSystemCalendar();
    await pending.started.future;

    app.disconnectSystemCalendar();
    pending.response.complete([deviceEvent('sample-device-event', now)]);
    await refresh;
    expect(app.settings.useSystemCalendar, isFalse);
    expect(app.lockScreenContent.events.map((event) => event.title), isEmpty);
  });

  test(
    'a slow calendar refresh keeps the results of the newer month',
    () async {
      final calendar = _DelayedCalendar();
      final app = AppState(
        store: MemoryDocumentStore(),
        clock: () => now,
        systemCalendar: calendar,
      );
      addTearDown(app.dispose);
      await app.load(seedDemoData: false);
      app.account.updateSettings(
        (settings) => settings.useSystemCalendar = true,
      );
      final oldRequest = calendar.queueResponse();
      final oldRefresh = app.refreshSystemCalendar();
      await oldRequest.started.future;
      final spring = DateTime(2027, 3, 8, 9);
      app.selectDay(spring);
      final newRequest = calendar.queueResponse();
      final newRefresh = app.refreshSystemCalendar();
      await newRequest.started.future;
      newRequest.response.complete([deviceEvent('new-month', spring)]);
      await newRefresh;
      oldRequest.response.complete([deviceEvent('old-month', now)]);
      await oldRefresh;

      expect(app.visibleCalendarEventsOn(spring).map((event) => event.id), [
        'new-month',
      ]);
    },
  );

  test('a habit starting in 20 days still plans its first reminder', () {
    final start = DateTime(now.year, now.month, now.day + 20);
    final habit = Habit(
      id: 'future-habit',
      title: 'Study',
      shortTitle: 'Study',
      startDate: start,
      createdAt: now,
      time: 10 * 60,
      repeatRule: 'FREQ=DAILY',
      reminderMinutes: 0,
    );
    final plan = buildReminderPlan(
      tasks: [],
      events: [],
      habits: [habit],
      now: now,
      context: ReminderContext(
        settings: AppSettings(notificationsEnabled: true),
      ),
    );
    expect(
      plan.map((entry) => entry.at),
      contains(start.add(const Duration(hours: 10))),
    );
  });

  Future<AppState> openApp(WidgetTester tester, {int tab = AppTab.home}) async {
    tester.view.physicalSize = const Size(1170, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = AppState(store: MemoryDocumentStore(), clock: () => now);
    addTearDown(app.dispose);
    await app.load();
    app.finishOnboarding('Audit');
    app.setTab(tab);
    await tester.pumpWidget(SuperCalendarApp(state: app));
    await tester.pumpAndSettle();
    return app;
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  final editor = find.byType(EditScreen);
  final canvas = find.descendant(of: editor, matching: find.byType(WidgetGrid));
  bool draftShowsCalendar(WidgetTester tester) =>
      tester.widget<WidgetGrid>(canvas).layout.shows(WidgetType.week);

  Future<void> hideCalendarLayer(WidgetTester tester) async {
    await tap(tester, find.text('Edit Your Screen'));
    expect(draftShowsCalendar(tester), isTrue);
    await tap(tester, find.text('Layers'));
    final layerSwitch = find.descendant(
      of: find
          .ancestor(
            of: find
                .descendant(of: editor, matching: find.text('Calendar'))
                .last,
            matching: find.byType(Row),
          )
          .first,
      matching: find.byType(AppSwitch),
    );
    await tap(tester, layerSwitch);
    expect(draftShowsCalendar(tester), isFalse);
  }

  testWidgets('switching tabs keeps the same editor draft', (tester) async {
    final app = await openApp(tester);
    await hideCalendarLayer(tester);
    final editorState = tester.state(editor);
    await tap(tester, find.text('Settings'));
    await tap(tester, find.text('Home'));
    expect(editor, findsOneWidget);
    expect(tester.state(editor), same(editorState));
    expect(draftShowsCalendar(tester), isFalse);
    expect(app.layouts.lock.shows(WidgetType.week), isTrue);
  });

  testWidgets('system Back saves the draft before closing the editor', (
    tester,
  ) async {
    final app = await openApp(tester);
    await hideCalendarLayer(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(editor, findsNothing);
    expect(app.layouts.lock.shows(WidgetType.week), isFalse);
  });

  testWidgets(
    'Theme Builder can go back to Appearance or continue after purchase',
    (tester) async {
      final app = await openApp(tester, tab: AppTab.settings);
      await tap(tester, find.text('Appearance'));
      await tap(tester, find.text('More control with VIP · Theme Builder'));
      final vip = find.byType(VipScreen);
      expect(vip, findsOneWidget);
      final back = find.descendant(of: vip, matching: find.byType(BackButton));
      expect(back, findsOneWidget);
      await tap(tester, back);
      expect(find.byType(AppearanceScreen), findsOneWidget);
      expect(app.isVip, isFalse);

      await tap(tester, find.text('More control with VIP · Theme Builder'));
      await tap(tester, find.text('Subscribe'));
      await tap(tester, find.text('Simulate successful payment'));
      expect(app.isVip, isTrue);
      expect(app.tab, AppTab.settings);
      expect(find.byType(TemplateStudioScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AppearanceScreen), findsOneWidget);
    },
  );
}
