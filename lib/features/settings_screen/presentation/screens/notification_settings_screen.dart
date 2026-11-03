import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// Turns notifications on (asks Android once) and reports the result.
Future<bool> _allowNotifications(BuildContext context) async {
  final granted = await AppScope.read(context).enableNotifications();
  if (context.mounted) {
    showAppSnack(
      context,
      granted
          ? 'Reminders are on'
          : 'Notifications are blocked for SuperCalendar in system settings',
    );
  }
  return granted;
}

const _appSettings = MethodChannel('supercalendar/app_settings');

/// Opens Android's notification settings for SuperCalendar (MainActivity).
/// False when there is no native side (tests, other platforms) or no
/// settings screen could be opened.
Future<bool> openAndroidNotificationSettings() async {
  try {
    return await _appSettings.invokeMethod<bool>('openNotificationSettings') ??
        false;
  } on MissingPluginException {
    return false;
  }
}

/// Settings → Notifications (Settings 28): reminders on/off and default
/// timing per type (§5.2 NotificationConfig). The system permission is
/// requested only when the user turns a reminder on (FR-01, AC-05).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  /// True after sending the user to Android's settings, so coming back can
  /// pick up a newly granted permission.
  bool _openedSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_recheckPermission());
  }

  /// Follows what the user changed in Android's settings (NFR-11).
  Future<void> _recheckPermission() async {
    final app = AppScope.read(context);
    final granted = await app.notifications.hasPermission();
    if (!mounted) return;
    final enabled = app.settings.notificationsEnabled;
    if (enabled && !granted) {
      await app.disableNotifications();
    } else if (!enabled && granted && _openedSettings) {
      await app.enableNotifications();
    }
    _openedSettings = false;
  }

  /// First time: Android's own permission dialog (POST_NOTIFICATIONS, API
  /// 33+). Once asked, Android may not show it again, so the app's
  /// notification settings page opens instead (NFR-11).
  Future<void> _openSystemSettings(BuildContext context) async {
    if (!AppScope.read(context).settings.notificationPermissionAsked) {
      await _allowNotifications(context);
      return;
    }
    _openedSettings = true;
    final opened = await openAndroidNotificationSettings();
    // No native side: fall back to the in-app permission request.
    if (!opened && context.mounted) await _allowNotifications(context);
  }

  Future<void> _toggle(
    BuildContext context,
    bool value,
    void Function(AppSettings settings, bool value) apply,
  ) async {
    final app = AppScope.read(context);
    if (value && !app.settings.notificationsEnabled) {
      if (!await _allowNotifications(context)) return;
    }
    app.account.updateSettings((s) => apply(s, value));
  }

  /// Picks a lead time; "None" stores null.
  Future<void> _pickLead(
    BuildContext context,
    int? current,
    void Function(AppSettings settings, int? minutes) apply,
  ) async {
    final picked = await pickReminder(context, current);
    if (picked == null || !context.mounted) return;
    AppScope.read(context).account
        .updateSettings((s) => apply(s, picked < 0 ? null : picked));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    final enabled = settings.notificationsEnabled;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'Notifications',
              subtitle: tr('A nudge, when you need it'),
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  AppCard(
                    color: AppColors.primarySoft,
                    borderColor: Colors.transparent,
                    shadow: false,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.bell,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr('Stay gently in the loop'),
                          style: AppText.s(17, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(
                            'Default reminders can be changed on each event, '
                            'task or habit.',
                          ),
                          style: AppText.s(
                            12.5,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('Reminders'),
                    style: AppText.s(15, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _ReminderRow(
                    title: 'Events',
                    lead: formatReminder(settings.defaultReminderMinutes),
                    value: enabled && settings.eventReminders,
                    onChanged: (v) =>
                        _toggle(context, v, (s, v) => s.eventReminders = v),
                    onTap: () => _pickLead(
                      context,
                      settings.defaultReminderMinutes,
                      (s, m) => s.defaultReminderMinutes = m,
                    ),
                  ),
                  _ReminderRow(
                    title: 'Tasks',
                    lead: settings.taskReminderMinutes == null
                        ? tr('At the due time')
                        : formatReminder(settings.taskReminderMinutes),
                    value: enabled && settings.taskReminders,
                    onChanged: (v) =>
                        _toggle(context, v, (s, v) => s.taskReminders = v),
                    onTap: () => _pickLead(
                      context,
                      settings.taskReminderMinutes,
                      (s, m) => s.taskReminderMinutes = m,
                    ),
                  ),
                  _ReminderRow(
                    title: 'Habits',
                    lead: settings.habitReminderMinutes == null
                        ? tr('At the scheduled time')
                        : formatReminder(settings.habitReminderMinutes),
                    value: enabled && settings.habitReminders,
                    onChanged: (v) =>
                        _toggle(context, v, (s, v) => s.habitReminders = v),
                    onTap: () => _pickLead(
                      context,
                      settings.habitReminderMinutes,
                      (s, m) => s.habitReminderMinutes = m,
                    ),
                    last: true,
                  ),
                  // AC-05: the app keeps working and says why nothing fires.
                  if (!enabled && settings.notificationPermissionAsked) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      color: AppColors.pink,
                      shadow: false,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.triangleAlert,
                            size: 16,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr(
                                'Notifications are off, so reminders will not '
                                'fire. Turn Reminders on, or allow '
                                'notifications for SuperCalendar in Android '
                                'settings.',
                              ),
                              style: AppText.s(11, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppCard(
                    color: AppColors.blue,
                    borderColor: Colors.transparent,
                    shadow: false,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Quick Note on your lock screen'),
                          style: AppText.s(15, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            'Allow SuperCalendar notifications in Android '
                            'settings to see Quick Note. Lock-screen '
                            'visibility also depends on your device’s '
                            'notification privacy settings.',
                          ),
                          style: AppText.s(
                            12.5,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StudioButton(
                          label: settings.notificationPermissionAsked
                              ? 'Open Android notification settings'
                              : 'Allow notifications',
                          soft: true,
                          onTap: () => unawaited(_openSystemSettings(context)),
                        ),
                      ],
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
}

/// One reminder type: name, default timing (tap to change) and a switch.
class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.title,
    required this.lead,
    required this.value,
    required this.onChanged,
    required this.onTap,
    this.last = false,
  });

  final String title;
  final String lead;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(title), style: AppText.s(14)),
                    const SizedBox(height: 4),
                    Text(lead, style: AppText.s(12.5, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Settings → Lock Screen: the lock screen notification (FR-19, AC-38) and
/// the Quick Note notification (FR-20), with in-app previews.
class LockScreenSettingsScreen extends StatelessWidget {
  const LockScreenSettingsScreen({super.key});

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

  Future<void> _toggleQuickNote(BuildContext context, bool value) async {
    final ok = await AppScope.read(context).setQuickNoteNotification(value);
    if (!ok && context.mounted) {
      showAppSnack(context, 'Allow notifications first');
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
    showAppSnack(
      context,
      trf('Test reminder sent for "{title}"', {'title': task.title}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'Lock Screen',
              subtitle: tr('Schedule, quick tasks and Quick Note'),
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: LucideIcons.lockKeyhole,
                        color: AppColors.blue,
                        title: 'Show on lock screen',
                        subtitle:
                            'Today’s schedule and your next to-do, with Done '
                            'and Add task',
                        trailing: AppSwitch(
                          value: settings.lockScreenEnabled,
                          onChanged: (v) => _toggleLockScreen(context, v),
                        ),
                        onTap: () => _toggleLockScreen(
                          context,
                          !settings.lockScreenEnabled,
                        ),
                      ),
                      SettingsRow(
                        icon: LucideIcons.eyeOff,
                        color: AppColors.pink,
                        title: 'Hide details',
                        subtitle:
                            'Lock screen shows only how many events and to-dos',
                        trailing: AppSwitch(
                          value: settings.lockScreenHideDetails,
                          onChanged: app.setLockScreenHideDetails,
                        ),
                        onTap: () => app.setLockScreenHideDetails(
                          !settings.lockScreenHideDetails,
                        ),
                      ),
                      SettingsRow(
                        icon: LucideIcons.stickyNote,
                        color: AppColors.yellow,
                        title: 'Quick Note in notifications',
                        subtitle:
                            'Write a note straight from the notification shade',
                        trailing: AppSwitch(
                          value: settings.quickNoteNotification,
                          onChanged: (v) => _toggleQuickNote(context, v),
                        ),
                        onTap: () => _toggleQuickNote(
                          context,
                          !settings.quickNoteNotification,
                        ),
                      ),
                      if (settings.quickNoteNotification)
                        SettingsRow(
                          icon: LucideIcons.listPlus,
                          color: AppColors.green,
                          title: 'Saving from the notification',
                          value: settings.quickNoteAppend
                              ? 'Append'
                              : 'Replace',
                          onTap: () async {
                            final picked = await pickOption(
                              context,
                              title: 'Saving from the notification',
                              options: const ['Append', 'Replace'],
                              current: settings.quickNoteAppend
                                  ? 'Append'
                                  : 'Replace',
                            );
                            if (picked == null) return;
                            app.account.updateSettings(
                              (s) => s.quickNoteAppend = picked == 'Append',
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'Android shows reminders on the lock screen. Opening an '
                      'event from there asks for your screen lock first; '
                      'SuperCalendar never sees your PIN.',
                    ),
                    style: AppText.s(10, color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  Text(tr('TRY IT'), style: AppText.label()),
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
                        subtitle:
                            'The in-app version of your lock screen layout',
                        onTap: () =>
                            pushFullScreen(context, const LockScreen()),
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
          ],
        ),
      ),
    );
  }
}
