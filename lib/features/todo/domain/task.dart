import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

class Subtask {
  Subtask(this.title, {this.done = false});

  factory Subtask.fromJson(Map<String, dynamic> json) =>
      Subtask(json['title'] as String, done: json['done'] as bool? ?? false);

  String title;
  bool done;

  Map<String, dynamic> toJson() => {'title': title, 'done': done};
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.dueTime,
    this.priority = priorityMedium,
    this.completed = false,
    required this.createdAt,
    DateTime? updatedAt,
    this.reminderMinutes,
    this.repeat = 'Never',
    this.category = 'Personal',
    this.estimateMinutes = 30,
    this.colorIndex = 0,
    this.order = 0,
    List<String>? tags,
    List<Subtask>? subtasks,
  }) : updatedAt = updatedAt ?? createdAt,
       tags = tags ?? [],
       subtasks = subtasks ?? [];

  factory Task.fromJson(Map<String, dynamic> json) {
    final created = parseDate(json['createdAt']) ?? DateTime.now();
    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: parseDate(json['dueDate']),
      dueTime: json['dueTime'] as int?,
      priority: json['priority'] as String? ?? priorityMedium,
      completed: json['completed'] as bool? ?? false,
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
      reminderMinutes: json['reminderMinutes'] as int?,
      repeat: json['repeat'] as String? ?? 'Never',
      category: json['category'] as String? ?? 'Personal',
      estimateMinutes: json['estimateMinutes'] as int? ?? 30,
      colorIndex: json['colorIndex'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      tags: [...?(json['tags'] as List?)?.cast<String>()],
      subtasks: [
        for (final s in (json['subtasks'] as List?) ?? const [])
          Subtask.fromJson((s as Map).cast<String, dynamic>()),
      ],
    );
  }

  static const priorityLow = 'Low';
  static const priorityMedium = 'Medium';
  static const priorityHigh = 'High';
  static const priorities = [priorityLow, priorityMedium, priorityHigh];

  final String id;
  String title;
  String description;

  /// Day the task is due (time stripped); null when it has no date.
  DateTime? dueDate;

  /// Minutes since midnight on [dueDate]; null when it has no time.
  int? dueTime;
  String priority;
  bool completed;
  final DateTime createdAt;
  DateTime updatedAt;

  /// Minutes before the due time to notify; null for no reminder.
  int? reminderMinutes;
  String repeat;
  String category;
  int estimateMinutes;
  int colorIndex;

  /// Position in the user's manually ordered list.
  int order;
  List<String> tags;
  List<Subtask> subtasks;

  /// Exact moment the task is due, when both date and time are set.
  DateTime? get dueAt {
    final date = dueDate;
    final time = dueTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time ~/ 60, time % 60);
  }

  bool isDueOn(DateTime day) => dueDate != null && sameDay(dueDate!, day);

  /// `Today`, `Tue`, ... or empty when there is no due date.
  String dueLabel(DateTime today) =>
      dueDate == null ? '' : relativeDay(dueDate!, today);

  /// `Today · 4:00 PM`, `Today`, or `Anytime`.
  String timeLabel(DateTime today) {
    if (dueDate == null) return 'Anytime';
    final day = dueLabel(today);
    return dueTime == null ? day : '$day · ${formatClock(dueTime!)}';
  }

  /// Second line of a list row: `Today · High`, `Tue · Personal`, `Completed`.
  String subtitle(DateTime today) {
    if (completed) return 'Completed';
    final detail = priority == priorityHigh ? priorityHigh : category;
    return [
      dueLabel(today),
      detail,
    ].where((part) => part.isNotEmpty).join(' · ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'dueTime': dueTime,
    'priority': priority,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'reminderMinutes': reminderMinutes,
    'repeat': repeat,
    'category': category,
    'estimateMinutes': estimateMinutes,
    'colorIndex': colorIndex,
    'order': order,
    'tags': tags,
    'subtasks': [for (final s in subtasks) s.toJson()],
  };
}
