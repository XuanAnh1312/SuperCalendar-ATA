import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_form_screen.dart';

/// Read-only view of one event with Edit and Delete for local events.
/// Events from the phone calendar can only be viewed.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final CalendarEvent event;

  Future<void> _delete(BuildContext context) async {
    final events = AppScope.read(context).events;
    // [event] may be one repeat of a series; edits go through the series.
    final series = events.byId(event.id);
    if (series == null) return;
    if (series.isRecurring) {
      final scope = await pickEventScope(context, title: 'Delete event');
      if (scope == null || !context.mounted) return;
      events.deleteScope(series, scope, occurrenceDate: event.date);
      Navigator.of(context).pop();
      showAppSnack(context, 'Event deleted');
      return;
    }
    events.delete(series);
    Navigator.of(context).pop();
    showUndoSnack(
      context,
      'Event deleted',
      onUndo: () => events.restore(series),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Subscribing keeps the page in sync after the event is edited.
    final app = AppScope.of(context);
    final exists = app.events.byId(event.id) != null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            TopBar(
              title: 'Event',
              trailing: event.isSystem || !exists
                  ? null
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _delete(context),
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.accentSurface(event.colorIndex),
              shadow: false,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.accent(event.colorIndex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.category.toUpperCase(),
                          style: AppText.label(),
                        ),
                      ),
                      if (event.isSystem)
                        SoftPill(
                          label: 'Phone calendar · read only',
                          icon: LucideIcons.lockKeyhole,
                          color: AppColors.surface,
                          textColor: AppColors.muted,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: AppText.s(20, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${longDate(event.date)} · ${event.timeRange}',
                    style: AppText.s(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (event.location.isNotEmpty)
              FieldTile(
                icon: LucideIcons.mapPin,
                label: 'Location',
                value: event.location,
              ),
            FieldTile(
              icon: LucideIcons.bell,
              label: 'Reminder',
              value: formatReminder(event.reminderMinutes),
            ),
            if (!event.isSystem)
              FieldTile(
                icon: LucideIcons.repeat2,
                label: 'Repeat',
                value: event.repeatLabel,
              ),
            FieldTile(
              icon: LucideIcons.calendarDays,
              label: 'Calendar',
              value: event.calendar,
            ),
            FieldTile(
              icon: LucideIcons.notebookPen,
              label: 'Notes',
              value: event.description.isEmpty
                  ? 'No description'
                  : event.description,
            ),
            FieldTile(
              icon: LucideIcons.database,
              label: 'Source',
              value: event.isSystem ? 'System calendar' : 'SuperCalendar',
            ),
            if (!event.isSystem && exists) ...[
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Edit event',
                icon: LucideIcons.pencil,
                onTap: () =>
                    pushFullScreen(context, EventFormScreen(event: event)),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Delete event',
                icon: LucideIcons.trash2,
                danger: true,
                onTap: () => _delete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
