import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // 0 = daily, 1 = weekly, 2 = custom.
  int _filter = 0;

  static const _kinds = ['Daily', 'Weekly', 'Custom'];

  List<Color> _weekColors(DateTime today) => [
    for (var i = 0; i < 7; i++)
      i == today.weekday - 1
          ? AppColors.primary
          : i < today.weekday - 1 || i < 4
          ? AppColors.dotDone
          : AppColors.dotIdle,
  ];

  Future<void> _addHabit(BuildContext context) async {
    final title = await promptText(
      context,
      title: 'New ${_kinds[_filter].toLowerCase()} habit',
      hint: 'e.g. Drink water',
    );
    if (title == null || title.isEmpty || !context.mounted) return;
    final kind = _kinds[_filter];
    AppScope.read(context).habits.add(
      Habit(
        id: newId('habit'),
        title: title,
        shortTitle: title,
        schedule: '$kind · anytime',
        occurrence: 'Today · ${kind.toLowerCase()} occurrence',
        icon: 'check',
        colorIndex: _filter == 0 ? 0 : (_filter == 1 ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = app.today;
    final habits = app.habits.occurrences(today);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            PageHeader(
              title: 'Habits',
              subtitle: 'Generated automatically from your rhythm',
              trailing: RoundIconButton(
                icon: LucideIcons.plus,
                size: 40,
                filled: true,
                onTap: () => _addHabit(context),
              ),
            ),
            const SizedBox(height: 10),
            FilterPillRow(
              labels: _kinds,
              index: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.subtle,
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: WeekDots(
                labels: weekLabels(today),
                colors: _weekColors(today),
                activeIndex: today.weekday - 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Today · ${habits.length} occurrences',
                    style: AppText.cardTitle(),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Text('Manage habits', style: AppText.action()),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (habits.isEmpty)
              const EmptyState(
                icon: LucideIcons.circleCheck,
                message: 'No occurrences left today',
              ),
            for (final habit in habits)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HabitCard(
                  habit: habit,
                  today: today,
                  onToggle: () => app.habits.toggle(habit, today),
                  onOpen: () => _showActions(context, habit),
                ),
              ),
            AppCard(
              color: AppColors.blue,
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(LucideIcons.repeat2, size: 14, color: AppColors.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Future occurrences update when you change a habit’s repetition.',
                      style: AppText.s(10, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, Habit habit) {
    final app = AppScope.read(context);
    final today = app.today;
    final done = habit.isDone(today);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface(habit.colorIndex),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    habitIcon(habit.icon),
                    size: 17,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: AppText.s(15, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habit.occurrence,
                        style: AppText.s(10.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SheetAction(
              icon: LucideIcons.pencil,
              title: 'Edit this occurrence',
              subtitle: done ? 'Mark today as not done' : 'Mark today as done',
              color: AppColors.text,
              onTap: () {
                Navigator.pop(sheetContext);
                app.habits.toggle(habit, today);
              },
            ),
            _SheetAction(
              icon: LucideIcons.circleSlash2,
              title: 'Skip occurrence',
              subtitle: 'Keep future repeats',
              color: AppColors.amber,
              onTap: () {
                Navigator.pop(sheetContext);
                app.habits.skip(habit, today);
                showAppSnack(context, '${habit.title} skipped for today');
              },
            ),
            _SheetAction(
              icon: LucideIcons.trash2,
              title: 'Delete occurrence',
              subtitle: 'Remove today only',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(sheetContext);
                app.habits.removeOccurrence(habit, today);
                showAppSnack(context, '${habit.title} removed from today');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.today,
    required this.onToggle,
    required this.onOpen,
  });

  final Habit habit;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final done = habit.isDone(today);
    return AppCard(
      color: AppColors.accentSurface(habit.colorIndex),
      shadow: false,
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(
              habitIcon(habit.icon),
              size: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  habit.isSkipped(today) ? 'Skipped today' : habit.schedule,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(9.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: done ? onToggle : onOpen,
            onLongPress: onToggle,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                done ? LucideIcons.circleCheck : LucideIcons.ellipsisVertical,
                size: 17,
                color: done ? AppColors.greenStrong : AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.s(12.5, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.s(9.5, color: AppColors.muted)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 14, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}
