import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/presentation/calendar_visibility.dart';
import 'package:flutter_application/features/calendar/presentation/widgets/system_calendar_prompt.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

/// Settings → Calendar: system calendar permission and the default calendar.
class CalendarSettingsScreen extends StatefulWidget {
  const CalendarSettingsScreen({super.key});

  @override
  State<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends State<CalendarSettingsScreen>
    with WidgetsBindingObserver {
  List<DeviceCalendar> _calendars = const [];
  bool _loadingCalendars = false;
  bool _openedSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadCalendars());
    });
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

  Future<void> _recheckPermission() async {
    if (!_openedSettings) return;
    _openedSettings = false;
    if (!mounted) return;
    await connectSystemCalendar(context);
    if (mounted) await _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    if (!mounted) return;
    setState(() => _loadingCalendars = true);
    final calendars = await AppScope.read(context).systemCalendar.calendars();
    if (!mounted) return;
    setState(() {
      _calendars = calendars;
      _loadingCalendars = false;
    });
  }

  Future<void> _togglePhoneCalendar(bool value) async {
    final app = AppScope.read(context);
    if (value) {
      await connectSystemCalendar(context);
      if (mounted) await _loadCalendars();
    } else {
      app.disconnectSystemCalendar();
      setState(() => _calendars = const []);
    }
  }

  Future<void> _openAndroidSettings() async {
    _openedSettings = true;
    final opened = await AppScope.read(context).systemCalendar.openAppSettings();
    if (!opened && mounted) {
      await connectSystemCalendar(context);
      if (mounted) await _loadCalendars();
    }
  }

  void _setCalendarVisible(DeviceCalendar calendar, bool visible) {
    final app = AppScope.read(context);
    final next = visibleIdsAfterToggle(
      current: app.settings.visibleCalendarIds,
      allIds: [for (final c in _calendars) c.id],
      id: calendar.id,
      visible: visible,
    );
    app.account.updateSettings((s) => s.visibleCalendarIds = next);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final settings = app.settings;
    final connected = settings.useSystemCalendar;
    final visibleSystem = app.events.systemEvents
        .where((e) => isVisibleCalendarEvent(settings, e))
        .length;
    final status = connected
        ? trf(
            visibleSystem == 1
                ? '{n} event read from this phone'
                : '{n} events read from this phone',
            {'n': visibleSystem},
          )
        : settings.calendarPermissionAsked
        ? 'Not connected · using local events'
        : 'Not connected';
    final denied =
        !connected && settings.calendarPermissionAsked && !app.systemCalendarGranted;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StudioHeader(
              title: 'Calendar',
              subtitle: tr('Preferences'),
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
                        Text(
                          tr('Phone calendars'),
                          style: AppText.s(17, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(
                            'Events from these calendars show in SuperCalendar. They stay read-only.',
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
                  const SizedBox(height: 16),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: LucideIcons.smartphone,
                        color: AppColors.blue,
                        title: 'Phone calendar',
                        subtitle: status,
                        trailing: AppSwitch(
                          value: connected,
                          onChanged: (value) => unawaited(_togglePhoneCalendar(value)),
                        ),
                        onTap: () => unawaited(_togglePhoneCalendar(!connected)),
                      ),
                    ],
                  ),
                  if (denied) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      color: AppColors.pink,
                      shadow: false,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              'Calendar access is off, so SuperCalendar cannot read events from this phone. Local events still work.',
                            ),
                            style: AppText.s(11, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          StudioButton(
                            label: 'Open Android settings',
                            soft: true,
                            onTap: () => unawaited(_openAndroidSettings()),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (connected) ...[
                    const SizedBox(height: 18),
                    Text(
                      tr('SHOW THESE CALENDARS'),
                      style: AppText.label(),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingCalendars)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_calendars.isEmpty)
                      Text(
                        tr('No calendars found on this phone'),
                        style: AppText.s(12, color: AppColors.muted),
                      )
                    else
                      SettingsGroup(
                        children: [
                          for (final calendar in _calendars)
                            SettingsRow(
                              icon: LucideIcons.circle,
                              color: calendar.color != null
                                  ? Color(calendar.color!)
                                  : AppColors.primary,
                              title: calendar.name,
                              subtitle: calendar.account.isEmpty
                                  ? null
                                  : calendar.account,
                              trailing: AppSwitch(
                                value: isDeviceCalendarVisible(
                                  settings,
                                  calendar.id,
                                ),
                                onChanged: (v) =>
                                    _setCalendarVisible(calendar, v),
                              ),
                              onTap: () => _setCalendarVisible(
                                calendar,
                                !isDeviceCalendarVisible(settings, calendar.id),
                              ),
                            ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 16),
                  SettingsGroup(
                    children: [
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
                        icon: LucideIcons.calendarRange,
                        color: AppColors.yellow,
                        title: 'Week starts on',
                        value: settings.weekStart == WeekStartSetting.sunday
                            ? 'Sunday'
                            : 'Monday',
                        onTap: () async {
                          final picked = await pickOption(
                            context,
                            title: 'Week starts on',
                            options: const ['Monday', 'Sunday'],
                            current: settings.weekStart == WeekStartSetting.sunday
                                ? 'Sunday'
                                : 'Monday',
                          );
                          if (picked == null) return;
                          app.setWeekStart(
                            picked == 'Sunday'
                                ? WeekStartSetting.sunday
                                : WeekStartSetting.monday,
                          );
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
                    tr(
                      'Why the permission? With calendar access SuperCalendar can '
                      'show the events already on this phone next to yours. They are '
                      'read-only and are not copied or uploaded. Without it, the app '
                      'works the same with the events you create here.',
                    ),
                    style: AppText.s(10, color: AppColors.muted, height: 1.45),
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
