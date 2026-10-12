import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

/// Editor for one task. Changes are applied when "Save changes" is pressed.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final _title = TextEditingController(text: widget.task.title);
  late final _notes = TextEditingController(text: widget.task.description);

  late bool _completed = widget.task.completed;
  late DateTime? _dueDate = widget.task.dueDate;
  late int? _dueTime = widget.task.dueTime;
  late String _priority = widget.task.priority;
  late int? _reminder = widget.task.reminderMinutes;
  late String _repeat = widget.task.repeat;
  late String _category = widget.task.category;
  late int _estimate = widget.task.estimateMinutes;
  late int _color = widget.task.colorIndex;
  late final List<String> _tags = [...widget.task.tags];
  late final List<Subtask> _subtasks = [
    for (final s in widget.task.subtasks) Subtask(s.title, done: s.done),
  ];

  static const _estimates = [15, 30, 45, 60, 120];

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _timeLabel(DateTime today) {
    final date = _dueDate;
    if (date == null) return 'Anytime';
    final day = relativeDay(date, today);
    return _dueTime == null ? day : '$day · ${formatClock(_dueTime!)}';
  }

  Future<void> _pickDue() async {
    final today = AppScope.read(context).today;
    const pick = 'Pick date & time';
    const none = 'No due date';
    final choice = await pickOption(
      context,
      title: 'Time',
      options: const [pick, none],
      current: _dueDate == null ? none : pick,
    );
    if (choice == null || !mounted) return;
    if (choice == none) {
      setState(() {
        _dueDate = null;
        _dueTime = null;
      });
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (date == null || !mounted) return;
    final initial = _dueTime ?? 9 * 60;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (!mounted) return;
    setState(() {
      _dueDate = dateOnly(date);
      // Cancelling the time picker leaves the task due "any time that day".
      _dueTime = time == null ? null : time.hour * 60 + time.minute;
    });
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

  Future<void> _chooseReminder() async {
    final picked = await pickReminder(context, _reminder);
    if (picked != null) setState(() => _reminder = picked < 0 ? null : picked);
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
    final app = AppScope.read(context);
    final task = widget.task
      ..title = title
      ..description = _notes.text.trim()
      ..completed = _completed
      ..dueDate = _dueDate
      ..dueTime = _dueTime
      ..priority = _priority
      ..reminderMinutes = _reminder
      ..repeat = _repeat
      ..category = _category
      ..estimateMinutes = _estimate
      ..colorIndex = _color
      ..tags = [..._tags]
      ..subtasks = [..._subtasks];
    app.tasks.save(task);
    if (_reminder != null && task.dueAt != null) {
      unawaited(app.ensureRemindersCanFire());
    }
    Navigator.of(context).pop();
    showAppSnack(context, 'Changes saved');
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete task?',
      message: '"${widget.task.title}" will be removed.',
    );
    if (!ok || !mounted) return;
    AppScope.read(context).tasks.delete(widget.task);
    Navigator.of(context).pop();
    showAppSnack(context, 'Task deleted');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final doneCount = _subtasks.where((s) => s.done).length;
    final tagColors = [AppColors.primarySoft, AppColors.blue];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            TopBar(
              title: 'Task details',
              trailing: GestureDetector(
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
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            hintText: 'Task title',
                            hintStyle: AppText.s(16, color: AppColors.faint),
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
                value: _timeLabel(app.today),
                onTap: _pickDue,
              ),
              FieldTile(
                icon: LucideIcons.flag,
                label: 'Priority',
                value: _priority,
                onTap: () => _choose(
                  'Priority',
                  Task.priorities,
                  _priority,
                  (v) => _priority = v,
                ),
              ),
            ),
            _fieldRow(
              FieldTile(
                icon: LucideIcons.bell,
                label: 'Reminder',
                value: formatReminder(_reminder),
                onTap: _chooseReminder,
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
                value: formatDuration(_estimate),
                onTap: () => _choose(
                  'Estimated time',
                  [for (final m in _estimates) formatDuration(m)],
                  formatDuration(_estimate),
                  (v) => _estimate = _estimates.firstWhere(
                    (m) => formatDuration(m) == v,
                  ),
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
                    padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
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
                                SoftPill(
                                  label: _tags[i],
                                  color: tagColors[i % 2],
                                  textColor: i.isEven
                                      ? AppColors.primary
                                      : AppColors.text,
                                  onTap: () =>
                                      setState(() => _tags.removeAt(i)),
                                ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _addTag,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
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
            InlineField(
              icon: LucideIcons.notebookPen,
              label: 'Notes',
              controller: _notes,
              hint: 'Add a description',
              multiline: true,
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
