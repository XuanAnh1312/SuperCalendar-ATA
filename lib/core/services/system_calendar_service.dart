import 'package:flutter/services.dart';

import 'package:flutter_application/features/calendar/domain/event.dart';

/// Read-only access to the device calendar.
abstract class SystemCalendarService {
  Future<bool> hasPermission();

  /// Shows the system permission prompt; resolves to whether it was granted.
  Future<bool> requestPermission();

  /// Events between [from] and [to], marked `source = system_calendar`.
  Future<List<CalendarEvent>> events(DateTime from, DateTime to);
}

/// Talks to `MainActivity.kt`, which queries Android's calendar provider.
class AndroidSystemCalendarService implements SystemCalendarService {
  static const _channel = MethodChannel('supercalendar/system_calendar');

  @override
  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<List<CalendarEvent>> events(DateTime from, DateTime to) async {
    try {
      final rows = await _channel.invokeListMethod<Map>('events', {
        'from': from.millisecondsSinceEpoch,
        'to': to.millisecondsSinceEpoch,
      });
      return [
        for (final row in rows ?? const <Map>[])
          CalendarEvent(
            id: 'system_${row['id']}_${row['begin']}',
            title: (row['title'] as String?)?.trim().isNotEmpty ?? false
                ? row['title'] as String
                : '(No title)',
            description: row['description'] as String? ?? '',
            startTime: DateTime.fromMillisecondsSinceEpoch(row['begin'] as int),
            endTime: DateTime.fromMillisecondsSinceEpoch(row['end'] as int),
            location: row['location'] as String? ?? '',
            colorIndex: 4,
            source: CalendarEvent.sourceSystem,
            category: 'Phone calendar',
            calendar: row['calendar'] as String? ?? 'Phone',
          ),
      ];
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }
}

/// Scripted calendar for tests.
class FakeSystemCalendarService implements SystemCalendarService {
  FakeSystemCalendarService({
    this.granted = false,
    this.grantOnRequest = true,
    List<CalendarEvent>? events,
  }) : _events = events ?? [];

  bool granted;
  bool grantOnRequest;
  int requests = 0;
  final List<CalendarEvent> _events;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    granted = grantOnRequest;
    return granted;
  }

  @override
  Future<List<CalendarEvent>> events(DateTime from, DateTime to) async {
    if (!granted) return [];
    return _events
        .where((e) => !e.startTime.isBefore(from) && e.startTime.isBefore(to))
        .toList();
  }
}
