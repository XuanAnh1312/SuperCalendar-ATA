import 'package:flutter/material.dart';

class Subtask {
  Subtask(this.title, {this.done = false});

  String title;
  bool done;
}

class Task {
  Task({
    required this.id,
    required this.title,
    String? shortTitle,
    required this.due,
    required this.detail,
    required this.tagColor,
    this.completed = false,
    this.time = 'Today · 4:00 PM',
    this.priority = 'Medium',
    this.reminder = '30 min before',
    this.repeat = 'Never',
    this.category = 'Personal',
    this.estimate = '30 min',
    this.colorIndex = 0,
    List<String>? tags,
    this.notes = '',
    List<Subtask>? subtasks,
  }) : shortTitle = shortTitle ?? title,
       tags = tags ?? [],
       subtasks = subtasks ?? [];

  final String id;
  String title;

  /// Compact title used by the small dashboard widget.
  String shortTitle;

  /// When the task is due: `Today`, a weekday such as `Tue`, or empty.
  String due;

  /// Second half of the list subtitle, e.g. `High`, `Finance`, `45 min`.
  String detail;
  Color tagColor;
  bool completed;

  String time;
  String priority;
  String reminder;
  String repeat;
  String category;
  String estimate;
  int colorIndex;
  List<String> tags;
  String notes;
  List<Subtask> subtasks;

  bool get isToday => due == 'Today';

  String get subtitle {
    if (completed) return 'Completed';
    return [due, detail].where((part) => part.isNotEmpty).join(' · ');
  }
}
