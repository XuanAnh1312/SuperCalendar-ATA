import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application/core/services/local_notification_service.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/features/calendar/data/habit_repository.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/note/data/note_repository.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/features/todo/data/task_repository.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/features/todo/presentation/screens/todo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 9, 10);
  late MemoryDocumentStore store;
  late NoopNotificationService notifications;
  late TaskRepository tasks;

  setUp(() async {
    store = MemoryDocumentStore();
    notifications = NoopNotificationService();
    tasks = TaskRepository(store, clock: () => now);
    await tasks.load();
  });

  Future<AppState> app() async {
    final state = AppState(
      store: store,
      notifications: notifications,
      clock: () => now,
    );
    await state.load();
    return state;
  }

  Future<void> action(String id, NotificationTarget target, {String? input}) =>
      handleNotificationAction(
        store: store,
        notifications: notifications,
        actionId: id,
        payload: target.encode(),
        input: input,
        clock: () => now,
      );

  test(
    'FR-09 / AC-03: delete and undo preserve task and subtasks after reload',
    () async {
      final task = tasks.add('Keep me')!
        ..subtasks.add(Subtask('Child', done: true));
      tasks.save(task);
      final removed = tasks.delete(task)!;
      tasks.restore(removed);
      await tasks.flush();
      await tasks.load();
      expect(tasks.items.single.title, 'Keep me');
      expect(tasks.items.single.subtasks.single.done, isTrue);
    },
  );

  test('FR-09 / AC-23: reorder survives reload', () async {
    tasks.add('First');
    tasks.add('Second');
    tasks.add('Third');
    tasks.reorder(2, 0);
    await tasks.flush();
    await tasks.load();
    expect(tasks.items.map((t) => t.title), ['First', 'Third', 'Second']);
  });

  test('FR-10 / AC-24: deleted task and embedded subtasks disappear', () async {
    final task = tasks.add('Parent')!
      ..subtasks.addAll([Subtask('a'), Subtask('b'), Subtask('c')]);
    tasks.save(task);
    tasks.delete(task);
    await tasks.flush();
    await tasks.load();
    expect(tasks.items, isEmpty);
  });

  test(
    'FR-10 / AC-25: Friday weekday completion creates Monday occurrence',
    () async {
      final task = tasks.add('Repeat', dueDate: now)!..repeat = 'Weekdays';
      final next = tasks.completeAndReschedule(task)!;
      expect(next.dueDate, DateTime(2026, 10, 12));
      expect(task.completed, isTrue);
      expect(tasks.completeAndReschedule(task), isNull);
    },
  );

  test('FR-11 / AC-26: Quick Note caps at 500 and persists', () async {
    final notes = NoteRepository(store);
    await notes.load();
    notes.setQuick('a' * 501);
    await notes.flush();
    await notes.load();
    expect(notes.quickText, 'a' * 500);
  });

  test(
    'FR-18 / AC-35: background Done completes once without generating a task',
    () async {
      final task = tasks.add('Repeat', dueDate: now)!..repeat = 'Daily';
      tasks.save(task);
      await tasks.flush();
      final target = NotificationTarget(NotificationTarget.task, task.id);
      await action(NotificationActions.done, target);
      await action(NotificationActions.done, target);
      await tasks.load();
      expect(tasks.items, hasLength(1));
      expect(tasks.items.single.completed, isTrue);
    },
  );

  test('FR-20 / AC-39: notification save updates shared Quick Note', () async {
    await action(
      NotificationActions.saveNote,
      const NotificationTarget(NotificationTarget.quickNote, ''),
      input: 'From notification',
    );
    final notes = NoteRepository(store);
    await notes.load();
    expect(notes.quickText, 'From notification');
    expect(notifications.quickNoteText, 'From notification');
  });

  test(
    'FR-18 / BR-02: Habit snoozes 10 minutes; Skip affects only today',
    () async {
      final occurrences = HabitOccurrenceRepository(store);
      await occurrences.load();
      final habits = HabitRepository(store, occurrences: occurrences);
      await habits.load();
      final habit = Habit(
        id: 'read',
        title: 'Read',
        shortTitle: 'Read',
        startDate: now,
        createdAt: now,
        repeatRule: 'FREQ=DAILY',
        time: 660,
      );
      habits.add(habit);
      await habits.flush();
      final before = habit.toJson();
      final target = NotificationTarget(NotificationTarget.habit, habit.id);
      await action(NotificationActions.snooze, target);
      expect(snoozeDelay, const Duration(minutes: 10));
      expect(notifications.snoozed, [habit.id]);
      expect(notifications.snoozeDelays[habit.id], const Duration(minutes: 10));
      await action(NotificationActions.skip, target);
      await occurrences.load();
      await habits.load();
      expect(occurrences.statusOn(habit.id, now), OccurrenceStatus.skipped);
      expect(
        occurrences.statusOn(habit.id, now.add(const Duration(days: 1))),
        OccurrenceStatus.pending,
      );
      expect(habits.byId(habit.id)!.toJson(), before);
      await action(NotificationActions.snooze, target);
      expect(notifications.snoozed, [habit.id]);
    },
  );

  testWidgets('FR-09 / AC-21 / AC-22: Today Quick Add clears and keeps focus', (
    tester,
  ) async {
    final state = await app();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: TodoScreen()),
      ),
    );
    await tester.tap(find.textContaining('Today').first);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(state.tasks.items.first.title, 'Buy milk');
    expect(state.tasks.items.first.dueDate, DateTime(2026, 10, 9));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    await state.flush();
    state.dispose();
  });

  testWidgets('FR-09: Settings hides completed tasks immediately', (
    tester,
  ) async {
    final state = await app();
    state.tasks.add('Finished')!.completed = true;
    state.tasks.add('Pending');
    state.settings.hideCompletedTasks = true;
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: TodoScreen()),
      ),
    );
    expect(find.text('Finished'), findsNothing);
    expect(find.text('Pending'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await state.flush();
    state.dispose();
  });

  testWidgets('FR-20 / UI-08 / AC-27: old note appears above an empty input', (
    tester,
  ) async {
    final state = await app();
    state.notes.setQuick('Existing note');
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: QuickNoteNotificationScreen()),
      ),
    );
    expect(find.text('Existing note'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.textContaining('notification access'), findsNothing);
    await tester.enterText(find.byType(TextField), 'New line');
    await tester.ensureVisible(find.text('Save note'));
    await tester.tap(find.text('Save note'));
    await tester.pump();
    expect(state.notes.quickText, 'Existing note\nNew line');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
    await state.flush();
    state.dispose();
  });
  test('FR-11 / AC-27: Quick Note changes reach notification through shared app state', () async {
    final state = await app();
    state.settings.notificationsEnabled = true;
    state.settings.quickNoteNotification = true;
    state.notes.setQuick('Shared content');
    await state.flush();
    await state.syncNotifications();
    expect(notifications.quickNoteText, 'Shared content');
    final reloaded = NoteRepository(store);
    await reloaded.load();
    expect(reloaded.quickText, 'Shared content');
    state.dispose();
  });

  test(
    'FR-09: new tasks use persisted default reminder and priority',
    () async {
      final settings = AppSettings(
        taskReminderMinutes: 15,
        defaultPriority: Task.priorityHigh,
      );
      await store.put(Collections.settings, AppSettings.id, settings.toJson());
      await tasks.load();
      expect(tasks.add('Default')!.reminderMinutes, 15);
      expect(
        tasks
            .add('Explicit', reminderMinutes: 0, priority: Task.priorityHigh)!
            .priority,
        Task.priorityHigh,
      );
      expect(tasks.items.first.reminderMinutes, 0);
    },
  );

  test(
    'FR-18: sync respects type switches and leaves Quick Note pending alone',
    () async {
      final today = DateTime.now();
      final now = DateTime(today.year, today.month, today.day + 1, 8);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'pendingNotificationRequests') {
              return [
                {
                  'id': 2,
                  'title': '',
                  'body': '',
                  'payload': const NotificationTarget(
                    NotificationTarget.quickNote,
                    '',
                  ).encode(),
                },
              ];
            }
            if (call.method == 'initialize') {
              return true;
            }
            if (call.method == 'canScheduleExactNotifications') {
              return true;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final settings = AppSettings(
        eventReminders: false,
        taskReminders: false,
        habitReminders: false,
      );
      await store.put(Collections.settings, AppSettings.id, settings.toJson());
      final task = tasks.add('Later', dueDate: now)!..dueTime = 720;
      final event = CalendarEvent(
        id: 'event',
        title: 'Later',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        reminderMinutes: 10,
      );
      final local = LocalNotificationService(store: store);
      await local.init();
      await local.syncReminders(tasks: [task], events: [event], now: now);
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      expect(calls.where((c) => c.method == 'cancel'), isEmpty);
      settings.taskReminders = true;
      await store.put(Collections.settings, AppSettings.id, settings.toJson());
      await local.syncReminders(tasks: [task], events: [event], now: now);
      expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(1));
      final habit = Habit(
        id: 'habit',
        title: 'Read',
        shortTitle: 'Read',
        startDate: now,
        createdAt: now,
        repeatRule: 'FREQ=DAILY',
        time: 720,
      );
      final occurrences = HabitOccurrenceRepository(store);
      await occurrences.load();
      final habits = HabitRepository(store, occurrences: occurrences);
      await habits.load();
      habits.add(habit);
      await habits.flush();
      settings.taskReminders = false;
      settings.habitReminders = true;
      settings.habitReminderMinutes = 15;
      await store.put(Collections.settings, AppSettings.id, settings.toJson());
      calls.clear();
      await local.syncReminders(
        tasks: [task],
        events: [event],
        habits: [habit],
        now: now,
      );
      expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(1));
      habits.skip(habit, now);
      await occurrences.flush();
      calls.clear();
      await local.syncReminders(
        tasks: [task],
        events: [event],
        habits: [habit],
        now: now,
      );
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    },
  );
}
