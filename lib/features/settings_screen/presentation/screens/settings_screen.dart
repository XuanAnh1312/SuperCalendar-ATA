import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'English';
  String _dateTime = 'Automatic';
  String _appearance = 'Light';

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

  Future<void> _confirmLogOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    showAppSnack(context, 'Log out is not available in this prototype');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final rows = [
      _SettingsRow(
        icon: LucideIcons.circleUserRound,
        color: AppColors.purple,
        title: 'Account',
        value: app.userFullName,
        onTap: () => showAppSnack(context, 'Signed in as ${app.userFullName}'),
      ),
      _SettingsRow(
        icon: LucideIcons.sun,
        color: AppColors.yellow,
        title: 'Appearance',
        value: _appearance,
        onTap: () => _choose(
          'Appearance',
          const ['Light', 'Dark'],
          _appearance,
          (v) => _appearance = v,
        ),
      ),
      _SettingsRow(
        icon: LucideIcons.languages,
        color: AppColors.blue,
        title: 'Language',
        value: _language,
        onTap: () => _choose(
          'Language',
          const ['English', 'Tiếng Việt'],
          _language,
          (v) => _language = v,
        ),
      ),
      _SettingsRow(
        icon: LucideIcons.clock3,
        color: AppColors.green,
        title: 'Date & Time',
        value: _dateTime,
        onTap: () => _choose(
          'Date & Time',
          const ['Automatic', '24-hour', '12-hour'],
          _dateTime,
          (v) => _dateTime = v,
        ),
      ),
      _SettingsRow(
        icon: LucideIcons.bell,
        color: AppColors.purple,
        title: 'Notifications',
        value: 'On',
        onTap: () =>
            pushFullScreen(context, const QuickNoteNotificationScreen()),
      ),
      _SettingsRow(
        icon: LucideIcons.calendarDays,
        color: AppColors.pink,
        title: 'Calendar',
        value: 'Edit',
        onTap: () => goToTab(context, AppTab.calendar),
      ),
      _SettingsRow(
        icon: LucideIcons.lockKeyhole,
        color: AppColors.blue,
        title: 'Mobile Screen',
        value: 'Edit',
        onTap: () => pushFullScreen(context, const LockScreen()),
      ),
      _SettingsRow(
        icon: LucideIcons.circleQuestionMark,
        color: AppColors.green,
        title: 'Help',
        onTap: () =>
            showAppSnack(context, 'Help center comes in a later phase'),
      ),
      _SettingsRow(
        icon: LucideIcons.info,
        color: AppColors.yellow,
        title: 'App Version',
        value: '1.0.0',
        onTap: () => showAppSnack(context, 'SuperCalendar 1.0.0 · Prototype'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            PageHeader(
              title: 'Settings',
              subtitle: 'Make SuperCalendar yours',
              trailing: CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.pink,
                child: Text('MC', style: AppText.s(13)),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => goToTab(context, AppTab.vip),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 13, 14, 13),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.gem,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${app.userFullName} · VIP',
                              style: AppText.s(
                                14,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Synced across 3 devices',
                              style: AppText.s(
                                9.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Designed for calmer, more personal days.',
                style: AppText.s(9.5, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              borderColor: Colors.transparent,
              shadow: false,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    rows[i],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _confirmLogOut,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppColors.text),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: AppText.s(12.5, weight: FontWeight.w600),
              ),
            ),
            if (value != null)
              Text(value!, style: AppText.s(10.5, color: AppColors.muted)),
            const SizedBox(width: 14),
            const Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: AppColors.faint,
            ),
          ],
        ),
      ),
    );
  }
}
