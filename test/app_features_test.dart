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
}
