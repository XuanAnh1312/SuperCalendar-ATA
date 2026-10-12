import 'package:flutter_application/core/data/repository.dart';

class Habit {
  Habit({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.schedule,
    required this.occurrence,
    required this.icon,
    required this.colorIndex,
    this.doneOn,
    this.skippedOn,
    this.removedOn,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    shortTitle: json['shortTitle'] as String? ?? '',
    schedule: json['schedule'] as String? ?? '',
    occurrence: json['occurrence'] as String? ?? '',
    icon: json['icon'] as String? ?? 'check',
    colorIndex: json['colorIndex'] as int? ?? 0,
    doneOn: json['doneOn'] as String?,
    skippedOn: json['skippedOn'] as String?,
    removedOn: json['removedOn'] as String?,
  );

  final String id;
  final String title;
  final String shortTitle;

  /// Repetition summary, e.g. `Daily · 08:00 · auto-generated`.
  final String schedule;

  /// Today's occurrence, e.g. `Today, 7:30 PM · weekly occurrence`.
  final String occurrence;

  /// Key of the icon, resolved to an `IconData` by the presentation layer.
  final String icon;
  final int colorIndex;

  // Day keys (`yyyy-mm-dd`) of the last day each action applied to, so an
  // occurrence resets by itself the next day.
  String? doneOn;
  String? skippedOn;
  String? removedOn;

  bool isDone(DateTime day) => doneOn == dayKey(day);
  bool isSkipped(DateTime day) => skippedOn == dayKey(day);
  bool isRemoved(DateTime day) => removedOn == dayKey(day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'shortTitle': shortTitle,
    'schedule': schedule,
    'occurrence': occurrence,
    'icon': icon,
    'colorIndex': colorIndex,
    'doneOn': doneOn,
    'skippedOn': skippedOn,
    'removedOn': removedOn,
  };
}
