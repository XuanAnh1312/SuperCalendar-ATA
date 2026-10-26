import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_detail_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/lock_screen/presentation/widgets/lock_widgets.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// Background of the lock screen for the active theme's lock screen style.
BoxDecoration lockScreenDecoration() {
  if (AppTheme.current.lockScreenStyle == AppThemeData.lockStylePlain) {
    return BoxDecoration(color: AppColors.background);
  }
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.lockTop, AppColors.lockMid, AppColors.lockBottom],
      stops: const [0, 0.45, 1],
    ),
  );
}

/// In-app lock screen: the schedule is read-only, the to-do list is
/// interactive, and both use the same data as the rest of the app. On a real
/// locked device the same content is delivered as a lock screen notification.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  void _unlock(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final layout = app.layouts.lock;
    final now = app.now;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -250) _unlock(context);
        },
        child: LayoutBackground(
          layout: layout,
          fallback: lockScreenDecoration(),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(19, 20, 19, 24),
                children: [
                  Center(
                    child: Text(
                      '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                      style: AppText.s(54, height: 1.1),
                    ),
                  ),
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
                  LockWidgetList(
                    layout: layout,
                    actions: LockActions(
                      // Opening an event leaves the lock screen for the app.
                      onOpenEvent: (event) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        );
                      },
                      onToggleTask: app.tasks.toggle,
                      onRemindTask: (task) async {
                        final ok = await app.enableNotifications();
                        if (!context.mounted) return;
                        if (!ok) {
                          showAppSnack(context, 'Notifications are turned off');
                          return;
                        }
                        unawaited(app.notifications.showTaskReminder(task));
                        showAppSnack(
                          context,
                          trf('Reminder sent for "{title}"', {'title': task.title}),
                        );
                      },
                      onAddTask: () => showQuickAddTask(context),
                      onOpenNote: () => pushFullScreen(
                        context,
                        const QuickNoteNotificationScreen(),
                      ),
                    ),
                  ),
                  if (layout.visibleItems.isEmpty)
                    const EmptyState(
                      icon: LucideIcons.layoutGrid,
                      message: 'No widgets on the lock screen.\nAdd some in Edit Your Screen.',
                    ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _unlock(context),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.lockKeyholeOpen,
                          size: 17,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 8),
                        Text(tr('Swipe up to unlock'),
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
