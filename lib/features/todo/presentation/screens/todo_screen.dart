import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/todo/presentation/screens/task_detail_screen.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();

  // 0 = all, 1 = today, 2 = upcoming.
  int _filter = 0;
  bool _hideCompleted = false;

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _submit(AppState app) {
    if (_input.text.trim().isEmpty) {
      _inputFocus.requestFocus();
      return;
    }
    app.addTask(_input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = app.tasks.where((t) => t.isToday).toList();
    final upcoming = app.tasks.where((t) => !t.isToday).toList();
    var visible = switch (_filter) {
      1 => today,
      2 => upcoming,
      _ => app.tasks,
    };
    if (_hideCompleted) {
      visible = visible.where((t) => !t.completed).toList();
    }
    // Reordering maps list positions to the full task list, so it is only
    // offered when nothing is filtered out.
    final canReorder = _filter == 0 && !_hideCompleted;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            PageHeader(
              title: 'TO-DO LIST',
              subtitle:
                  '${longDate(app.today)} · ${app.remainingTasks} remaining',
              trailing: RoundIconButton(
                icon: LucideIcons.listFilter,
                iconColor: _hideCompleted ? AppColors.primary : AppColors.text,
                onTap: () {
                  setState(() => _hideCompleted = !_hideCompleted);
                  showAppSnack(
                    context,
                    _hideCompleted
                        ? 'Completed tasks hidden'
                        : 'Showing all tasks',
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            FilterPillRow(
              labels: [
                'All ${app.tasks.length}',
                'Today ${today.length}',
                'Upcoming',
              ],
              index: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 11),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderColor: AppColors.primary,
              borderWidth: 1.5,
              shadow: false,
              child: Row(
                children: [
                  RoundIconButton(
                    icon: LucideIcons.plus,
                    size: 26,
                    background: AppColors.primarySoft,
                    iconColor: AppColors.primary,
                    onTap: () => _submit(app),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      style: AppText.s(13),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(app),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add a new task',
                        hintStyle: AppText.s(13, color: AppColors.faint),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.only(bottom: 28),
              borderColor: Colors.transparent,
              shadow: false,
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Center(
                        child: Text(
                          'Nothing here yet',
                          style: AppText.s(11, color: AppColors.muted),
                        ),
                      ),
                    )
                  : canReorder
                  ? ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visible.length,
                      onReorderItem: app.reorderTasks,
                      proxyDecorator: (child, _, _) => Material(
                        color: AppColors.surface,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      ),
                      itemBuilder: (context, i) =>
                          _row(context, app, visible[i]),
                    )
                  : Column(
                      children: [
                        for (final task in visible) _row(context, app, task),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap + to add another row · drag tasks to reorder',
                style: AppText.s(10, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppState app, Task task) {
    return Container(
      key: ValueKey(task.id),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          AppCheckbox(
            value: task.completed,
            onChanged: (_) => app.toggleTask(task),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(
                    12.5,
                    weight: FontWeight.w600,
                    color: task.completed ? AppColors.muted : AppColors.text,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 3,
                      decoration: BoxDecoration(
                        color: task.tagColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.subtitle,
                      style: AppText.s(9.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => pushFullScreen(context, TaskDetailScreen(task: task)),
            child: Container(
              width: 34,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Edit',
                style: AppText.s(10, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
