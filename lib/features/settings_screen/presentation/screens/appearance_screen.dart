import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// Settings → Appearance: theme, light/dark and accent color. Typography is
/// part of the VIP Theme Builder.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    // Built-in themes plus the themes of templates the user can apply.
    final owned = app.templates.ownedBy(app.user.id);
    final themes = [
      ...builtInThemes,
      for (final template in owned)
        if (!builtInThemes.any((t) => t.id == template.themeData.id))
          template.themeData,
    ];
    final typography = app.isVip
        ? settings.typography ?? app.selectedTheme.typography
        : app.selectedTheme.typography;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const TopBar(title: 'Appearance'),
            const SizedBox(height: 14),
            Text(tr('THEME'), style: AppText.label()),
            const SizedBox(height: 8),
            SettingsGroup(
              children: [
                for (final theme in themes)
                  InkWell(
                    onTap: () => app.selectTheme(theme.id),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(
                                theme.radius * 0.55,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme.name,
                                  style: AppText.s(
                                    12.5,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  theme.builtIn
                                      ? 'Built-in'
                                      : '${tr('Template')} · ${theme.typography}',
                                  style: AppText.s(9.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          if (theme.id == app.user.selectedThemeId)
                            Icon(
                              LucideIcons.check,
                              size: 16,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(tr('MODE'), style: AppText.label()),
            const SizedBox(height: 8),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: settings.darkMode ? LucideIcons.moon : LucideIcons.sun,
                  color: AppColors.yellow,
                  title: 'Dark mode',
                  subtitle: settings.darkMode ? 'Dark' : 'Light',
                  trailing: AppSwitch(
                    value: settings.darkMode,
                    onChanged: app.setDarkMode,
                  ),
                  onTap: () => app.setDarkMode(!settings.darkMode),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(tr('ACCENT COLOR'), style: AppText.label()),
            const SizedBox(height: 8),
            AppCard(
              shadow: false,
              borderColor: Colors.transparent,
              child: Row(
                children: [
                  ColorDots(
                    colors: AppColors.accents,
                    index: settings.accentIndex,
                    size: 24,
                    spacing: 10,
                    onChanged: app.setAccent,
                  ),
                  const Spacer(),
                  SoftPill(
                    label: settings.accentIndex == null
                        ? 'Theme default'
                        : 'Reset',
                    color: settings.accentIndex == null
                        ? AppColors.primarySoft
                        : AppColors.subtle,
                    textColor: settings.accentIndex == null
                        ? AppColors.primary
                        : AppColors.muted,
                    onTap: () => app.setAccent(null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(tr('TYPOGRAPHY'), style: AppText.label()),
            const SizedBox(height: 8),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: LucideIcons.type,
                  color: AppColors.purple,
                  title: 'Font style',
                  subtitle: app.isVip ? null : 'VIP · Theme Builder',
                  value: typography,
                  trailing: app.isVip
                      ? null
                      : Icon(
                          LucideIcons.lockKeyhole,
                          size: 14,
                          color: AppColors.faint,
                        ),
                  onTap: () => pickTypography(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () => goToTab(context, AppTab.vip),
                child: Text(
                  tr(app.isVip
                      ? 'Build your own theme in the Template Studio'
                      : 'More control with VIP · Theme Builder'),
                  style: AppText.s(10, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Typography picker. A Free user is sent to the VIP offer instead.
Future<void> pickTypography(BuildContext context) async {
  final app = AppScope.read(context);
  if (!await requireVip(context, feature: VipFeature.customTypography)) return;
  if (!context.mounted) return;
  final picked = await pickOption(
    context,
    title: 'Typography',
    options: AppThemeData.typographies,
    current: app.settings.typography ?? app.selectedTheme.typography,
  );
  if (picked != null) app.setTypography(picked);
}
