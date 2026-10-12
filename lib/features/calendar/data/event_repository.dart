import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';

/// Local events are stored on the device. Events read from the system
/// calendar are held in memory only and merged in when listing a day.
class EventRepository extends Repository<CalendarEvent> {
  EventRepository(DocumentStore store) : super(store, Collections.events);

  final List<CalendarEvent> _systemEvents = [];

  @override
  CalendarEvent decode(Map<String, dynamic> json) =>
      CalendarEvent.fromJson(json);

  @override
  Map<String, dynamic> encode(CalendarEvent item) => item.toJson();

  @override
  String idOf(CalendarEvent item) => item.id;

  List<CalendarEvent> get systemEvents => List.unmodifiable(_systemEvents);

  CalendarEvent? byId(String id) {
    for (final event in [...items, ..._systemEvents]) {
      if (event.id == id) return event;
    }
    return null;
  }

  /// Local and system events on [day], earliest first.
  List<CalendarEvent> on(DateTime day) {
    final list = [
      ...items.where((e) => e.isOn(day)),
      ..._systemEvents.where((e) => e.isOn(day)),
    ];
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

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

  void delete(CalendarEvent event) {
    if (event.isSystem || !items.remove(event)) return;
    erase(event);
    notifyListeners();
  }

  /// Replaces the events read from the system calendar.
  void setSystemEvents(List<CalendarEvent> events) {
    _systemEvents
      ..clear()
      ..addAll(events);
    notifyListeners();
  }
}
