import 'package:flutter/material.dart';

class Habit {
  Habit({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.schedule,
    required this.occurrence,
    required this.icon,
    required this.color,
    this.done = false,
    this.skipped = false,
  });

  final String id;
  final String title;
  final String shortTitle;

  /// Repetition summary, e.g. `Daily · 08:00 · auto-generated`.
  final String schedule;

  /// Today's occurrence, e.g. `Today, 7:30 PM · weekly occurrence`.
  final String occurrence;
  final IconData icon;
  final Color color;
  bool done;
  bool skipped;
}
