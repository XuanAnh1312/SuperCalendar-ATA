import 'dart:convert';

import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

/// What a notification points at; carried as its payload.
class NotificationTarget {
  const NotificationTarget(this.type, this.id, {this.snoozed = false});

  static const task = 'task';
  static const event = 'event';
  static const lockScreen = 'lock';

  final String type;
  final String id;

  /// True for a reminder the user postponed; a reminder sync leaves it alone.
  final bool snoozed;

  String encode() =>
      jsonEncode({'type': type, 'id': id, if (snoozed) 'snoozed': true});

  static NotificationTarget? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      return NotificationTarget(
        json['type'] as String,
        json['id'] as String,
        snoozed: json['snoozed'] as bool? ?? false,
      );
    } on Object {
      return null;
    }
  }
}

/// Ids of the notification action buttons.
abstract final class NotificationActions {
  static const done = 'done';
  static const snooze = 'snooze';
  static const addTask = 'add_task';
}

/// Data for the persistent lock screen notification.
class LockScreenContent {
  const LockScreenContent({
    required this.events,
    required this.tasks,
    required this.day,
  });

  final List<CalendarEvent> events;

  /// Incomplete tasks, most relevant first.
  final List<Task> tasks;
  final DateTime day;
}

/// Reminders and the lock screen notification. The Android implementation is
/// `LocalNotificationService`; tests use [NoopNotificationService].
abstract class NotificationService {
  /// Prepares the plugin. [onOpen] runs when the user taps a notification
  /// while the app is alive; [onDataChanged] when a notification action
  /// (Done, Add task) changed the database behind the UI's back.
  Future<void> init({
    void Function(NotificationTarget target)? onOpen,
    void Function()? onDataChanged,
  });

  /// The notification that launched the app, if any.
  Future<NotificationTarget?> launchTarget();

  Future<bool> hasPermission();

  /// Shows the system permission prompt (Android 13+).
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with the ones due after [now].
  Future<void> syncReminders({
    required List<Task> tasks,
    required List<CalendarEvent> events,
    required DateTime now,
  });

  Future<void> cancelReminders();

  /// Fires a task reminder right away (Settings → Notifications → test).
  Future<void> showTaskReminder(Task task);

  /// Shows the reminder for [task] again after [delay].
  Future<void> snoozeTask(Task task, Duration delay);

  /// Shows the reminder for [event] again after [delay].
  Future<void> snoozeEvent(CalendarEvent event, Duration delay);

  Future<void> showLockScreen(LockScreenContent content);

  Future<void> hideLockScreen();
}

/// Does nothing but remember what it was asked to do.
class NoopNotificationService implements NotificationService {
  NoopNotificationService({this.permissionGranted = true});

  bool permissionGranted;
  int permissionRequests = 0;
  int syncCount = 0;
  List<String> scheduled = [];
  LockScreenContent? lockScreen;
  final List<Task> shownReminders = [];

  final List<String> snoozed = [];

  @override
  Future<void> init({
    void Function(NotificationTarget target)? onOpen,
    void Function()? onDataChanged,
  }) async {}

  @override
  Future<void> snoozeTask(Task task, Duration delay) async =>
      snoozed.add(task.id);

  @override
  Future<void> snoozeEvent(CalendarEvent event, Duration delay) async =>
      snoozed.add(event.id);

  @override
  Future<NotificationTarget?> launchTarget() async => null;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> syncReminders({
    required List<Task> tasks,
    required List<CalendarEvent> events,
    required DateTime now,
  }) async {
    syncCount++;
    scheduled = [
      for (final task in tasks)
        if (taskReminderTime(task, now) != null) task.id,
      for (final event in events)
        if (eventReminderTime(event, now) != null) event.id,
    ];
  }

  @override
  Future<void> cancelReminders() async => scheduled = [];

  @override
  Future<void> showTaskReminder(Task task) async => shownReminders.add(task);

  @override
  Future<void> showLockScreen(LockScreenContent content) async =>
      lockScreen = content;

  @override
  Future<void> hideLockScreen() async => lockScreen = null;
}

/// When to remind about [task]; null if it has no future reminder.
DateTime? taskReminderTime(Task task, DateTime now) {
  final due = task.dueAt;
  final minutes = task.reminderMinutes;
  if (task.completed || due == null || minutes == null) return null;
  final at = due.subtract(Duration(minutes: minutes));
  return at.isAfter(now) ? at : null;
}

/// When to remind about [event]; null if it has no future reminder.
DateTime? eventReminderTime(CalendarEvent event, DateTime now) {
  final minutes = event.reminderMinutes;
  if (minutes == null) return null;
  final at = event.startTime.subtract(Duration(minutes: minutes));
  return at.isAfter(now) ? at : null;
}
