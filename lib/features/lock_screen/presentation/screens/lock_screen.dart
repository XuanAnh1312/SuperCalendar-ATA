import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

/// In-app simulation of the lock screen: the schedule is read-only, the
/// to-do list is interactive and shares its data with the rest of the app.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  void _unlock(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final events = app.eventsOn(app.today);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -250) _unlock(context);
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8EFF3), Color(0xFFFCFCFE), Color(0xFFEDE9F8)],
              stops: [0, 0.45, 1],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(19, 20, 19, 24),
              children: [
                Center(child: Text('9:41', style: AppText.s(54, height: 1.1))),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    longDate(app.today),
                    style: AppText.s(
                      13,
                      weight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LockCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.calendarDays,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Schedule',
                              style: AppText.s(12.5, weight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.lockKeyhole,
                                  size: 11,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Read only',
                                  style: AppText.s(10, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Nothing scheduled today',
                            style: AppText.s(11, color: AppColors.muted),
                          ),
                        ),
                      for (final event in events)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // Tapping an event opens the app on the calendar.
                          onTap: () {
                            _unlock(context);
                            goToTab(context, AppTab.calendar);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 47,
                                  child: Text(
                                    event.startLabel,
                                    style: AppText.s(
                                      9.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: event.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.s(
                                      11.5,
                                      weight: FontWeight.w600,
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
                _LockCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.circleCheckBig,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To-do',
                              style: AppText.s(12.5, weight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            'Quick actions on',
                            style: AppText.s(9.5, color: AppColors.greenStrong),
                          ),
                        ],
                      ),
                      for (final task in app.dashboardTasks)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              AppCheckbox(
                                value: task.completed,
                                onChanged: (_) => app.toggleTask(task),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.s(
                                    11.5,
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
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => showAppSnack(
                                    context,
                                    'Reminder set for "${task.title}"',
                                  ),
                                  child: const Icon(
                                    LucideIcons.alarmClockPlus,
                                    size: 15,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _LockCard(
                  color: const Color(0xFFFCF6DA),
                  onTap: () => pushFullScreen(
                    context,
                    const QuickNoteNotificationScreen(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.notebookPen,
                            size: 15,
                            color: AppColors.yellowText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quick Note',
                              style: AppText.s(12.5, weight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            'Tap to type',
                            style: AppText.s(
                              10.5,
                              weight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.mic, size: 14),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        app.quickNote.isEmpty
                            ? 'Tap to write a note'
                            : app.quickNote,
                        style: AppText.s(11.5, height: 1.35),
                      ),
                      const SizedBox(height: 9),
                      const SavedStatus(size: 9.5),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _unlock(context),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.lockKeyholeOpen,
                        size: 17,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Swipe up to unlock',
                        style: AppText.s(10.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({
    required this.child,
    this.color = const Color(0xFFFDFCFE),
    this.onTap,
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color,
      borderColor: Colors.white,
      onTap: onTap,
      child: child,
    );
  }
}
