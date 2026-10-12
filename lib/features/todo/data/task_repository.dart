import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

class TaskRepository extends Repository<Task> {
  TaskRepository(DocumentStore store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(store, Collections.tasks);

  final DateTime Function() _clock;

  @override
  Task decode(Map<String, dynamic> json) => Task.fromJson(json);

  @override
  Map<String, dynamic> encode(Task item) => item.toJson();

  @override
  String idOf(Task item) => item.id;

  @override
  void afterLoad() => items.sort((a, b) => a.order.compareTo(b.order));

  int get remaining => items.where((t) => !t.completed).length;

  Task? byId(String id) {
    for (final task in items) {
      if (task.id == id) return task;
    }
    return null;
  }

  List<Task> dueOn(DateTime day) => items.where((t) => t.isDueOn(day)).toList();

  /// Tasks that are not due on [day]: later, earlier or undated.
  List<Task> notDueOn(DateTime day) =>
      items.where((t) => !t.isDueOn(day)).toList();

  /// Up to three tasks for the dashboard and lock screen: today's first.
  List<Task> dashboard(DateTime day) {
    final picked = dueOn(day);
    for (final task in items) {
      if (picked.length >= 3) break;
      if (!picked.contains(task) && !task.completed) picked.add(task);
    }
    return picked.take(3).toList();
  }

  /// Up to [limit] incomplete tasks for the lock screen notification:
  /// today's first, then the rest in list order.
  List<Task> pending(DateTime day, {int limit = 3}) {
    final open = items.where((t) => !t.completed);
    return [
      ...open.where((t) => t.isDueOn(day)),
      ...open.where((t) => !t.isDueOn(day)),
    ].take(limit).toList();
  }

  /// Creates a task at the top of the list, due on [dueDate].
  Task? add(String title, {DateTime? dueDate, int? reminderMinutes}) {
    final clean = title.trim();
    if (clean.isEmpty) return null;
    final now = _clock();
    final task = Task(
      id: newId('task'),
      title: clean,
      dueDate: dueDate == null ? null : dateOnly(dueDate),
      createdAt: now,
      reminderMinutes: reminderMinutes,
    );
    items.insert(0, task);
    _renumber();
    notifyListeners();
    return task;
  }

  /// Adds a fully built task without touching the order of the others.
  void insert(Task task) {
    task.order = items.length;
    items.add(task);
    persist(task);
    notifyListeners();
  }

  void toggle(Task task) => setCompleted(task, !task.completed);

  void setCompleted(Task task, bool completed) {
    task.completed = completed;
    save(task);
  }

  /// Persists edits made to [task] in place.
  void save(Task task) {
    task.updatedAt = _clock();
    persist(task);
    notifyListeners();
  }

  void delete(Task task) {
    if (!items.remove(task)) return;
    erase(task);
    notifyListeners();
  }

  /// [newIndex] is the position after the item at [oldIndex] is removed.
  void reorder(int oldIndex, int newIndex) {
    items.insert(newIndex, items.removeAt(oldIndex));
    _renumber();
    notifyListeners();
  }

  void _renumber() {
    for (var i = 0; i < items.length; i++) {
      if (items[i].order != i || i == 0) {
        items[i].order = i;
        persist(items[i]);
      }
    }
  }
}
