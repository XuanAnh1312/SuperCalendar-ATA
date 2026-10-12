import 'package:flutter/material.dart';

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.color,
    required this.accent,
    this.location = '',
    this.category = 'Personal',
  });

  final String id;
  String title;

  /// Day of the event, time of day stripped.
  DateTime date;

  /// Minutes since midnight.
  int startMinutes;
  int endMinutes;

  /// Pastel fill used for event blocks.
  Color color;

  /// Strong color used for calendar dots.
  Color accent;
  String location;
  String category;

  String get startLabel => formatMinutes(startMinutes);

  static String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
