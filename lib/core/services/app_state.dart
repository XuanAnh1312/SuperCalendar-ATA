import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

/// In-memory sample data shared by every screen (Phase 1: no database yet).
class AppState extends ChangeNotifier {
  AppState() {
    selectedDay = today;
  }

  /// The demo data is anchored on the date used in the design.
  final DateTime today = DateTime(2026, 10, 5);
  final String userName = 'Mia';
  final String userFullName = 'Mia Chen';

  // ---- Navigation -------------------------------------------------------

  int tab = 0;
  bool weekView = false;
  late DateTime selectedDay;

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  void setWeekView(bool value) {
    weekView = value;
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  // ---- Tasks ------------------------------------------------------------

  int _nextId = 100;

  final List<Task> tasks = [
    Task(
      id: 't1',
      title: 'Send launch proposal',
      shortTitle: 'Send proposal',
      due: 'Today',
      detail: 'High',
      tagColor: AppColors.pink,
      priority: 'High',
      repeat: 'Weekdays',
      category: 'Work',
      estimate: '45 min',
      tags: ['launch', 'client'],
      notes: 'Include updated timeline, package options and the revised launch date.',
      subtasks: [
        Subtask('Finalize pricing table', done: true),
        Subtask('Attach project timeline'),
        Subtask('Proofread email'),
      ],
    ),
    Task(
      id: 't2',
      title: 'Review October budget',
      shortTitle: 'Review budget',
      due: 'Today',
      detail: 'Finance',
      tagColor: AppColors.blue,
      category: 'Finance',
      colorIndex: 2,
    ),
    Task(
      id: 't3',
      title: 'Book dentist appointment',
      shortTitle: 'Book dentist',
      due: 'Today',
      detail: 'Health',
      tagColor: AppColors.green,
      completed: true,
      category: 'Health',
      colorIndex: 2,
    ),
    Task(
      id: 't4',
      title: 'Pick up dry cleaning',
      due: 'Tue',
      detail: 'Personal',
      tagColor: AppColors.yellow,
      time: 'Tue · 6:00 PM',
      colorIndex: 3,
    ),
    Task(
      id: 't5',
      title: 'Outline newsletter',
      due: 'Wed',
      detail: '45 min',
      tagColor: AppColors.purple,
      time: 'Wed · 10:00 AM',
      category: 'Work',
      estimate: '45 min',
    ),
    Task(
      id: 't6',
      title: 'Buy oat milk and berries',
      due: '',
      detail: 'Shopping',
      tagColor: AppColors.green,
      time: 'Anytime',
      category: 'Shopping',
      colorIndex: 2,
    ),
  ];

  int get remainingTasks => tasks.where((t) => !t.completed).length;

  /// The three tasks shown on the dashboard and lock screen widgets.
  List<Task> get dashboardTasks {
    const pinned = ['t1', 't3', 't2'];
    final picked = [for (final id in pinned) ...tasks.where((t) => t.id == id)];
    for (final t in tasks) {
      if (picked.length >= 3) break;
      if (!picked.contains(t)) picked.add(t);
    }
    return picked;
  }

  void toggleTask(Task task) {
    task.completed = !task.completed;
    notifyListeners();
  }

  void addTask(String title) {
    final clean = title.trim();
    if (clean.isEmpty) return;
    tasks.insert(
      0,
      Task(
        id: 't${_nextId++}',
        title: clean,
        due: 'Today',
        detail: 'New',
        tagColor: AppColors.purple,
      ),
    );
    notifyListeners();
  }

  void deleteTask(Task task) {
    tasks.remove(task);
    notifyListeners();
  }

  /// [newIndex] is the position after the item at [oldIndex] is removed.
  void reorderTasks(int oldIndex, int newIndex) {
    tasks.insert(newIndex, tasks.removeAt(oldIndex));
    notifyListeners();
  }

  /// Call after mutating a model object in place.
  void touch() => notifyListeners();

  // ---- Events -----------------------------------------------------------

  late final List<CalendarEvent> events = [
    _event('Team sync', 5, 9, 0, 90, 2, location: 'Room A203'),
    _event('Lunch with Ana', 5, 11, 30, 60, 1, category: 'Personal'),
    _event('Design review', 5, 14, 0, 60, 3, location: 'Studio 4'),
    _event('1:1 with Sam', 6, 10, 0, 60, 0),
    _event('Gym', 7, 11, 30, 90, 1, category: 'Health'),
    _event('Launch', 9, 10, 0, 120, 0, location: 'Main stage'),
    _event('Coffee with Lina', 9, 15, 0, 60, 3, category: 'Personal'),
    _event('Sprint planning', 2, 9, 30, 60, 0),
    _event('Yoga', 2, 18, 0, 60, 1, category: 'Health'),
    _event('Budget check', 14, 13, 0, 60, 0, category: 'Finance'),
    _event('Run club', 14, 18, 30, 60, 1, category: 'Health'),
    _event('Dinner with Mom', 17, 19, 0, 90, 3, category: 'Personal'),
    _event('Workout', 17, 7, 0, 60, 1, category: 'Health'),
    _event('Book club', 21, 19, 30, 90, 3, category: 'Personal'),
    _event('Photo shoot', 23, 10, 0, 120, 3),
    _event('Pilates', 23, 17, 0, 60, 1, category: 'Health'),
    _event('Retro', 26, 15, 0, 60, 0),
    _event('Swim', 26, 7, 30, 45, 1, category: 'Health'),
    _event('Client call', 28, 11, 0, 45, 0),
    _event('Month wrap-up', 30, 16, 0, 60, 0),
  ];

  // Palette index: 0 purple, 1 green, 2 blue, 3 pink.
  static const _eventColors = [
    AppColors.purple,
    AppColors.green,
    AppColors.blue,
    AppColors.pink,
  ];
  static const _eventAccents = [
    AppColors.primary,
    AppColors.greenDot,
    AppColors.primary,
    AppColors.pinkStrong,
  ];

  CalendarEvent _event(
    String title,
    int day,
    int hour,
    int minute,
    int duration,
    int palette, {
    String location = '',
    String category = 'Work',
  }) {
    final start = hour * 60 + minute;
    return CalendarEvent(
      id: 'e${_nextId++}',
      title: title,
      date: DateTime(2026, 10, day),
      startMinutes: start,
      endMinutes: start + duration,
      color: _eventColors[palette],
      accent: _eventAccents[palette],
      location: location,
      category: category,
    );
  }

  List<CalendarEvent> eventsOn(DateTime day) {
    final list = events.where((e) => sameDay(e.date, day)).toList();
    list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return list;
  }

  void addEvent(CalendarEvent event) {
    events.add(event);
    selectedDay = event.date;
    notifyListeners();
  }

  String newEventId() => 'e${_nextId++}';

  // ---- Habits -----------------------------------------------------------

  final List<Habit> habits = [
    Habit(
      id: 'h1',
      title: 'Morning meditation',
      shortTitle: 'Meditate',
      schedule: 'Daily · 08:00 · auto-generated',
      occurrence: 'Today, 8:00 AM · daily occurrence',
      icon: LucideIcons.brain,
      color: AppColors.purple,
      done: true,
    ),
    Habit(
      id: 'h2',
      title: 'Read 20 minutes',
      shortTitle: 'Read 20 min',
      schedule: 'Mon, Wed, Fri · 19:30 · auto-generated',
      occurrence: 'Today, 7:30 PM · weekly occurrence',
      icon: LucideIcons.bookOpen,
      color: AppColors.yellow,
      done: true,
    ),
    Habit(
      id: 'h3',
      title: 'Evening walk',
      shortTitle: 'Evening walk',
      schedule: 'Custom · sunset · auto-generated',
      occurrence: 'Today, sunset · custom occurrence',
      icon: LucideIcons.footprints,
      color: AppColors.green,
    ),
  ];

  void toggleHabit(Habit habit) {
    habit.done = !habit.done;
    habit.skipped = false;
    notifyListeners();
  }

  void skipHabit(Habit habit) {
    habit.skipped = true;
    habit.done = false;
    notifyListeners();
  }

  void deleteHabitOccurrence(Habit habit) {
    habits.remove(habit);
    notifyListeners();
  }

  // ---- Goals & notes ----------------------------------------------------

  final String goalTitle = 'Finish portfolio refresh';
  final double goalProgress = 0.67;

  String quickNote = 'Ask Lina for the launch photos before Friday.';

  void setQuickNote(String value) {
    quickNote = value.trim();
    notifyListeners();
  }
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Access without subscribing, for use in callbacks.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
