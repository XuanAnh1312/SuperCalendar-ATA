import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';

// ---------------------------------------------------------------------------
// HabitOccurrenceRepository
// ---------------------------------------------------------------------------

/// Persists [HabitOccurrence] records in [Collections.habitOccurrences].
///
/// Occurrences are the source of truth for a habit's daily state.  They are
/// created on demand when the user first interacts with a day, and are never
/// modified by changes to the parent [Habit] rule (BR-02).
///
/// When the user changes a [Habit]'s [Habit.repeatRule], the presentation
/// layer must call [deleteFrom] to purge future pending occurrences so they
/// can be re-generated according to the new rule (BR-17).
class HabitOccurrenceRepository extends Repository<HabitOccurrence> {
  HabitOccurrenceRepository(DocumentStore store)
    : super(store, Collections.habitOccurrences);

  @override
  HabitOccurrence decode(Map<String, dynamic> json) =>
      HabitOccurrence.fromJson(json);

  @override
  Map<String, dynamic> encode(HabitOccurrence item) => item.toJson();

  @override
  String idOf(HabitOccurrence item) => item.id;

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Returns all occurrences that belong to [habitId].
  List<HabitOccurrence> forHabit(String habitId) =>
      items.where((o) => o.habitId == habitId).toList();

  /// Returns the occurrence for [habitId] on [date], or null if none has been
  /// recorded yet.
  HabitOccurrence? find(String habitId, DateTime date) {
    for (final o in items) {
      if (o.habitId == habitId && _sameDate(o.date, date)) return o;
    }
    return null;
  }

  /// Convenience: the [OccurrenceStatus] for [habitId] on [date], defaulting
  /// to [OccurrenceStatus.pending] when no record exists.
  OccurrenceStatus statusOn(String habitId, DateTime date) =>
      find(habitId, date)?.status ?? OccurrenceStatus.pending;

  /// All recorded occurrences for [habitId], sorted ascending by date.
  List<HabitOccurrence> historyFor(String habitId) {
    final list = forHabit(habitId).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Occurrences for [habitId] that are [OccurrenceStatus.done], sorted
  /// ascending.  Useful for streak and goal calculations.
  List<HabitOccurrence> completedFor(String habitId) =>
      historyFor(habitId).where((o) => o.isDone).toList();

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Marks [habitId] as [OccurrenceStatus.done] on [date].
  ///
  /// Creates the occurrence record if it does not already exist (BR-02: the
  /// rule is never touched).
  HabitOccurrence markDone(String habitId, DateTime date) =>
      _upsert(habitId, date, OccurrenceStatus.done, completedAt: DateTime.now());

  /// Marks [habitId] as [OccurrenceStatus.skipped] on [date].
  ///
  /// Subsequent occurrences on other days remain unaffected (AC-19).
  HabitOccurrence markSkipped(String habitId, DateTime date) =>
      _upsert(habitId, date, OccurrenceStatus.skipped);

  /// Marks [habitId] as [OccurrenceStatus.deleted] on [date] (soft-delete of
  /// a single occurrence; the rule continues for future days).
  HabitOccurrence markDeleted(String habitId, DateTime date) =>
      _upsert(habitId, date, OccurrenceStatus.deleted);

  /// Resets [habitId] on [date] back to [OccurrenceStatus.pending], removing
  /// any prior Done / Skipped / Deleted state.
  HabitOccurrence markPending(String habitId, DateTime date) =>
      _upsert(habitId, date, OccurrenceStatus.pending, completedAt: null);

  /// Toggles the [habitId] occurrence on [date] between done and pending.
  /// Returns the updated occurrence.
  HabitOccurrence toggle(String habitId, DateTime date) {
    final current = statusOn(habitId, date);
    if (current == OccurrenceStatus.done) {
      return markPending(habitId, date);
    } else {
      return markDone(habitId, date);
    }
  }

  /// Saves [overrideData] for [habitId] on [date] (e.g. a custom title or
  /// time for that specific day only).  Does not change the status.
  HabitOccurrence saveOverride(
    String habitId,
    DateTime date,
    Map<String, dynamic> overrideData,
  ) {
    final existing = find(habitId, date);
    if (existing != null) {
      existing.overrideData = overrideData;
      persist(existing);
      notifyListeners();
      return existing;
    }
    return _upsert(
      habitId,
      date,
      OccurrenceStatus.pending,
      overrideData: overrideData,
    );
  }

  // ── BR-17: Repeat-rule change ─────────────────────────────────────────────

  /// Deletes all [OccurrenceStatus.pending] occurrences for [habitId] that
  /// fall on or after [fromDate].
  ///
  /// Call this immediately after changing [Habit.repeatRule] so that pending
  /// occurrences based on the old rule are purged.  Past Done/Skipped/Deleted
  /// records are preserved (BR-17, AC-20).
  void deleteFrom(String habitId, DateTime fromDate) {
    final toRemove = items
        .where(
          (o) =>
              o.habitId == habitId &&
              o.status == OccurrenceStatus.pending &&
              !o.date.isBefore(_dateOnly(fromDate)),
        )
        .toList();
    for (final o in toRemove) {
      items.remove(o);
      erase(o);
    }
    if (toRemove.isNotEmpty) notifyListeners();
  }

  /// Removes ALL occurrence records for [habitId] (called when the habit
  /// itself is permanently deleted).
  void deleteAllFor(String habitId) {
    final toRemove = forHabit(habitId).toList();
    for (final o in toRemove) {
      items.remove(o);
      erase(o);
    }
    if (toRemove.isNotEmpty) notifyListeners();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  HabitOccurrence _upsert(
    String habitId,
    DateTime date,
    OccurrenceStatus status, {
    DateTime? completedAt,
    Map<String, dynamic>? overrideData,
    bool clearCompletedAt = false,
  }) {
    final existing = find(habitId, date);
    if (existing != null) {
      existing.status = status;
      if (status == OccurrenceStatus.done) {
        existing.completedAt = completedAt ?? DateTime.now();
      } else if (status == OccurrenceStatus.pending || clearCompletedAt) {
        existing.completedAt = null;
      }
      if (overrideData != null) existing.overrideData = overrideData;
      persist(existing);
      notifyListeners();
      return existing;
    }
    final occurrence = HabitOccurrence(
      id: newId('occ'),
      habitId: habitId,
      date: _dateOnly(date),
      status: status,
      completedAt: status == OccurrenceStatus.done
          ? (completedAt ?? DateTime.now())
          : null,
      overrideData: overrideData,
    );
    items.add(occurrence);
    persist(occurrence);
    notifyListeners();
    return occurrence;
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

// ---------------------------------------------------------------------------
// HabitRepository
// ---------------------------------------------------------------------------

/// Manages [Habit] rules stored in [Collections.habits].
///
/// Each [Habit] is just the rule (title, schedule, icon, colour).  The daily
/// state lives in [HabitOccurrence] records managed by
/// [HabitOccurrenceRepository].  Changing a rule's repeat rule must only
/// affect occurrences from today onwards (BR-17); the caller is responsible
/// for passing the companion [occurrences] repository so this is enforced
/// automatically via [updateRepeatRule].
class HabitRepository extends Repository<Habit> {
  HabitRepository(DocumentStore store, {HabitOccurrenceRepository? occurrences})
      : super(store, Collections.habits) {
    _occurrences = occurrences;
  }

  /// Optional companion.  Attach after construction via [attachOccurrences].
  HabitOccurrenceRepository? _occurrences;

  /// Attaches the companion occurrence repository.  Call once at startup.
  void attachOccurrences(HabitOccurrenceRepository repo) {
    _occurrences ??= repo;
  }

  @override
  Habit decode(Map<String, dynamic> json) => Habit.fromJson(json);

  @override
  Map<String, dynamic> encode(Habit item) => item.toJson();

  @override
  String idOf(Habit item) => item.id;

  // ── Queries ──────────────────────────────────────────────────────────────

  /// All active (non-archived) habits.
  List<Habit> get active => items.where((h) => !h.isArchived).toList();

  /// Returns the habit with [id], or null.
  Habit? byId(String id) {
    for (final h in items) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Active habits whose rule is in effect on [day].
  ///
  /// Checks [Habit.startDate] ≤ [day] ≤ [Habit.endDate] (or no end date).
  /// Does NOT expand the RRULE — the caller filters occurrences by day using
  /// the RRULE engine or a simpler check; this just guards the date range.
  List<Habit> activeOn(DateTime day) => active.where((h) {
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(DateTime(h.startDate.year, h.startDate.month, h.startDate.day))) {
      return false;
    }
    final end = h.endDate;
    if (end != null && d.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }
    return true;
  }).toList();

  // ── Mutations ─────────────────────────────────────────────────────────────

  void add(Habit habit) {
    items.add(habit);
    persist(habit);
    notifyListeners();
  }

  /// Persists in-place edits to [habit].  For repeat-rule changes use
  /// [updateRepeatRule] so BR-17 is enforced.
  void save(Habit habit) {
    habit.updatedAt = DateTime.now();
    persist(habit);
    notifyListeners();
  }

  /// Changes [habit]'s [Habit.repeatRule] and purges pending future
  /// occurrences so they are re-generated from the new rule (BR-17, AC-20).
  ///
  /// Past Done/Skipped/Deleted records are preserved.
  void updateRepeatRule(Habit habit, String newRule, DateTime today) {
    habit.repeatRule = newRule;
    habit.updatedAt = DateTime.now();
    persist(habit);
    _occurrences?.deleteFrom(habit.id, today);
    notifyListeners();
  }

  void archive(Habit habit) {
    habit.isArchived = true;
    habit.updatedAt = DateTime.now();
    persist(habit);
    notifyListeners();
  }

  void delete(Habit habit) {
    if (!items.remove(habit)) return;
    erase(habit);
    _occurrences?.deleteAllFor(habit.id);
    notifyListeners();
  }

  // ── Legacy convenience wrappers (kept for backwards-compat with existing UI)

  /// Legacy: habits that should appear on [day] (not archived, within date
  /// range).  Prefer [activeOn] for new code.
  List<Habit> occurrences(DateTime day) => activeOn(day);

  /// Convenience: delegates to [HabitOccurrenceRepository.toggle].
  /// Falls back to the old in-memory flag when the occurrence repo is absent.
  void toggle(Habit habit, DateTime day) {
    if (_occurrences != null) {
      _occurrences!.toggle(habit.id, day);
    } else {
      // Legacy fallback
      habit.doneOn = habit.isDone(day) ? null : dayKey(day);
      habit.skippedOn = null;
      persist(habit);
      notifyListeners();
    }
  }

  /// Convenience: delegates to [HabitOccurrenceRepository.markSkipped].
  void skip(Habit habit, DateTime day) {
    if (_occurrences != null) {
      _occurrences!.markSkipped(habit.id, day);
    } else {
      habit.skippedOn = dayKey(day);
      habit.doneOn = null;
      persist(habit);
      notifyListeners();
    }
  }

  /// Convenience: delegates to [HabitOccurrenceRepository.markDeleted].
  void removeOccurrence(Habit habit, DateTime day) {
    if (_occurrences != null) {
      _occurrences!.markDeleted(habit.id, day);
    } else {
      habit.removedOn = dayKey(day);
      persist(habit);
      notifyListeners();
    }
  }
}
