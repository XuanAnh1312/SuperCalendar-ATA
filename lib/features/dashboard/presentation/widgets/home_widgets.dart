import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/core/utils/strings.dart';

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
  if (AppStrings.vi) {
    return sunday.month == monday.month
        ? '${monday.day}–${sunday.day}/${sunday.month}'
        : '${monday.day}/${monday.month}–${sunday.day}/${sunday.month}';
  }
  return '$month ${monday.day}–$end';
}

List<Color> get weekDotColors => [
  AppColors.pink,
  AppColors.blue,
  AppColors.green,
  AppColors.yellow,
  AppColors.purple,
  AppColors.border,
  AppColors.border,
];

/// Callbacks of the dashboard widgets; all optional so the same widgets can
/// be shown as a non-interactive preview.
class HomeWidgetActions {
  const HomeWidgetActions({
    this.onEditTodo,
    this.onEditHabits,
    this.onOpenWeek,
    this.onEditNote,
    this.onSaveSnapshot,
  });

  final VoidCallback? onEditTodo;
  final VoidCallback? onEditHabits;
  final VoidCallback? onOpenWeek;
  final VoidCallback? onEditNote;
  final VoidCallback? onSaveSnapshot;
}

/// Builds the dashboard widget for a layout [type].
Widget buildHomeWidget(
  String type, {
  HomeWidgetActions actions = const HomeWidgetActions(),
}) {
  return switch (type) {
    WidgetType.todo => TodoWidget(onEdit: actions.onEditTodo),
    WidgetType.habits => HabitsWidget(onEdit: actions.onEditHabits),
    WidgetType.week => WeekWidget(onOpen: actions.onOpenWeek),
    WidgetType.goals => const GoalsWidget(),
    WidgetType.quickNote => QuickNoteWidget(onEdit: actions.onEditNote),
    WidgetType.snapshot => MonthSnapshotWidget(onSave: actions.onSaveSnapshot),
    WidgetType.weather => const WeatherWidget(),
    _ => const SizedBox.shrink(),
  };
}

/// The dashboard widgets placed on the grid of a [ScreenLayout].
class HomeWidgetGrid extends StatelessWidget {
  const HomeWidgetGrid({
    super.key,
    required this.layout,
    this.actions = const HomeWidgetActions(),
  });

  final ScreenLayout layout;
  final HomeWidgetActions actions;

  @override
  Widget build(BuildContext context) {
    if (layout.visibleItems.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.layoutGrid,
        message:
            'No widgets on this screen yet.\nAdd some in Edit Your Screen.',
      );
    }
    return WidgetGrid(
      layout: layout,
      cellBuilder: (item, size, _) => GridCell(
        size: size,
        color: item.color,
        textSize: item.textSize,
        surface: item.surface,
        child: buildHomeWidget(item.type, actions: actions),
      ),
    );
  }
}

class TodoWidget extends StatelessWidget {
  const TodoWidget({super.key, this.onEdit});

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tasks = app.tasks.dashboard(app.today);
    return AppCard(
      color: CardTint.fill(context, null),
      borderColor: CardTint.border(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'To-do', action: 'Edit', onAction: onEdit),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(tr('Nothing to do today'),
                style: AppText.s(11, color: AppColors.muted),
              ),
            ),
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                children: [
                  AppCheckbox(
                    value: task.completed,
                    onChanged: (_) => app.tasks.toggle(task),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
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
                  const SizedBox(width: 4),
                  Text(
                    tr(task.completed
                        ? 'done'
                        : task.dueLabel(app.today).toLowerCase()),
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
    final habits = app.habits.occurrences(app.today);
    return AppCard(
      color: CardTint.fill(context, AppColors.green),
      borderColor: CardTint.border(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'Habits', action: 'Edit', onAction: onEdit),
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(tr('All done for today'),
                style: AppText.s(11, color: AppColors.muted),
              ),
            ),
          for (final habit in habits)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => app.habits.toggle(habit, app.today),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: app.habits.isDone(habit, app.today)
                            ? AppColors.greenStrong
                            : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        app.habits.isDone(habit, app.today)
                            ? LucideIcons.check
                            : habitIcon(habit.icon),
                        size: 12,
                        color: app.habits.isDone(habit, app.today)
                            ? AppColors.onPrimary
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
      color: CardTint.fill(context, null),
      borderColor: CardTint.border(context),
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
    // Show the first active weekly goal; fall back to monthly if none.
    final allGoals = [...app.weeklyGoals, ...app.monthlyGoals];
    final goal = allGoals.isNotEmpty ? allGoals.first : null;
    final progress = goal?.progress ?? 0.0;
    final title = goal?.title ?? 'No active goals';
    final pct = '${(progress * 100).round()}%';
    return AppCard(
      color: CardTint.fill(context, AppColors.purple),
      borderColor: CardTint.border(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'Goals', action: pct),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(11),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
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

  /// Hides the note text (used by the layout editor tray).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = app.notes.quickText;
    return AppCard(
      color: CardTint.fill(context, AppColors.yellow),
      borderColor: CardTint.border(context),
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
              tr(text.isEmpty ? 'Tap to write a note' : text),
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

class MonthSnapshotWidget extends StatefulWidget {
  const MonthSnapshotWidget({super.key, this.onSave});

  /// Called after the image is saved; null hides the Save image action.
  final VoidCallback? onSave;

  @override
  State<MonthSnapshotWidget> createState() => _MonthSnapshotWidgetState();
}

class _MonthSnapshotWidgetState extends State<MonthSnapshotWidget> {
  final _boundary = GlobalKey();

  /// Saves the card as a PNG in the phone's gallery (AC-28).
  Future<void> _save() async {
    final boundary =
        _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    // Render at the screen's full width in pixels.
    final ratio = View.of(context).physicalSize.width / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return;
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImageBytes(
        data.buffer.asUint8List(),
        name: 'supercalendar_${DateTime.now().millisecondsSinceEpoch}',
      );
      widget.onSave?.call();
    } on GalException {
      if (mounted) showAppSnack(context, 'Could not save the image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final first = app.today;
    return RepaintBoundary(key: _boundary, child: _card(app, first));
  }

  Widget _card(AppState app, DateTime first) {
    return AppCard(
      color: CardTint.fill(context, AppColors.blue),
      borderColor: CardTint.border(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: trf('{month} snapshot', {'month': monthNames[first.month - 1]}),
            action: widget.onSave == null ? null : 'Save image',
            onAction: widget.onSave == null ? null : _save,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < 14; i++)
                Expanded(
                  child: _snapshotDay(
                    app,
                    DateTime(first.year, first.month, first.day + i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(tr('Display-only · tap snapshot to share your month'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _snapshotDay(AppState app, DateTime day) {
    final isToday = sameDay(day, app.today);
    final events = app.events.on(day);
    var dot = Colors.transparent;
    if (events.isNotEmpty) {
      dot = events.first.colorIndex == 2
          ? AppColors.greenStrong
          : AppColors.primary;
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

/// Weather card. The prototype has no internet access (README 10), so it
/// shows clearly labelled sample data.
class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: CardTint.fill(context, AppColors.yellow),
      borderColor: CardTint.border(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'Weather', action: 'Sample'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.sun, size: 24, color: AppColors.yellowText),
              const SizedBox(width: 8),
              Text('18°', style: AppText.s(26, height: 1)),
            ],
          ),
          const SizedBox(height: 6),
          Text(tr('Mostly sunny'), style: AppText.s(11)),
          const SizedBox(height: 3),
          Text(
            'H: 21°   L: 14°',
            style: AppText.s(10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
