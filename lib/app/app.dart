import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_detail_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/screens/home_screen.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/settings_screen.dart';
import 'package:flutter_application/features/todo/presentation/screens/task_detail_screen.dart';
import 'package:flutter_application/features/todo/presentation/screens/todo_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/vip_screen.dart';

class SuperCalendarApp extends StatefulWidget {
  const SuperCalendarApp({super.key, required this.state});

  /// Already-loaded application state.
  final AppState state;

  @override
  State<SuperCalendarApp> createState() => _SuperCalendarAppState();
}

class _SuperCalendarAppState extends State<SuperCalendarApp>
    with WidgetsBindingObserver {
  AppState get _app => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _app.themeRevision.addListener(_onThemeChanged);
    unawaited(_initNotifications());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _app.themeRevision.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _initNotifications() async {
    await _app.notifications.init(
      onOpen: _openTarget,
      onDataChanged: () => unawaited(_app.reloadFromDisk()),
    );
    final launch = await _app.notifications.launchTarget();
    if (launch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openTarget(launch));
    }
  }

  /// Opens the screen a tapped notification points at.
  void _openTarget(NotificationTarget target) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    Widget? page;
    switch (target.type) {
      case NotificationTarget.event:
        final event = _app.events.byId(target.id);
        if (event != null) page = EventDetailScreen(event: event);
      case NotificationTarget.task:
        final task = _app.tasks.byId(target.id);
        if (task != null) page = TaskDetailScreen(task: task);
      case NotificationTarget.lockScreen:
        // The lock screen notification opens the next event of the day, or
        // the lock screen layout when nothing is left on the schedule.
        final next = _app.events
            .on(_app.today)
            .where((e) => e.endTime.isAfter(_app.now))
            .firstOrNull;
        page = next == null
            ? const LockScreen()
            : EventDetailScreen(event: next);
    }
    if (page == null) return;
    final destination = page;
    navigator.push(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // A notification action may have changed data while we were away.
    unawaited(_app.reloadFromDisk());
    unawaited(_app.refreshSystemCalendar());
    unawaited(_app.syncNotifications());
  }

  void _onThemeChanged() {
    if (!mounted) return;
    // Colors are read from AppTheme rather than through an InheritedWidget,
    // so every element (const ones included) has to be asked to rebuild.
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    setState(() {});
    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _app,
      child: MaterialApp(
        title: 'SuperCalendar',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        theme: buildAppTheme(),
        home: const AppShell(),
      ),
    );
  }
}

/// Hosts the five tabs and the bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _roots = <Widget>[
    HomeScreen(),
    CalendarScreen(),
    TodoScreen(),
    VipScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final dark = AppTheme.palette.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = tabNavigatorKeys[app.tab].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else if (app.tab != AppTab.home) {
          app.setTab(AppTab.home);
        } else {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.surface,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
        child: Scaffold(
          body: IndexedStack(
            index: app.tab,
            children: [
              for (var i = 0; i < _roots.length; i++)
                Navigator(
                  key: tabNavigatorKeys[i],
                  onGenerateRoute: (_) =>
                      MaterialPageRoute<void>(builder: (_) => _roots[i]),
                ),
            ],
          ),
          bottomNavigationBar: _BottomNavigation(
            index: app.tab,
            onTap: (i) => goToTab(context, i),
          ),
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (LucideIcons.house, 'Home'),
    (LucideIcons.calendarDays, 'Calendar'),
    (LucideIcons.circleCheckBig, 'To-do'),
    (LucideIcons.gem, 'VIP'),
    (LucideIcons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          height: 28,
                          decoration: BoxDecoration(
                            color: i == index
                                ? AppColors.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _items[i].$1,
                            size: 17,
                            color: i == index
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].$2,
                          style: AppText.s(
                            10,
                            color: i == index
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
