import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

class TaskRepository extends Repository<Task> {
  TaskRepository(DocumentStore store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(store, Collections.tasks);

  final DateTime Function() _clock;

  // ── Recurring tasks (AC-25) ───────────────────────────────────────────────

  /// Returns the next [dueDate] for a recurring [task] after [completedOn].
  ///
  /// Supported repeat values (case-insensitive):
  ///   `'Daily'`    → +1 day
  ///   `'Weekdays'` → skip to Mon when completing on Fri/Sat/Sun
  ///   `'Weekly'`   → +7 days
  ///   `'Monthly'`  → same day next month (clamped to last day of month)
  ///   `'Never'`    → null (not recurring)
  ///
  /// (AC-25) Completing a 'Weekdays' task on Friday → next is Monday.
  static DateTime? nextOccurrence(Task task, {DateTime? completedOn}) {
    final base = completedOn ?? task.dueDate;
    if (base == null) return null;

    switch (task.repeat.trim().toLowerCase()) {
      case 'daily':
        return dateOnly(base.add(const Duration(days: 1)));

      case 'weekdays':
        // Skip Sat (6) and Sun (7) — next weekday after base.
        var next = dateOnly(base.add(const Duration(days: 1)));
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case 'weekly':
        return dateOnly(base.add(const Duration(days: 7)));

      case 'monthly':
        // Same day next month, clamped to the last day of that month.
        final targetMonth = base.month + 1;
        final targetYear = base.year + (targetMonth > 12 ? 1 : 0);
        final month = targetMonth > 12 ? targetMonth - 12 : targetMonth;
        final lastDay = DateTime(targetYear, month + 1, 0).day;
        return DateTime(targetYear, month, base.day.clamp(1, lastDay));

      default:
        // 'Never' or unknown — not recurring.
        return null;
    }
  }

  /// Completes [task] and, when it is recurring, creates the next occurrence.
  ///
  /// Returns the newly created recurring task, or null when the task is not
  /// recurring or was already completed.
  Task? completeAndReschedule(Task task) {
    if (task.completed) return null;
    final completedOn = task.dueDate;
    setCompleted(task, true);

    final next = nextOccurrence(task, completedOn: completedOn);
    if (next == null) return null;

    final newTask = Task(
      id: newId('task'),
      title: task.title,
      description: task.description,
      dueDate: next,
      dueTime: task.dueTime,
      priority: task.priority,
      createdAt: _clock(),
      reminderMinutes: task.reminderMinutes,
      repeat: task.repeat,
      category: task.category,
      estimateMinutes: task.estimateMinutes,
      colorIndex: task.colorIndex,
      tags: List<String>.from(task.tags),
      subtasks: [],
    );
    insert(newTask);
    return newTask;
  }

  // ── Tag management (BR-13) ────────────────────────────────────────────────

  /// Adds [tag] to [task]'s tag list and persists.
  ///
  /// Does nothing when [tag] is blank or already present.
  void addTag(Task task, String tag) {
    final clean = tag.trim();
    if (clean.isEmpty || task.tags.contains(clean)) return;
    task.tags.add(clean);
    save(task);
  }

  /// Removes [tag] from [task]'s tag list and persists.
  ///
  /// Does nothing when the tag is not found.
  void removeTag(Task task, String tag) {
    if (!task.tags.remove(tag.trim())) return;
    save(task);
  }

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

  /// Removes [task] from the repository and storage.
  ///
  /// Returns the deleted task so the caller can offer an undo (BR-13);
  /// null when the task was not in the list.
  Task? delete(Task task) {
    if (!items.remove(task)) return null;
    erase(task);
    notifyListeners();
    return task;
  }

  /// Restores a previously [delete]d [task] at the top of the list (BR-13 undo).
  void restore(Task task) {
    items.insert(0, task);
    _renumber();
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
