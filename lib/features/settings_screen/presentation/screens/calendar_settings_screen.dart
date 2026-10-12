import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/presentation/widgets/system_calendar_prompt.dart';

/// Settings → Calendar: system calendar permission and the default calendar.
class CalendarSettingsScreen extends StatelessWidget {
  const CalendarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    final connected = settings.useSystemCalendar;
    final status = connected
        ? '${app.events.systemEvents.length} event'
              '${app.events.systemEvents.length == 1 ? '' : 's'} read from this phone'
        : settings.calendarPermissionAsked
        ? 'Not connected · using local events'
        : 'Not connected';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const TopBar(title: 'Calendar'),
            const SizedBox(height: 14),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: LucideIcons.smartphone,
                  color: AppColors.blue,
                  title: 'Phone calendar',
                  subtitle: status,
                  trailing: AppSwitch(
                    value: connected,
                    onChanged: (value) => value
                        ? connectSystemCalendar(context)
                        : app.disconnectSystemCalendar(),
                  ),
                  onTap: () => connected
                      ? app.disconnectSystemCalendar()
                      : connectSystemCalendar(context),
                ),
                SettingsRow(
                  icon: LucideIcons.calendarDays,
                  color: AppColors.pink,
                  title: 'Default calendar',
                  subtitle: 'Used for new events',
                  value: settings.defaultCalendar,
                  onTap: () async {
                    final picked = await pickOption(
                      context,
                      title: 'Default calendar',
                      options: const ['Personal', 'Work', 'Family'],
                      current: settings.defaultCalendar,
                    );
                    if (picked != null) {
                      app.account.updateSettings(
                        (s) => s.defaultCalendar = picked,
                      );
                    }
                  },
                ),
                SettingsRow(
                  icon: LucideIcons.calendar,
                  color: AppColors.green,
                  title: 'Open calendar',
                  onTap: () => goToTab(context, AppTab.calendar),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Why the permission? With calendar access SuperCalendar can '
              'show the events already on this phone next to yours. They are '
              'read-only and are not copied or uploaded. Without it, the app '
              'works the same with the events you create here.',
              style: AppText.s(10, color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
