import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.reminderMinutes,
    this.colorIndex = 0,
    this.source = sourceLocal,
    this.category = 'Personal',
    this.repeat = 'Never',
    this.calendar = 'Personal',
    List<String>? guests,
  }) : guests = guests ?? [];

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final start = parseDate(json['startTime']) ?? DateTime.now();
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startTime: start,
      endTime:
          parseDate(json['endTime']) ?? start.add(const Duration(hours: 1)),
      location: json['location'] as String? ?? '',
      reminderMinutes: json['reminder'] as int?,
      colorIndex: json['color'] as int? ?? 0,
      source: json['source'] as String? ?? sourceLocal,
      category: json['category'] as String? ?? 'Personal',
      repeat: json['repeat'] as String? ?? 'Never',
      calendar: json['calendar'] as String? ?? 'Personal',
      guests: [...?(json['guests'] as List?)?.cast<String>()],
    );
  }

  static const sourceLocal = 'local';
  static const sourceSystem = 'system_calendar';

  final String id;
  String title;
  String description;
  DateTime startTime;
  DateTime endTime;
  String location;

  /// Minutes before the start to notify; null for no reminder.
  int? reminderMinutes;

  /// Index into the accent palette.
  int colorIndex;

  /// [sourceLocal] or [sourceSystem]. System events are read-only.
  final String source;
  String category;
  String repeat;
  String calendar;
  List<String> guests;

  bool get isSystem => source == sourceSystem;

  DateTime get date => dateOnly(startTime);
  int get startMinutes => startTime.hour * 60 + startTime.minute;

  /// Minutes since midnight of the start day; past midnight is capped.
  int get endMinutes => sameDay(startTime, endTime)
      ? endTime.hour * 60 + endTime.minute
      : 24 * 60 - 1;

  String get startLabel => formatMinutes(startMinutes);
  String get timeRange => '$startLabel–${formatMinutes(endMinutes)}';

  bool isOn(DateTime day) => sameDay(startTime, day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'location': location,
    'reminder': reminderMinutes,
    'color': colorIndex,
    'source': source,
    'category': category,
    'repeat': repeat,
    'calendar': calendar,
    'guests': guests,
  };
}
