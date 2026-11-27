import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

import 'notification_payload.dart';

import 'package:flutter_application/core/utils/date_formatter.dart';

abstract interface class ReminderContextConsumer {
  void updateReminderContext(ReminderContext context);
}

class ReminderContext {
  ReminderContext({
    AppSettings? settings,
    List<HabitOccurrence> habitOccurrences = const [],
  }) : settings = settings == null
           ? AppSettings(notificationsEnabled: true)
           : AppSettings.fromJson(settings.toJson()),
       habitOccurrences = [
         for (final o in habitOccurrences) HabitOccurrence.fromJson(o.toJson()),
       ];

  final AppSettings settings;
  final List<HabitOccurrence> habitOccurrences;

  bool enabled(String type) =>
      settings.notificationsEnabled &&
      switch (type) {
        NotificationTarget.task => settings.taskReminders,
        NotificationTarget.event => settings.eventReminders,
        NotificationTarget.habit => settings.habitReminders,
        _ => false,
      };

  HabitOccurrence? occurrence(Habit h, DateTime day) => habitOccurrences
      .where((o) => o.habitId == h.id && sameDay(o.date, day))
      .firstOrNull;
}

class ReminderPlanEntry {
  const ReminderPlanEntry({
    required this.target,
    required this.at,
    this.task,
    this.event,
    this.habit,
    this.expiresAt,
  });
  final NotificationTarget target;
  final DateTime at;
  final DateTime? expiresAt;
  final Task? task;
  final CalendarEvent? event;
  final Habit? habit;
  String get reminderKey => reminderKeyFor(target);
}

/// Alarm and Snooze share the same identity for one occurrence and lead time.
String reminderKeyFor(NotificationTarget target) {
  final day = target.occurrenceDate;
  final lead = target.reminderLead;
  return [
    target.type,
    target.id,
    if (day != null && target.type != NotificationTarget.task) dayKey(day),
    if (lead != null) 'lead:$lead',
  ].join(':');
}

const reminderPlanningDays = 14;
const _reminderFallbackDays = 366;

DateTime? taskReminderTime(Task task, DateTime now) {
  final due = task.dueAt;
  final minutes = task.reminderMinutes;
  if (task.completed || due == null || minutes == null) return null;
  final at = due.subtract(Duration(minutes: minutes));
  return at.isAfter(now) ? at : null;
}

CalendarEvent? eventReminderOccurrence(
  CalendarEvent event,
  DateTime now, {
  int? lead,
}) {
  CalendarEvent? best;
  DateTime? bestTime;
  void consider(CalendarEvent? candidate) {
    if (candidate == null || candidate.reminderLeadTimes.isEmpty) return;
    if (lead != null && !candidate.reminderLeadTimes.contains(lead)) return;
    final at = candidate.startTime.subtract(
      Duration(minutes: lead ?? candidate.reminderLeadTimes.first),
    );
    if (at.isAfter(now) && (bestTime == null || at.isBefore(bestTime!))) {
      best = candidate;
      bestTime = at;
    }
  }

  // Include exceptions moved from a past original date into the future.
  for (final override in event.overrideResolver?.call() ?? <CalendarEvent>[]) {
    consider(override);
  }
  if (!event.isRecurring) {
    consider(event.resolvedOccurrenceOn(event.startTime));
    return best;
  }
  final from = event.startTime.isAfter(now) ? event.startTime : now;
  for (var i = 0; i <= _reminderFallbackDays; i++) {
    final day = DateTime(from.year, from.month, from.day + i);
    consider(event.resolvedOccurrenceOn(day));
  }
  return best;
}

DateTime? eventReminderTime(CalendarEvent event, DateTime now) {
  DateTime? earliest;
  for (final lead in event.reminderLeadTimes) {
    final occurrence = eventReminderOccurrence(event, now, lead: lead);
    if (occurrence == null) continue;
    final at = occurrence.startTime.subtract(Duration(minutes: lead));
    if (earliest == null || at.isBefore(earliest)) earliest = at;
  }
  return earliest;
}

bool habitOccursOn(Habit habit, DateTime day, [ReminderContext? context]) {
  final date = DateTime(day.year, day.month, day.day);
  final start = DateTime(
    habit.startDate.year,
    habit.startDate.month,
    habit.startDate.day,
  );
  final end = habit.endDate;
  if (habit.isArchived ||
      date.isBefore(start) ||
      (end != null && date.isAfter(DateTime(end.year, end.month, end.day))) ||
      !rruleOccursOn(habit.repeatRule, habit.startDate, date)) {
    return false;
  }
  final occurrence = context?.occurrence(habit, date);
  if (occurrence != null) return occurrence.status == OccurrenceStatus.pending;
  return !habit.isDone(date) &&
      !habit.isSkipped(date) &&
      !habit.isRemoved(date);
}

DateTime? habitReminderTime(Habit habit, DateTime now) {
  if (habit.reminderMinutes == null ||
      habit.time == null ||
      !habitOccursOn(habit, now)) {
    return null;
  }
  final at = DateTime(
    now.year,
    now.month,
    now.day,
    0,
    habit.time!,
  ).subtract(Duration(minutes: habit.reminderMinutes!));
  return at.isAfter(now) ? at : null;
}

Habit effectiveHabit(Habit habit, DateTime day, ReminderContext context) {
  final override = context.occurrence(habit, day)?.overrideData;
  final result = Habit.fromJson(habit.toJson());
  if (override?.containsKey('time') == true) {
    result.time = override!['time'] as int?;
  }
  if (override?.containsKey('reminderMinutes') == true) {
    result.reminderMinutes = override!['reminderMinutes'] as int?;
  }
  if (override?['title'] case final String title) result.title = title;
  result.reminderMinutes ??= context.settings.habitReminderMinutes ?? 0;
  return result;
}

List<ReminderPlanEntry> buildReminderPlan({
  required List<Task> tasks,
  required List<CalendarEvent> events,
  required List<Habit> habits,
  required DateTime now,
  required ReminderContext context,
}) {
  final result = <ReminderPlanEntry>[];
  if (context.enabled(NotificationTarget.task)) {
    for (final task in tasks) {
      final at = taskReminderTime(task, now);
      if (at != null) {
        result.add(
          ReminderPlanEntry(
            at: at,
            task: task,
            target: NotificationTarget(
              NotificationTarget.task,
              task.id,
              occurrenceStart: task.dueAt,
            ),
          ),
        );
      }
    }
  }
  if (context.enabled(NotificationTarget.event)) {
    for (final event in events) {
      final seen = <String>{};
      final plannedLeads = <int>{};
      void addOccurrence(CalendarEvent? occurrence, {int? onlyLead}) {
        if (occurrence == null) return;
        for (final lead in occurrence.reminderLeadTimes) {
          if (onlyLead != null && lead != onlyLead) continue;
          final at = occurrence.startTime.subtract(Duration(minutes: lead));
          if (!at.isAfter(now)) continue;
          final target = NotificationTarget(
            NotificationTarget.event,
            event.id,
            reminderLead: occurrence.reminderOffsets == null ? null : lead,
            occurrenceDate:
                occurrence.originalOccurrenceDate ??
                dateOnly(occurrence.startTime),
            occurrenceStart: occurrence.startTime,
          );
          plannedLeads.add(lead);
          if (!seen.add(reminderKeyFor(target))) continue;
          result.add(
            ReminderPlanEntry(
              at: at,
              event: occurrence,
              expiresAt: occurrence.endTime,
              target: target,
            ),
          );
        }
      }

      final overrides = event.overrideResolver?.call().toList() ?? [];
      for (final occurrence in overrides) {
        addOccurrence(occurrence);
      }
      if (!event.isRecurring) {
        addOccurrence(event.resolvedOccurrenceOn(event.startTime));
        continue;
      }
      final first = event.startTime.isAfter(now) ? event.startTime : now;
      for (var offset = 0; offset < reminderPlanningDays; offset++) {
        addOccurrence(
          event.resolvedOccurrenceOn(
            DateTime(first.year, first.month, first.day + offset),
          ),
        );
      }
      // Preserve the next notification for sparse recurrence rules, too.
      for (final lead in event.reminderLeadTimes.where(
        (lead) => !plannedLeads.contains(lead),
      )) {
        addOccurrence(
          eventReminderOccurrence(event, now, lead: lead),
          onlyLead: lead,
        );
      }
    }
  }
  if (context.enabled(NotificationTarget.habit)) {
    final today = dateOnly(now);
    final windowEnd = DateTime(
      today.year,
      today.month,
      today.day + reminderPlanningDays,
    );
    for (final habit in habits) {
      if (habit.isArchived ||
          (habit.time == null &&
              !context.habitOccurrences.any(
                (occurrence) =>
                    occurrence.habitId == habit.id &&
                    occurrence.overrideData?['time'] != null,
              ))) {
        continue;
      }
      final startDay = dateOnly(habit.startDate);
      final firstDay = startDay.isAfter(today) ? startDay : today;
      final endDay = habit.endDate == null ? null : dateOnly(habit.endDate!);
      final firstIndex = result.length;
      for (
        var offset = 0;
        offset < reminderPlanningDays + _reminderFallbackDays;
        offset++
      ) {
        final day = DateTime(
          firstDay.year,
          firstDay.month,
          firstDay.day + offset,
        );
        if (endDay != null && day.isAfter(endDay)) break;
        // If the rolling window is empty for this habit, keep its next alarm.
        if (!day.isBefore(windowEnd) && result.length > firstIndex) break;
        if (!habitOccursOn(habit, day, context)) continue;
        final effective = effectiveHabit(habit, day, context);
        if (effective.time == null) continue;
        final start = DateTime(
          day.year,
          day.month,
          day.day,
          0,
          effective.time!,
        );
        final at = start.subtract(
          Duration(minutes: effective.reminderMinutes!),
        );
        if (!at.isAfter(now)) continue;
        result.add(
          ReminderPlanEntry(
            at: at,
            habit: effective,
            expiresAt: DateTime(day.year, day.month, day.day + 1),
            target: NotificationTarget(
              NotificationTarget.habit,
              habit.id,
              occurrenceDate: day,
              occurrenceStart: start,
            ),
          ),
        );
      }
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

bool reminderTargetIsValid(
  NotificationTarget target, {
  required List<Task> tasks,
  required List<CalendarEvent> events,
  required List<Habit> habits,
  required DateTime now,
  required ReminderContext context,
}) {
  if (!context.enabled(target.type)) return false;
  bool sameStart(DateTime? start) =>
      target.occurrenceStart == null ||
      (start != null && target.occurrenceStart!.isAtSameMomentAs(start));
  switch (target.type) {
    case NotificationTarget.task:
      final task = tasks.where((t) => t.id == target.id).firstOrNull;
      return task != null &&
          !task.completed &&
          task.reminderMinutes != null &&
          sameStart(task.dueAt);
    case NotificationTarget.event:
      final event = events.where((e) => e.id == target.id).firstOrNull;
      if (event == null) return false;
      final next = event.resolvedOccurrenceOn(
        target.occurrenceDate ?? (event.isRecurring ? now : event.startTime),
      );
      return next != null &&
          next.reminderLeadTimes.isNotEmpty &&
          (target.reminderLead == null ||
              next.reminderLeadTimes.contains(target.reminderLead)) &&
          next.endTime.isAfter(now) &&
          sameStart(next.startTime);
    case NotificationTarget.habit:
      final habit = habits.where((h) => h.id == target.id).firstOrNull;
      final day = target.occurrenceDate ?? now;
      if (habit == null ||
          !habitOccursOn(habit, day, context) ||
          DateTime(day.year, day.month, day.day + 1).isBefore(now)) {
        return false;
      }
      final effective = effectiveHabit(habit, day, context);
      return effective.time != null &&
          sameStart(DateTime(day.year, day.month, day.day, 0, effective.time!));
    default:
      return false;
  }
}

/// Stable across Dart isolates, with IDs 1 and 2 reserved for ongoing cards.
int reminderNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return hash < 100 ? hash + 100 : hash;
}
