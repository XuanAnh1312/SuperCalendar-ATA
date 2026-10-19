import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';

/// Settings → Notifications: reminders on/off, default timing and the lock
/// screen notification. The system permission is requested only when the
/// user turns something on here.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _toggle(BuildContext context, bool value) async {
    final app = AppScope.read(context);
    if (!value) {
      await app.disableNotifications();
      return;
    }
    final granted = await app.enableNotifications();
    if (!context.mounted) return;
    showAppSnack(
      context,
      granted
          ? 'Reminders are on'
          : 'Notifications are blocked for SuperCalendar in system settings',
    );
  }

  Future<void> _toggleLockScreen(BuildContext context, bool value) async {
    final app = AppScope.read(context);
    final ok = await app.setLockScreenNotification(value);
    if (!context.mounted) return;
    if (!ok) {
      showAppSnack(context, 'Allow notifications first');
    } else if (value) {
      showAppSnack(context, 'Lock your phone to see today’s schedule');
    }
  }

  Future<void> _sendTest(BuildContext context) async {
    final app = AppScope.read(context);
    if (!app.settings.notificationsEnabled) {
      showAppSnack(context, 'Turn on reminders first');
      return;
    }
    final task = app.tasks.items.where((t) => !t.completed).firstOrNull;
    if (task == null) {
      showAppSnack(context, 'Add a task first');
      return;
    }
    await app.notifications.showTaskReminder(task);
    if (!context.mounted) return;
    showAppSnack(context, 'Test reminder sent for "${task.title}"');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    final enabled = settings.notificationsEnabled;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const TopBar(title: 'Notifications'),
            const SizedBox(height: 14),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: LucideIcons.bell,
                  color: AppColors.purple,
                  title: 'Reminders',
                  subtitle: 'Event and task reminders with Done and Snooze',
                  trailing: AppSwitch(
                    value: enabled,
                    onChanged: (v) => _toggle(context, v),
                  ),
                  onTap: () => _toggle(context, !enabled),
                ),
                SettingsRow(
                  icon: LucideIcons.timer,
                  color: AppColors.green,
                  title: 'Default reminder',
                  subtitle: 'Used for new events',
                  value: formatReminder(settings.defaultReminderMinutes),
                  onTap: () async {
                    final picked = await pickReminder(
                      context,
                      settings.defaultReminderMinutes,
                    );
                    if (picked != null && picked > 0) {
                      app.setDefaultReminder(picked);
                    }
                  },
                ),
                SettingsRow(
                  icon: LucideIcons.lockKeyhole,
                  color: AppColors.blue,
                  title: 'Show on lock screen',
                  subtitle: 'Today’s schedule and your next to-do, with Done and Add task',
                  trailing: AppSwitch(
                    value: settings.lockScreenEnabled,
                    onChanged: (v) => _toggleLockScreen(context, v),
                  ),
                  onTap: () =>
                      _toggleLockScreen(context, !settings.lockScreenEnabled),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              enabled
                  ? 'Android shows reminders on the lock screen. Opening an '
                        'event from there asks for your screen lock first; '
                        'SuperCalendar never sees your PIN.'
                  : 'SuperCalendar only asks Android for notification access '
                        'when you turn reminders on.',
              style: AppText.s(10, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            Text('TRY IT', style: AppText.label()),
            const SizedBox(height: 8),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: LucideIcons.send,
                  color: AppColors.yellow,
                  title: 'Send a test reminder',
                  subtitle: 'Fires a task reminder now',
                  onTap: () => unawaited(_sendTest(context)),
                ),
                SettingsRow(
                  icon: LucideIcons.smartphone,
                  color: AppColors.pink,
                  title: 'Preview lock screen',
                  subtitle: 'The in-app version of your lock screen layout',
                  onTap: () => pushFullScreen(context, const LockScreen()),
                ),
                SettingsRow(
                  icon: LucideIcons.notebookPen,
                  color: AppColors.yellow,
                  title: 'Preview Quick Note',
                  subtitle: 'Type a note from the notification shade',
                  onTap: () => pushFullScreen(
                    context,
                    const QuickNoteNotificationScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
