import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _title = TextEditingController(text: 'Design review');
  final _location = TextEditingController(text: 'Studio 4 · 2nd floor');
  final _notes = TextEditingController(
    text: 'Review final flows with the product team. Bring tablet and printed specs.',
  );

  late DateTime _date = widget.initialDate;
  int _start = 14 * 60;
  int _end = 15 * 60;
  int _color = 1;
  String _category = 'Work';
  String _reminder = '15 min before';
  String _repeat = 'Every Monday';
  String _calendar = 'Personal';
  final List<String> _guests = ['AL', 'MK'];

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
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start ~/ 60, minute: _start % 60),
    );
    if (picked == null) return;
    setState(() {
      final duration = _end - _start;
      _start = picked.hour * 60 + picked.minute;
      _end = (_start + duration).clamp(0, 24 * 60 - 1);
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

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showAppSnack(context, 'Give the event a title first');
      return;
    }
    final app = AppScope.read(context);
    app.addEvent(
      CalendarEvent(
        id: app.newEventId(),
        title: title,
        date: DateTime(_date.year, _date.month, _date.day),
        startMinutes: _start,
        endMinutes: _end,
        color: AppColors.accentSurfaces[_color],
        accent: AppColors.accents[_color],
        location: _location.text.trim(),
        category: _category,
      ),
    );
    Navigator.of(context).pop();
    showAppSnack(context, 'Event "$title" created');
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${CalendarEvent.formatMinutes(_start)}–${CalendarEvent.formatMinutes(_end)}';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: LucideIcons.x,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(child: Text('New event', style: AppText.s(18))),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _save,
                  child: Text(
                    'Save',
                    style: AppText.s(
                      13,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
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
                  Text(
                    'EVENT TITLE',
                    style: AppText.s(10, color: AppColors.primary),
                  ),
                  TextField(
                    controller: _title,
                    style: AppText.s(18),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      hintText: 'Add title',
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
                    value: shortDate(_date),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: FieldTile(
                    icon: LucideIcons.clock3,
                    label: 'Time',
                    value: time,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                AppCard(
                  shadow: false,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(13, 11, 30, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COLOR', style: AppText.label()),
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
            _InlineField(
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
                    value: _reminder,
                    onTap: () => _choose(
                      'Reminder',
                      const [
                        'None',
                        '5 min before',
                        '15 min before',
                        '30 min before',
                        '1 hour before',
                      ],
                      _reminder,
                      (v) => _reminder = v,
                    ),
                  ),
                ),
                Expanded(
                  child: FieldTile(
                    icon: LucideIcons.repeat2,
                    label: 'Repeat',
                    value: _repeat,
                    onTap: () => _choose(
                      'Repeat',
                      const ['Never', 'Every day', 'Weekdays', 'Every Monday'],
                      _repeat,
                      (v) => _repeat = v,
                    ),
                  ),
                ),
              ],
            ),
            _InlineField(
              icon: LucideIcons.notebookPen,
              label: 'Notes',
              controller: _notes,
              hint: 'Add notes',
              multiline: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < _guests.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
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
                Expanded(
                  child: Text(
                    '${_guests.length} guests',
                    style: AppText.s(11, color: AppColors.muted),
                  ),
                ),
                GestureDetector(
                  onTap: _addGuest,
                  child: Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.userPlus,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Add guests',
                          style: AppText.s(10, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
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
                _calendar,
                (v) => _calendar = v,
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${AppScope.of(context).userName} · $_calendar',
                      style: AppText.s(12),
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppColors.faint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Create event',
              icon: LucideIcons.calendarPlus,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Field with an icon and label whose value is edited in place.
class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.hint,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AppText.label()),
                TextField(
                  controller: controller,
                  maxLines: multiline ? null : 1,
                  style: AppText.s(13, height: 1.4),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 3),
                    hintText: hint,
                    hintStyle: AppText.s(13, color: AppColors.faint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
