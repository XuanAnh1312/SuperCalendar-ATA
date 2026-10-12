import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_application/core/data/sqlite_document_store.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

/// Port the UI isolate listens on to learn that a notification action changed
/// the database from the background isolate.
const _refreshPortName = 'supercalendar_data_changed';

/// Entry point for notification action buttons. Android runs it in a separate
/// isolate, with or without the app's UI alive.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  unawaited(_handleBackgroundResponse(response));
}

Future<void> _handleBackgroundResponse(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final notifications = LocalNotificationService();
  await notifications.init();
  // The database connection is shared with the UI isolate's process, so it
  // is intentionally left open here.
  final store = await SqliteDocumentStore.open();
  final changed = await handleNotificationAction(
    store: store,
    notifications: notifications,
    actionId: response.actionId,
    payload: response.payload,
    input: response.input,
  );
  if (changed) {
    IsolateNameServer.lookupPortByName(_refreshPortName)?.send(true);
  }
}

/// Android notifications: reminders with Done / Snooze, and the persistent
/// lock screen notification with today's schedule and to-do quick actions.
class LocalNotificationService implements NotificationService {
  static const _lockScreenId = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  ReceivePort? _refreshPort;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({
    void Function(NotificationTarget target)? onOpen,
    void Function()? onDataChanged,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final target = NotificationTarget.decode(response.payload);
        if (target != null) onOpen?.call(target);
      },
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
    if (onDataChanged != null) {
      IsolateNameServer.removePortNameMapping(_refreshPortName);
      _refreshPort = ReceivePort()..listen((_) => onDataChanged());
      IsolateNameServer.registerPortWithName(
        _refreshPort!.sendPort,
        _refreshPortName,
      );
    }
  }

  @override
  Future<NotificationTarget?> launchTarget() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return NotificationTarget.decode(details.notificationResponse?.payload);
  }

  @override
  Future<bool> hasPermission() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  // ---- Reminders ----------------------------------------------------------

  NotificationDetails _reminderDetails({required bool task}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Event and task reminders',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        actions: [
          if (task)
            const AndroidNotificationAction(NotificationActions.done, 'Done'),
          const AndroidNotificationAction(NotificationActions.snooze, 'Snooze'),
        ],
      ),
    );
  }

  String _taskBody(Task task) => [
    task.title,
    if (task.dueTime != null) formatClock(task.dueTime!),
  ].join(' · ');

  String _eventBody(CalendarEvent event) => [
    event.title,
    event.startLabel,
    if (event.location.isNotEmpty) event.location,
  ].join(' · ');

  @override
  Future<void> syncReminders({
    required List<Task> tasks,
    required List<CalendarEvent> events,
    required DateTime now,
  }) async {
    // Drop what was scheduled before, except reminders the user snoozed.
    for (final pending in await _plugin.pendingNotificationRequests()) {
      final target = NotificationTarget.decode(pending.payload);
      if (target == null || !target.snoozed) {
        await _plugin.cancel(id: pending.id);
      }
    }
    for (final task in tasks) {
      final at = taskReminderTime(task, now);
      if (at == null) continue;
      await _schedule(
        id: _stableId('task:${task.id}'),
        at: at,
        title: 'Task reminder',
        body: _taskBody(task),
        target: NotificationTarget(NotificationTarget.task, task.id),
        details: _reminderDetails(task: true),
      );
    }
    for (final event in events) {
      final at = eventReminderTime(event, now);
      if (at == null) continue;
      await _schedule(
        id: _stableId('event:${event.id}'),
        at: at,
        title: 'Upcoming event',
        body: _eventBody(event),
        target: NotificationTarget(NotificationTarget.event, event.id),
        details: _reminderDetails(task: false),
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required NotificationTarget target,
    required NotificationDetails details,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // An absolute instant, so no time zone database is needed.
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: details,
      // Inexact alarms need no special permission; Android may deliver them
      // a few minutes late while the phone is idle.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: target.encode(),
    );
  }

  @override
  Future<void> cancelReminders() => _plugin.cancelAllPendingNotifications();

  @override
  Future<void> showTaskReminder(Task task) {
    return _plugin.show(
      id: _stableId('task:${task.id}'),
      title: 'Task reminder',
      body: _taskBody(task),
      notificationDetails: _reminderDetails(task: true),
      payload: NotificationTarget(NotificationTarget.task, task.id).encode(),
    );
  }

  @override
  Future<void> snoozeTask(Task task, Duration delay) {
    return _schedule(
      id: _stableId('snooze:task:${task.id}'),
      at: DateTime.now().add(delay),
      title: 'Task reminder',
      body: _taskBody(task),
      target: NotificationTarget(
        NotificationTarget.task,
        task.id,
        snoozed: true,
      ),
      details: _reminderDetails(task: true),
    );
  }

  @override
  Future<void> snoozeEvent(CalendarEvent event, Duration delay) {
    return _schedule(
      id: _stableId('snooze:event:${event.id}'),
      at: DateTime.now().add(delay),
      title: 'Upcoming event',
      body: _eventBody(event),
      target: NotificationTarget(
        NotificationTarget.event,
        event.id,
        snoozed: true,
      ),
      details: _reminderDetails(task: false),
    );
  }

  // ---- Lock screen --------------------------------------------------------

  @override
  Future<void> showLockScreen(LockScreenContent content) {
    final events = content.events;
    final tasks = content.tasks;
    final next = tasks.firstOrNull;
    final lines = [
      for (final event in events) '${event.startLabel}  ${event.title}',
      if (events.isEmpty) 'Nothing scheduled today',
      for (final task in tasks) '☐ ${task.title}',
    ];
    final summary = [
      '${events.length} event${events.length == 1 ? '' : 's'}',
      '${tasks.length} to-do${tasks.length == 1 ? '' : 's'}',
    ].join(' · ');
    return _plugin.show(
      id: _lockScreenId,
      title: shortDate(content.day),
      body: summary,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'lock_screen',
          'Lock screen',
          channelDescription: "Today's schedule and to-do on the lock screen",
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          // Public: the content is shown without unlocking the phone.
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: false,
          styleInformation: InboxStyleInformation(
            lines,
            contentTitle: shortDate(content.day),
            summaryText: summary,
          ),
          actions: [
            if (next != null)
              AndroidNotificationAction(
                NotificationActions.done,
                '✓ ${next.title}',
                cancelNotification: false,
              ),
            const AndroidNotificationAction(
              NotificationActions.addTask,
              'Add task',
              cancelNotification: false,
              inputs: [AndroidNotificationActionInput(label: 'New task')],
            ),
          ],
        ),
      ),
      // The Done action completes the task named in the payload.
      payload: NotificationTarget(
        NotificationTarget.lockScreen,
        next?.id ?? '',
      ).encode(),
    );
  }

  @override
  Future<void> hideLockScreen() => _plugin.cancel(id: _lockScreenId);

  /// FNV-1a hash: `String.hashCode` differs between isolates, and the id has
  /// to match when a reminder is rescheduled or cancelled later.
  int _stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    // Keep clear of the fixed lock screen id.
    return hash < 100 ? hash + 100 : hash;
  }
}
