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
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/notification_settings_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_store_screen.dart';
import 'package:flutter_application/core/utils/strings.dart';

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

  Future<void> _rename(BuildContext context) async {
    final app = AppScope.read(context);
    final name = await promptText(
      context,
      title: 'Your name',
      initial: app.user.name,
      hint: 'Name',
    );
    if (name != null) app.account.rename(name);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    final owned = app.templates
        .ownedBy(app.user.id)
        .where((t) => t.price > 0 || t.creatorId == app.user.id)
        .length;

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
                child: Text(app.user.initials, style: AppText.s(13)),
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
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.gem,
                          size: 17,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${app.user.name} · ${app.isVip ? 'VIP' : 'Free'}',
                              style: AppText.s(
                                14,
                                weight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tr(app.isVip
                                  ? 'All customization unlocked'
                                  : 'Upgrade to unlock the Theme Builder'),
                              style: AppText.s(
                                9.5,
                                color: AppColors.onPrimary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(tr('Designed for calmer, more personal days.'),
                style: AppText.s(9.5, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 10),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: LucideIcons.circleUserRound,
                  color: AppColors.purple,
                  title: 'Account',
                  value: app.user.name,
                  onTap: () => _rename(context),
                ),
                SettingsRow(
                  icon: LucideIcons.sun,
                  color: AppColors.yellow,
                  title: 'Appearance',
                  value: settings.darkMode ? 'Dark' : 'Light',
                  onTap: () => pushInTab(context, const AppearanceScreen()),
                ),
                SettingsRow(
                  icon: LucideIcons.languages,
                  color: AppColors.blue,
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
                SettingsRow(
                  icon: LucideIcons.clock3,
                  color: AppColors.green,
                  title: 'Date & Time',
                  value: switch (settings.timeFormat) {
                    TimeFormatSetting.h12 => '12-hour',
                    TimeFormatSetting.h24 => '24-hour',
                    TimeFormatSetting.automatic => 'Automatic',
                  },
                  onTap: () => _choose(
                    context,
                    'Date & Time',
                    const ['Automatic', '24-hour', '12-hour'],
                    switch (settings.timeFormat) {
                      TimeFormatSetting.h12 => '12-hour',
                      TimeFormatSetting.h24 => '24-hour',
                      TimeFormatSetting.automatic => 'Automatic',
                    },
                    (v) => app.account.updateSettings(
                      (s) => s.timeFormat = switch (v) {
                        '12-hour' => TimeFormatSetting.h12,
                        '24-hour' => TimeFormatSetting.h24,
                        _ => TimeFormatSetting.automatic,
                      },
                    ),
                  ),
                ),
                SettingsRow(
                  icon: LucideIcons.bell,
                  color: AppColors.purple,
                  title: 'Notifications',
                  value: settings.notificationsEnabled ? 'On' : 'Off',
                  onTap: () =>
                      pushInTab(context, const NotificationSettingsScreen()),
                ),
                SettingsRow(
                  icon: LucideIcons.calendarDays,
                  color: AppColors.pink,
                  title: 'Calendar',
                  value: settings.useSystemCalendar ? 'Phone + local' : 'Local',
                  onTap: () =>
                      pushInTab(context, const CalendarSettingsScreen()),
                ),
                SettingsRow(
                  icon: LucideIcons.lockKeyhole,
                  color: AppColors.blue,
                  title: 'Mobile Screen',
                  value: 'Edit',
                  onTap: () => pushInTab(context, const EditScreen()),
                ),
                SettingsRow(
                  icon: LucideIcons.gem,
                  color: AppColors.purple,
                  title: 'VIP',
                  value: app.isVip ? 'Active' : 'Free plan',
                  onTap: () => goToTab(context, AppTab.vip),
                ),
                SettingsRow(
                  icon: LucideIcons.store,
                  color: AppColors.pink,
                  title: 'Template Store',
                  value: owned == 0 ? 'Browse' : trf('{n} owned', {'n': owned}),
                  onTap: () => pushInTab(context, const TemplateStoreScreen()),
                ),
                SettingsRow(
                  icon: LucideIcons.circleQuestionMark,
                  color: AppColors.green,
                  title: 'Help',
                  onTap: () => showAppSnack(
                    context,
                    'Everything is stored on this device · no account needed',
                  ),
                ),
                SettingsRow(
                  icon: LucideIcons.info,
                  color: AppColors.yellow,
                  title: 'App Version',
                  value: '1.0.0',
                  onTap: () =>
                      showAppSnack(context, 'SuperCalendar 1.0.0 · Prototype'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
