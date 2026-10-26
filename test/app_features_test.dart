import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/goal.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/layout_gallery_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';
import 'package:flutter_application/features/settings_screen/domain/user.dart';
import 'package:flutter_application/features/vip/domain/purchase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Wednesday 14 Oct 2026, 10:00.
  final now = DateTime(2026, 10, 14, 10);

  Future<AppState> loadedApp([DocumentStore? store]) async {
    final app = AppState(
      store: store ?? MemoryDocumentStore(),
      clock: () => now,
    );
    await app.load();
    return app;
  }

  CalendarEvent mondayStandup() => CalendarEvent(
    id: 'standup',
    title: 'Standup',
    startTime: DateTime(2026, 10, 5, 9), // a Monday
    endTime: DateTime(2026, 10, 5, 9, 30),
    repeatRule: 'FREQ=WEEKLY',
  );

  test('RRULE matching', () {
    final start = DateTime(2026, 10, 5);
    expect(rruleOccursOn('FREQ=WEEKLY', start, DateTime(2026, 10, 12)), isTrue);
    expect(
      rruleOccursOn('FREQ=WEEKLY', start, DateTime(2026, 10, 13)),
      isFalse,
    );
    expect(rruleOccursOn('FREQ=DAILY', start, DateTime(2026, 10, 4)), isFalse);
    const weekdays = 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
    expect(rruleOccursOn(weekdays, start, DateTime(2026, 10, 10)), isFalse);
    expect(rruleOccursOn(weekdays, start, DateTime(2026, 10, 9)), isTrue);
    const until = 'FREQ=DAILY;UNTIL=20261007';
    expect(rruleOccursOn(until, start, DateTime(2026, 10, 7)), isTrue);
    expect(rruleOccursOn(until, start, DateTime(2026, 10, 8)), isFalse);
  });

  test(
    'AC-15: deleting one repeat keeps the others, and survives restart',
    () async {
      final store = MemoryDocumentStore();
      final app = await loadedApp(store);
      app.events.add(mondayStandup());
      final repeat = app.events.on(DateTime(2026, 10, 12)).single;
      expect(repeat.startTime, DateTime(2026, 10, 12, 9));

      app.events.deleteScope(
        app.events.byId('standup')!,
        DeleteScope.one,
        occurrenceDate: repeat.date,
      );
      await app.flush();

      final reopened = await loadedApp(store);
      expect(reopened.events.on(DateTime(2026, 10, 12)), isEmpty);
      expect(reopened.events.on(DateTime(2026, 10, 19)), hasLength(1));
      expect(reopened.events.on(DateTime(2026, 10, 5)), hasLength(1));
    },
  );

  test('BR-10: delete from this repeat on ends the series', () async {
    final app = await loadedApp();
    app.events.add(mondayStandup());
    app.events.deleteScope(
      app.events.byId('standup')!,
      DeleteScope.fromThis,
      occurrenceDate: DateTime(2026, 10, 19),
    );
    expect(app.events.on(DateTime(2026, 10, 12)), hasLength(1));
    expect(app.events.on(DateTime(2026, 10, 19)), isEmpty);
    expect(app.events.byId('standup')!.repeatLabel, 'Every week');
  });

  test('recurring event reminders target the next repeat', () {
    final event = mondayStandup()..reminderMinutes = 15;
    expect(eventReminderTime(event, now), DateTime(2026, 10, 19, 8, 45));
  });

  test(
    'habit ticks and skips read from the occurrence table (AC-19)',
    () async {
      final app = await loadedApp();
      final habit = Habit(
        id: 'read',
        title: 'Read',
        shortTitle: 'Read',
        startDate: DateTime(2026, 10, 1),
        repeatRule: 'FREQ=DAILY',
        createdAt: now,
      );
      app.habits.add(habit);
      final today = app.today;
      app.habits.toggle(habit, today);
      expect(app.habits.isDone(habit, today), isTrue);
      app.habits.skip(habit, today);
      expect(app.habits.isSkipped(habit, today), isTrue);
      expect(
        app.habits.isSkipped(habit, today.add(const Duration(days: 1))),
        isFalse,
      );
      app.habits.removeOccurrence(habit, today);
      expect(app.habits.occurrences(today), isNot(contains(habit)));
    },
  );

  test('AC-20: a weekday rule hides the habit on weekends', () async {
    final app = await loadedApp();
    final habit = Habit(
      id: 'gym',
      title: 'Gym',
      shortTitle: 'Gym',
      startDate: DateTime(2026, 10, 1),
      repeatRule: 'FREQ=DAILY',
      createdAt: now,
    );
    app.habits.add(habit);
    final saturday = DateTime(2026, 10, 17);
    expect(app.habits.occurrences(saturday), contains(habit));
    app.habits.updateRepeatRule(
      habit,
      'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      app.today,
    );
    expect(app.habits.occurrences(saturday), isNot(contains(habit)));
  });

  test('AC-17: tapping the last workout completes the goal', () async {
    final app = await loadedApp();
    final goal = app.goals.add(
      type: GoalType.monthly,
      title: '12 workouts',
      target: 12,
      periodStart: DateTime(2026, 10, 1),
      periodEnd: DateTime(2026, 10, 31),
    );
    for (var i = 0; i < 11; i++) {
      app.goals.increment(goal);
    }
    expect(goal.status, GoalStatus.active);
    app.goals.increment(goal);
    expect(goal.status, GoalStatus.completed);
    // AC-18 / BR-03: monthly goals never show as weekly ones.
    expect(
      app.goals.activeOn(app.today, GoalType.weekly),
      isNot(contains(goal)),
    );
  });

  test('a goal is still active on the last day of its period', () {
    final goal = Goal(
      id: 'g',
      type: GoalType.weekly,
      title: 'Run',
      target: 3,
      periodStart: DateTime(2026, 10, 12),
      periodEnd: DateTime(2026, 10, 18),
      createdAt: now,
    )..recalculate(DateTime(2026, 10, 18, 20));
    expect(goal.status, GoalStatus.active);
  });

  test('AC-40: week start follows the setting', () async {
    final app = await loadedApp();
    expect(app.weekStartOf(DateTime(2026, 10, 14)), DateTime(2026, 10, 12));
    app.setWeekStart(WeekStartSetting.sunday);
    expect(app.weekStartOf(DateTime(2026, 10, 14)), DateTime(2026, 10, 11));
    expect(app.weekStartOf(DateTime(2026, 10, 11)), DateTime(2026, 10, 11));
  });

  test('AC-38: hide details reaches the lock screen content', () async {
    final app = await loadedApp();
    expect(app.lockScreenContent.hideDetails, isFalse);
    app.setLockScreenHideDetails(true);
    expect(app.lockScreenContent.hideDetails, isTrue);
  });

  test('AC-34: downgrading locks own templates and resets VIP looks', () async {
    final app = await loadedApp();
    app.completeVipPayment(PaymentResult.success);
    final mine = app.createTemplate(
      name: 'Mine',
      description: '',
      price: 0,
      preview: '*',
      theme: app.selectedTheme,
    )!;
    app.applyTemplate(mine);
    app.layouts.setVisible(ScreenLayout.home, WidgetType.goals, false);

    app.cancelVip();
    expect(app.ownsTemplate(mine), isFalse);
    expect(app.user.selectedThemeId, 'pastel_minimal');
    expect(app.layouts.home.preset, ScreenLayout.presetDefault);
  });

  test('FR-20.03: notification text is appended to the Quick Note', () async {
    final store = MemoryDocumentStore();
    final app = await loadedApp(store);
    app.notes.setQuick('Buy milk');
    await app.flush();
    await handleNotificationAction(
      store: store,
      notifications: NoopNotificationService(),
      actionId: NotificationActions.saveNote,
      payload: null,
      input: 'Call mom',
      clock: () => now,
    );
    final reopened = await loadedApp(store);
    expect(reopened.notes.quickText, 'Buy milk\nCall mom');
  });

  test('AC-04: onboarding saves the name', () async {
    final app = await loadedApp();
    expect(app.settings.onboarded, isFalse);
    app.finishOnboarding('  Mia  ');
    expect(app.user.firstName, 'Mia');
    expect(app.settings.onboarded, isTrue);
  });

  test('AC-41: language switch translates and falls back to English', () async {
    final app = await loadedApp();
    app.setLanguage(AppStrings.vietnamese);
    expect(tr('Settings'), 'Cài đặt');
    expect(trf('{n} remaining', {'n': 3}), 'còn 3 việc');
    expect(
      tr('Some text with no translation'),
      'Some text with no translation',
    );
    app.setLanguage('English');
    expect(tr('Settings'), 'Settings');
  });

  test('AC-08: a placed widget keeps its spot after reopening', () async {
    final store = MemoryDocumentStore();
    final app = await loadedApp(store);
    final draft = app.layouts.home.copy();
    expect(draft.place(WidgetType.weather, 7, 8), PlaceResult.exact);
    app.layouts.save(draft);
    await app.flush();

    final weather = (await loadedApp(store)).layouts.home.item(
      WidgetType.weather,
    );
    expect(weather.visible, isTrue);
    expect((weather.x, weather.y), (7, 8));
  });

  test('AC-09: the clock or another widget snaps to the nearest free spot', () {
    final layout = ScreenLayout(
      id: ScreenLayout.home,
      items: ScreenLayout.presetItems(
        ScreenLayout.home,
        ScreenLayout.presetDefault,
      ),
    );
    // Above the grid is the clock / greeting.
    expect(layout.place(WidgetType.weather, 0, -2), PlaceResult.snapped);
    final weather = layout.item(WidgetType.weather);
    expect((weather.x, weather.y), (7, 7));
    // On top of the to-do widget.
    layout.hide(WidgetType.goals);
    expect(layout.place(WidgetType.goals, 0, 0), PlaceResult.snapped);
    final goals = layout.item(WidgetType.goals);
    expect(goals.overlaps(0, 0, 7, 5), isFalse);
  });

  test('FR-04: the lock screen starts like the design and stays tidy', () {
    final lock = ScreenLayout(
      id: ScreenLayout.lock,
      items: ScreenLayout.presetItems(
        ScreenLayout.lock,
        ScreenLayout.presetDefault,
      ),
    );
    (int, int, int, int) area(String type) {
      final item = lock.item(type);
      return (item.x, item.y, item.w, item.h);
    }

    // Calendar, weather, mini note and habits, as in Personalize 23.
    expect(area(WidgetType.week), (0, 0, 7, 4));
    expect(area(WidgetType.weather), (7, 0, 5, 4));
    expect(area(WidgetType.quickNote), (0, 4, 7, 4));
    expect(area(WidgetType.habits), (7, 4, 5, 4));
    // Full: no room for another big widget, and no overlapping resize.
    expect(lock.place(WidgetType.todo, 0, 0), PlaceResult.full);
    expect(lock.shows(WidgetType.todo), isFalse);
    expect(lock.resize(WidgetType.quickNote, 0, 4, 12, 4), isFalse);
    expect(lock.item(WidgetType.quickNote).w, 7);
  });

  test('FR-04: layouts saved before the grid keep every widget', () {
    final home = ScreenLayout.fromJson({
      'id': ScreenLayout.home,
      'preset': ScreenLayout.presetCustom,
      'items': [
        for (final type in [
          WidgetType.todo,
          WidgetType.habits,
          WidgetType.week,
          WidgetType.goals,
          WidgetType.quickNote,
          WidgetType.snapshot,
        ])
          {'type': type, 'visible': true, 'wide': false},
      ],
    });
    expect(home.visibleItems, hasLength(6));
    final todo = home.item(WidgetType.todo);
    final week = home.item(WidgetType.week);
    expect((todo.x, todo.y, todo.w, todo.h), (0, 0, 7, 5));
    expect((week.x, week.y, week.w, week.h), (0, 5, 7, 4));

    final lock = ScreenLayout.fromJson({
      'id': ScreenLayout.lock,
      'preset': ScreenLayout.presetCustom,
      'items': [
        for (final type in [
          WidgetType.schedule,
          WidgetType.todo,
          WidgetType.quickNote,
        ])
          {'type': type, 'visible': true, 'wide': true},
      ],
    });
    expect(lock.visibleItems, hasLength(3));
  });

  test('FR-04: old layout names become the names of the design', () {
    final layout = ScreenLayout.fromJson({
      'id': ScreenLayout.home,
      'preset': 'Balanced',
      'grid': ScreenLayout.columns,
      'items': <Map<String, dynamic>>[],
    });
    expect(layout.preset, ScreenLayout.presetDefault);
    expect(ScreenLayout.presetDefault, 'Calm Week');
  });

  test('FR-04: a widget keeps its style after reopening', () async {
    final store = MemoryDocumentStore();
    final app = await loadedApp(store);
    final draft = app.layouts.lock.copy()
      ..setStyle(
        WidgetType.weather,
        color: 2,
        textSize: 16,
        surface: CardSurface.outline,
      );
    app.layouts.save(draft);
    await app.flush();

    final weather = (await loadedApp(store)).layouts.lock.item(
      WidgetType.weather,
    );
    expect(
      (weather.color, weather.textSize, weather.surface),
      (2, 16, CardSurface.outline),
    );
  });

  test('AC-34: a VIP layout goes back to the free default', () async {
    final app = await loadedApp();
    app.completeVipPayment(PaymentResult.success);
    app.layouts.applyPreset(ScreenLayout.lock, ScreenLayout.presetDailyReset);
    app.cancelVip();
    expect(app.layouts.lock.preset, ScreenLayout.presetDefault);
  });

  testWidgets('FR-04: Find your calm and Style your widget render', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await loadedApp();
    Future<void> show(Widget screen) async {
      await tester.pumpWidget(
        AppScope(state: app, child: MaterialApp(home: screen)),
      );
      await tester.pumpAndSettle();
    }

    await show(const LayoutGalleryScreen(current: ScreenLayout.presetDefault));
    expect(find.text('Calm Week'), findsOneWidget);
    expect(find.text('Free · Current layout'), findsOneWidget);
    expect(find.text('Daily Reset'), findsOneWidget);

    await show(
      WidgetStyleScreen(
        type: WidgetType.week,
        lock: true,
        item: app.layouts.lock.item(WidgetType.week),
        layoutName: ScreenLayout.presetDefault,
      ),
    );
    expect(find.text('Text size'), findsOneWidget);
    expect(find.text('Two columns'), findsOneWidget);
    expect(find.text('Soft cards'), findsOneWidget);
  });

  testWidgets(
    'AC-08/AC-09: drag out with Undo, drag in, saved on leaving',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 3300);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final app = await loadedApp();
      // Free user: arranging must not ask for VIP.
      expect(app.isVip, isFalse);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: MaterialApp(navigatorKey: navigator, home: const SizedBox()),
        ),
      );
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const EditScreen()),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> dragTo(Finder from, Offset to) async {
        final gesture = await tester.startGesture(tester.getCenter(from));
        await tester.pump(const Duration(seconds: 1));
        await gesture.moveTo(to);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      // The lock screen starts with the weather widget of the design.
      expect(find.text('Mostly sunny'), findsOneWidget);

      // Canvas → outside the frame: removed, with Undo (BR-13).
      await dragTo(find.text('Mostly sunny'), const Offset(4, 4));
      expect(find.text('Mostly sunny'), findsNothing);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Mostly sunny'), findsOneWidget);

      // Removed again, then dragged from the library onto the clock: not a
      // valid spot, so it snaps (AC-09).
      await dragTo(find.text('Mostly sunny'), const Offset(4, 4));
      await dragTo(find.text('Weather'), tester.getCenter(find.text('10:00')));
      expect(find.text('Moved to the nearest free spot'), findsOneWidget);
      expect(find.text('Mostly sunny'), findsOneWidget);

      // Removed once more: only the draft changes until the user leaves.
      await dragTo(find.text('Mostly sunny'), const Offset(4, 4));
      expect(app.layouts.lock.shows(WidgetType.weather), isTrue);
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();
      expect(app.layouts.lock.shows(WidgetType.weather), isFalse);
    },
  );
}
