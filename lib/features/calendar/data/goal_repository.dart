import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/calendar/domain/goal.dart';

/// Manages the user's weekly and monthly [Goal]s (§5.11, FR-07).
///
/// Weekly and Monthly goals are stored in the same collection but must never
/// be mixed in the same UI list (BR-03).  Status transitions (active →
/// completed / missed) follow BR-11 and are applied whenever [recalculate] is
/// called.
class GoalRepository extends Repository<Goal> {
  GoalRepository(DocumentStore store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(store, Collections.goals);

  final DateTime Function() _clock;

  @override
  Goal decode(Map<String, dynamic> json) => Goal.fromJson(json);

  @override
  Map<String, dynamic> encode(Goal item) => item.toJson();

  @override
  String idOf(Goal item) => item.id;

  @override
  void afterLoad() => recalculate();

  // ── Queries ──────────────────────────────────────────────────────────────

  /// All [GoalType.weekly] goals, newest period first.
  List<Goal> get weekly => _byType(GoalType.weekly);

  /// All [GoalType.monthly] goals, newest period first.
  List<Goal> get monthly => _byType(GoalType.monthly);

  List<Goal> _byType(GoalType type) {
    final list = items.where((g) => g.type == type).toList();
    list.sort((a, b) => b.periodStart.compareTo(a.periodStart));
    return list;
  }

  /// Goals whose period includes [day], filtered by [type].
  List<Goal> activeOn(DateTime day, GoalType type) => items
      .where(
        (g) =>
            g.type == type &&
            !day.isBefore(g.periodStart) &&
            !day.isAfter(g.periodEnd),
      )
      .toList();

  Goal? byId(String id) {
    for (final goal in items) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Creates and persists a new goal.
  Goal add({
    required GoalType type,
    required String title,
    String? icon,
    String? color,
    int? target,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final now = _clock();
    final goal = Goal(
      id: newId('goal'),
      type: type,
      title: title.trim(),
      icon: icon,
      color: color,
      target: target,
      periodStart: periodStart,
      periodEnd: periodEnd,
      createdAt: now,
    );
    items.add(goal);
    persist(goal);
    notifyListeners();
    return goal;
  }

  /// Increments [current] by 1 and re-evaluates the status (BR-11).
  void increment(Goal goal) {
    goal.current += 1;
    goal.updatedAt = _clock();
    goal.recalculate(_clock());
    persist(goal);
    notifyListeners();
  }

  /// Decrements [current] by 1, clamped to 0.
  void decrement(Goal goal) {
    if (goal.current <= 0) return;
    goal.current -= 1;
    goal.status = GoalStatus.active; // reopen if it was auto-completed
    goal.updatedAt = _clock();
    persist(goal);
    notifyListeners();
  }

  /// Persists edits made to [goal] in place.
  void save(Goal goal) {
    goal.updatedAt = _clock();
    goal.recalculate(_clock());
    persist(goal);
    notifyListeners();
  }

  void delete(Goal goal) {
    if (!items.remove(goal)) return;
    erase(goal);
    notifyListeners();
  }

  /// Puts back a goal removed by [delete] (BR-13 undo).
  void restore(Goal goal) {
    if (items.contains(goal)) return;
    items.add(goal);
    persist(goal);
    notifyListeners();
  }

  /// Re-evaluates all goals against today's date.  Call on app start and
  /// when the date changes (BR-11).
  void recalculate() {
    final today = _clock();
    var changed = false;
    for (final goal in items) {
      final before = goal.status;
      goal.recalculate(today);
      if (goal.status != before) {
        persist(goal);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
