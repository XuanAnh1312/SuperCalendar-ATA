import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// What the lock screen widgets do when touched. Left empty, the widgets are
/// a non-interactive preview.
class LockActions {
  const LockActions({
    this.onOpenEvent,
    this.onToggleTask,
    this.onRemindTask,
    this.onAddTask,
    this.onOpenNote,
  });

  final ValueChanged<CalendarEvent>? onOpenEvent;
  final ValueChanged<Task>? onToggleTask;
  final ValueChanged<Task>? onRemindTask;
  final VoidCallback? onAddTask;
  final VoidCallback? onOpenNote;
}

/// The wallpaper widgets of the Personalize design. They are drawn at the
/// design's size and scaled to their grid cell.
const wallpaperWidgets = [
  WidgetType.week,
  WidgetType.weather,
  WidgetType.quickNote,
  WidgetType.habits,
];

/// The lock screen card for a widget [type]. Types without a lock screen
/// version use the dashboard widget, read-only.
Widget buildLockWidget(
  String type, {
  LockActions actions = const LockActions(),
}) => switch (type) {
  WidgetType.schedule => LockScheduleCard(actions: actions),
  WidgetType.todo => LockTodoCard(actions: actions),
  WidgetType.week => const WallpaperCalendarCard(),
  WidgetType.weather => const WallpaperWeatherCard(),
  WidgetType.quickNote => WallpaperNoteCard(onTap: actions.onOpenNote),
  WidgetType.habits => const WallpaperHabitCard(),
  _ => IgnorePointer(child: buildHomeWidget(type)),
};

/// Translucent rounded card of a wallpaper widget. Content that does not
/// fit a small widget is clipped instead of overflowing.
class _WallpaperCard extends StatelessWidget {
  const _WallpaperCard({required this.color, required this.child, this.onTap});

  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CardTint.fill(context, color),
          border: CardTint.border(context) == null
              ? null
              : Border.all(color: CardTint.border(context)!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: child,
        ),
      ),
    );
  }
}

/// This week with today highlighted and the next event of the day.
class WallpaperCalendarCard extends StatelessWidget {
  const WallpaperCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = app.today;
    final start = app.weekStartOf(today);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    final weeklyEvents = [
      for (final day in days) app.visibleCalendarEventsOn(day),
    ];
    final highlighted = weeklyEvents
        .expand((events) => events)
        .where((event) => event.endTime.isAfter(app.now))
        .firstOrNull;
    Widget cells(List<Widget> children) => Row(
      children: [for (final c in children) Expanded(child: Center(child: c))],
    );
    return _WallpaperCard(
      color: AppColors.surface.withValues(alpha: 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthNames[today.month - 1],
                  style: AppText.s(13, weight: FontWeight.w500),
                ),
              ),
              Text('${today.year}', style: AppText.s(10)),
            ],
          ),
          const SizedBox(height: 9),
          cells([
            for (final day in days)
              Text(
                weekdayLetters[day.weekday - 1],
                style: AppText.s(9, color: AppColors.muted),
              ),
          ]),
          const SizedBox(height: 9),
          cells([
            for (final day in days)
              Text(
                '${day.day}',
                style: sameDay(day, today)
                    ? AppText.s(
                        10,
                        weight: FontWeight.w700,
                        color: AppColors.primary,
                      )
                    : AppText.s(10),
              ),
          ]),
          const SizedBox(height: 5),
          cells([
            for (final events in weeklyEvents)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: events.isEmpty
                      ? Colors.transparent
                      : AppColors.accentSurface(events.first.colorIndex),
                  shape: BoxShape.circle,
                ),
              ),
          ]),
          Text(
            app.settings.lockScreenHideDetails
                ? trf('{n} events today', {
                    'n': app.visibleCalendarEventsOn(today).length,
                  })
                : highlighted == null
                ? tr('No more events this week')
                : '${dayMonth(highlighted.startTime)} · ${highlighted.startLabel} · ${highlighted.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Weather card. The prototype has no internet access (README 10), so it
/// shows clearly labelled sample data.
class WallpaperWeatherCard extends StatelessWidget {
  const WallpaperWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _WallpaperCard(
      color: AppColors.yellow.withValues(alpha: 0.91),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'San Francisco · ${tr('Sample')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(10),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sun, size: 24, color: AppColors.yellowStrong),
                const SizedBox(width: 5),
                Text('18°', style: AppText.s(29, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(tr('Mostly sunny'), style: AppText.s(10)),
          const SizedBox(height: 6),
          Text('H: 21°  L: 14°', style: AppText.s(9, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// The Quick Note as a small note on the wallpaper (BR-09: same note).
class WallpaperNoteCard extends StatelessWidget {
  const WallpaperNoteCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = app.settings.lockScreenHideDetails ? '' : app.notes.quickText;
    return _WallpaperCard(
      color: AppColors.pink.withValues(alpha: 0.93),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr('a little reminder'), style: AppText.s(11)),
              ),
              Icon(
                LucideIcons.gripVertical,
                size: 13,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text.isEmpty ? tr('Tap to write a note') : text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(15, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            tr('one small step at a time'),
            style: AppText.s(10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Today's first habit with the last five days and the current streak.
class WallpaperHabitCard extends StatelessWidget {
  const WallpaperHabitCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = app.today;
    final habits = app.habits.occurrences(today);
    final habit = habits.firstOrNull;
    final children = <Widget>[];
    if (habit == null) {
      children.add(Text(tr('No habits today'), style: AppText.s(11)));
    } else {
      final done = habits.where((h) => app.habits.isDone(h, today)).length;
      var streak = 0;
      // A streak still counts when today is not ticked yet.
      var day = app.habits.isDone(habit, today)
          ? today
          : today.subtract(const Duration(days: 1));
      while (streak < 365 && app.habits.isDone(habit, day)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }
      children.addAll([
        Text(
          app.settings.lockScreenHideDetails ? tr('Habits') : habit.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.s(11, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          trf('{done} of {total} today', {
            'done': done,
            'total': habits.length,
          }),
          style: AppText.s(11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 4; i >= 0; i--) ...[
              _HabitDot(
                done: app.habits.isDone(
                  habit,
                  today.subtract(Duration(days: i)),
                ),
              ),
              if (i > 0) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          trf('{n}-day streak', {'n': streak}),
          style: AppText.s(10, color: AppColors.greenStrong),
        ),
      ]);
    }
    return _WallpaperCard(
      color: AppColors.green.withValues(alpha: 0.91),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _HabitDot extends StatelessWidget {
  const _HabitDot({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: done ? AppColors.greenStrong : AppColors.surface,
        borderRadius: BorderRadius.circular(7),
      ),
      child: done
          ? Icon(LucideIcons.check, size: 9, color: AppColors.onPrimary)
          : null,
    );
  }
}

/// The lock screen widgets placed on the grid of the lock [ScreenLayout].
class LockWidgetList extends StatelessWidget {
  const LockWidgetList({
    super.key,
    required this.layout,
    this.actions = const LockActions(),
  });

  final ScreenLayout layout;
  final LockActions actions;

  @override
  Widget build(BuildContext context) {
    return WidgetGrid(
      layout: layout,
      cellBuilder: (item, size, scale) => GridCell(
        size: size,
        fillWidth: item.type == WidgetType.schedule,
        minWidth: minLockCardWidth,
        scale: wallpaperWidgets.contains(item.type) ? scale : null,
        color: item.color,
        textSize: item.textSize,
        surface: item.surface,
        child: buildLockWidget(item.type, actions: actions),
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({required this.child, this.color, this.onTap, this.padding});

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      color: CardTint.fill(context, color ?? AppColors.lockCard),
      borderColor: CardTint.border(context) ?? AppColors.surface,
      onTap: onTap,
      child: child,
    );
  }
}

/// Today's schedule. Read-only: an event can be opened, never edited here.
class LockScheduleCard extends StatelessWidget {
  const LockScheduleCard({super.key, this.actions = const LockActions()});

  final LockActions actions;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final events = app.visibleCalendarEventsOn(app.today);
    final start = app.weekStartOf(app.today);
    final tasks = app.tasks
        .dueOn(app.today)
        .where((t) => !t.completed)
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 420.0;
        final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
        final usable = (height - 6).clamp(0.0, double.infinity);
        final weekShare = usable * 0.42;
        final weekRows = ((weekShare - 40 * scale - 14) / (9 * scale + 7))
            .floor()
            .clamp(0, 3);
        // The week strip takes only what its rows need; the rest goes to the
        // list, so the cards fill the cell instead of leaving a gap (FR-19).
        final weekNeeds = 40 * scale + 14 + weekRows * (9 * scale + 7);
        final weekHeight = weekNeeds < weekShare ? weekNeeds : weekShare;
        final detailsHeight = usable - weekHeight;
        final totalDetails = events.length + tasks.length;
        // Fill the list with as many rows as really fit: card padding, the
        // date row and its gap first, then 28 px per event (24 px color bar)
        // and one text line per task. "+N" sits in the date row.
        var room = detailsHeight - 10 - 17 * scale - 4;
        final shownEvents = <CalendarEvent>[];
        for (final event in events) {
          if (room < 28) break;
          room -= 28;
          shownEvents.add(event);
        }
        final shownTasks = <Task>[];
        if (shownEvents.length == events.length) {
          for (final task in tasks) {
            if (room < 4 + 14 * scale) break;
            room -= 4 + 14 * scale;
            shownTasks.add(task);
          }
        }
        final shown = shownEvents.length + shownTasks.length;
        final sections = <Widget>[
          _LockCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = DateTime(
                          start.year,
                          start.month,
                          start.day + i,
                        );
                        final dayEvents = app.visibleCalendarEventsOn(day);
                        final today = sameDay(day, app.today);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                weekdayLetters[day.weekday - 1],
                                style: AppText.s(8, color: AppColors.muted),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: today
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: AppText.s(
                                    10,
                                    color: today
                                        ? AppColors.surface
                                        : AppColors.text,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (app.settings.lockScreenHideDetails)
                                Text('${dayEvents.length}', style: AppText.s(8))
                              else if (weekRows == 0 && dayEvents.isNotEmpty)
                                Text(
                                  '+${dayEvents.length}',
                                  style: AppText.s(7),
                                )
                              else ...[
                                for (final event in dayEvents.take(
                                  dayEvents.length > weekRows && weekRows > 0
                                      ? weekRows - 1
                                      : weekRows,
                                ))
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentSurface(
                                        event.colorIndex,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.s(7),
                                    ),
                                  ),
                                if (dayEvents.length > weekRows && weekRows > 0)
                                  Text(
                                    '+${dayEvents.length - weekRows + 1}',
                                    style: AppText.s(7),
                                  ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          _LockCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendarDays,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        longDate(app.today),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.s(12.5, weight: FontWeight.w700),
                      ),
                    ),
                    if (!app.settings.lockScreenHideDetails &&
                        totalDetails > shown)
                      Text(
                        '+${totalDetails - shown}',
                        style: AppText.s(9, color: AppColors.muted),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // AC-38: Hide details shows counts only.
                if (app.settings.lockScreenHideDetails)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      trf(
                        events.length == 1
                            ? '{n} event today'
                            : '{n} events today',
                        {'n': events.length},
                      ),
                      style: AppText.s(11.5, weight: FontWeight.w600),
                    ),
                  )
                else if (totalDetails == 0 && detailsHeight >= 42)
                  Text(
                    tr('Nothing scheduled today'),
                    style: AppText.s(9, color: AppColors.muted),
                  ),
                if (!app.settings.lockScreenHideDetails)
                  for (final event in shownEvents)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: actions.onOpenEvent == null
                          ? null
                          : () => actions.onOpenEvent!(event),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 47,
                              child: Text(
                                event.startLabel,
                                style: AppText.s(9.5, color: AppColors.muted),
                              ),
                            ),
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.accentSurface(
                                  event.colorIndex,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.s(11.5, weight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (!app.settings.lockScreenHideDetails)
                  for (final task in shownTasks)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circle,
                            size: 12,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.s(11),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ];
        // At least as tall as its slot, so the card reaches the cell's edge.
        Widget boundedCard(double available, Widget child) => SizedBox(
          height: available,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: available,
              maxHeight: double.infinity,
              child: child,
            ),
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            boundedCard(weekHeight, sections[0]),
            SizedBox(height: height >= 6 ? 6 : height),
            boundedCard(detailsHeight, sections[1]),
          ],
        );
      },
    );
  }
}

/// To-do with quick actions: complete a task or add one.
class LockTodoCard extends StatelessWidget {
  const LockTodoCard({super.key, this.actions = const LockActions()});

  final LockActions actions;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tasks = app.tasks.dashboard(app.today);
    return _LockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.circleCheckBig,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('To-do'),
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
              ),
              Text(
                tr('Quick actions on'),
                style: AppText.s(9.5, color: AppColors.greenStrong),
              ),
            ],
          ),
          if (app.settings.lockScreenHideDetails)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                trf('{n} to-dos left', {
                  'n': tasks.where((t) => !t.completed).length,
                }),
                style: AppText.s(11.5, weight: FontWeight.w600),
              ),
            )
          else if (tasks.isEmpty)
            const EmptyState(
              compact: true,
              icon: LucideIcons.circleCheckBig,
              message: 'Nothing to do today',
            )
          else
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    AppCheckbox(
                      value: task.completed,
                      onChanged: actions.onToggleTask == null
                          ? null
                          : (_) => actions.onToggleTask!(task),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.s(
                          11.5,
                          color: task.completed
                              ? AppColors.muted
                              : AppColors.text,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (!task.completed)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: actions.onRemindTask == null
                            ? null
                            : () => actions.onRemindTask!(task),
                        child: Icon(
                          LucideIcons.alarmClockPlus,
                          size: 15,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: actions.onAddTask,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
                  const SizedBox(width: 9),
                  Text(tr('Add Task'), style: AppText.action()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LockNoteCard extends StatelessWidget {
  const LockNoteCard({super.key, this.actions = const LockActions()});

  final LockActions actions;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = app.notes.quickText;
    return _LockCard(
      color: AppColors.note,
      onTap: actions.onOpenNote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.notebookPen,
                size: 15,
                color: AppColors.yellowText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Quick Note'),
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
              ),
              Text(
                tr('Tap to type'),
                style: AppText.s(
                  10.5,
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.mic, size: 14, color: AppColors.text),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              app.settings.lockScreenHideDetails
                  ? 'Hidden on the lock screen'
                  : text.isEmpty
                  ? 'Tap to write a note'
                  : text,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(11.5, height: 1.35),
          ),
          const SizedBox(height: 9),
          const SavedStatus(size: 9.5),
        ],
      ),
    );
  }
}

/// Minimal "Add Task" input shown from the lock screen. The task is saved to
/// the same database the app reads.
Future<void> showQuickAddTask(BuildContext context) async {
  final app = AppScope.read(context);
  final controller = TextEditingController();
  final title = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        16,
        18,
        16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: AppText.s(14),
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (value) => Navigator.pop(sheetContext, value),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: tr('Add a task for today'),
                hintStyle: AppText.s(14, color: AppColors.faint),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: PrimaryButton(
              label: 'Add',
              height: 36,
              radius: 18,
              onTap: () => Navigator.pop(sheetContext, controller.text),
            ),
          ),
        ],
      ),
    ),
  );
  if (title == null || title.trim().isEmpty) return;
  final task = app.quickAddTask(title);
  if (task != null && context.mounted) {
    showAppSnack(context, trf('Added "{title}"', {'title': task.title}));
  }
}
