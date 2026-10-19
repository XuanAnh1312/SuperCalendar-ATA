import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';

// ---------------------------------------------------------------------------
// EventException
// ---------------------------------------------------------------------------

/// Records a change to one specific occurrence of a recurring event (§5.7).
///
/// When a user edits or deletes a single occurrence of a recurring event
/// (BR-10 scope "one"), an [EventException] is persisted instead of mutating
/// the original [CalendarEvent.repeatRule].  The presentation layer must check
/// [exceptions] before expanding recurrences.
class EventException {
  EventException({
    required this.id,
    required this.eventId,
    required this.originalDate,
    this.isDeleted = false,
    this.overrideData,
  });

  factory EventException.fromJson(Map<String, dynamic> json) => EventException(
    id: json['id'] as String,
    eventId: json['eventId'] as String,
    originalDate: parseDate(json['originalDate']) ?? DateTime.now(),
    isDeleted: json['isDeleted'] as bool? ?? false,
    overrideData: json['overrideData'] as Map<String, dynamic>?,
  );

  /// Unique id for this exception record.
  final String id;

  /// The [CalendarEvent.id] of the repeating rule this exception belongs to.
  final String eventId;

  /// The date of the occurrence that was changed (date only, time stripped).
  final DateTime originalDate;

  /// True when this occurrence has been deleted rather than modified.
  bool isDeleted;

  /// Partial override fields (e.g. custom title or time for this day only).
  Map<String, dynamic>? overrideData;

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'originalDate': originalDate.toIso8601String(),
    'isDeleted': isDeleted,
    'overrideData': overrideData,
  };
}

// ---------------------------------------------------------------------------
// Delete scope — BR-10
// ---------------------------------------------------------------------------

/// Scope of a recurring-event edit or deletion (BR-10).
enum DeleteScope {
  /// Only this specific occurrence.
  one,

  /// This occurrence and all future ones (≥ occurrence date).
  fromThis,

  /// The entire series, including past and future occurrences.
  all,
}

// ---------------------------------------------------------------------------
// EventExceptionRepository
// ---------------------------------------------------------------------------

/// Stores [EventException] records in [Collections.eventExceptions].
///
/// Kept as a lightweight companion to [EventRepository] so exceptions can be
/// loaded and flushed independently.
class EventExceptionRepository extends Repository<EventException> {
  EventExceptionRepository(DocumentStore store)
    : super(store, Collections.eventExceptions);

  @override
  EventException decode(Map<String, dynamic> json) =>
      EventException.fromJson(json);

  @override
  Map<String, dynamic> encode(EventException item) => item.toJson();

  @override
  String idOf(EventException item) => item.id;

  // ── Queries ──────────────────────────────────────────────────────────────

  /// All exceptions that belong to [eventId].
  List<EventException> forEvent(String eventId) =>
      items.where((e) => e.eventId == eventId).toList();

  /// Whether [date] (date-only) has been deleted for [eventId].
  bool isDeleted(String eventId, DateTime date) => items.any(
    (e) =>
        e.eventId == eventId && _sameDate(e.originalDate, date) && e.isDeleted,
  );

  /// Override data (if any) for a specific occurrence of [eventId] on [date].
  Map<String, dynamic>? overrideFor(String eventId, DateTime date) {
    for (final e in items) {
      if (e.eventId == eventId &&
          _sameDate(e.originalDate, date) &&
          !e.isDeleted) {
        return e.overrideData;
      }
    }
    return null;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Marks [date] as a deleted occurrence for [eventId] (BR-10 scope "one").
  EventException markDeleted(String eventId, DateTime date) {
    // Re-use an existing exception for the same day if present.
    EventException? existing;
    for (final e in items) {
      if (e.eventId == eventId && _sameDate(e.originalDate, date)) {
        existing = e;
        break;
      }
    }
    if (existing != null) {
      existing.isDeleted = true;
      persist(existing);
      notifyListeners();
      return existing;
    }
    final ex = EventException(
      id: newId('exc'),
      eventId: eventId,
      originalDate: _dateOnly(date),
      isDeleted: true,
    );
    items.add(ex);
    persist(ex);
    notifyListeners();
    return ex;
  }

  /// Saves a data-override for [eventId] on [date] without deleting it.
  EventException saveOverride(
    String eventId,
    DateTime date,
    Map<String, dynamic> overrideData,
  ) {
    EventException? existing;
    for (final e in items) {
      if (e.eventId == eventId && _sameDate(e.originalDate, date)) {
        existing = e;
        break;
      }
    }
    if (existing != null) {
      existing.isDeleted = false;
      existing.overrideData = overrideData;
      persist(existing);
      notifyListeners();
      return existing;
    }
    final ex = EventException(
      id: newId('exc'),
      eventId: eventId,
      originalDate: _dateOnly(date),
      isDeleted: false,
      overrideData: overrideData,
    );
    items.add(ex);
    persist(ex);
    notifyListeners();
    return ex;
  }

  /// Removes all exception records for [eventId].
  void removeAll(String eventId) {
    final toRemove = forEvent(eventId).toList();
    for (final e in toRemove) {
      items.remove(e);
      erase(e);
    }
    if (toRemove.isNotEmpty) notifyListeners();
  }

  /// Removes exception records for [eventId] whose [originalDate] is on or
  /// after [fromDate].  Used for [DeleteScope.fromThis].
  void removeFrom(String eventId, DateTime fromDate) {
    final toRemove = items
        .where(
          (e) =>
              e.eventId == eventId &&
              !e.originalDate.isBefore(_dateOnly(fromDate)),
        )
        .toList();
    for (final e in toRemove) {
      items.remove(e);
      erase(e);
    }
    if (toRemove.isNotEmpty) notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

// ---------------------------------------------------------------------------
// EventRepository
// ---------------------------------------------------------------------------

/// Local events are stored on the device.  Events read from the system
/// calendar are held in memory only and merged in when listing a day.
///
/// Recurring-event mutations follow BR-10:
/// - [DeleteScope.one]: inserts an [EventException] marking that occurrence
///   as deleted; the rule is preserved.
/// - [DeleteScope.fromThis]: shortens [CalendarEvent.repeatRule] by setting an
///   UNTIL clause on the day before, then removes future exceptions.
/// - [DeleteScope.all]: deletes the event and all its exceptions.
class EventRepository extends Repository<CalendarEvent> {
  EventRepository(DocumentStore store, {EventExceptionRepository? exceptions})
    : super(store, Collections.events) {
    _exceptions = exceptions;
  }

  final List<CalendarEvent> _systemEvents = [];

  /// Optional companion repository.  When provided, [deleteScope] and
  /// [saveScope] can persist exceptions to disk.  If null, exception records
  /// exist in-memory only through a temporary internal instance.
  EventExceptionRepository? _exceptions;

  /// Attach the companion exception repository after construction.  Call this
  /// once during app startup before any delete operations.
  void attachExceptions(EventExceptionRepository repo) {
    _exceptions ??= repo;
  }

  // ── Repository boilerplate ───────────────────────────────────────────────

  @override
  CalendarEvent decode(Map<String, dynamic> json) =>
      CalendarEvent.fromJson(json);

  @override
  Map<String, dynamic> encode(CalendarEvent item) => item.toJson();

  @override
  String idOf(CalendarEvent item) => item.id;

  // ── Queries ──────────────────────────────────────────────────────────────

  List<CalendarEvent> get systemEvents => List.unmodifiable(_systemEvents);

  CalendarEvent? byId(String id) {
    for (final event in [...items, ..._systemEvents]) {
      if (event.id == id) return event;
    }
    return null;
  }

  /// Local and system events on [day], earliest first.
  ///
  /// When [exceptions] is attached, occurrences that have been individually
  /// deleted via [deleteScope] are filtered out.
  List<CalendarEvent> on(DateTime day) {
    final exc = _exceptions;
    final list = [
      for (final e in items)
        if (e.isOn(day) && (exc == null || !exc.isDeleted(e.id, day)))
          if (!e.isRecurring)
            e
          else if (exc?.overrideFor(e.id, day) case final data?)
            CalendarEvent.fromJson(data)
          else
            e.occurrenceOn(day),
      ..._systemEvents.where((e) => e.isOn(day)),
    ];
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  // ── Simple mutations ──────────────────────────────────────────────────────

  void add(CalendarEvent event) {
    items.add(event);
    persist(event);
    notifyListeners();
  }

  /// Persists edits made to [event] in place. System events are read-only.
  void save(CalendarEvent event) {
    if (event.isSystem) return;
    persist(event);
    notifyListeners();
  }

  /// Simple delete for non-recurring events (or when the caller already
  /// determined the scope).  For recurring events use [deleteScope].
  void delete(CalendarEvent event) {
    if (event.isSystem || !items.remove(event)) return;
    erase(event);
    _exceptions?.removeAll(event.id);
    notifyListeners();
  }

  /// Puts back an event removed by [delete] (BR-13 undo).
  void restore(CalendarEvent event) {
    if (byId(event.id) != null) return;
    add(event);
  }

  // ── Recurring-event mutations (BR-10) ─────────────────────────────────────

  /// Deletes an event according to [scope] (BR-10).
  ///
  /// - [DeleteScope.one]: the occurrence on [occurrenceDate] is marked deleted
  ///   via [EventException]; the repeating rule is untouched.
  /// - [DeleteScope.fromThis]: adds an `UNTIL` clause to the RRULE so
  ///   recurrences end the day before [occurrenceDate], then cleans up future
  ///   exceptions.  If the rule has no occurrences left the event is removed.
  /// - [DeleteScope.all]: removes the event and all its exceptions.
  ///
  /// [occurrenceDate] is only used for [DeleteScope.one] and
  /// [DeleteScope.fromThis]; it can be null for [DeleteScope.all].
  void deleteScope(
    CalendarEvent event,
    DeleteScope scope, {
    DateTime? occurrenceDate,
  }) {
    if (event.isSystem) return;

    switch (scope) {
      case DeleteScope.one:
        final date = occurrenceDate ?? event.startTime;
        _ensureExceptions().markDeleted(event.id, date);
        notifyListeners();

      case DeleteScope.fromThis:
        final date = occurrenceDate ?? event.startTime;
        // From the very first repeat on means the whole series.
        if (!dateOnlyOf(date).isAfter(dateOnlyOf(event.startTime))) {
          deleteScope(event, DeleteScope.all);
          return;
        }
        // Shorten the RRULE so the series ends before this occurrence.
        final until = date.subtract(const Duration(days: 1));
        event.repeatRule = _addUntil(event.repeatRule ?? '', until);
        event.updatedAt = DateTime.now();
        persist(event);
        _exceptions?.removeFrom(event.id, date);
        notifyListeners();

      case DeleteScope.all:
        if (!items.remove(event)) return;
        erase(event);
        _exceptions?.removeAll(event.id);
        notifyListeners();
    }
  }

  /// Saves edits to a recurring event according to [scope].
  ///
  /// - [DeleteScope.one]: saves the changes as an [EventException.overrideData]
  ///   for [occurrenceDate] without touching the rule.
  /// - [DeleteScope.fromThis] / [DeleteScope.all]: directly mutates and
  ///   persists the event (standard save).
  void saveScope(
    CalendarEvent event,
    DeleteScope scope, {
    DateTime? occurrenceDate,
  }) {
    if (event.isSystem) return;

    if (scope == DeleteScope.one) {
      final date = occurrenceDate ?? event.startTime;
      _ensureExceptions().saveOverride(event.id, date, event.toJson());
      notifyListeners();
    } else {
      save(event);
    }
  }

  // ── System calendar ───────────────────────────────────────────────────────

  /// Replaces the events read from the system calendar.
  void setSystemEvents(List<CalendarEvent> events) {
    _systemEvents
      ..clear()
      ..addAll(events);
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static DateTime dateOnlyOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns the attached exceptions repo, or creates a transient one.
  EventExceptionRepository _ensureExceptions() {
    return _exceptions ??= EventExceptionRepository(store);
  }

  /// Appends or replaces an `UNTIL=<yyyymmdd>` clause in an RRULE string.
  static String _addUntil(String rrule, DateTime until) {
    final untilStr =
        '${until.year.toString().padLeft(4, '0')}'
        '${until.month.toString().padLeft(2, '0')}'
        '${until.day.toString().padLeft(2, '0')}';
    // Remove existing UNTIL or COUNT to avoid conflicts.
    var result = rrule
        .split(';')
        .where((p) => !p.startsWith('UNTIL=') && !p.startsWith('COUNT='))
        .join(';');
    if (result.isNotEmpty && !result.endsWith(';')) result += ';';
    result += 'UNTIL=$untilStr';
    return result;
  }
}
