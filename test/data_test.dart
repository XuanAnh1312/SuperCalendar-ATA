import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/features/vip/domain/template.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

CalendarEvent _event(String id, DateTime start, {int? reminder}) =>
    CalendarEvent(
      id: id,
      title: 'Standup',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      reminderMinutes: reminder,
    );

void main() {
  group('local database', () {
    test('first run seeds sample data once, anchored on today', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      expect(app.tasks.items, hasLength(6));
      expect(app.events.on(testToday), hasLength(3));
      expect(app.notes.quickText, isNotEmpty);
      expect(app.settings.seeded, isTrue);

      await app.flush();
      final reopened = await loadApp(store: store);
      expect(reopened.tasks.items, hasLength(6), reason: 'not seeded twice');
    });

    test('tasks survive a restart: create, complete, edit, delete', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      final created = app.tasks.add('Water the plants', dueDate: testToday)!;
      final first = app.tasks.byId('seed_task_0')!;
      app.tasks.toggle(first);
      first
        ..title = 'Send proposal v2'
        ..priority = Task.priorityLow;
      app.tasks.save(first);
      app.tasks.delete(app.tasks.byId('seed_task_5')!);
      await app.flush();

      final reopened = await loadApp(store: store);
      expect(reopened.tasks.items.first.id, created.id, reason: 'order kept');
      expect(reopened.tasks.byId(created.id)!.isDueOn(testToday), isTrue);
      final saved = reopened.tasks.byId('seed_task_0')!;
      expect(saved.completed, isTrue);
      expect(saved.title, 'Send proposal v2');
      expect(saved.priority, Task.priorityLow);
      expect(saved.subtasks, hasLength(3));
      expect(reopened.tasks.byId('seed_task_5'), isNull);
    });

    test('events survive a restart: create, edit, delete', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      final day = DateTime(2026, 10, 20);
      app.events.add(_event('e1', DateTime(2026, 10, 20, 8)));
      app.events.add(_event('e2', DateTime(2026, 10, 20, 15)));
      final e1 = app.events.byId('e1')!
        ..title = 'Moved standup'
        ..location = 'Room 2';
      app.events.save(e1);
      app.events.delete(app.events.byId('e2')!);
      await app.flush();

      final reopened = await loadApp(store: store);
      final events = reopened.events.on(day);
      expect(events, hasLength(1));
      expect(events.single.title, 'Moved standup');
      expect(events.single.location, 'Room 2');
      expect(events.single.source, CalendarEvent.sourceLocal);
    });

    test('notes survive a restart: create, edit, delete, quick note', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      final note = app.notes.add(title: 'English notes', content: 'Unit 4');
      note.content = 'Unit 5';
      app.notes.save(note);
      app.notes.delete(
        app.notes.notes.firstWhere((n) => n.title == 'Java notes'),
      );
      app.notes.setQuick('Call the dentist');
      await app.flush();

      final reopened = await loadApp(store: store);
      final titles = reopened.notes.notes.map((n) => n.title);
      expect(titles, contains('English notes'));
      expect(titles, isNot(contains('Java notes')));
      expect(
        reopened.notes.notes.firstWhere((n) => n.id == note.id).content,
        'Unit 5',
      );
      expect(reopened.notes.quickText, 'Call the dentist');
    });

    test('habit actions apply to today only', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      final walk = app.habits.items.last;
      expect(walk.isDone(testToday), isFalse);
      app.habits.toggle(walk, testToday);
      app.habits.removeOccurrence(app.habits.items.first, testToday);
      await app.flush();

      final reopened = await loadApp(store: store);
      expect(reopened.habits.occurrences(testToday), hasLength(2));
      expect(reopened.habits.items.last.isDone(testToday), isTrue);

      final tomorrow = testToday.add(const Duration(days: 1));
      expect(reopened.habits.occurrences(tomorrow), hasLength(3));
      expect(reopened.habits.items.last.isDone(tomorrow), isFalse);
    });
  });

  group('theme', () {
    test('theme, dark mode and accent are applied and remembered', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      expect(AppTheme.current.id, 'pastel_minimal');
      final lightBackground = AppColors.background;

      app.selectTheme('pastel_green');
      expect(AppColors.primary, builtInThemes[2].primary);
      app.setDarkMode(true);
      expect(AppColors.background, isNot(lightBackground));
      app.setAccent(1);
      await app.flush();

      // Simulate a cold start with the default theme in memory.
      AppTheme.apply(builtInThemes.first);
      final reopened = await loadApp(store: store);
      expect(reopened.user.selectedThemeId, 'pastel_green');
      expect(reopened.settings.darkMode, isTrue);
      expect(AppTheme.palette.dark, isTrue);
      expect(AppTheme.current.primary, AppColors.accent(1));

      reopened
        ..setDarkMode(false)
        ..selectTheme('pastel_minimal');
    });
  });

  group('VIP and mock payment', () {
    test(
      'only a successful payment grants VIP, and it is remembered',
      () async {
        final store = MemoryDocumentStore();
        final app = await loadApp(store: store);
        expect(app.isVip, isFalse);

        app.completeVipPayment(PaymentResult.failed);
        app.completeVipPayment(PaymentResult.cancelled);
        expect(app.isVip, isFalse);

        app.completeVipPayment(PaymentResult.success);
        expect(app.isVip, isTrue);
        expect(app.templates.purchases, hasLength(3));
        await app.flush();

        final reopened = await loadApp(store: store);
        expect(reopened.isVip, isTrue);
        expect(
          reopened.templates.purchases.map((p) => p.status),
          containsAll(PaymentResult.values),
        );
      },
    );

    test('VIP features are locked for a Free user', () async {
      final app = await loadApp();
      expect(app.setTypography(AppThemeData.typographyBold), isFalse);
      expect(
        app.createTemplate(
          name: 'Mine',
          description: '',
          price: 0,
          preview: '🎨',
          theme: builtInThemes.first,
        ),
        isNull,
      );

      app.completeVipPayment(PaymentResult.success);
      expect(app.setTypography(AppThemeData.typographyBold), isTrue);
      expect(AppTheme.current.typography, AppThemeData.typographyBold);

      // Back on Free the custom typography no longer applies.
      app.cancelVip();
      expect(AppTheme.current.typography, AppThemeData.typographyClean);
    });
  });

  group('templates', () {
    test('a paid template must be bought before it can be applied', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      final sakura = app.templates.byId('sakura_morning')!;
      expect(sakura.priceLabel, '29,000đ');
      expect(app.ownsTemplate(sakura), isFalse);
      expect(app.applyTemplate(sakura), isFalse);

      app.completeTemplatePayment(sakura, PaymentResult.failed);
      expect(app.ownsTemplate(sakura), isFalse);

      app.completeTemplatePayment(sakura, PaymentResult.success);
      expect(app.ownsTemplate(sakura), isTrue);
      expect(app.applyTemplate(sakura), isTrue);
      expect(AppTheme.current.primary, sakura.themeData.primary);
      expect(AppTheme.current.radius, 22);
      await app.flush();

      final reopened = await loadApp(store: store);
      expect(
        reopened.ownsTemplate(reopened.templates.byId('sakura_morning')!),
        isTrue,
      );
      expect(reopened.user.selectedThemeId, sakura.themeData.id);
      reopened.selectTheme('pastel_minimal');
    });

    test('free templates apply without a purchase', () async {
      final app = await loadApp();
      final forest = app.templates.byId('forest')!;
      expect(app.applyTemplate(forest), isTrue);
      expect(app.isTemplateApplied(forest), isTrue);
      app.selectTheme('pastel_minimal');
    });

    test('a VIP user creates and publishes a template', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      app.completeVipPayment(PaymentResult.success);
      final template = app.createTemplate(
        name: 'My Calm Week',
        description: 'Mine',
        price: 9000,
        preview: '🎨',
        theme: AppThemeData(
          id: 'draft',
          name: 'draft',
          primary: AppColors.accent(4),
          radius: 16,
        ),
      )!;
      expect(template.published, isFalse);
      expect(app.templates.published, isNot(contains(template)));
      expect(app.ownsTemplate(template), isTrue, reason: 'creator owns it');

      expect(app.publishTemplate(template), isTrue);
      await app.flush();

      final reopened = await loadApp(store: store);
      final saved = reopened.templates.byId(template.id)!;
      expect(saved.published, isTrue);
      expect(saved.creatorId, reopened.user.id);
      expect(saved.themeData.radius, 16);
      expect(reopened.templates.published.map((t) => t.id), contains(saved.id));
    });
  });

  group('screen layout', () {
    test('presets and free-form edits are saved per screen', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      expect(app.layouts.home.visibleItems, hasLength(6));

      app.layouts.applyPreset(ScreenLayout.home, ScreenLayout.presetFocus);
      expect(app.layouts.home.visibleItems.map((i) => i.type), [
        WidgetType.todo,
        WidgetType.week,
        WidgetType.quickNote,
      ]);
      app.layouts.setVisible(ScreenLayout.lock, WidgetType.quickNote, false);
      app.layouts.reorder(ScreenLayout.lock, 1, 0);
      await app.flush();

      final reopened = await loadApp(store: store);
      expect(reopened.layouts.home.preset, ScreenLayout.presetFocus);
      expect(reopened.layouts.home.shows(WidgetType.habits), isFalse);
      expect(reopened.layouts.lock.preset, ScreenLayout.presetCustom);
      expect(reopened.layouts.lock.visibleItems.map((i) => i.type), [
        WidgetType.todo,
        WidgetType.schedule,
      ]);
    });
  });

  group('screen background and lock content', () {
    test('a background image is remembered per screen', () async {
      final store = MemoryDocumentStore();
      final app = await loadApp(store: store);
      app.layouts.setBackground(ScreenLayout.lock, '/data/bg_lock.jpg');
      await app.flush();

      final reopened = await loadApp(store: store);
      expect(reopened.layouts.lock.backgroundPath, '/data/bg_lock.jpg');
      expect(reopened.layouts.home.backgroundPath, isNull);
    });

    test('the lock screen notification lists only open tasks', () async {
      final app = await loadApp();
      final content = app.lockScreenContent;
      expect(content.events, hasLength(3));
      expect(content.tasks.every((t) => !t.completed), isTrue);
      expect(content.tasks.first.id, 'seed_task_0');

      app.tasks.toggle(app.tasks.byId('seed_task_0')!);
      expect(
        app.lockScreenContent.tasks.map((t) => t.id),
        isNot(contains('seed_task_0')),
      );
    });

    test('quick add creates a task due today', () async {
      final app = await loadApp();
      expect(app.quickAddTask('   '), isNull);
      final task = app.quickAddTask('Call the bank')!;
      expect(task.isDueOn(testToday), isTrue);
      expect(app.tasks.items.first, task);
    });
  });

  group('system calendar', () {
    final phoneEvent = CalendarEvent(
      id: 'system_1',
      title: 'Dentist',
      startTime: DateTime(2026, 10, 5, 17),
      endTime: DateTime(2026, 10, 5, 18),
      source: CalendarEvent.sourceSystem,
    );

    test('nothing is requested until the user connects', () async {
      final calendar = FakeSystemCalendarService(events: [phoneEvent]);
      final app = await loadApp(systemCalendar: calendar);
      await app.refreshSystemCalendar();
      expect(calendar.requests, 0);
      expect(app.events.on(testToday), hasLength(3));
    });

    test('granted: system events are merged in, read-only', () async {
      final calendar = FakeSystemCalendarService(events: [phoneEvent]);
      final app = await loadApp(systemCalendar: calendar);
      expect(await app.connectSystemCalendar(), isTrue);
      expect(calendar.requests, 1);

      final today = app.events.on(testToday);
      expect(today, hasLength(4));
      expect(today.last.source, CalendarEvent.sourceSystem);

      app.events.delete(today.last);
      expect(app.events.on(testToday), hasLength(4), reason: 'read-only');
    });

    test('denied: the app keeps working on local events', () async {
      final calendar = FakeSystemCalendarService(
        grantOnRequest: false,
        events: [phoneEvent],
      );
      final app = await loadApp(systemCalendar: calendar);
      expect(await app.connectSystemCalendar(), isFalse);
      expect(app.settings.useSystemCalendar, isFalse);
      expect(app.settings.calendarPermissionAsked, isTrue);
      expect(app.events.on(testToday), hasLength(3));
      expect(app.events.systemEvents, isEmpty);
    });
  });

  group('notifications', () {
    test('reminders are scheduled only after the user enables them', () async {
      final notifications = NoopNotificationService();
      final app = await loadApp(notifications: notifications);
      await pumpEventQueue();
      expect(notifications.permissionRequests, 0);
      expect(notifications.syncCount, 0);

      expect(await app.enableNotifications(), isTrue);
      await pumpEventQueue();
      // At 9:41: the 14:00 event (15 min before), the launch event and the
      // 16:00 task (30 min before). The 9:00 event's reminder has passed.
      expect(
        notifications.scheduled,
        containsAll(['seed_task_0', 'seed_event_2', 'seed_event_5']),
      );
      expect(notifications.scheduled, isNot(contains('seed_event_0')));
    });

    test('a denied permission leaves reminders off', () async {
      final notifications = NoopNotificationService(permissionGranted: false);
      final app = await loadApp(notifications: notifications);
      expect(await app.enableNotifications(), isFalse);
      expect(app.settings.notificationsEnabled, isFalse);
      expect(await app.setLockScreenNotification(true), isFalse);

      // Saving something with a reminder does not nag again.
      final asked = notifications.permissionRequests;
      await app.ensureRemindersCanFire();
      expect(notifications.permissionRequests, asked);
    });

    test(
      'Done from a notification completes the task in the database',
      () async {
        final store = MemoryDocumentStore();
        final notifications = NoopNotificationService();
        final app = await loadApp(store: store, notifications: notifications);
        await app.enableNotifications();
        await app.setLockScreenNotification(true);
        await app.flush();

        final changed = await handleNotificationAction(
          store: store,
          notifications: notifications,
          actionId: NotificationActions.done,
          payload: const NotificationTarget(
            NotificationTarget.task,
            'seed_task_0',
          ).encode(),
          clock: () => testNow,
        );
        expect(changed, isTrue);
        expect(
          app.tasks.byId('seed_task_0')!.completed,
          isFalse,
          reason: 'the UI has not reloaded yet',
        );

        await app.reloadFromDisk();
        expect(app.tasks.byId('seed_task_0')!.completed, isTrue);
        expect(notifications.scheduled, isNot(contains('seed_task_0')));
        expect(
          notifications.lockScreen!.tasks.map((t) => t.id),
          isNot(contains('seed_task_0')),
        );
      },
    );

    test('Add task and Snooze from a notification', () async {
      final store = MemoryDocumentStore();
      final notifications = NoopNotificationService();
      final app = await loadApp(store: store, notifications: notifications);
      await app.flush();

      await handleNotificationAction(
        store: store,
        notifications: notifications,
        actionId: NotificationActions.addTask,
        payload: null,
        input: 'Buy stamps',
        clock: () => testNow,
      );
      await handleNotificationAction(
        store: store,
        notifications: notifications,
        actionId: NotificationActions.snooze,
        payload: const NotificationTarget(
          NotificationTarget.event,
          'seed_event_2',
        ).encode(),
        clock: () => testNow,
      );

      await app.reloadFromDisk();
      final added = app.tasks.items.firstWhere((t) => t.title == 'Buy stamps');
      expect(added.isDueOn(testToday), isTrue);
      expect(notifications.snoozed, ['seed_event_2']);
    });

    test('reminder times', () {
      final task = Task(
        id: 't',
        title: 'x',
        dueDate: testToday,
        dueTime: 10 * 60,
        reminderMinutes: 15,
        createdAt: testNow,
      );
      expect(taskReminderTime(task, testNow), DateTime(2026, 10, 5, 9, 45));
      task.completed = true;
      expect(taskReminderTime(task, testNow), isNull);

      final soon = _event('e', DateTime(2026, 10, 5, 9, 50), reminder: 15);
      expect(eventReminderTime(soon, testNow), isNull, reason: 'already past');
      expect(dayKey(testNow), '2026-10-05');
    });
  });
}
