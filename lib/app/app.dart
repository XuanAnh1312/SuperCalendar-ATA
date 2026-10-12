import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/screens/home_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/settings_screen.dart';
import 'package:flutter_application/features/todo/presentation/screens/todo_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_studio_screen.dart';
import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme.dart';

class SuperCalendarApp extends StatefulWidget {
  const SuperCalendarApp({super.key});

  @override
  State<SuperCalendarApp> createState() => _SuperCalendarAppState();
}

class _SuperCalendarAppState extends State<SuperCalendarApp> {
  final _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'SuperCalendar',
        debugShowCheckedModeBanner: false,
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
    TemplateStudioScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
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
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
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
      decoration: const BoxDecoration(
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
