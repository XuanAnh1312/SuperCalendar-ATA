import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/local_notification_service.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/data/habit_repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/note/presentation/screens/note_edit_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/features/todo/presentation/screens/todo_screen.dart';

class _LaunchNotifications extends NoopNotificationService {
  NotificationTarget? launch;
  void Function(NotificationTarget)? open;
  @override
  Future<NotificationTarget?> launchTarget() async => launch;
  @override
  Future<void> init({
    void Function(NotificationTarget)? onOpen,
    void Function()? onDataChanged,
  }) async {
    open = onOpen;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 9, 10); // Friday.
  late MemoryDocumentStore store;
  late AppState app;
  late _LaunchNotifications notifications;

  setUp(() async {
    store = MemoryDocumentStore();
    await store.put(
      Collections.settings,
      AppSettings.id,
      AppSettings(
        seeded: true,
        onboarded: true,
        notificationsEnabled: true,
      ).toJson(),
    );
    notifications = _LaunchNotifications();
    app = AppState(
      store: store,
      notifications: notifications,
      clock: () => now,
    );
    await app.load();
  });
  tearDown(() => app.dispose());

  Future<void> widgetFixture() async {
    app.dispose();
    app = AppState(
      store: store,
      notifications: notifications,
      clock: () => now,
    );
    await app.load();
  }

  Future<bool> action(
    String name,
    NotificationTarget target, {
    String? input,
  }) => handleNotificationAction(
    store: store,
    notifications: notifications,
    actionId: name,
    payload: target.encode(),
    input: input,
    clock: () => now,
  );

  Habit habit({DateTime? start, DateTime? end, String rule = 'FREQ=DAILY'}) =>
      Habit(
        id: 'read',
        title: 'Read',
        shortTitle: 'Read',
        time: 660,
        startDate: start ?? now,
        endDate: end,
        repeatRule: rule,
        reminderMinutes: 0,
        createdAt: now,
      );

  Widget host(Widget child) => AppScope(
    state: app,
    child: MaterialApp(home: child),
  );

  test('AUD-T01: weekdays checkbox creates Monday with fresh subtasks; notification Done does not', () async {
    final task = app.tasks.add('Recurring', dueDate: now)!
      ..repeat = 'Weekdays'
      ..subtasks.add(Subtask('Read a chapter', done: true));
    app.tasks.toggle(task);
    final next = app.tasks.items.where((t) => !t.completed).single;
    expect(next.dueDate, DateTime(2026, 10, 12));
    expect(next.subtasks.single.done, isFalse);
    await app.flush();
    await action(
      NotificationActions.done,
      NotificationTarget(NotificationTarget.task, next.id),
    );
    await app.reloadFromDisk();
    expect(app.tasks.items, hasLength(2));
    expect(app.tasks.items.every((t) => t.completed), isTrue);
  });

  test(
    'AUD-T02: Upcoming is future dated; overdue and undated stay in All',
    () {
      app.tasks.add('Overdue', dueDate: DateTime(2026, 10, 8));
      app.tasks.add('Today', dueDate: now);
      app.tasks.add('Undated');
      final later = app.tasks.add('Later', dueDate: DateTime(2026, 10, 10))!;
      expect(app.tasks.notDueOn(now).map((t) => t.id), [later.id]);
      expect(app.tasks.items, hasLength(4));
    },
  );

  test('AUD-T03: Lock Screen and background Add task use current defaults and priority', () async {
    app.account.updateSettings((s) {
      s.taskReminderMinutes = 15;
      s.defaultPriority = Task.priorityHigh;
    });
    expect(app.quickAddTask('Lock')!.reminderMinutes, 15);
    await app.flush();
    await action(
      NotificationActions.addTask,
      const NotificationTarget(NotificationTarget.lockScreen, ''),
      input: 'Background',
    );
    await app.reloadFromDisk();
    expect(app.tasks.items.first.priority, Task.priorityHigh);
    expect(app.tasks.items.first.reminderMinutes, 15);
    app.account.updateSettings((s) => s.taskReminderMinutes = null);
    expect(app.quickAddTask('At deadline')!.reminderMinutes, 0);
    final custom = app.tasks.add('Custom', reminderMinutes: 60)!;
    await app.flush();
    await app.reloadFromDisk();
    expect(app.tasks.byId(custom.id)!.reminderMinutes, 60);
  });

  testWidgets(
    'AUD-T04: filter setting, counters and reorder reflect the same visible rows',
    (tester) async {
      await widgetFixture();
      final done = app.tasks.add('Finished', dueDate: now)!;
      app.tasks.setCompleted(done, true);
      app.tasks.add('Pending', dueDate: now);
      await tester.pumpWidget(host(const TodoScreen()));
      await tester.tap(find.byIcon(LucideIcons.listFilter));
      await tester.pumpAndSettle();
      expect(app.settings.hideCompletedTasks, isTrue);
      expect(find.text('Finished'), findsNothing);
      expect(find.text('All 1'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
      await tester.runAsync(() async {
        await app.flush();
        await app.account.load();
      });
      expect(app.settings.hideCompletedTasks, isTrue);
      app.account.updateSettings((s) => s.hideCompletedTasks = false);
      await tester.pumpAndSettle();
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('All 2'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
    },
  );

  testWidgets('AUD-T05: Quick Add clears after Done and retains focus', (
    tester,
  ) async {
    await widgetFixture();
    await tester.pumpWidget(host(const TodoScreen()));
    await tester.enterText(find.byType(TextField), 'Keep typing');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(field.focusNode!.hasFocus, isTrue);
  });

  test('CRUD, embedded subtasks, reorder and Undo survive reload', () async {
    final first = app.tasks.add('First')!;
    final second = app.tasks.add('Second')!
      ..subtasks.add(Subtask('Child', done: true));
    app.tasks.save(second);
    app.tasks.reorder(0, 1);
    await app.flush();
    final removed = app.tasks.delete(second)!;
    await app.flush();
    await app.reloadFromDisk();
    app.tasks.restore(removed);
    await app.flush();
    await app.reloadFromDisk();
    expect(app.tasks.items.map((t) => t.id), [second.id, first.id]);
    expect(app.tasks.byId(second.id)!.subtasks.single.done, isTrue);
  });

  for (final grapheme in ['😀', '👨‍👩‍👧‍👦', 'e\u0301', '🇻🇳']) {
    test(
      'AUD-Q02: 499 letters plus $grapheme survives database and Replace',
      () async {
        final text = '${'a' * 499}$grapheme';
        app.notes.setQuick(text);
        await app.flush();
        await app.reloadFromDisk();
        expect(app.notes.quickText, text);
        expect(app.notes.quickText.characters.length, 500);
        app.notes.captureQuick('$text extra', append: false);
        expect(app.notes.quickText, text);
      },
    );
  }

  test(
    'AUD-Q02: Append accounts for newline and never stores a separator alone',
    () {
      app.notes.setQuick('a' * 498);
      expect(app.notes.captureQuick('👨‍👩‍👧‍👦extra', append: true), isTrue);
      expect(app.notes.quickText, '${'a' * 498}\n👨‍👩‍👧‍👦');
      app.notes.setQuick('a' * 499);
      expect(app.notes.captureQuick('😀', append: true), isFalse);
      expect(app.notes.quickText, 'a' * 499);
      expect(app.notes.captureQuick(' \n ', append: false), isFalse);
      expect(app.notes.quickText, 'a' * 499);
    },
  );

  testWidgets(
    'AUD-Q01/Q02: preview old text, empty input and grapheme counter',
    (tester) async {
      await widgetFixture();
      app.notes.setQuick('Existing');
      app.settings.quickNoteAppend = false;
      await tester.pumpWidget(host(const QuickNoteNotificationScreen()));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Existing'), findsOneWidget);
      expect(find.textContaining('notification access'), findsNothing);
      await tester.enterText(find.byType(TextField), '${'a' * 499}👨‍👩‍👧‍👦');
      await tester.pump();
      expect(find.text('500/500'), findsOneWidget);
      await tester.ensureVisible(find.text('Save note'));
      await tester.tap(find.text('Save note'));
      await tester.pumpAndSettle();
      expect(app.notes.quickText.characters.length, 500);
      expect(app.notes.quickText.endsWith('👨‍👩‍👧‍👦'), isTrue);
    },
  );

  test('AUD-N01: Snooze is 10 minutes; Skip persists only today and invalidates Snooze', () async {
    final source = habit();
    app.habits.add(source);
    await app.flush();
    final before = source.toJson();
    final target = NotificationTarget(
      NotificationTarget.habit,
      source.id,
      occurrenceDate: now,
    );
    await action(NotificationActions.snooze, target);
    expect(notifications.snoozeDelays[source.id], const Duration(minutes: 10));
    await action(NotificationActions.skip, target);
    await app.reloadFromDisk();
    expect(app.habits.isSkipped(source, now), isTrue);
    expect(
      app.habitOccurrences.statusOn(source.id, DateTime(2026, 10, 10)),
      OccurrenceStatus.pending,
    );
    expect(app.habits.byId(source.id)!.toJson(), before);
    expect(notifications.pendingSnoozes, isEmpty);
    await action(NotificationActions.snooze, target);
    expect(notifications.snoozed, [source.id]);
  });

  test(
    'AUD-N02: disabled reminder categories are excluded before service calls',
    () async {
      final task = app.tasks.add('Task', dueDate: now, reminderMinutes: 0)!
        ..dueTime = 660;
      app.tasks.save(task);
      app.habits.add(habit());
      app.account.updateSettings((s) {
        s.taskReminders = false;
        s.habitReminders = false;
        s.eventReminders = false;
      });
      await app.syncNotifications();
      expect(notifications.scheduled, isEmpty);
      app.account.updateSettings((s) => s.taskReminders = true);
      await app.syncNotifications();
      expect(notifications.scheduled, [task.id]);
    },
  );

  test('AUD-N03: start/end dates, RRULE and persisted statuses gate Habit reminders', () async {
    final tomorrow = habit(start: DateTime(2026, 10, 10));
    expect(habitReminderTime(tomorrow, now), isNull);
    expect(habitReminderTime(habit(end: DateTime(2026, 10, 8)), now), isNull);
    expect(habitReminderTime(habit(rule: 'FREQ=WEEKLY;BYDAY=MO'), now), isNull);
    final source = habit();
    app.habits.add(source);
    await app.flush();
    for (final status in [
      OccurrenceStatus.done,
      OccurrenceStatus.skipped,
      OccurrenceStatus.deleted,
    ]) {
      if (status == OccurrenceStatus.done) {
        app.habitOccurrences.markDone(source.id, now);
      }
      if (status == OccurrenceStatus.skipped) {
        app.habitOccurrences.markSkipped(source.id, now);
      }
      if (status == OccurrenceStatus.deleted) {
        app.habitOccurrences.markDeleted(source.id, now);
      }
      await app.syncNotifications();
      expect(notifications.scheduled, isEmpty, reason: status.name);
    }
  });

  test(
    'AUD-N04: disabling hides Quick Note and persists all display toggles',
    () async {
      await app.setQuickNoteNotification(true);
      await app.setLockScreenNotification(true);
      await app.disableNotifications();
      await app.syncNotifications();
      expect(notifications.quickNoteHidden, isTrue);
      expect(notifications.lockScreen, isNull);
      expect(notifications.scheduled, isEmpty);
      await app.account.load();
      expect(app.settings.notificationsEnabled, isFalse);
      expect(app.settings.quickNoteNotification, isFalse);
      expect(app.settings.lockScreenEnabled, isFalse);
    },
  );

  test('AUD-N05: resume sees background Habit status and external Note/Task changes', () async {
    final source = habit();
    app.habits.add(source);
    await app.flush();
    final occurrences = HabitOccurrenceRepository(store);
    await occurrences.load();
    occurrences.markSkipped(source.id, now);
    await occurrences.flush();
    await action(
      NotificationActions.saveNote,
      const NotificationTarget(NotificationTarget.quickNote, ''),
      input: 'Background note',
    );
    await action(
      NotificationActions.addTask,
      const NotificationTarget(NotificationTarget.lockScreen, ''),
      input: 'Background task',
    );
    await app.reloadFromDisk();
    expect(app.habits.isSkipped(source, now), isTrue);
    expect(app.notes.quickText, 'Background note');
    expect(app.tasks.items.single.title, 'Background task');
  });

  test('AUD-C02: deleted event occurrence advances; override uses the changed time', () async {
    final source = CalendarEvent(
      id: 'daily',
      title: 'Daily',
      startTime: DateTime(2026, 10, 9, 11),
      endTime: DateTime(2026, 10, 9, 12),
      repeatRule: 'FREQ=DAILY',
      reminderMinutes: 0,
    );
    app.events.add(source);
    app.events.deleteScope(source, DeleteScope.one, occurrenceDate: now);
    expect(eventReminderTime(source, now), DateTime(2026, 10, 10, 11));
    app.eventExceptions.saveOverride(source.id, now, {
      'startTime': DateTime(2026, 10, 9, 14).toIso8601String(),
    });
    expect(eventReminderTime(source, now), DateTime(2026, 10, 9, 14));
    await app.flush();
    await app.reloadFromDisk();
    expect(
      eventReminderTime(app.events.byId(source.id)!, now),
      DateTime(2026, 10, 9, 14),
    );
  });

  test(
    'AUD-C02: past original occurrence moved into the future is considered',
    () {
      final source = CalendarEvent(
        id: 'weekly',
        title: 'Weekly',
        startTime: DateTime(2026, 10, 5, 11),
        endTime: DateTime(2026, 10, 5, 12),
        repeatRule: 'FREQ=WEEKLY;BYDAY=MO',
        reminderMinutes: 0,
      );
      app.events.add(source);
      app.eventExceptions.saveOverride(source.id, DateTime(2026, 10, 5), {
        'startTime': DateTime(2026, 10, 9, 11).toIso8601String(),
      });
      expect(eventReminderTime(source, now), DateTime(2026, 10, 9, 11));
    },
  );

  testWidgets(
    'REVIEW-03: cold-start Quick Note target opens the actual composer',
    (tester) async {
      await widgetFixture();
      app.notes.setQuick('Restore latest note');
      await app.flush();
      notifications.launch = const NotificationTarget(
        NotificationTarget.quickNote,
        '',
      );
      await tester.pumpWidget(SuperCalendarApp(state: app));
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Restore latest note',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('REVIEW-03: foreground Open app also routes to composer', (
    tester,
  ) async {
    await widgetFixture();
    await tester.pumpWidget(SuperCalendarApp(state: app));
    await tester.pumpAndSettle();
    notifications.open!(
      const NotificationTarget(NotificationTarget.quickNote, ''),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'AC-05: revoked permission disables notifications without breaking data',
    () async {
      await app.setQuickNoteNotification(true);
      notifications.permissionGranted = false;
      await app.syncNotifications();
      expect(app.settings.notificationsEnabled, isFalse);
      expect(notifications.quickNoteHidden, isTrue);
      expect(app.quickAddTask('Still works'), isNotNull);
    },
  );

  group('Android plugin boundary (mock channel, not device acceptance)', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    late List<MethodCall> calls;
    late Map<int, Map<String, Object?>> pending;
    late List<Map<String, Object?>> active;
    late DateTime nativeNow;
    late LocalNotificationService local;
    bool exactDeniedOnce = false;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      calls = [];
      pending = {};
      active = [];
      final today = DateTime.now();
      nativeNow = DateTime(today.year, today.month, today.day + 1, 10);
      exactDeniedOnce = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            final args = call.arguments is Map
                ? Map<String, Object?>.from(call.arguments as Map)
                : <String, Object?>{};
            switch (call.method) {
              case 'initialize':
              case 'areNotificationsEnabled':
              case 'canScheduleExactNotifications':
                return true;
              case 'pendingNotificationRequests':
                return pending.values.toList();
              case 'getActiveNotifications':
                return active;
              case 'cancelAllPendingNotifications':
                pending.clear();
                return null;
              case 'cancel':
                pending.remove(args['id']);
                active.removeWhere(
                  (a) => a['id'] == args['id'] && a['tag'] == args['tag'],
                );
                return null;
              case 'zonedSchedule':
                if (exactDeniedOnce) {
                  exactDeniedOnce = false;
                  throw PlatformException(code: 'exact_alarms_not_permitted');
                }
                pending[args['id']! as int] = {
                  'id': args['id'],
                  'title': args['title'],
                  'body': args['body'],
                  'payload': args['payload'],
                };
                return null;
              default:
                return null;
            }
          });
      local = LocalNotificationService(store: store, clock: () => nativeNow);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    Future<Task> scheduledTask() async {
      final task = app.tasks.add(
        'Native task',
        dueDate: nativeNow,
        reminderMinutes: 0,
      )!..dueTime = 660;
      app.tasks.save(task);
      await app.flush();
      await local.syncReminders(tasks: [task], events: [], now: nativeNow);
      return task;
    }

    test('REVIEW-04: Snooze replaces normal, survives sync once, completion cancels both', () async {
      final task = await scheduledTask();
      await local.snoozeTask(task, snoozeDelay);
      expect(pending.keys, [reminderNotificationId('snooze:task:${task.id}')]);
      await local.syncReminders(tasks: [task], events: [], now: nativeNow);
      expect(pending, hasLength(1));
      app.tasks.setCompleted(task, true);
      await app.flush();
      await local.syncReminders(tasks: [task], events: [], now: nativeNow);
      expect(pending, isEmpty);
    });

    test('REVIEW-04: deleting source removes pending and tagged active notifications', () async {
      final task = await scheduledTask();
      final target = NotificationTarget(NotificationTarget.task, task.id);
      active.add({
        'id': reminderNotificationId('task:${task.id}'),
        'channelId': 'reminders',
        'tag': target.encode(),
      });
      app.tasks.delete(task);
      await app.flush();
      await local.syncReminders(tasks: [], events: [], now: nativeNow);
      expect(pending, isEmpty);
      expect(active, isEmpty);
    });

    test('AUD-N02/REVIEW-04: disabling one category drops its Snooze and retains Quick Note', () async {
      final task = await scheduledTask();
      await local.snoozeTask(task, snoozeDelay);
      pending[2] = {
        'id': 2,
        'payload': const NotificationTarget(
          NotificationTarget.quickNote,
          '',
        ).encode(),
      };
      app.account.updateSettings((s) => s.taskReminders = false);
      await app.flush();
      await local.syncReminders(tasks: [task], events: [], now: nativeNow);
      expect(pending.keys, [2]);
    });

    test(
      'AUD-C02: changed/deleted event occurrence invalidates its Snooze',
      () async {
        final event = CalendarEvent(
          id: 'event',
          title: 'Event',
          startTime: nativeNow.add(const Duration(hours: 1)),
          endTime: nativeNow.add(const Duration(hours: 2)),
          repeatRule: 'FREQ=DAILY',
          reminderMinutes: 0,
        );
        app.events.add(event);
        await app.flush();
        await local.syncReminders(tasks: [], events: [event], now: nativeNow);
        final occurrence = event.resolvedOccurrenceOn(nativeNow)!;
        await local.snoozeEvent(occurrence, snoozeDelay);
        app.events.deleteScope(
          event,
          DeleteScope.one,
          occurrenceDate: nativeNow,
        );
        await app.flush();
        await local.syncReminders(tasks: [], events: [event], now: nativeNow);
        expect(pending.keys, [reminderNotificationId('event:event')]);
        expect(
          NotificationTarget.decode(pending.values.single['payload'] as String)!
              .snoozed,
          isFalse,
        );
      },
    );

    test(
      'NFR-11: exact alarm revoked during schedule falls back to inexact',
      () async {
        exactDeniedOnce = true;
        await scheduledTask();
        final attempts = calls
            .where((c) => c.method == 'zonedSchedule')
            .toList();
        expect(attempts, hasLength(2));
        final specifics =
            (attempts.last.arguments as Map)['platformSpecifics'] as Map;
        expect(
          specifics['scheduleMode'],
          AndroidScheduleMode.inexactAllowWhileIdle.name,
        );
        expect(pending, hasLength(1));
      },
    );

    test('REVIEW-03: Open app and Schedule request a UI; Save note stays RemoteInput', () async {
      app.account.updateSettings((s) => s.quickNoteNotification = true);
      await app.flush();
      await local.showQuickNoteNotification('Old note');
      final show = calls.lastWhere((c) => c.method == 'show');
      final details = (show.arguments as Map)['platformSpecifics'] as Map;
      final actions = (details['actions'] as List).cast<Map>();
      expect(
        actions.singleWhere(
          (a) => a['id'] == NotificationActions.openApp,
        )['showsUserInterface'],
        isTrue,
      );
      expect(
        actions.singleWhere(
          (a) => a['id'] == NotificationActions.saveNote,
        )['inputs'],
        isNotEmpty,
      );
      await local.showLockScreen(
        LockScreenContent(events: [], tasks: [], day: nativeNow),
      );
      final lock =
          (calls.lastWhere((c) => c.method == 'show').arguments
                  as Map)['platformSpecifics']
              as Map;
      expect(
        (lock['actions'] as List).cast<Map>().singleWhere(
          (a) => a['id'] == NotificationActions.schedule,
        )['showsUserInterface'],
        isTrue,
      );
    });

    test('AUD-N04: stale background Save does not resurrect a disabled notification', () async {
      app.account.updateSettings((s) {
        s.notificationsEnabled = false;
        s.quickNoteNotification = false;
      });
      await app.flush();
      await local.showQuickNoteNotification('Should remain hidden');
      expect(calls.where((c) => c.method == 'show'), isEmpty);
    });
  });
}
