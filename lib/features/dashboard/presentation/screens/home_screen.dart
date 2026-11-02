import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/presentation/screens/habits_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/note/presentation/screens/note_list_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/core/utils/strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openEditor(BuildContext context) =>
      pushInTab(context, const EditScreen());

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final layout = app.layouts.home;
    return Scaffold(
      body: LayoutBackground(
        layout: layout,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 12),
                child: PageHeader(
                  title: 'SuperCalendar',
                  subtitle: longDate(app.today),
                  trailing: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openEditor(context),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        LucideIcons.slidersHorizontal,
                        size: 19,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tr(_greeting(app.now))}, ${app.user.firstName}',
                      style: AppText.s(18, weight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SoftPill(
                    label: 'Edit Your Screen',
                    icon: LucideIcons.pencil,
                    onTap: () => _openEditor(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              HomeWidgetGrid(
                layout: layout,
                actions: HomeWidgetActions(
                  onEditTodo: () => goToTab(context, AppTab.todo),
                  onEditHabits: () =>
                      openInTab(context, AppTab.calendar, const HabitsScreen()),
                  onOpenWeek: () {
                    app
                      ..selectDay(app.today)
                      ..setWeekView(true);
                    goToTab(context, AppTab.calendar);
                  },
                  onEditNote: () => pushInTab(context, const NoteListScreen()),
                  onSaveSnapshot: () =>
                      showAppSnack(context, 'Snapshot saved to Photos'),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      tr(app.isVip
                          ? 'VIP · free-form layouts unlocked'
                          : '3 free layouts · More templates with VIP'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.s(10, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedActionButton(
                icon: LucideIcons.plus,
                label: 'CREATE MORE',
                onTap: () => _openEditor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
