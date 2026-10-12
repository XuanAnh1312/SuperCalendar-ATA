import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

/// Labels `M 5 … S 11` for the week containing [today].
List<String> weekLabels(DateTime today) {
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      '${weekdayLetters[i]} ${monday.add(Duration(days: i)).day}',
  ];
}

/// `Oct 5–11`
String weekRangeLabel(DateTime today, {bool longMonth = false}) {
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  final month = longMonth
      ? monthNames[monday.month - 1]
      : monthShort(monday.month);
  final end = sunday.month == monday.month
      ? '${sunday.day}'
      : '${monthShort(sunday.month)} ${sunday.day}';
  return '$month ${monday.day}–$end';
}

const weekDotColors = [
  AppColors.pink,
  AppColors.blue,
  AppColors.green,
  AppColors.yellow,
  AppColors.purple,
  AppColors.border,
  AppColors.border,
];

class TodoWidget extends StatelessWidget {
  const TodoWidget({super.key, this.onEdit});

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardHeader(title: 'To-do', action: 'Edit', onAction: onEdit),
          for (final task in app.dashboardTasks)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                children: [
                  AppCheckbox(
                    value: task.completed,
                    onChanged: (_) => app.toggleTask(task),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      task.shortTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.s(
                        12,
                        color: task.completed
                            ? AppColors.muted
                            : AppColors.text,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.completed ? 'done' : task.due.toLowerCase(),
                    style: AppText.s(10, color: AppColors.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class HabitsWidget extends StatelessWidget {
  const HabitsWidget({super.key, this.onEdit});

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AppCard(
      color: AppColors.green,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardHeader(title: 'Habits', action: 'Edit', onAction: onEdit),
          for (final habit in app.habits)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => app.toggleHabit(habit),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: habit.done
                            ? AppColors.greenStrong
                            : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        habit.done ? LucideIcons.check : habit.icon,
                        size: 12,
                        color: habit.done
                            ? Colors.white
                            : AppColors.greenStrong,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        habit.shortTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.s(11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WeekWidget extends StatelessWidget {
  const WeekWidget({super.key, this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AppCard(
      onTap: onOpen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardHeader(
            title: 'This week',
            action: weekRangeLabel(app.today),
            onAction: onOpen,
          ),
          const SizedBox(height: 9),
          WeekDots(
            labels: weekLabels(app.today),
            colors: weekDotColors,
            activeIndex: app.today.weekday - 1,
          ),
        ],
      ),
    );
  }
}

class GoalsWidget extends StatelessWidget {
  const GoalsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AppCard(
      color: AppColors.purple,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Goals',
            action: '${(app.goalProgress * 100).round()}%',
          ),
          const SizedBox(height: 8),
          Text(
            app.goalTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(11),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: app.goalProgress,
              minHeight: 5,
              backgroundColor: AppColors.surface,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickNoteWidget extends StatelessWidget {
  const QuickNoteWidget({super.key, this.onEdit, this.compact = false});

  final VoidCallback? onEdit;

  /// Hides the note text (used by the layout editor preview).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AppCard(
      color: AppColors.yellow,
      onTap: onEdit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Quick Note',
            action: compact ? null : 'Edit',
            onAction: onEdit,
          ),
          if (!compact) ...[
            const SizedBox(height: 7),
            Text(
              app.quickNote.isEmpty ? 'Tap to write a note' : app.quickNote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.s(11, height: 1.35),
            ),
          ],
          const SizedBox(height: 7),
          const SavedStatus(),
        ],
      ),
    );
  }
}

class MonthSnapshotWidget extends StatelessWidget {
  const MonthSnapshotWidget({super.key, this.onSave});

  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final first = app.today;
    return AppCard(
      color: AppColors.blue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: '${monthNames[first.month - 1]} snapshot',
            action: 'Save image',
            onAction: onSave,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < 14; i++)
                Expanded(
                  child: _snapshotDay(app, first.add(Duration(days: i))),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Display-only · tap snapshot to share your month',
            style: AppText.s(9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _snapshotDay(AppState app, DateTime day) {
    final isToday = sameDay(day, app.today);
    final events = app.eventsOn(day);
    Color dot = Colors.transparent;
    if (events.isNotEmpty) {
      dot = events.first.accent == AppColors.primary
          ? AppColors.primary
          : AppColors.greenStrong;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${day.day}',
          style: AppText.s(
            9,
            weight: isToday ? FontWeight.w700 : FontWeight.w400,
            color: isToday ? AppColors.primary : AppColors.text,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
      ],
    );
  }
}
