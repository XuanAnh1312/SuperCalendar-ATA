import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/ios_notification_configuration.dart';
import 'package:flutter_application/core/services/local_notification_service.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/wallpaper_service.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late MemoryDocumentStore store;
  late LocalNotificationService notifications;
  late List<MethodCall> calls;
  var granted = true;
  var active = <Map<String, Object?>>[];
  final today = DateTime.now();
  final now = DateTime(today.year, today.month, today.day + 1, 9);

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    active = [];
    granted = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' || 'requestPermissions' => granted,
            'checkPermissions' => {'isEnabled': granted},
            'pendingNotificationRequests' => <Object>[],
            'getActiveNotifications' => active,
            _ => null,
          };
        });
    store = MemoryDocumentStore();
    await store.put(
      Collections.settings,
      AppSettings.id,
      AppSettings(
        seeded: true,
        notificationsEnabled: true,
        quickNoteNotification: true,
      ).toJson(),
    );
    notifications = LocalNotificationService(store: store, clock: () => now);
    await notifications.init();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  test(
    'iOS asks notification permission only when explicitly requested',
    () async {
      final config = iosNotificationConfiguration();
      expect(config.requestAlertPermission, isFalse);
      expect(config.requestSoundPermission, isFalse);
      expect(await notifications.hasPermission(), isTrue);
      expect(calls.where((c) => c.method == 'requestPermissions'), isEmpty);
      granted = false;
      expect(await notifications.hasPermission(), isFalse);
      expect(await notifications.requestPermission(), isFalse);
    },
  );

  test('iOS Quick Note has text input and Open app; Schedule requires authentication', () {
    final categories = iosNotificationConfiguration().notificationCategories;
    final note = categories.singleWhere((c) => c.identifier == 'quick_note');
    final save = note.actions.singleWhere(
      (a) => a.identifier == NotificationActions.saveNote,
    );
    expect(save.type.name, 'text');
    expect(
      note.actions
          .singleWhere((a) => a.identifier == NotificationActions.openApp)
          .options,
      contains(DarwinNotificationActionOption.foreground),
    );
    for (final category in categories.where(
      (c) => c.identifier.startsWith('schedule'),
    )) {
      final action = category.actions.singleWhere(
        (a) => a.identifier == NotificationActions.schedule,
      );
      expect(
        action.options,
        containsAll([
          DarwinNotificationActionOption.foreground,
          DarwinNotificationActionOption.authenticationRequired,
        ]),
      );
    }
    final habit = categories.singleWhere(
      (c) => c.identifier == 'habit_reminder',
    );
    expect(
      habit.actions.map((a) => a.identifier),
      containsAll([NotificationActions.snooze, NotificationActions.skip]),
    );
  });

  test('iOS Quick Note posts with the registered category and denied permission hides it', () async {
    await notifications.showQuickNoteNotification('Hello iPhone');
    final show = calls.lastWhere((c) => c.method == 'show').arguments as Map;
    expect(
      (show['platformSpecifics'] as Map)['categoryIdentifier'],
      'quick_note',
    );
    final before = calls.where((c) => c.method == 'show').length;
    granted = false;
    await notifications.showQuickNoteNotification('Do not post');
    expect(calls.where((c) => c.method == 'show').length, before);
  });

  test('iOS limits pending reminders and removes delivered reminders through payload', () async {
    final tasks = [
      for (var i = 0; i < 70; i++)
        Task(
          id: 'ios-$i',
          title: 'Task $i',
          createdAt: now,
          dueDate: now,
          dueTime: 600 + i,
          reminderMinutes: 0,
        ),
    ];
    active = [
      {
        'id': 76543,
        'payload': const NotificationTarget(
          NotificationTarget.task,
          'deleted-task',
        ).encode(),
      },
    ];
    await notifications.syncReminders(tasks: tasks, events: [], now: now);
    final scheduled = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(scheduled, hasLength(62));
    expect(
      (scheduled.first.arguments as Map)['platformSpecifics'],
      containsPair('categoryIdentifier', 'task_reminder'),
    );
    expect(
      calls
          .where((c) => c.method == 'cancel')
          .map(
            (c) =>
                c.arguments is int ? c.arguments : (c.arguments as Map)['id'],
          ),
      contains(76543),
    );
  });

  test('iPhone exports wallpaper for manual setup, Android retains automatic setup', () {
    expect(requiresManualWallpaperSetup, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(requiresManualWallpaperSetup, isFalse);
  });
}
