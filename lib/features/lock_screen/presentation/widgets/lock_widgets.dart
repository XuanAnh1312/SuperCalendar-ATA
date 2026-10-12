import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

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

/// The lock screen widgets in the order of the lock [ScreenLayout].
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
    final items = layout.visibleItems;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          switch (items[i].type) {
            WidgetType.schedule => LockScheduleCard(actions: actions),
            WidgetType.todo => LockTodoCard(actions: actions),
            WidgetType.quickNote => LockNoteCard(actions: actions),
            _ => const SizedBox.shrink(),
          },
        ],
      ],
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({required this.child, this.color, this.onTap});

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color ?? AppColors.lockCard,
      borderColor: AppColors.surface,
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
    final events = app.events.on(app.today);
    return _LockCard(
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
                  'Schedule',
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
              ),
              SoftPill(
                label: 'Read only',
                icon: LucideIcons.lockKeyhole,
                color: AppColors.background,
                textColor: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Nothing scheduled today',
                style: AppText.s(11, color: AppColors.muted),
              ),
            ),
          for (final event in events)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: actions.onOpenEvent == null
                  ? null
                  : () => actions.onOpenEvent!(event),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
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
                        color: AppColors.accentSurface(event.colorIndex),
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
        ],
      ),
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
                  'To-do',
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
              ),
              Text(
                'Quick actions on',
                style: AppText.s(9.5, color: AppColors.greenStrong),
              ),
            ],
          ),
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
                  Text('Add Task', style: AppText.action()),
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
                  'Quick Note',
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
              ),
              Text(
                'Tap to type',
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
            text.isEmpty ? 'Tap to write a note' : text,
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
                hintText: 'Add a task for today',
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
    showAppSnack(context, 'Added "${task.title}"');
  }
}
