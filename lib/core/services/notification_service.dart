import 'notification_payload.dart';
import 'reminder_plan.dart';

export 'notification_payload.dart';
export 'reminder_plan.dart';

import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

/// Data for the persistent lock screen notification.
class LockScreenContent {
  const LockScreenContent({
    required this.events,
    required this.tasks,
    required this.day,
    this.hideDetails = false,
  });

  final List<CalendarEvent> events;

  /// AC-38: show only how many events and to-dos there are.
  final bool hideDetails;

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

  Future<void> snoozeHabit(Habit habit, Duration delay);

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
class NoopNotificationService
    implements NotificationService, ReminderContextConsumer {
  ReminderContext _context = ReminderContext();
  @override
  void updateReminderContext(ReminderContext context) => _context = context;
  final Map<String, NotificationTarget> pendingSnoozes = {};
  NoopNotificationService({this.permissionGranted = true});

  bool permissionGranted;
  int permissionRequests = 0;
  int syncCount = 0;
  List<String> scheduled = [];
  LockScreenContent? lockScreen;
  final List<Task> shownReminders = [];
  final List<String> snoozed = [];
  final Map<String, Duration> snoozeDelays = {};

  @override
  Future<void> snoozeHabit(Habit habit, Duration delay) async {
    snoozed.add(habit.id);
    snoozeDelays[habit.id] = delay;
    pendingSnoozes['habit:${habit.id}'] = NotificationTarget(
      NotificationTarget.habit,
      habit.id,
      snoozed: true,
    );
  }

  // Quick Note notification tracking
  String? quickNoteText;
  bool quickNoteHidden = false;

  @override
  Future<void> init({
    void Function(NotificationTarget target)? onOpen,
    void Function()? onDataChanged,
  }) async {}

  @override
  Future<void> snoozeTask(Task task, Duration delay) async {
    snoozed.add(task.id);
    snoozeDelays[task.id] = delay;
    pendingSnoozes['task:${task.id}'] = NotificationTarget(
      NotificationTarget.task,
      task.id,
      snoozed: true,
    );
  }

  @override
  Future<void> snoozeEvent(CalendarEvent event, Duration delay) async {
    snoozed.add(event.id);
    snoozeDelays[event.id] = delay;
    pendingSnoozes['event:${event.id}'] = NotificationTarget(
      NotificationTarget.event,
      event.id,
      snoozed: true,
      occurrenceDate: event.originalOccurrenceDate,
      occurrenceStart: event.startTime,
    );
  }

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
    final plan = buildReminderPlan(
      tasks: tasks,
      events: events,
      habits: habits,
      now: now,
      context: _context,
    );
    pendingSnoozes.removeWhere(
      (_, target) => !reminderTargetIsValid(
        target,
        tasks: tasks,
        events: events,
        habits: habits,
        now: now,
        context: _context,
      ),
    );
    scheduled = [
      for (final entry in plan)
        if (!pendingSnoozes.containsKey(entry.sourceKey)) entry.target.id,
      for (final target in pendingSnoozes.values) target.id,
    ];
  }

  @override
  Future<void> cancelReminders() async {
    scheduled = [];
    pendingSnoozes.clear();
  }

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
    pendingSnoozes.remove("$sourceType:$sourceId");
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
