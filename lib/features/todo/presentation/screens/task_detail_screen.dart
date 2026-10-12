import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';

/// Editor for one task. Changes are applied when "Save changes" is pressed.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final _title = TextEditingController(text: widget.task.title);
  late final _notes = TextEditingController(text: widget.task.notes);

  late bool _completed = widget.task.completed;
  late String _time = widget.task.time;
  late String _priority = widget.task.priority;
  late String _reminder = widget.task.reminder;
  late String _repeat = widget.task.repeat;
  late String _category = widget.task.category;
  late String _estimate = widget.task.estimate;
  late int _color = widget.task.colorIndex;
  late final List<String> _tags = [...widget.task.tags];
  late final List<Subtask> _subtasks = [
    for (final s in widget.task.subtasks) Subtask(s.title, done: s.done),
  ];

  static const _tagColors = [AppColors.primarySoft, AppColors.blue];

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _choose(
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onPicked,
  ) async {
    final picked = await pickOption(
      context,
      title: title,
      options: options,
      current: current,
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _addTag() async {
    final tag = await promptText(context, title: 'Add tag', hint: 'Tag name');
    if (tag != null && tag.isNotEmpty) setState(() => _tags.add(tag));
  }

  Future<void> _addSubtask() async {
    final title = await promptText(
      context,
      title: 'Add subtask',
      hint: 'Subtask title',
    );
    if (title != null && title.isNotEmpty) {
      setState(() => _subtasks.add(Subtask(title)));
    }
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showAppSnack(context, 'A task needs a title');
      return;
    }
    final task = widget.task;
    if (task.title != title) task.shortTitle = title;
    task
      ..title = title
      ..notes = _notes.text.trim()
      ..completed = _completed
      ..time = _time
      ..priority = _priority
      ..reminder = _reminder
      ..repeat = _repeat
      ..category = _category
      ..estimate = _estimate
      ..colorIndex = _color
      ..tagColor = AppColors.accentSurfaces[_color]
      ..tags = [..._tags]
      ..subtasks = [..._subtasks];
    AppScope.read(context).touch();
    Navigator.of(context).pop();
    showAppSnack(context, 'Changes saved');
  }

  void _delete() {
    AppScope.read(context).deleteTask(widget.task);
    Navigator.of(context).pop();
    showAppSnack(context, 'Task deleted');
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _subtasks.where((s) => s.done).length;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text('Task details', style: AppText.s(18)),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _delete,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              borderColor: AppColors.primary,
              borderWidth: 1.5,
              shadow: false,
              child: Row(
                children: [
                  AppCheckbox(
                    value: _completed,
                    onChanged: (v) => setState(() => _completed = v),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TASK',
                          style: AppText.s(9, color: AppColors.primary),
                        ),
                        TextField(
                          controller: _title,
                          style: AppText.s(16),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 5),
                            hintText: 'Task title',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _fieldRow(
              FieldTile(
                icon: LucideIcons.clock3,
                label: 'Time',
                value: _time,
                onTap: () => _choose(
                  'Time',
                  const [
                    'Today · 4:00 PM',
                    'Today · 6:00 PM',
                    'Tomorrow · 9:00 AM',
                    'Anytime',
                  ],
                  _time,
                  (v) => _time = v,
                ),
              ),
              FieldTile(
                icon: LucideIcons.flag,
                label: 'Priority',
                value: _priority,
                onTap: () => _choose(
                  'Priority',
                  const ['Low', 'Medium', 'High'],
                  _priority,
                  (v) => _priority = v,
                ),
              ),
            ),
            _fieldRow(
              FieldTile(
                icon: LucideIcons.bell,
                label: 'Reminder',
                value: _reminder,
                onTap: () => _choose(
                  'Reminder',
                  const [
                    'None',
                    '15 min before',
                    '30 min before',
                    '1 hour before',
                  ],
                  _reminder,
                  (v) => _reminder = v,
                ),
              ),
              FieldTile(
                icon: LucideIcons.repeat2,
                label: 'Repeat',
                value: _repeat,
                onTap: () => _choose(
                  'Repeat',
                  const ['Never', 'Every day', 'Weekdays', 'Weekly'],
                  _repeat,
                  (v) => _repeat = v,
                ),
              ),
            ),
            _fieldRow(
              FieldTile(
                icon: LucideIcons.folder,
                label: 'Category',
                value: _category,
                onTap: () => _choose(
                  'Category',
                  const ['Work', 'Personal', 'Finance', 'Health', 'Shopping'],
                  _category,
                  (v) => _category = v,
                ),
              ),
              FieldTile(
                icon: LucideIcons.timer,
                label: 'Estimated time',
                value: _estimate,
                onTap: () => _choose(
                  'Estimated time',
                  const ['15 min', '30 min', '45 min', '1 hour', '2 hours'],
                  _estimate,
                  (v) => _estimate = v,
                ),
              ),
            ),
            const SizedBox(height: 4),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    shadow: false,
                    borderColor: Colors.transparent,
                    padding: const EdgeInsets.fromLTRB(12, 10, 24, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COLOR', style: AppText.label()),
                        const SizedBox(height: 9),
                        ColorDots(
                          colors: AppColors.accents,
                          index: _color,
                          size: 12,
                          spacing: 6,
                          onChanged: (i) => setState(() => _color = i),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppCard(
                      shadow: false,
                      borderColor: Colors.transparent,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TAGS', style: AppText.label()),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (var i = 0; i < _tags.length; i++)
                                GestureDetector(
                                  onLongPress: () =>
                                      setState(() => _tags.removeAt(i)),
                                  child: Container(
                                    height: 21,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _tagColors[i % 2],
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Center(
                                      widthFactor: 1,
                                      child: Text(
                                        _tags[i],
                                        style: AppText.s(
                                          10,
                                          color: i.isEven
                                              ? AppColors.primary
                                              : AppColors.text,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _addTag,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    LucideIcons.plus,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.notebookPen,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NOTES', style: AppText.label()),
                        TextField(
                          controller: _notes,
                          maxLines: null,
                          style: AppText.s(13, height: 1.4),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(top: 3),
                            hintText: 'Add notes',
                            hintStyle: AppText.s(13, color: AppColors.faint),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            AppCard(
              shadow: false,
              borderColor: Colors.transparent,
              child: Column(
                children: [
                  CardHeader(
                    title: 'Subtasks · $doneCount/${_subtasks.length}',
                    action: '+ Add',
                    onAction: _addSubtask,
                  ),
                  for (final subtask in _subtasks)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => subtask.done = !subtask.done),
                        child: Row(
                          children: [
                            AppCheckbox(value: subtask.done),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                subtask.title,
                                style: AppText.s(
                                  11,
                                  color: subtask.done
                                      ? AppColors.muted
                                      : AppColors.text,
                                  decoration: subtask.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Save changes',
              icon: LucideIcons.check,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    );
  }
}
