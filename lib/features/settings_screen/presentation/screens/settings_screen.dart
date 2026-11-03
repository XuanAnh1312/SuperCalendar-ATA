import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/appearance_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/calendar_settings_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/notification_settings_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/profile_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/sync_status_screen.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// Settings overview (Settings 26, FR-21): profile card, the preference rows
/// of the design, then the Tasks / Data / Privacy rows of README UI-09.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _choose(
    BuildContext context,
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
    if (picked != null) onPicked(picked);
  }

  /// Date & Time: the time format (shown on the row) or the order of
  /// numeric dates (FR-21).
  Future<void> _pickDateTime(BuildContext context, String timeFormat) async {
    final app = AppScope.read(context);
    final what = await pickOption(
      context,
      title: 'Date & Time',
      options: const ['Time format', 'Date format'],
      current: '',
    );
    if (what == null || !context.mounted) return;
    if (what == 'Time format') {
      await _choose(
        context,
        'Time format',
        const ['Automatic', '24-hour', '12-hour'],
        timeFormat,
        (v) => app.account.updateSettings(
          (s) => s.timeFormat = switch (v) {
            '12-hour' => TimeFormatSetting.h12,
            '24-hour' => TimeFormatSetting.h24,
            _ => TimeFormatSetting.automatic,
          },
        ),
      );
    } else {
      final monthFirst = app.settings.dateFormat.startsWith('MM');
      await _choose(
        context,
        'Date format',
        const ['Day/Month', 'Month/Day'],
        monthFirst ? 'Month/Day' : 'Day/Month',
        (v) => app.account.updateSettings(
          (s) => s.dateFormat = v == 'Month/Day' ? 'MM/dd/yyyy' : 'dd/MM/yyyy',
        ),
      );
    }
  }

  /// UI-09: privacy notes of the Prototype (README §28, BR-14, NFR-10).
  Future<void> _showPrivacy(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('Privacy & Terms'), style: AppText.cardTitle()),
      content: SingleChildScrollView(
        child: Text(
          tr(
            'SuperCalendar keeps all your data on this device. There is no '
            'account, no server and no cloud sync. The app never asks for or '
            'stores your PIN, password or biometrics. Calendar and '
            'notification access are only used for the features you turn on. '
            'VIP and template purchases in this prototype are simulated; no '
            'real payment is made.',
          ),
          style: AppText.s(12.5, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('OK')),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    final timeFormat = switch (settings.timeFormat) {
      TimeFormatSetting.h12 => '12-hour',
      TimeFormatSetting.h24 => '24-hour',
      TimeFormatSetting.automatic => 'Automatic',
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const PageHeader(
              title: 'Settings',
              subtitle: 'Make SuperCalendar yours',
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.primarySoft,
              borderColor: Colors.transparent,
              shadow: false,
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              onTap: () => pushInTab(context, const ProfileScreen()),
              child: Row(
                children: [
                  ProfileAvatar(
                    user: app.user,
                    radius: 20,
                    background: AppColors.surface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${app.user.name} · ${app.isVip ? 'VIP' : 'Free'}',
                          style: AppText.s(15, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          app.user.email ?? tr('Add your email'),
                          style: AppText.s(11.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            // Prototype mock (README §10 has no cloud sync); opens the
            // design's sync status screen.
            InkWell(
              onTap: () => pushInTab(context, const SyncStatusScreen()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.cloudCheck,
                      size: 15,
                      color: AppColors.greenStrong,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('Synced across 3 devices'),
                      style: AppText.s(12, color: AppColors.greenStrong),
                    ),
                  ],
                ),
              ),
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shadow: false,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: LucideIcons.user,
                    title: 'Account',
                    value: app.user.name,
                    onTap: () => pushInTab(context, const ProfileScreen()),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.sun,
                    title: 'Appearance',
                    value: settings.darkMode ? 'Dark' : 'Light',
                    onTap: () => pushInTab(context, const AppearanceScreen()),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.languages,
                    title: 'Language',
                    value: settings.language,
                    onTap: () => _choose(
                      context,
                      'Language',
                      const ['English', 'Tiếng Việt'],
                      settings.language,
                      app.setLanguage,
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.clock3,
                    title: 'Date & Time',
                    value: timeFormat,
                    onTap: () => _pickDateTime(context, timeFormat),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.calendarDays,
                    title: 'Calendar',
                    value: 'Preferences',
                    onTap: () =>
                        pushInTab(context, const CalendarSettingsScreen()),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.bell,
                    title: 'Notifications',
                    value: settings.notificationsEnabled ? 'On' : 'Off',
                    onTap: () =>
                        pushInTab(context, const NotificationSettingsScreen()),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.lockKeyhole,
                    title: 'Lock Screen',
                    value: settings.quickNoteNotification
                        ? 'Quick Note'
                        : settings.lockScreenEnabled
                        ? 'On'
                        : 'Off',
                    onTap: () =>
                        pushInTab(context, const LockScreenSettingsScreen()),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.circleQuestionMark,
                    title: 'Help',
                    onTap: () => showAppSnack(
                      context,
                      'Everything is stored on this device · no account needed',
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.info,
                    title: 'App Version',
                    value: '1.0.0',
                    chevron: false,
                    last: true,
                    onTap: () => showAppSnack(
                      context,
                      'SuperCalendar 1.0.0 · Prototype',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // UI-09: the Tasks, Data and Privacy/Terms groups of FR-21.
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shadow: false,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: LucideIcons.listChecks,
                    title: 'Hide completed tasks',
                    onTap: () => app.account.updateSettings(
                      (s) => s.hideCompletedTasks = !s.hideCompletedTasks,
                    ),
                    trailing: AppSwitch(
                      value: settings.hideCompletedTasks,
                      onChanged: (v) => app.account.updateSettings(
                        (s) => s.hideCompletedTasks = v,
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.flag,
                    title: 'Default priority',
                    value: settings.defaultPriority ?? Task.priorityMedium,
                    onTap: () => _choose(
                      context,
                      'Default priority',
                      Task.priorities,
                      settings.defaultPriority ?? Task.priorityMedium,
                      (v) => app.account.updateSettings(
                        (s) => s.defaultPriority = v,
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.database,
                    title: 'Data',
                    value: 'On this device',
                    onTap: () => showAppSnack(
                      context,
                      'Everything is stored on this device · no account needed',
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.shieldCheck,
                    title: 'Privacy & Terms',
                    last: true,
                    onTap: () => _showPrivacy(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                tr('Designed for calmer, more personal days.'),
                style: AppText.s(12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the Settings list (Settings 26): outline icon, title, value
/// and chevron, at least 48 dp tall (NFR-08).
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.trailing,
    this.chevron = true,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool chevron;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 49),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.text),
            const SizedBox(width: 14),
            Expanded(child: Text(tr(title), style: AppText.s(14))),
            if (value != null)
              Text(tr(value!), style: AppText.s(12, color: AppColors.muted)),
            if (trailing != null)
              trailing!
            else if (chevron) ...[
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 16, color: AppColors.muted),
            ],
          ],
        ),
      ),
    );
  }
}
