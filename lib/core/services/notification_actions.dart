import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/features/calendar/domain/calendar_visibility.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/data/habit_repository.dart';
import 'package:flutter_application/features/note/data/note_repository.dart';
import 'package:flutter_application/features/settings_screen/data/user_repository.dart';
import 'package:flutter_application/features/todo/data/task_repository.dart';

/// How long "Snooze" postpones a reminder.
const snoozeDelay = Duration(minutes: 10);

/// Applies a notification action button to the database.
///
/// This runs without the UI (the user may be on the lock screen), so it works
/// straight on the [store] the app itself uses: `Done` completes the task,
/// `Snooze` re-schedules the reminder, `Add task` creates a task from the
/// typed [input], `Save note` updates the Quick Note (AC-39).
/// Returns true when it changed stored data.
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
  // Runs outside the UI, so pick up the user's language here too.
  final account = UserRepository(store, clock: now);
  await account.load();
  AppStrings.vi = account.settings.language == AppStrings.vietnamese;
  // Quick capture only needs the note and settings. Avoid refreshing every
  // reminder from the background callback when a note is saved.
  if (actionId == NotificationActions.saveNote) {
    if (input == null || input.trim().isEmpty) return false;
    final notes = NoteRepository(store, clock: now);
    try {
      await notes.load();
      if (!notes.captureQuick(
        input,
        append: account.settings.quickNoteAppend,
      )) {
        return false;
      }
      await notes.flush();
      await notifications.showQuickNoteNotification(
        account.settings.lockScreenHideDetails ? '' : notes.quickText,
      );
      return true;
    } finally {
      notes.dispose();
    }
  }
  final tasks = TaskRepository(store, clock: now);
  await tasks.load();
  var changed = false;

  switch (actionId) {
    case NotificationActions.done:
      final task =
          target == null ||
              (target.type != NotificationTarget.task &&
                  target.type != NotificationTarget.lockScreen)
          ? null
          : tasks.byId(target.id);
      if (task != null && !task.completed) {
        tasks.setCompleted(task, true);
        await notifications.cancel(NotificationTarget.task, task.id);
        changed = true;
      }
    case NotificationActions.addTask:
      changed =
          tasks.add(
            input ?? '',
            dueDate: dateOnly(now()),
            priority: account.settings.defaultPriority,
            reminderMinutes: account.settings.taskReminderMinutes ?? 0,
          ) !=
          null;
    case NotificationActions.skip:
      if (target?.type != NotificationTarget.habit) break;
      final day = target?.occurrenceDate ?? now();
      final occurrences = HabitOccurrenceRepository(store);
      await occurrences.load();
      final habits = HabitRepository(store, occurrences: occurrences);
      await habits.load();
      final habit = habits.byId(target!.id);
      if (habit != null &&
          habitOccursOn(
            habit,
            day,
            ReminderContext(
              settings: account.settings,
              habitOccurrences: occurrences.items,
            ),
          )) {
        habits.skip(habit, day);
        await occurrences.flush();
        changed = true;
      }
    case NotificationActions.snooze:
      if (target == null) break;
      if ((target.type == NotificationTarget.task &&
              !account.settings.taskReminders) ||
          (target.type == NotificationTarget.event &&
              !account.settings.eventReminders) ||
          (target.type == NotificationTarget.habit &&
              !account.settings.habitReminders)) {
        break;
      }
      if (target.type == NotificationTarget.event) {
        final exceptions = EventExceptionRepository(store);
        await exceptions.load();
        final events = EventRepository(store, exceptions: exceptions);
        await events.load();
        final root = events.byId(target.id);
        final event = root?.resolvedOccurrenceOn(
          target.occurrenceDate ?? (root.isRecurring ? now() : root.startTime),
        );
        if (event != null &&
            event.endTime.isAfter(now()) &&
            (target.occurrenceStart == null ||
                target.occurrenceStart!.isAtSameMomentAs(event.startTime))) {
          await notifications.snoozeEvent(
            event,
            snoozeDelay,
            reminderLead: target.reminderLead,
          );
        }
      } else if (target.type == NotificationTarget.habit) {
        final day = target.occurrenceDate ?? now();
        if (dateOnly(day).isBefore(dateOnly(now()))) break;
        final occurrences = HabitOccurrenceRepository(store);
        await occurrences.load();
        final habits = HabitRepository(store, occurrences: occurrences);
        await habits.load();
        final habit = habits.byId(target.id);
        if (habit != null &&
            habits.occurrences(day).contains(habit) &&
            !habits.isDone(habit, day) &&
            !habits.isSkipped(habit, day)) {
          final context = ReminderContext(
            settings: account.settings,
            habitOccurrences: occurrences.items,
          );
          if (habitOccursOn(habit, day, context)) {
            await notifications.snoozeHabit(
              effectiveHabit(habit, day, context),
              snoozeDelay,
              occurrenceDay: day,
            );
          }
        }
      } else {
        final task = tasks.byId(target.id);
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
  AppStrings.vi = account.settings.language == AppStrings.vietnamese;
  if (!account.settings.notificationsEnabled) {
    await notifications.cancelReminders();
    await notifications.hideLockScreen();
    await notifications.hideQuickNoteNotification();
    return;
  }
  final exceptions = EventExceptionRepository(store);
  await exceptions.load();
  final events = EventRepository(store, exceptions: exceptions);
  await events.load();
  final occurrences = HabitOccurrenceRepository(store);
  await occurrences.load();
  final habits = HabitRepository(store, occurrences: occurrences);
  await habits.load();
  if (notifications case final ReminderContextConsumer consumer) {
    consumer.updateReminderContext(
      ReminderContext(
        settings: account.settings,
        habitOccurrences: occurrences.items,
      ),
    );
  }
  await notifications.syncReminders(
    tasks: account.settings.taskReminders ? tasks.items : const [],
    events: account.settings.eventReminders ? events.items : const [],
    now: now(),
    habits: account.settings.habitReminders ? habits.active : const [],
  );
  if (account.settings.lockScreenEnabled) {
    final today = dateOnly(now());
    await notifications.showLockScreen(
      LockScreenContent(
        events: visibleEventsOn(events.on(today), account.settings),
        tasks: tasks.pending(today),
        day: today,
        hideDetails: account.settings.lockScreenHideDetails,
      ),
    );
  } else {
    await notifications.hideLockScreen();
  }
  if (account.settings.quickNoteNotification) {
    final notes = NoteRepository(store);
    await notes.load();
    await notifications.showQuickNoteNotification(notes.quickText);
  } else {
    await notifications.hideQuickNoteNotification();
  }
}
