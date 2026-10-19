import 'package:flutter_application/core/data/repository.dart';

/// A repeating behaviour tracked by the user (§5.12).
///
/// The Rule defines the habit (title, schedule, etc.).  Each calendar day
/// that falls within the active period and matches the repeat rule generates
/// a [HabitOccurrence].  Changing a Rule's repeat rule only affects
/// occurrences from today onwards (BR-17).
class Habit {
  Habit({
    required this.id,
    required this.title,
    required this.shortTitle,
    this.icon = 'check',
    this.color,
    this.colorIndex = 0,
    required this.startDate,
    this.endDate,
    this.time,
    required this.repeatRule,
    this.reminderMinutes,
    this.isArchived = false,
    required this.createdAt,
    DateTime? updatedAt,
    // Legacy in-memory occurrence tracking (kept for backwards-compat)
    this.doneOn,
    this.skippedOn,
    this.removedOn,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Habit.fromJson(Map<String, dynamic> json) {
    final created = parseDate(json['createdAt']) ?? DateTime.now();
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      shortTitle: json['shortTitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'check',
      color: json['color'] as String?,
      colorIndex: json['colorIndex'] as int? ?? 0,
      startDate:
          parseDate(json['startDate']) ??
          parseDate(json['createdAt']) ??
          DateTime.now(),
      endDate: parseDate(json['endDate']),
      time: json['time'] as int?,
      repeatRule: json['repeatRule'] as String? ??
          json['schedule'] as String? ??
          'FREQ=DAILY',
      reminderMinutes: json['reminderMinutes'] as int?,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
      // Legacy
      doneOn: json['doneOn'] as String?,
      skippedOn: json['skippedOn'] as String?,
      removedOn: json['removedOn'] as String?,
    );
  }

  final String id;
  String title;

  /// Short version displayed on chips and the calendar grid.
  String shortTitle;

  /// Icon key resolved by the presentation layer (e.g. `'check'`, `'run'`).
  String icon;

  /// Optional hex colour string; null uses the theme accent.
  String? color;

  /// Palette index (legacy; prefer [color]).
  int colorIndex;

  /// Inclusive start date of the habit (date only, time stripped).
  DateTime startDate;

  /// Optional end date; null means the habit runs indefinitely.
  DateTime? endDate;

  /// Minutes since midnight for the preferred execution time; null = any time.
  int? time;

  /// RRULE string describing the repetition pattern (e.g. `'FREQ=DAILY'`).
  String repeatRule;

  /// Minutes before [time] to send a reminder; null = no reminder.
  int? reminderMinutes;

  bool isArchived;

  final DateTime createdAt;
  DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Legacy occurrence tracking (one day key per action)
  // These will be superseded by the [HabitOccurrence] table.

  /// `yyyy-mm-dd` of the last day the habit was marked Done.
  String? doneOn;

  /// `yyyy-mm-dd` of the last day the habit was Skipped.
  String? skippedOn;

  /// `yyyy-mm-dd` of the last day the occurrence was removed.
  String? removedOn;

  // ---------------------------------------------------------------------------
  // Derived helpers (legacy convenience)

  bool isDone(DateTime day) => doneOn == dayKey(day);
  bool isSkipped(DateTime day) => skippedOn == dayKey(day);
  bool isRemoved(DateTime day) => removedOn == dayKey(day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'shortTitle': shortTitle,
    'icon': icon,
    'color': color,
    'colorIndex': colorIndex,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'time': time,
    'repeatRule': repeatRule,
    'reminderMinutes': reminderMinutes,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    // Legacy
    'doneOn': doneOn,
    'skippedOn': skippedOn,
    'removedOn': removedOn,
  };
}

// ---------------------------------------------------------------------------

/// The state of a single occurrence of a [Habit] on a specific [date] (§5.13).
///
/// Stored in [Collections.habitOccurrences].  Occurrences are created on
/// demand (or by a background job) for every day that matches the Habit's
/// repeat rule.  Changing a Rule affects only occurrences from today onwards
/// (BR-02, BR-17).
class HabitOccurrence {
  HabitOccurrence({
    required this.id,
    required this.habitId,
    required this.date,
    this.status = OccurrenceStatus.pending,
    this.overrideData,
    this.completedAt,
  });

  factory HabitOccurrence.fromJson(Map<String, dynamic> json) =>
      HabitOccurrence(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        date: parseDate(json['date']) ?? DateTime.now(),
        status: OccurrenceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => OccurrenceStatus.pending,
        ),
        overrideData: json['overrideData'] as Map<String, dynamic>?,
        completedAt: parseDate(json['completedAt']),
      );

  final String id;

  /// The [Habit.id] this occurrence belongs to.
  final String habitId;

  /// Calendar day (time stripped).
  final DateTime date;

  OccurrenceStatus status;

  /// Per-occurrence overrides (e.g. custom title or time for this day only).
  Map<String, dynamic>? overrideData;

  /// When status was set to [OccurrenceStatus.done].
  DateTime? completedAt;

  bool get isDone => status == OccurrenceStatus.done;
  bool get isSkipped => status == OccurrenceStatus.skipped;

  Map<String, dynamic> toJson() => {
    'id': id,
    'habitId': habitId,
    'date': date.toIso8601String(),
    'status': status.name,
    'overrideData': overrideData,
    'completedAt': completedAt?.toIso8601String(),
  };
}

enum OccurrenceStatus { pending, done, skipped, deleted }
