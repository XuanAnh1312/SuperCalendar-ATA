import 'package:flutter/services.dart';

import 'package:flutter_application/features/calendar/domain/event.dart';

/// One calendar on the phone (FR-22 step 5).
class DeviceCalendar {
  const DeviceCalendar({
    required this.id,
    required this.name,
    this.account = '',
    this.color,
  });

  factory DeviceCalendar.fromMap(Map<dynamic, dynamic> row) => DeviceCalendar(
    id: '${row['id'] ?? ''}',
    name: (row['name'] as String?)?.trim().isNotEmpty == true
        ? (row['name'] as String).trim()
        : 'Calendar',
    account: (row['account'] as String?)?.trim() ?? '',
    color: row['color'] as int?,
  );

  final String id;
  final String name;
  final String account;

  /// Android ARGB colour, when the provider supplies one.
  final int? color;
}

/// Read-only access to the device calendar (FR-22).
abstract class SystemCalendarService {
  Future<bool> hasPermission();

  /// Shows the system permission prompt; resolves to whether it was granted.
  Future<bool> requestPermission();

  /// Events between [from] and [to], marked `source = system_calendar`.
  Future<List<CalendarEvent>> events(DateTime from, DateTime to);

  /// Calendars on the device (id, name, account, colour). Empty without
  /// permission.
  Future<List<DeviceCalendar>> calendars();

  /// Opens this app's Android settings so the user can grant Calendar access.
  Future<bool> openAppSettings();
}

/// Talks to `MainActivity.kt`, which queries Android's CalendarContract
/// provider via the `supercalendar/system_calendar` MethodChannel.
///
/// Fields returned per event (all Android-sourced):
/// - id            : long   event_id from CalendarContract.Instances
/// - title         : String
/// - description   : String?
/// - begin         : long   epoch ms
/// - end           : long   epoch ms
/// - allDay        : int    1 = all-day, 0 = timed
/// - location      : String?
/// - calendar      : String display name of the owning calendar
/// - calendarId    : long   calendar id (_ID of CalendarContract.Calendars)
/// - color         : int?   ARGB colour integer of the event
///
/// FR-22.01: Events are read-only ([CalendarEvent.source] = system_calendar).
/// FR-22.02: System events are never written back to Android.
/// FR-22.03: Data is refreshed on every Calendar open / pull-to-refresh.
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
        for (final row in rows ?? const <Map>[]) _rowToEvent(row),
      ];
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  @override
  Future<List<DeviceCalendar>> calendars() async {
    try {
      final rows = await _channel.invokeListMethod<Map>('calendars');
      return [
        for (final row in rows ?? const <Map>[]) DeviceCalendar.fromMap(row),
      ];
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static CalendarEvent _rowToEvent(Map<dynamic, dynamic> row) {
    final eventId = row['id'];
    final begin = row['begin'] as int? ?? 0;
    final end = row['end'] as int? ?? begin;
    final allDay = (row['allDay'] as int? ?? 0) == 1;
    final calendarId = row['calendarId']?.toString() ?? 'system';
    final externalId = eventId?.toString();

    // Android ARGB int → hex string (#AARRGGBB) or null when absent.
    final colorHex = _argbToHex(row['color'] as int?);

    final startTime = allDay
        ? _utcToLocal(begin)
        : DateTime.fromMillisecondsSinceEpoch(begin);
    final endTime = allDay
        ? _utcToLocal(end)
        : DateTime.fromMillisecondsSinceEpoch(end);

    return CalendarEvent(
      // Stable unique id: prevents duplicates when the window is re-fetched.
      id: 'system_${externalId}_$begin',
      calendarId: calendarId,
      title: _nonEmpty(row['title'] as String?) ?? '(No title)',
      description: row['description'] as String? ?? '',
      startTime: startTime,
      endTime: endTime,
      isAllDay: allDay,
      location: row['location'] as String? ?? '',
      color: colorHex,
      // Teal-ish palette index so system events look visually distinct.
      colorIndex: 4,
      source: CalendarEvent.sourceSystem,
      externalId: externalId,
      // Legacy convenience fields
      category: 'Phone calendar',
      calendar: _nonEmpty(row['calendar'] as String?) ?? 'Phone',
    );
  }

  /// All-day events from Android are stored in UTC midnight; convert to local
  /// so the date displayed matches what the user expects.
  static DateTime _utcToLocal(int epochMs) =>
      DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true).toLocal();

  /// Converts an Android ARGB integer to a `#RRGGBB` hex string.
  static String? _argbToHex(int? argb) {
    if (argb == null) return null;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}

/// Scripted calendar for unit tests and the desktop preview.
class FakeSystemCalendarService implements SystemCalendarService {
  FakeSystemCalendarService({
    this.granted = false,
    this.grantOnRequest = true,
    List<CalendarEvent>? events,
    List<DeviceCalendar>? calendars,
  }) : _events = events ?? [],
       _calendars = calendars ?? [];

  bool granted;
  bool grantOnRequest;
  int requests = 0;
  int openSettingsCalls = 0;
  final List<CalendarEvent> _events;
  final List<DeviceCalendar> _calendars;

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

  @override
  Future<List<DeviceCalendar>> calendars() async {
    if (!granted) return [];
    return List.unmodifiable(_calendars);
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    return true;
  }
}
