import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/settings_screen/data/user_repository.dart';
import 'package:flutter_application/features/todo/data/task_repository.dart';

/// How long "Snooze" postpones a reminder.
const snoozeDelay = Duration(minutes: 10);

/// Applies a notification action button to the database.
///
/// This runs without the UI (the user may be on the lock screen), so it works
/// straight on the [store] the app itself uses: `Done` completes the task,
/// `Snooze` re-schedules the reminder, `Add task` creates a task from the
/// typed [input]. Returns true when it changed stored data.
Future<bool> handleNotificationAction({
  required DocumentStore store,
  required NotificationService notifications,
  required String? actionId,
  required String? payload,
  String? input,
  DateTime Function()? clock,
}) async {
  final now = clock ?? DateTime.now;
  final target = NotificationTarget.decode(payload);
  final tasks = TaskRepository(store, clock: now);
  await tasks.load();
  var changed = false;

  switch (actionId) {
    case NotificationActions.done:
      final task = target == null ? null : tasks.byId(target.id);
      if (task != null && !task.completed) {
        tasks.setCompleted(task, true);
        changed = true;
      }
    case NotificationActions.addTask:
      changed = tasks.add(input ?? '', dueDate: dateOnly(now())) != null;
    case NotificationActions.snooze:
      if (target?.type == NotificationTarget.event) {
        final events = EventRepository(store);
        await events.load();
        final event = events.byId(target!.id);
        if (event != null) await notifications.snoozeEvent(event, snoozeDelay);
      } else {
        final task = target == null ? null : tasks.byId(target.id);
        if (task != null && !task.completed) {
          await notifications.snoozeTask(task, snoozeDelay);
        }
      }
  }
  await tasks.flush();

  if (changed) await _refreshNotifications(store, notifications, tasks, now);
  return changed;
}

/// Brings the scheduled reminders and the lock screen notification in line
/// with the data that was just changed.
Future<void> _refreshNotifications(
  DocumentStore store,
  NotificationService notifications,
  TaskRepository tasks,
  DateTime Function() now,
) async {
  final account = UserRepository(store, clock: now);
  await account.load();
  if (!account.settings.notificationsEnabled) return;
  final events = EventRepository(store);
  await events.load();
  await notifications.syncReminders(
    tasks: tasks.items,
    events: events.items,
    now: now(),
  );
  if (account.settings.lockScreenEnabled) {
    final today = dateOnly(now());
    await notifications.showLockScreen(
      LockScreenContent(
        events: events.on(today),
        tasks: tasks.pending(today),
        day: today,
      ),
    );
  }
}
