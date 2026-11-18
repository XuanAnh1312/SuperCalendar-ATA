// Diagnostic acceptance probes for the system audit, not the default suite.
// Run explicitly: flutter test test/system_audit_probes.dart --reporter expanded
// Failures reproduce open defects; expectations describe the required behavior.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/wallpaper_service.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/data/habit_repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/lock_screen/presentation/widgets/lock_widgets.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/todo/presentation/screens/todo_screen.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/features/vip/domain/purchase.dart';

class _CaptureWallpaper extends FakeWallpaperService {
  Uint8List? png;
  @override
  Future<bool> setWallpaper(Uint8List png, {required bool lockScreen}) async {
    this.png = png;
    return super.setWallpaper(png, lockScreen: lockScreen);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 9, 10); // Friday
  late AppState app;
  late MemoryDocumentStore store;
  late NoopNotificationService notifications;

  setUp(() async {
    store = MemoryDocumentStore();
    notifications = NoopNotificationService();
    app = AppState(
      store: store,
      notifications: notifications,
      clock: () => now,
    );
    await app.load();
  });
  // Keep teardown synchronous: failed widget expectations must not wait on
  // repository futures trapped in the widget test's fake async zone.
  tearDown(() {
    app.dispose();
  });

  Widget host(Widget page) => AppScope(
    state: app,
    child: MaterialApp(home: page),
  );

  test('AUD-P01 task create edit complete survives reload', () async {
    final task = app.tasks.add('Audit CRUD', dueDate: now)!;
    task.title = 'Audit edited';
    app.tasks.save(task);
    app.tasks.setCompleted(task, true);
    await app.flush();
    await app.reloadFromDisk();
    expect(app.tasks.byId(task.id)!.title, 'Audit edited');
    expect(app.tasks.byId(task.id)!.completed, isTrue);
  });

  test(
    'AUD-P02 deleting and undoing task preserves embedded subtasks',
    () async {
      final task = app.tasks.add('Audit parent')!;
      task.subtasks.addAll([
        Subtask('One'),
        Subtask('Two', done: true),
        Subtask('Three'),
      ]);
      app.tasks.save(task);
      await app.flush();
      final removed = app.tasks.delete(task)!;
      await app.flush();
      await app.reloadFromDisk();
      expect(app.tasks.byId(task.id), isNull);
      app.tasks.restore(removed);
      await app.flush();
      await app.reloadFromDisk();
      expect(app.tasks.byId(task.id)!.subtasks, hasLength(3));
      expect(app.tasks.byId(task.id)!.subtasks[1].done, isTrue);
    },
  );

  test('AUD-P03 note CRUD pin and undo survive reload', () async {
    final note = app.notes.add(title: 'Audit note', content: 'Original');
    note.content = 'Edited';
    app.notes.save(note);
    app.notes.pin(note);
    await app.flush();
    await app.reloadFromDisk();
    expect(app.notes.notes.first.id, note.id);
    expect(app.notes.notes.first.content, 'Edited');
    final saved = app.notes.delete(app.notes.notes.first)!;
    await app.flush();
    await app.reloadFromDisk();
    expect(app.notes.notes.any((n) => n.id == note.id), isFalse);
    app.notes.restore(saved);
    await app.flush();
    await app.reloadFromDisk();
    expect(app.notes.notes.any((n) => n.id == note.id && n.isPinned), isTrue);
  });

  test('AUD-P04 Quick Note caps and persists 500 ASCII characters', () async {
    app.notes.setQuick('x' * 501);
    await app.flush();
    await app.reloadFromDisk();
    expect(app.notes.quickText, 'x' * 500);
  });

  test('AUD-P05 background Save note applies Append and Replace', () async {
    app.notes.setQuick('Old');
    await app.flush();
    final target = const NotificationTarget(
      NotificationTarget.quickNote,
      '',
    ).encode();
    await handleNotificationAction(
      store: store,
      notifications: notifications,
      actionId: NotificationActions.saveNote,
      payload: target,
      input: 'New',
      clock: () => now,
    );
    await app.reloadFromDisk();
    expect(app.notes.quickText, 'Old\nNew');
    app.account.updateSettings((s) => s.quickNoteAppend = false);
    await app.flush();
    await handleNotificationAction(
      store: store,
      notifications: notifications,
      actionId: NotificationActions.saveNote,
      payload: target,
      input: 'Replacement',
      clock: () => now,
    );
    await app.reloadFromDisk();
    expect(app.notes.quickText, 'Replacement');
    expect(notifications.quickNoteText, 'Replacement');
  });

  test('AUD-P06 failed and cancelled mock payments do not grant VIP', () async {
    app.completeVipPayment(PaymentResult.failed);
    expect(app.isVip, isFalse);
    app.completeVipPayment(PaymentResult.cancelled);
    expect(app.isVip, isFalse);
    await app.flush();
    await app.account.load();
    expect(app.isVip, isFalse);
  });

  test('AUD-N01 Habit Snooze schedules a reminder', () async {
    final habit = Habit(
      id: 'audit-habit',
      title: 'Read',
      shortTitle: 'Read',
      startDate: now,
      createdAt: now,
      repeatRule: 'FREQ=DAILY',
      time: 660,
      reminderMinutes: 0,
    );
    app.habits.add(habit);
    await app.flush();
    await handleNotificationAction(
      store: store,
      notifications: notifications,
      actionId: NotificationActions.snooze,
      payload: NotificationTarget(NotificationTarget.habit, habit.id).encode(),
      clock: () => now,
    );
    expect(notifications.snoozed, contains(habit.id));
  });

  test('AUD-N02 disabled reminder categories do not schedule', () async {
    app.settings.notificationsEnabled = true;
    app.settings.taskReminders = false;
    app.settings.eventReminders = false;
    app.settings.habitReminders = false;
    final task = app.tasks.add(
      'Audit reminder',
      dueDate: now,
      reminderMinutes: 0,
    )!;
    task.dueTime = 660;
    await app.syncNotifications();
    expect(notifications.scheduled, isNot(contains(task.id)));
  });

  test('AUD-N03 habit outside its start date does not remind', () {
    final habit = Habit(
      id: 'future',
      title: 'Future',
      shortTitle: 'Future',
      startDate: DateTime(2026, 10, 10),
      createdAt: now,
      repeatRule: 'FREQ=DAILY',
      time: 660,
      reminderMinutes: 0,
    );
    expect(habitReminderTime(habit, now), isNull);
  });

  test('AUD-N04 turning notifications off hides Quick Note too', () async {
    await app.setQuickNoteNotification(true);
    expect(notifications.quickNoteText, isNotNull);
    await app.disableNotifications();
    expect(notifications.quickNoteHidden, isTrue);
  });

  test(
    'AUD-N05 resume reloads Habit occurrences changed in background',
    () async {
      final habit = Habit(
        id: 'background-habit',
        title: 'Read',
        shortTitle: 'Read',
        startDate: now,
        createdAt: now,
        repeatRule: 'FREQ=DAILY',
      );
      app.habits.add(habit);
      await app.flush();
      final occurrences = HabitOccurrenceRepository(store);
      await occurrences.load();
      final habits = HabitRepository(store, occurrences: occurrences);
      await habits.load();
      habits.skip(habits.byId(habit.id)!, now);
      await occurrences.flush();
      await app.reloadFromDisk();
      expect(app.habits.isSkipped(habit, now), isTrue);
    },
  );

  test(
    'AUD-T01 checkbox completes recurring task and generates next Monday',
    () {
      final task = app.tasks.add('Audit weekdays', dueDate: now)!;
      task.repeat = 'Weekdays';
      app.tasks.toggle(task);
      expect(
        app.tasks.items
            .where((t) => t.title == task.title && !t.completed)
            .map((t) => t.dueDate),
        contains(DateTime(2026, 10, 12)),
      );
    },
  );

  test('AUD-T02 Upcoming excludes overdue tasks', () {
    final past = app.tasks.add(
      'Audit overdue',
      dueDate: DateTime(2026, 10, 8),
    )!;
    expect(
      app.tasks.notDueOn(app.today).map((t) => t.id),
      isNot(contains(past.id)),
    );
  });

  test('AUD-T03 Lock Screen Quick Add uses default reminder', () {
    app.settings.taskReminderMinutes = 15;
    final task = app.quickAddTask('Audit default')!;
    expect(task.reminderMinutes, 15);
  });

  test('AUD-C01 overnight event appears on its second day', () {
    final event = CalendarEvent(
      id: 'overnight',
      title: 'Overnight',
      startTime: DateTime(2026, 10, 9, 23),
      endTime: DateTime(2026, 10, 10, 1),
    );
    app.events.add(event);
    expect(
      app.events.on(DateTime(2026, 10, 10)).map((e) => e.id),
      contains(event.id),
    );
  });

  test('AUD-C02 deleted repeat does not retain its reminder', () async {
    final event = CalendarEvent(
      id: 'deleted-repeat',
      title: 'Daily',
      startTime: DateTime(2026, 10, 9, 11),
      endTime: DateTime(2026, 10, 9, 12),
      repeatRule: 'FREQ=DAILY',
      reminderMinutes: 0,
    );
    app.events.add(event);
    app.events.deleteScope(event, DeleteScope.one, occurrenceDate: app.today);
    final at = eventReminderTime(event, now);
    expect(at, isNot(DateTime(2026, 10, 9, 11)));
  });

  testWidgets('AUD-T04 hideCompletedTasks removes completed rows', (
    tester,
  ) async {
    final task = app.tasks.add('Audit completed')!;
    app.tasks.setCompleted(task, true);
    app.settings.hideCompletedTasks = true;
    await tester.pumpWidget(host(const TodoScreen()));
    await tester.pump();
    expect(find.text('Audit completed'), findsNothing);
  });

  testWidgets('AUD-T05 Quick Add keeps focus after Enter', (tester) async {
    await tester.pumpWidget(host(const TodoScreen()));
    await tester.enterText(find.byType(TextField), 'Audit enter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
  });

  testWidgets('AUD-Q01 notification preview input starts empty', (
    tester,
  ) async {
    app.notes.setQuick('Existing audit note');
    await tester.pumpWidget(host(const QuickNoteNotificationScreen()));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('AUD-W01 wallpaper week follows Sunday start', (tester) async {
    app.settings.weekStart = WeekStartSetting.sunday;
    await tester.pumpWidget(
      host(const Scaffold(body: WallpaperCalendarCard())),
    );
    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    // For 9 Oct, the Sunday-first week begins on 4 Oct, not Monday 5 Oct.
    expect(labels, contains('4'));
    expect(labels, isNot(contains('11')));
  });

  test('AUD-Q02 500 user-visible characters retain a final emoji', () {
    final text = '${'a' * 499}😀';
    app.notes.setQuick(text);
    expect(app.notes.quickText, text);
  });

  testWidgets(
    'AUD-W03 wallpaper week contains events from the other six days',
    (tester) async {
      app.events.add(
        CalendarEvent(
          id: 'audit-week-saturday',
          title: 'Audit Saturday event',
          startTime: DateTime(2026, 10, 10, 12),
          endTime: DateTime(2026, 10, 10, 13),
        ),
      );
      await tester.pumpWidget(
        host(const Scaffold(body: WallpaperCalendarCard())),
      );
      expect(find.textContaining('Audit Saturday event'), findsOneWidget);
    },
  );

  testWidgets('AUD-W02 exported PNG matches 1080x2400 phone dimensions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final oldService = WallpaperService.instance;
    final capture = _CaptureWallpaper();
    WallpaperService.instance = capture;
    addTearDown(() => WallpaperService.instance = oldService);
    await tester.pumpWidget(host(const EditScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Wallpaper'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && capture.png == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(capture.png, isNotNull);
    final header = ByteData.sublistView(capture.png!);
    expect([header.getUint32(16), header.getUint32(20)], [1080, 2400]);
  });
}
