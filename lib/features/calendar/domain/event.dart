import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

/// A time-boxed activity on the calendar (§5.5).
///
/// Events and Tasks are separate types and must not be used interchangeably
/// (BR-01).  Events from the system calendar have [source] ==
/// [sourceSystem] and are read-only in the Prototype (BR-16, FR-22.01).
class CalendarEvent {
  CalendarEvent({
    required this.id,
    this.calendarId = 'personal',
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location = '',
    this.categoryId,
    this.reminderMinutes,
    this.colorIndex = 0,
    this.color,
    this.repeatRule,
    this.notes = '',
    this.source = sourceLocal,
    this.externalId,
    // Legacy convenience fields
    this.category = 'Personal',
    this.calendar = 'Personal',
    List<String>? guests,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) : guests = guests ?? [],
       createdAt = createdAt ?? startTime,
       updatedAt = updatedAt ?? startTime;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final start = parseDate(json['startTime']) ?? DateTime.now();
    final created = parseDate(json['createdAt']) ?? start;
    return CalendarEvent(
      id: json['id'] as String,
      calendarId: json['calendarId'] as String? ?? 'personal',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startTime: start,
      endTime:
          parseDate(json['endTime']) ?? start.add(const Duration(hours: 1)),
      isAllDay: json['isAllDay'] as bool? ?? false,
      location: json['location'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      reminderMinutes:
          json['reminder'] as int? ?? json['reminderMinutes'] as int?,
      colorIndex: json['color'] as int? ?? json['colorIndex'] as int? ?? 0,
      color: json['colorHex'] as String?,
      repeatRule: json['repeatRule'] as String?,
      notes: json['notes'] as String? ?? '',
      source: json['source'] as String? ?? sourceLocal,
      externalId: json['externalId'] as String?,
      category: json['category'] as String? ?? 'Personal',
      calendar: json['calendar'] as String? ?? 'Personal',
      guests: [...?(json['guests'] as List?)?.cast<String>()],
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
    );
  }

  static const sourceLocal = 'local';
  static const sourceSystem = 'system_calendar';

  final String id;

  /// Id of the [CalendarSource] this event belongs to.
  String calendarId;

  String title;
  String description;
  DateTime startTime;
  DateTime endTime;

  /// True when the event spans the full day with no specific times.
  bool isAllDay;

  String location;

  /// Optional [Category.id] for colour-coded grouping.
  String? categoryId;

  /// Minutes before [startTime] to notify; null = no reminder.
  int? reminderMinutes;

  /// Legacy palette index (prefer [color]).
  int colorIndex;

  /// Hex colour override (e.g. `'#FF7BAC'`); null falls back to [colorIndex].
  String? color;

  /// RRULE string for recurring events; null = single occurrence (BR-10).
  String? repeatRule;

  /// Extra notes attached to this event (max 1000 chars per §5.5).
  String notes;

  /// [sourceLocal] or [sourceSystem].
  final String source;

  /// Id of the matching event in the Android calendar; null for local events.
  final String? externalId;

  // Legacy convenience fields kept for backwards-compat with existing code
  String category;
  String calendar;
  List<String> guests;

  final DateTime createdAt;
  DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Derived helpers

  bool get isSystem => source == sourceSystem;
  bool get isRecurring => repeatRule != null && repeatRule!.isNotEmpty;
  String get repeatLabel => switch (rruleWithoutUntil(repeatRule)) {
    null || '' => 'Never',
    'FREQ=DAILY' => 'Every day',
    'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR' => 'Weekdays',
    'FREQ=WEEKLY' => 'Every week',
    _ => 'Custom',
  };

  DateTime get date => dateOnly(startTime);
  int get startMinutes => startTime.hour * 60 + startTime.minute;

  int get endMinutes => sameDay(startTime, endTime)
      ? endTime.hour * 60 + endTime.minute
      : 24 * 60 - 1;

  String get startLabel => formatMinutes(startMinutes);
  String get timeRange => '$startLabel–${formatMinutes(endMinutes)}';

  /// True when this event (or one of its repeats) falls on [day].
  bool isOn(DateTime day) => isRecurring
      ? rruleOccursOn(repeatRule!, startTime, day)
      : sameDay(startTime, day);

  /// A copy of this event moved to [day], keeping its time of day. Used to
  /// show one repeat of a recurring event; it shares the series' [id].
  CalendarEvent occurrenceOn(DateTime day) {
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      startTime.hour,
      startTime.minute,
    );
    return CalendarEvent.fromJson({
      ...toJson(),
      'startTime': start.toIso8601String(),
      'endTime': start.add(endTime.difference(startTime)).toIso8601String(),
    });
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'calendarId': calendarId,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'isAllDay': isAllDay,
    'location': location,
    'categoryId': categoryId,
    'reminder': reminderMinutes,
    'reminderMinutes': reminderMinutes,
    'color': colorIndex,
    'colorIndex': colorIndex,
    'colorHex': color,
    'repeatRule': repeatRule,
    'notes': notes,
    'source': source,
    'externalId': externalId,
    'category': category,
    'calendar': calendar,
    'guests': guests,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

// ---------------------------------------------------------------------------
// Minimal RRULE support (shared by events and habits).

const _rruleDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// [rule] with any `UNTIL=` part removed; null stays null.
String? rruleWithoutUntil(String? rule) => rule
    ?.split(';')
    .where((p) => p.isNotEmpty && !p.startsWith('UNTIL='))
    .join(';');

/// True when a series that starts on [start] and repeats by [rule] has an
/// occurrence on [day].
///
/// shortcut: supports FREQ=DAILY/WEEKLY/MONTHLY, BYDAY and UNTIL only
/// (no INTERVAL/COUNT); use a full RRULE package if richer rules are needed.
bool rruleOccursOn(String rule, DateTime start, DateTime day) {
  final d = dateOnly(day);
  if (d.isBefore(dateOnly(start))) return false;
  final parts = {
    for (final p in rule.split(';'))
      if (p.contains('=')) p.split('=')[0]: p.split('=')[1],
  };
  final until = parts['UNTIL'];
  if (until != null && until.length >= 8) {
    final end = DateTime(
      int.parse(until.substring(0, 4)),
      int.parse(until.substring(4, 6)),
      int.parse(until.substring(6, 8)),
    );
    if (d.isAfter(end)) return false;
  }
  final byDay = parts['BYDAY'];
  switch (parts['FREQ']) {
    case 'DAILY':
      return true;
    case 'WEEKLY':
      if (byDay == null) return d.weekday == start.weekday;
      return byDay.split(',').contains(_rruleDays[d.weekday - 1]);
    case 'MONTHLY':
      return d.day == start.day;
    default:
      return sameDay(start, d);
  }
}
