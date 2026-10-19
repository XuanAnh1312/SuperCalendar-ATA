import 'dart:convert';

import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

/// What a notification points at; carried as its payload.
class NotificationTarget {
  const NotificationTarget(this.type, this.id, {this.snoozed = false});

  static const task = 'task';
  static const event = 'event';
  static const habit = 'habit';
  static const lockScreen = 'lock';
  static const quickNote = 'quick_note';

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
  static const saveNote = 'save_note';
  static const openApp = 'open_app';
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
  ///
  /// When [habits] is provided, habit reminders are also scheduled (FR-18).
  Future<void> syncReminders({
    required List<Task> tasks,
    required List<CalendarEvent> events,
    required DateTime now,
    List<Habit> habits,
  });

  Future<void> cancelReminders();

  // ── Individual scheduling (FR-18) ──────────────────────────────────────────

  /// Schedules a reminder for [event] based on its [CalendarEvent.reminderMinutes].
  /// Returns the scheduled time, or null when there is no future reminder.
  Future<DateTime?> scheduleForEvent(CalendarEvent event);

  /// Schedules a reminder for [task] based on its [Task.reminderMinutes].
  /// Returns the scheduled time, or null when there is no future reminder.
  Future<DateTime?> scheduleForTask(Task task);

  /// Schedules a reminder for [habit] based on its [Habit.reminderMinutes]
  /// and [Habit.time].  Returns the scheduled time, or null when there is no
  /// future reminder (FR-18).
  Future<DateTime?> scheduleForHabit(Habit habit);

  /// Cancels a scheduled reminder for the given [sourceType] and [sourceId].
  Future<void> cancel(String sourceType, String sourceId);

  // ── Immediate reminders (test / snooze) ────────────────────────────────────

  /// Fires a task reminder right away (Settings → Notifications → test).
  Future<void> showTaskReminder(Task task);

  /// Shows the reminder for [task] again after [delay].
  Future<void> snoozeTask(Task task, Duration delay);

  /// Shows the reminder for [event] again after [delay].
  Future<void> snoozeEvent(CalendarEvent event, Duration delay);

  // ── Lock screen ────────────────────────────────────────────────────────────

  Future<void> showLockScreen(LockScreenContent content);

  Future<void> hideLockScreen();

  // ── Quick Note notification (FR-20) ────────────────────────────────────────

  /// Shows or updates the ongoing Quick Note notification with [text] as the
  /// current content (FR-20.01, FR-20.02).
  ///
  /// The notification includes a RemoteInput text field and Save / Open app
  /// action buttons (FR-20.02, FR-20.03).
  Future<void> showQuickNoteNotification(String text);

  /// Hides the Quick Note notification (when the user disables the setting).
  Future<void> hideQuickNoteNotification();
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

  // Quick Note notification tracking
  String? quickNoteText;
  bool quickNoteHidden = false;

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
    List<Habit> habits = const [],
  }) async {
    syncCount++;
    scheduled = [
      for (final task in tasks)
        if (taskReminderTime(task, now) != null) task.id,
      for (final event in events)
        if (eventReminderTime(event, now) != null) event.id,
      for (final habit in habits)
        if (habitReminderTime(habit, now) != null) habit.id,
    ];
  }

  @override
  Future<void> cancelReminders() async => scheduled = [];

  @override
  Future<DateTime?> scheduleForEvent(CalendarEvent event) async =>
      eventReminderTime(event, DateTime.now());

  @override
  Future<DateTime?> scheduleForTask(Task task) async =>
      taskReminderTime(task, DateTime.now());

  @override
  Future<DateTime?> scheduleForHabit(Habit habit) async =>
      habitReminderTime(habit, DateTime.now());

  @override
  Future<void> cancel(String sourceType, String sourceId) async {
    scheduled.removeWhere((id) => id == sourceId);
  }

  @override
  Future<void> showTaskReminder(Task task) async => shownReminders.add(task);

  @override
  Future<void> showLockScreen(LockScreenContent content) async =>
      lockScreen = content;

  @override
  Future<void> hideLockScreen() async => lockScreen = null;

  @override
  Future<void> showQuickNoteNotification(String text) async {
    quickNoteText = text;
    quickNoteHidden = false;
  }

  @override
  Future<void> hideQuickNoteNotification() async => quickNoteHidden = true;
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

/// When to remind about [habit] today; null if it has no reminder configured,
/// no preferred time, or the reminder time has already passed today (FR-18).
DateTime? habitReminderTime(Habit habit, DateTime now) {
  final minutes = habit.reminderMinutes;
  final habitTime = habit.time;
  if (minutes == null || habitTime == null) return null;
  if (habit.isArchived) return null;

  final today = DateTime(now.year, now.month, now.day);
  final at = today.add(Duration(minutes: habitTime - minutes));
  return at.isAfter(now) ? at : null;
}
