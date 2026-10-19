import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/features/vip/domain/template.dart';

/// Writes the first-run sample data, anchored on the device's current day so
/// the app opens with a believable week.
void seedSampleData(AppState app) {
  final today = app.today;
  final now = app.now;
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  var counter = 0;
  CalendarEvent event(
    String title,
    int offset,
    int hour,
    int minute,
    int duration,
    int color, {
    String location = '',
    String category = 'Work',
    int? reminder,
  }) {
    final date = day(offset);
    final start = DateTime(date.year, date.month, date.day, hour, minute);
    return CalendarEvent(
      id: 'seed_event_${counter++}',
      title: title,
      startTime: start,
      endTime: start.add(Duration(minutes: duration)),
      location: location,
      reminderMinutes: reminder,
      colorIndex: color,
      category: category,
    );
  }

  // Color indexes: 0 lavender, 1 pink, 2 green, 3 yellow, 4 blue.
  final events = [
    event('Team sync', 0, 9, 0, 90, 4, location: 'Room A203', reminder: 15),
    event('Lunch with Ana', 0, 11, 30, 60, 2, category: 'Personal'),
    event('Design review', 0, 14, 0, 60, 1, location: 'Studio 4', reminder: 15),
    event('1:1 with Sam', 1, 10, 0, 60, 0),
    event('Gym', 2, 11, 30, 90, 2, category: 'Health'),
    event('Launch', 4, 10, 0, 120, 0, location: 'Main stage', reminder: 30),
    event('Coffee with Lina', 4, 15, 0, 60, 1, category: 'Personal'),
    event('Sprint planning', -3, 9, 30, 60, 0),
    event('Yoga', -3, 18, 0, 60, 2, category: 'Health'),
    event('Budget check', 9, 13, 0, 60, 0, category: 'Finance'),
    event('Run club', 9, 18, 30, 60, 2, category: 'Health'),
    event('Dinner with Mom', 12, 19, 0, 90, 1, category: 'Personal'),
    event('Workout', 12, 7, 0, 60, 2, category: 'Health'),
    event('Book club', 16, 19, 30, 90, 1, category: 'Personal'),
    event('Photo shoot', 18, 10, 0, 120, 1),
    event('Pilates', 18, 17, 0, 60, 2, category: 'Health'),
    event('Retro', 21, 15, 0, 60, 0),
    event('Swim', 21, 7, 30, 45, 2, category: 'Health'),
    event('Client call', 23, 11, 0, 45, 0),
    event('Month wrap-up', 25, 16, 0, 60, 0),
  ];
  events.forEach(app.events.add);

  final tasks = [
    Task(
      id: 'seed_task_0',
      title: 'Send launch proposal',
      description: 'Include updated timeline, package options and the revised launch date.',
      dueDate: day(0),
      dueTime: 16 * 60,
      priority: Task.priorityHigh,
      createdAt: now,
      reminderMinutes: 30,
      repeat: 'Weekdays',
      category: 'Work',
      estimateMinutes: 45,
      colorIndex: 1,
      tags: ['launch', 'client'],
      subtasks: [
        Subtask('Finalize pricing table', done: true),
        Subtask('Attach project timeline'),
        Subtask('Proofread email'),
      ],
    ),
    Task(
      id: 'seed_task_1',
      title: 'Review October budget',
      dueDate: day(0),
      dueTime: 18 * 60,
      createdAt: now,
      category: 'Finance',
      colorIndex: 4,
    ),
    Task(
      id: 'seed_task_2',
      title: 'Book dentist appointment',
      dueDate: day(0),
      completed: true,
      createdAt: now,
      category: 'Health',
      colorIndex: 2,
    ),
    Task(
      id: 'seed_task_3',
      title: 'Pick up dry cleaning',
      dueDate: day(1),
      dueTime: 18 * 60,
      createdAt: now,
      colorIndex: 3,
    ),
    Task(
      id: 'seed_task_4',
      title: 'Outline newsletter',
      dueDate: day(2),
      dueTime: 10 * 60,
      createdAt: now,
      category: 'Work',
      estimateMinutes: 45,
    ),
    Task(
      id: 'seed_task_5',
      title: 'Buy oat milk and berries',
      createdAt: now,
      category: 'Shopping',
      colorIndex: 2,
    ),
  ];
  tasks.forEach(app.tasks.insert);

  final habits = [
    Habit(
      id: 'seed_habit_0',
      title: 'Morning meditation',
      shortTitle: 'Meditate',
      startDate: day(0),
      time: 8 * 60,
      repeatRule: 'FREQ=DAILY',
      icon: 'brain',
      colorIndex: 0,
      createdAt: now,
    ),
    Habit(
      id: 'seed_habit_1',
      title: 'Read 20 minutes',
      shortTitle: 'Read 20 min',
      startDate: day(0),
      time: 19 * 60 + 30,
      repeatRule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
      icon: 'book',
      colorIndex: 3,
      createdAt: now,
    ),
    Habit(
      id: 'seed_habit_2',
      title: 'Evening walk',
      shortTitle: 'Evening walk',
      startDate: day(0),
      repeatRule: 'FREQ=DAILY',
      icon: 'walk',
      colorIndex: 2,
      createdAt: now,
    ),
  ];
  habits.forEach(app.habits.add);
  app.habits.toggle(habits[0], today);
  app.habits.toggle(habits[1], today);

  app.notes.setQuick('Ask Lina for the launch photos before Friday.');
  app.notes.add(
    title: 'Java notes',
    content: 'Interfaces vs abstract classes. Revise generics before Friday.',
  );
  app.notes.add(
    title: 'Flutter notes',
    content: 'Keep UI and data separate. Theme must not depend on data.',
  );

  Template template(
    String id,
    String name,
    String description,
    int price,
    String preview,
    Color primary, {
    String typography = AppThemeData.typographyClean,
    double radius = 18,
  }) {
    return Template(
      id: id,
      name: name,
      description: description,
      creatorId: Template.systemCreator,
      price: price,
      preview: preview,
      themeData: AppThemeData(
        id: 'theme_$id',
        name: name,
        primary: primary,
        typography: typography,
        radius: radius,
      ),
      published: true,
    );
  }

  final templates = [
    template(
      'sakura_morning',
      'Sakura Morning',
      'Pastel pink productivity theme.',
      29000,
      '🌸',
      const Color(0xFFD96C8E),
      radius: 22,
    ),
    template(
      'ocean_study',
      'Ocean Study',
      'Calm blues for long study sessions.',
      19000,
      '🩵',
      const Color(0xFF4F8FD9),
    ),
    template(
      'forest',
      'Forest',
      'Soft greens with airy typography.',
      0,
      '🌿',
      const Color(0xFF3F9B72),
      typography: AppThemeData.typographyAiry,
    ),
    template(
      'minimal_gray',
      'Minimal Gray',
      'Quiet neutrals and tighter corners.',
      0,
      '🩶',
      const Color(0xFF4B5563),
      radius: 12,
    ),
  ];
  templates.forEach(app.templates.saveTemplate);
}
