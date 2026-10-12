import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/screens/home_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

/// "Edit Your Screen": preview of the lock / home layout with the widget tray.
class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  // 0 = lock screen, 1 = home screen.
  int _target = 0;

  static const _previewWidth = 186.0;
  static const _previewHeight = 333.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PageHeader(
                title: 'Edit Your Screen',
                subtitle: 'Drag, resize and make it yours',
                trailing: SizedBox(
                  width: 61,
                  child: PrimaryButton(
                    label: 'Done',
                    height: 32,
                    radius: 16,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SegmentedToggle(
                    labels: const ['LOCK', 'HOME'],
                    index: _target,
                    onChanged: (i) => setState(() => _target = i),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.hand,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Press and hold any widget, then drag. '
                              'Pull a corner to resize.',
                              style: AppText.s(
                                10.5,
                                color: AppColors.primaryTint,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _canvas(context),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: OutlinedActionButton(
                      icon: LucideIcons.pencil,
                      label: 'EDIT',
                      onTap: () => _target == 0
                          ? pushFullScreen(context, const LockScreen())
                          : Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedActionButton(
                      icon: LucideIcons.plus,
                      label: 'LET MAKE YOURS',
                      background: const Color(0xFFE2E3E6),
                      trailing: Text(
                        '✨VIP',
                        style: AppText.s(
                          12,
                          weight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () => goToTab(context, AppTab.vip),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _OptionCard(
              title: 'BACKGROUND',
              action: '🖼️ ADD IMAGE',
              onAction: () =>
                  showAppSnack(context, 'Image picker comes in a later phase'),
            ),
            _OptionCard(
              title: 'FONT',
              action: 'EDIT',
              onAction: () => goToTab(context, AppTab.vip),
            ),
            _OptionCard(
              title: 'TEMPLATE',
              action: 'EDIT',
              onAction: () => goToTab(context, AppTab.vip),
            ),
          ],
        ),
      ),
    );
  }

  /// Phone preview in the middle with the widget tray bleeding off both edges.
  Widget _canvas(BuildContext context) {
    return SizedBox(
      height: _previewHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = (constraints.maxWidth - _previewWidth) / 2;
          final sideGap = constraints.maxWidth - left + 14;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Left tray: cards are right-aligned so they clip at the edge.
              Positioned(
                right: sideGap,
                top: 10,
                width: 174,
                child: const GoalsWidget(),
              ),
              Positioned(
                right: sideGap,
                top: 105,
                width: 358,
                child: const MonthSnapshotWidget(),
              ),
              Positioned(
                right: sideGap,
                top: 202,
                width: 174,
                child: const TodoWidget(),
              ),
              // Right tray.
              Positioned(
                left: sideGap,
                top: 10,
                width: 174,
                child: const QuickNoteWidget(compact: true),
              ),
              Positioned(
                left: sideGap,
                top: 92,
                width: 358,
                child: const WeekWidget(),
              ),
              Positioned(
                left: sideGap,
                top: 190,
                width: 174,
                child: const HabitsWidget(),
              ),
              Positioned(
                left: left,
                top: 0,
                width: _previewWidth,
                height: _previewHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _target == 0
                      ? const _LockPreview(key: ValueKey('lock'))
                      : const _HomePreview(key: ValueKey('home')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 34),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppText.s(13, weight: FontWeight.w700)),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Text(action, style: AppText.action()),
            ),
          ],
        ),
      ),
    );
  }
}

const _lockGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF8EFF3), Color(0xFFEDE9F8)],
);

/// Miniature lock screen. Laid out at 2x and scaled down to fit.
class _LockPreview extends StatelessWidget {
  const _LockPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final events = app.eventsOn(app.today).take(2).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _lockGradient),
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 372,
            height: 666,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  Text('9:41', style: AppText.s(52, height: 1.1)),
                  Text(
                    longDate(app.today),
                    style: AppText.s(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _miniCard(
                    color: AppColors.blue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.yellow,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(
                                LucideIcons.notebookPen,
                                size: 11,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Super Calendar',
                                style: AppText.s(11, weight: FontWeight.w700),
                              ),
                            ),
                            const Icon(LucideIcons.pencil, size: 13),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You've a notification from SuperCalendar. "
                          'You can take notes quickly.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.s(8.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _miniCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _miniHeader(
                                  LucideIcons.calendarDays,
                                  'Schedule',
                                ),
                                for (final event in events)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 34,
                                          child: Text(
                                            event.startLabel,
                                            style: AppText.s(
                                              8,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 3,
                                          height: 22,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: event.color,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            event.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                            softWrap: false,
                                            style: AppText.s(
                                              10,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _miniCard(
                            color: AppColors.note,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _miniHeader(
                                  LucideIcons.notebookPen,
                                  'Quick Note',
                                  iconColor: AppColors.yellowText,
                                ),
                                const Spacer(),
                                const SavedStatus(size: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _miniCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _miniHeader(LucideIcons.circleCheckBig, 'To-do'),
                        for (final task in app.dashboardTasks)
                          Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Row(
                              children: [
                                AppCheckbox(value: task.completed, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.s(
                                      10,
                                      color: task.completed
                                          ? AppColors.muted
                                          : AppColors.text,
                                      decoration: task.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (!task.completed)
                                  const Icon(
                                    LucideIcons.alarmClockPlus,
                                    size: 12,
                                    color: AppColors.muted,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(
                    LucideIcons.lockKeyholeOpen,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Swipe up to unlock',
                    style: AppText.s(9, color: AppColors.muted),
                  ),
                  const Spacer(),
                  Container(
                    width: 150,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniCard({required Widget child, Color color = AppColors.surface}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: softShadow,
      ),
      child: child,
    );
  }

  Widget _miniHeader(
    IconData icon,
    String title, {
    Color iconColor = AppColors.primary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 8),
        Text(title, style: AppText.s(11, weight: FontWeight.w700)),
      ],
    );
  }
}

/// Miniature home dashboard: the real widgets scaled down.
class _HomePreview extends StatelessWidget {
  const _HomePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: IgnorePointer(
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: 390,
              height: 698,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, ${app.userName}',
                      style: AppText.s(18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    const HomeWidgetGrid(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
