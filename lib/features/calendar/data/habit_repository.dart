import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';

class HabitRepository extends Repository<Habit> {
  HabitRepository(DocumentStore store) : super(store, Collections.habits);

  @override
  Habit decode(Map<String, dynamic> json) => Habit.fromJson(json);

  @override
  Map<String, dynamic> encode(Habit item) => item.toJson();

  @override
  String idOf(Habit item) => item.id;

  /// Habits that still have an occurrence on [day].
  List<Habit> occurrences(DateTime day) =>
      items.where((h) => !h.isRemoved(day)).toList();

  void add(Habit habit) {
    items.add(habit);
    persist(habit);
    notifyListeners();
  }

  void toggle(Habit habit, DateTime day) {
    habit.doneOn = habit.isDone(day) ? null : dayKey(day);
    habit.skippedOn = null;
    _save(habit);
  }

  /// Skips today's occurrence; future repeats are unaffected.
  void skip(Habit habit, DateTime day) {
    habit.skippedOn = dayKey(day);
    habit.doneOn = null;
    _save(habit);
  }

  /// Removes today's occurrence only.
  void removeOccurrence(Habit habit, DateTime day) {
    habit.removedOn = dayKey(day);
    _save(habit);
  }

  void _save(Habit habit) {
    persist(habit);
    notifyListeners();
  }
}
