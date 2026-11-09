import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';

/// Placeholder stored when every device calendar is switched off. An empty
/// [AppSettings.visibleCalendarIds] still means "show all".
const hiddenDeviceCalendarsSentinel = '__none__';

/// Whether a system-calendar event from [calendarId] should appear.
///
/// An empty id list shows every device calendar. Local events always show.
bool isDeviceCalendarVisible(AppSettings settings, String calendarId) {
  final ids = settings.visibleCalendarIds;
  if (ids.isEmpty) return true;
  return ids.contains(calendarId);
}

bool isVisibleCalendarEvent(AppSettings settings, CalendarEvent event) {
  if (!event.isSystem) return true;
  return isDeviceCalendarVisible(settings, event.calendarId);
}

List<CalendarEvent> visibleEventsOn(
  List<CalendarEvent> events,
  AppSettings settings,
) => events.where((e) => isVisibleCalendarEvent(settings, e)).toList();

/// Next [visibleCalendarIds] value after toggling [id].
List<String> visibleIdsAfterToggle({
  required List<String> current,
  required List<String> allIds,
  required String id,
  required bool visible,
}) {
  final showingAll = current.isEmpty;
  final on = showingAll
      ? {...allIds}
      : current.where((x) => x != hiddenDeviceCalendarsSentinel).toSet();
  if (visible) {
    on.add(id);
  } else {
    on.remove(id);
  }
  if (on.isEmpty) return const [hiddenDeviceCalendarsSentinel];
  if (allIds.isNotEmpty && allIds.every(on.contains)) return const [];
  return on.toList();
}
