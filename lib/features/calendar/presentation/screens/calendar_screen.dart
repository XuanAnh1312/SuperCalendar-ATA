import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/goal.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_detail_screen.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_form_screen.dart';
import 'package:flutter_application/features/calendar/presentation/widgets/system_calendar_prompt.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/core/utils/strings.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  void _newEvent(BuildContext context, DateTime day) {
    pushFullScreen(context, EventFormScreen(initialDate: day));
  }

  void _openEvent(BuildContext context, CalendarEvent event) {
    pushFullScreen(context, EventDetailScreen(event: event));
  }

  /// Moves the month view to [month] by selecting a day inside it: today
  /// for the current month, otherwise the 1st.
  void _showMonth(AppState app, DateTime month) {
    final today = app.today;
    app.selectDay(
      month.year == today.year && month.month == today.month ? today : month,
    );
    unawaited(app.refreshSystemCalendar());
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final selected = app.selectedDay;
    final month = DateTime(selected.year, selected.month);
    final showPrompt =
        !app.settings.useSystemCalendar &&
        !app.settings.calendarBannerDismissed;
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
                  onTap: () => _newEvent(context, selected),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (app.weekView)
              ..._weekView(context, app)
            else
              ..._monthView(context, app, month),
            if (showPrompt) ...[
              const SizedBox(height: 14),
              const SystemCalendarPrompt(),
            ],
          ],
        ),
      ),
    );
  }

  // ---- Month --------------------------------------------------------------

  List<Widget> _monthView(BuildContext context, AppState app, DateTime month) {
    final gridStart = app.weekStartOf(month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = (month.weekday - app.firstWeekday) % 7;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    final selected = app.selectedDay;
    final agenda = app.events.on(selected);

    return [
      PageHeader(
        title: '${monthNames[month.month - 1]} ${month.year}',
        subtitle: 'Tap a date to create an event',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chevron(
              LucideIcons.chevronLeft,
              AppColors.muted,
              () => _showMonth(app, DateTime(month.year, month.month - 1)),
            ),
            _chevron(
              LucideIcons.chevronRight,
              AppColors.text,
              () => _showMonth(app, DateTime(month.year, month.month + 1)),
            ),
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
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        weekdayShort[(app.firstWeekday - 1 + i) % 7],
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
      _GoalsCard(
        type: GoalType.monthly,
        periodStart: month,
        periodEnd: DateTime(month.year, month.month + 1, 0),
        color: AppColors.purple,
      ),
      const SizedBox(height: 14),
      if (agenda.isEmpty)
        Text(
          trf('No events on {date} · tap the date again to add one', {'date': shortDate(selected)}),
          style: AppText.s(10, color: AppColors.muted),
        )
      else
        for (final event in agenda)
          _AgendaRow(
            event: event,
            isToday: sameDay(event.date, app.today),
            onTap: () => _openEvent(context, event),
          ),
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
    final events = inMonth ? app.events.on(day) : const <CalendarEvent>[];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selected) {
          _newEvent(context, day);
        } else {
          app.selectDay(day);
          if (!inMonth) unawaited(app.refreshSystemCalendar());
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
                weight: selected || sameDay(day, app.today)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected || sameDay(day, app.today)
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
                  _dot(AppColors.accent(events.first.colorIndex), 8),
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
    final first = app.weekStartOf(anchor);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(first.year, first.month, first.day + i),
    ];
    // ISO week number of the Monday in this week (BR-15).
    final monday = days.firstWhere((d) => d.weekday == DateTime.monday);
    final eventCount = days.fold<int>(
      0,
      (sum, day) => sum + app.events.on(day).length,
    );
    final gridHeight = (_lastHour - _firstHour) * _hourHeight;
    final outside = app.events
        .on(anchor)
        .where(
          (e) =>
              e.endMinutes <= _firstHour * 60 ||
              e.startMinutes >= _lastHour * 60,
        )
        .toList();

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
                  trf('Week {n} · {count} events', {'n': _isoWeek(monday), 'count': eventCount}),
                  style: AppText.s(10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          SoftPill(label: 'Today', onTap: () => app.selectDay(app.today)),
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
      if (outside.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          trf('Outside 08:00–17:00 on {date}', {'date': shortDate(anchor)}),
          style: AppText.s(10, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        for (final event in outside)
          _AgendaRow(
            event: event,
            isToday: sameDay(event.date, app.today),
            onTap: () => _openEvent(context, event),
          ),
      ],
      const SizedBox(height: 12),
      _GoalsCard(
        type: GoalType.weekly,
        periodStart: first,
        periodEnd: DateTime(first.year, first.month, first.day + 6),
        color: AppColors.yellow,
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
              '${weekdayLetters[day.weekday - 1]} ${day.day}',
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
            for (final event in app.events.on(day))
              if (event.endMinutes > _firstHour * 60 &&
                  event.startMinutes < _lastHour * 60)
                _weekEvent(context, event),
          ],
        ),
      ),
    );
  }

  Widget _weekEvent(BuildContext context, CalendarEvent event) {
    final start = event.startMinutes.clamp(_firstHour * 60, _lastHour * 60);
    final end = event.endMinutes.clamp(_firstHour * 60, _lastHour * 60);
    final height = ((end - start) / 60 * _hourHeight - 3).clamp(
      24.0,
      double.infinity,
    );
    return Positioned(
      top: (start - _firstHour * 60) / 60 * _hourHeight,
      height: height,
      left: 1,
      right: 2,
      child: GestureDetector(
        onTap: () => _openEvent(context, event),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 2, 2),
          decoration: BoxDecoration(
            color: AppColors.accentSurface(event.colorIndex),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${event.title}\n${event.startLabel}',
            overflow: TextOverflow.clip,
            style: AppText.s(8.5, height: 1.2),
          ),
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

/// Weekly or Monthly goals of one period (BR-03: the two never mix).
/// Tap a chip to add progress (AC-17), long-press to delete, + to add one
/// of this card's type (AC-18).
class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.type,
    required this.periodStart,
    required this.periodEnd,
    required this.color,
  });

  final GoalType type;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Color color;

  bool get _monthly => type == GoalType.monthly;

  Future<void> _add(BuildContext context) async {
    final app = AppScope.read(context);
    final title = await promptText(
      context,
      title: _monthly ? 'New monthly goal' : 'New weekly goal',
      hint: 'e.g. 12 workouts',
    );
    if (title == null || title.isEmpty || !context.mounted) return;
    final target = await promptText(
      context,
      title: 'How many times?',
      hint: 'Leave empty for a one-off goal',
    );
    app.goals.add(
      type: type,
      title: title,
      target: int.tryParse(target ?? ''),
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // A day inside this card's period; the selected day for weeks, so goals
    // still match after the week start setting changes.
    final day = _monthly ? periodStart : app.selectedDay;
    final goals = app.goals.activeOn(day, type);
    final done = goals.where((g) => g.status == GoalStatus.completed).length;
    return AppCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: _monthly ? 'Monthly Goals' : 'Weekly Goals',
            action: '$done of ${goals.length}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final goal in goals)
                GestureDetector(
                  onLongPress: () {
                    app.goals.delete(goal);
                    showUndoSnack(
                      context,
                      'Goal deleted',
                      onUndo: () => app.goals.restore(goal),
                    );
                  },
                  child: SoftPill(
                    label: goal.target == null
                        ? goal.title
                        : '${goal.title} · ${goal.progressLabel}',
                    icon: switch (goal.status) {
                      GoalStatus.completed => LucideIcons.check,
                      GoalStatus.missed => LucideIcons.x,
                      GoalStatus.active => null,
                    },
                    color: goal.status == GoalStatus.completed
                        ? AppColors.green
                        : AppColors.surface,
                    textColor: switch (goal.status) {
                      GoalStatus.completed => AppColors.greenStrong,
                      GoalStatus.missed => AppColors.muted,
                      GoalStatus.active => AppColors.text,
                    },
                    onTap: goal.isActive
                        ? () => app.goals.increment(goal)
                        : null,
                  ),
                ),
              SoftPill(
                label: 'Add',
                icon: LucideIcons.plus,
                color: AppColors.surface,
                textColor: AppColors.primary,
                onTap: () => _add(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.event,
    required this.isToday,
    required this.onTap,
  });

  final CalendarEvent event;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (event.location.isNotEmpty) event.location,
      event.category,
    ].join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
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
                      tr(isToday
                          ? 'TODAY'
                          : shortDate(event.date)
                                .split(',')
                                .first
                                .toUpperCase()),
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
                color: AppColors.accent(event.colorIndex),
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
              if (event.isSystem)
                Icon(LucideIcons.smartphone, size: 12, color: AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}
