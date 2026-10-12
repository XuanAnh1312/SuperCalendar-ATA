import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/calendar/presentation/screens/habits_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openEditor(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const EditScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
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
                  child: const SizedBox(
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
                    'Good morning, ${app.userName}',
                    style: AppText.s(18, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _openEditor(context),
                  child: Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.pencil,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Edit Your Screen',
                          style: AppText.s(10, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            HomeWidgetGrid(
              onEditTodo: () => goToTab(context, AppTab.todo),
              onEditHabits: () =>
                  openInTab(context, AppTab.calendar, const HabitsScreen()),
              onOpenWeek: () {
                app.setWeekView(true);
                goToTab(context, AppTab.calendar);
              },
              onEditNote: () =>
                  pushFullScreen(context, const QuickNoteNotificationScreen()),
              onSaveSnapshot: () =>
                  showAppSnack(context, 'Snapshot saved to your gallery'),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    '3 free layouts · More templates with VIP',
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
    );
  }
}

/// The dashboard widgets in their default arrangement.
class HomeWidgetGrid extends StatelessWidget {
  const HomeWidgetGrid({
    super.key,
    this.onEditTodo,
    this.onEditHabits,
    this.onOpenWeek,
    this.onEditNote,
    this.onSaveSnapshot,
  });

  final VoidCallback? onEditTodo;
  final VoidCallback? onEditHabits;
  final VoidCallback? onOpenWeek;
  final VoidCallback? onEditNote;
  final VoidCallback? onSaveSnapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: TodoWidget(onEdit: onEditTodo)),
            const SizedBox(width: 10),
            Expanded(child: HabitsWidget(onEdit: onEditHabits)),
          ],
        ),
        const SizedBox(height: 12),
        WeekWidget(onOpen: onOpenWeek),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: GoalsWidget()),
            const SizedBox(width: 10),
            Expanded(child: QuickNoteWidget(onEdit: onEditNote)),
          ],
        ),
        const SizedBox(height: 12),
        MonthSnapshotWidget(onSave: onSaveSnapshot),
      ],
    );
  }
}

/// White button with a primary outline (`+ CREATE MORE`, `EDIT`).
class OutlinedActionButton extends StatelessWidget {
  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.background = AppColors.surface,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color background;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(
                    12,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 14), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
