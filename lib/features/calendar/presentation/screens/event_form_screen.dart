import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// Creates an event, or edits [event] when one is given.
/// Asks which repeats of a recurring event an edit or delete applies to
/// (BR-10). Null when dismissed.
Future<DeleteScope?> pickEventScope(
  BuildContext context, {
  required String title,
}) async {
  const labels = {
    'Only this event': DeleteScope.one,
    'This and following events': DeleteScope.fromThis,
    'All events': DeleteScope.all,
  };
  final picked = await pickOption(
    context,
    title: title,
    options: labels.keys.toList(),
    current: '',
  );
  return labels[picked];
}

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.initialDate, this.event});

  /// Day preselected for a new event.
  final DateTime? initialDate;

  /// Event being edited; null to create one.
  final CalendarEvent? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  late final _title = TextEditingController(text: widget.event?.title);
  late final _location = TextEditingController(text: widget.event?.location);
  late final _notes = TextEditingController(text: widget.event?.description);

  DateTime? _date;
  late int _start = widget.event?.startMinutes ?? 14 * 60;
  late int _end = widget.event?.endMinutes ?? 15 * 60;
  late int _color = widget.event?.colorIndex ?? 0;
  late String _category = widget.event?.category ?? 'Work';
  int? _reminder;
  late String _repeat = widget.event?.repeatLabel ?? 'Never';
  String? _calendar;
  late final List<String> _guests = [...?widget.event?.guests];
  bool _initialized = false;

  bool get _editing => widget.event != null;

  String? _repeatRule(String repeat) => switch (repeat) {
    'Every day' => 'FREQ=DAILY',
    'Weekdays' => 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
    'Every week' => 'FREQ=WEEKLY',
    _ => null,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final app = AppScope.read(context);
    final event = widget.event;
    _date = event?.date ?? widget.initialDate ?? app.today;
    _reminder = event == null
        ? app.settings.defaultReminderMinutes
        : event.reminderMinutes;
    _calendar = event?.calendar ?? app.settings.defaultCalendar;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final start = await showTimePicker(
      context: context,
      helpText: tr('Start time'),
      initialTime: TimeOfDay(hour: _start ~/ 60, minute: _start % 60),
    );
    if (start == null || !mounted) return;
    final duration = _end - _start;
    final newStart = start.hour * 60 + start.minute;
    final suggestedEnd = (newStart + duration).clamp(newStart + 5, 24 * 60 - 1);
    final end = await showTimePicker(
      context: context,
      helpText: tr('End time'),
      initialTime: TimeOfDay(
        hour: suggestedEnd ~/ 60,
        minute: suggestedEnd % 60,
      ),
    );
    if (!mounted) return;
    setState(() {
      _start = newStart;
      final picked = end == null ? suggestedEnd : end.hour * 60 + end.minute;
      // An end before the start is kept so the form can flag it (AC-14).
      _end = picked;
    });
  }

  Future<void> _choose(
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onPicked,
  ) async {
    final picked = await pickOption(
      context,
      title: title,
      options: options,
      current: current,
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _chooseReminder() async {
    final picked = await pickReminder(context, _reminder);
    if (picked != null) setState(() => _reminder = picked < 0 ? null : picked);
  }

  Future<void> _addGuest() async {
    final name = await promptText(
      context,
      title: 'Add guest',
      hint: 'Guest name',
    );
    if (name == null || name.isEmpty) return;
    final parts = name.split(RegExp(r'\s+'));
    final initials = parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'
        : name.substring(0, name.length >= 2 ? 2 : 1);
    setState(() => _guests.add(initials.toUpperCase()));
  }

  /// The rule to save; an unchanged choice keeps the stored rule (and any
  /// UNTIL it carries).
  String? get _rule => _repeat == widget.event?.repeatLabel
      ? widget.event!.repeatRule
      : _repeatRule(_repeat);

  /// AC-14: an event must end after it starts.
  bool get _timeValid => _end > _start;

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showAppSnack(context, 'Give the event a title first');
      return;
    }
    if (!_timeValid) {
      setState(() {});
      return;
    }
    final app = AppScope.read(context);
    final date = _date!;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      _start ~/ 60,
      _start % 60,
    );
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      _end ~/ 60,
      _end % 60,
    );
    final existing = widget.event;
    CalendarEvent build(String id) => CalendarEvent(
      id: id,
      title: title,
      description: _notes.text.trim(),
      startTime: start,
      endTime: end,
      location: _location.text.trim(),
      reminderMinutes: _reminder,
      colorIndex: _color,
      category: _category,
      repeatRule: _rule,
      calendar: _calendar!,
      guests: [..._guests],
    );
    // [existing] may be one repeat of a series (BR-10).
    final series = existing == null ? null : app.events.byId(existing.id);
    if (series != null && series.isRecurring) {
      final scope = await pickEventScope(context, title: 'Save changes to');
      if (scope == null || !mounted) return;
      final occurrence = existing!.date;
      switch (scope) {
        case DeleteScope.one:
          // The edited repeat becomes a standalone event.
          app.events.deleteScope(series, scope, occurrenceDate: occurrence);
          app.events.add(build(newId('event'))..repeatRule = null);
        case DeleteScope.fromThis:
          // End the old series here and start a new one with the edits.
          app.events.deleteScope(series, scope, occurrenceDate: occurrence);
          app.events.add(build(newId('event')));
        case DeleteScope.all:
          final edited = build(series.id);
          // Keep the series' first day; only the time of day changes.
          final shift = DateTime(
            series.date.year,
            series.date.month,
            series.date.day,
          ).difference(DateTime(date.year, date.month, date.day));
          series
            ..title = edited.title
            ..description = edited.description
            ..startTime = edited.startTime.add(shift)
            ..endTime = edited.endTime.add(shift)
            ..location = edited.location
            ..reminderMinutes = edited.reminderMinutes
            ..colorIndex = edited.colorIndex
            ..category = edited.category
            ..repeatRule = edited.repeatRule
            ..calendar = edited.calendar
            ..guests = edited.guests;
          app.events.save(series);
      }
    } else if (existing == null) {
      app.events.add(
        CalendarEvent(
          id: newId('event'),
          title: title,
          description: _notes.text.trim(),
          startTime: start,
          endTime: end,
          location: _location.text.trim(),
          reminderMinutes: _reminder,
          colorIndex: _color,
          category: _category,
          repeatRule: _rule,
          calendar: _calendar!,
          guests: _guests,
        ),
      );
    } else {
      existing
        ..title = title
        ..description = _notes.text.trim()
        ..startTime = start
        ..endTime = end
        ..location = _location.text.trim()
        ..reminderMinutes = _reminder
        ..colorIndex = _color
        ..category = _category
        ..repeatRule = _rule
        ..calendar = _calendar!
        ..guests = [..._guests];
      app.events.save(existing);
    }
    app.selectDay(date);
    if (_reminder != null) unawaited(app.ensureRemindersCanFire());
    Navigator.of(context).pop();
    showAppSnack(
      context,
      existing == null
          ? trf('Event "{title}" created', {'title': title})
          : 'Event updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            TopBar(
              title: _editing ? 'Edit event' : 'New event',
              close: true,
              trailing: TopBarAction(label: 'Save', onTap: _save),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              borderColor: AppColors.primary,
              borderWidth: 1.5,
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('EVENT TITLE'),
                    style: AppText.s(10, color: AppColors.primary),
                  ),
                  TextField(
                    controller: _title,
                    autofocus: !_editing,
                    style: AppText.s(18),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintText: tr('Add title'),
                      hintStyle: AppText.s(18, color: AppColors.faint),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FieldTile(
                    icon: LucideIcons.calendar,
                    label: 'Date',
                    value: shortDate(_date!),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: FieldTile(
                    icon: LucideIcons.clock3,
                    label: 'Time',
                    value: '${formatMinutes(_start)}–${formatMinutes(_end)}',
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            if (!_timeValid)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: Text(tr('End time must be after the start time'),
                  style: AppText.s(11, color: AppColors.danger),
                ),
              ),
            Row(
              children: [
                AppCard(
                  shadow: false,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(13, 11, 16, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('COLOR'), style: AppText.label()),
                      const SizedBox(height: 7),
                      ColorDots(
                        colors: AppColors.accents,
                        index: _color,
                        onChanged: (i) => setState(() => _color = i),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FieldTile(
                    icon: LucideIcons.briefcaseBusiness,
                    label: 'Category',
                    value: _category,
                    onTap: () => _choose(
                      'Category',
                      const ['Work', 'Personal', 'Health', 'Finance'],
                      _category,
                      (v) => _category = v,
                    ),
                  ),
                ),
              ],
            ),
            InlineField(
              icon: LucideIcons.mapPin,
              label: 'Location',
              controller: _location,
              hint: 'Add location',
            ),
            Row(
              children: [
                Expanded(
                  child: FieldTile(
                    icon: LucideIcons.bell,
                    label: 'Reminder',
                    value: formatReminder(_reminder),
                    onTap: _chooseReminder,
                  ),
                ),
                Expanded(
                  child: FieldTile(
                    icon: LucideIcons.repeat2,
                    label: 'Repeat',
                    value: _repeat,
                    onTap: () => _choose(
                      'Repeat',
                      const ['Never', 'Every day', 'Weekdays', 'Every week'],
                      _repeat,
                      (v) => _repeat = v,
                    ),
                  ),
                ),
              ],
            ),
            InlineField(
              icon: LucideIcons.notebookPen,
              label: 'Notes',
              controller: _notes,
              hint: 'Add a description',
              multiline: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < _guests.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onLongPress: () => setState(() => _guests.removeAt(i)),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: i.isEven
                            ? AppColors.pink
                            : AppColors.blue,
                        child: Text(
                          _guests[i],
                          style: AppText.s(9.5, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _guests.isEmpty
                        ? tr('No guests')
                        : trf(_guests.length == 1 ? '{n} guest' : '{n} guests', {'n': _guests.length}),
                    style: AppText.s(11, color: AppColors.muted),
                  ),
                ),
                SoftPill(
                  label: 'Add guests',
                  icon: LucideIcons.userPlus,
                  onTap: _addGuest,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              shadow: false,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              onTap: () => _choose(
                'Calendar',
                const ['Personal', 'Work', 'Family'],
                _calendar!,
                (v) => _calendar = v,
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accent(_color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${app.user.firstName} · $_calendar',
                      style: AppText.s(12),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppColors.faint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _editing ? 'Save changes' : 'Create event',
              icon: _editing ? LucideIcons.check : LucideIcons.calendarPlus,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}
