import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_form_screen.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _month;

  void _newEvent(BuildContext context, DateTime day) {
    pushFullScreen(context, EventFormScreen(initialDate: day));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final month = _month ?? DateTime(app.today.year, app.today.month);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                SegmentedToggle(
                  labels: const ['Month', 'Week'],
                  index: app.weekView ? 1 : 0,
                  onChanged: (i) => app.setWeekView(i == 1),
                ),
                const Spacer(),
                RoundIconButton(
                  icon: LucideIcons.plus,
                  size: 40,
                  filled: true,
                  onTap: () => _newEvent(context, app.selectedDay),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (app.weekView)
              ..._weekView(context, app)
            else
              ..._monthView(context, app, month),
          ],
        ),
      ),
    );
  }

  // ---- Month --------------------------------------------------------------

  List<Widget> _monthView(BuildContext context, AppState app, DateTime month) {
    final gridStart = month.subtract(Duration(days: month.weekday - 1));
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final weeks = ((month.weekday - 1 + daysInMonth) / 7).ceil();
    final selected = app.selectedDay;
    final agenda = app.eventsOn(selected);

    return [
      PageHeader(
        title: '${monthNames[month.month - 1]} ${month.year}',
        subtitle: 'Tap a date to create an event',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chevron(LucideIcons.chevronLeft, AppColors.muted, () {
              setState(() => _month = DateTime(month.year, month.month - 1));
            }),
            _chevron(LucideIcons.chevronRight, AppColors.text, () {
              setState(() => _month = DateTime(month.year, month.month + 1));
            }),
          ],
        ),
      ),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                for (final name in weekdayShort)
                  Expanded(
                    child: Center(
                      child: Text(
                        name,
                        style: AppText.s(9, color: AppColors.muted),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var week = 0; week < weeks; week++)
              Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: _dayCell(
                        context,
                        app,
                        DateTime(
                          gridStart.year,
                          gridStart.month,
                          gridStart.day + week * 7 + d,
                        ),
                        month,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        color: AppColors.purple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Monthly Goals', action: '3 of 5'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                _GoalChip(
                  'Launch site',
                  color: AppColors.primarySoft,
                  textColor: AppColors.primary,
                  icon: LucideIcons.rocket,
                ),
                _GoalChip(
                  '12 workouts',
                  color: AppColors.green,
                  textColor: AppColors.greenStrong,
                ),
                _GoalChip(
                  'Read 2 books',
                  color: AppColors.yellow,
                  textColor: AppColors.yellowText,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (agenda.isEmpty)
        Text(
          'No events on ${shortDate(selected)} · tap the date again to add one',
          style: AppText.s(10, color: AppColors.muted),
        )
      else
        for (final event in agenda) _AgendaRow(event: event, app: app),
    ];
  }

  Widget _chevron(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _dayCell(
    BuildContext context,
    AppState app,
    DateTime day,
    DateTime month,
  ) {
    final inMonth = day.month == month.month;
    final selected = sameDay(day, app.selectedDay);
    final events = inMonth ? app.eventsOn(day) : const <CalendarEvent>[];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selected) {
          _newEvent(context, day);
        } else {
          app.selectDay(day);
          if (!inMonth) setState(() => _month = DateTime(day.year, day.month));
        }
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        padding: const EdgeInsets.only(top: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '${day.day}',
              style: AppText.s(
                11,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : inMonth
                    ? AppColors.text
                    : AppColors.faint,
              ),
            ),
            const SizedBox(height: 5),
            if (events.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dot(events.first.accent, 8),
                  if (events.length > 1) ...[
                    const SizedBox(width: 2),
                    _dot(AppColors.greenStrong, 4),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  // ---- Week ---------------------------------------------------------------

  static const _firstHour = 8;
  static const _lastHour = 17;
  static const _hourHeight = 37.0;
  static const _hourColumn = 37.0;

  List<Widget> _weekView(BuildContext context, AppState app) {
    final anchor = app.selectedDay;
    final monday = DateTime(
      anchor.year,
      anchor.month,
      anchor.day - (anchor.weekday - 1),
    );
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];
    final eventCount = days.fold<int>(
      0,
      (sum, day) => sum + app.eventsOn(day).length,
    );
    final gridHeight = (_lastHour - _firstHour) * _hourHeight;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekRangeLabel(anchor, longMonth: true),
                  style: AppText.s(20),
                ),
                const SizedBox(height: 2),
                Text(
                  'Week ${_isoWeek(monday)} · $eventCount events',
                  style: AppText.s(10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => app.selectDay(app.today),
            child: Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                'Today',
                style: AppText.s(10, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(left: _hourColumn),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(child: _weekDayHeader(app, days[i], i)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
        child: SizedBox(
          height: gridHeight + 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _hourColumn - 1,
                child: Column(
                  children: [
                    for (var h = _firstHour; h < _lastHour; h++)
                      SizedBox(
                        height: _hourHeight,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              h.toString().padLeft(2, '0'),
                              style: AppText.s(8.5, color: AppColors.faint),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < 7; i++)
                Expanded(child: _weekColumn(context, app, days[i], i)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        color: AppColors.yellow,
        borderColor: AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Weekly Goals', action: '2 of 4'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                _GoalChip(
                  '3 workouts',
                  color: AppColors.green,
                  textColor: AppColors.greenStrong,
                  icon: LucideIcons.check,
                ),
                _GoalChip('Draft launch'),
                _GoalChip('Call Mom'),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _weekDayHeader(AppState app, DateTime day, int index) {
    final selected = sameDay(day, app.selectedDay);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => app.selectDay(day),
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${weekdayLetters[index]} ${day.day}',
              style: AppText.s(
                9.5,
                weight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 14,
              height: 2.5,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekColumn(
    BuildContext context,
    AppState app,
    DateTime day,
    int index,
  ) {
    final gridHeight = (_lastHour - _firstHour) * _hourHeight;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (sameDay(day, app.selectedDay)) {
          _newEvent(context, day);
        } else {
          app.selectDay(day);
        }
      },
      child: Container(
        height: gridHeight + 16,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: index == 0 ? Colors.transparent : AppColors.border,
            ),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final event in app.eventsOn(day))
              if (event.endMinutes > _firstHour * 60 &&
                  event.startMinutes < _lastHour * 60)
                _weekEvent(event),
          ],
        ),
      ),
    );
  }

  Widget _weekEvent(CalendarEvent event) {
    final start = event.startMinutes.clamp(_firstHour * 60, _lastHour * 60);
    final end = event.endMinutes.clamp(_firstHour * 60, _lastHour * 60);
    return Positioned(
      top: (start - _firstHour * 60) / 60 * _hourHeight,
      height: ((end - start) / 60 * _hourHeight - 3).clamp(24, double.infinity),
      left: 1,
      right: 2,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 2, 2),
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${event.title}\n${event.startLabel}',
          overflow: TextOverflow.clip,
          style: AppText.s(8.5, height: 1.2),
        ),
      ),
    );
  }

  int _isoWeek(DateTime monday) {
    final thursday = monday.add(const Duration(days: 3));
    final firstDay = DateTime(thursday.year, 1, 1);
    return thursday.difference(firstDay).inDays ~/ 7 + 1;
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip(
    this.label, {
    this.color = AppColors.surface,
    this.textColor = AppColors.text,
    this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(label, style: AppText.s(10, color: textColor)),
        ],
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.event, required this.app});

  final CalendarEvent event;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final isToday = sameDay(event.date, app.today);
    final details = [
      if (event.location.isNotEmpty) event.location,
      event.category,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday
                        ? 'TODAY'
                        : shortDate(event.date).split(',').first.toUpperCase(),
                    style: AppText.s(9.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.startLabel,
                    style: AppText.s(12.5, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Container(
              width: 2.5,
              margin: const EdgeInsets.only(right: 9),
              color: event.accent,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppText.s(12.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(details, style: AppText.s(10, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
