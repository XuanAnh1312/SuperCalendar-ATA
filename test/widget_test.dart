import 'package:flutter/material.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/features/calendar/presentation/screens/event_detail_screen.dart';
import 'package:flutter_application/features/calendar/presentation/screens/habits_screen.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/note_list_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/todo/presentation/screens/task_detail_screen.dart';
import 'package:flutter_application/features/vip/domain/template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'helpers.dart';

void main() {
  tearDown(() => AppTheme.apply(builtInThemes.first));

  testWidgets('home dashboard renders and bottom navigation switches tabs', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Good morning, Mia'), findsOneWidget);
    expect(find.text('October snapshot'), findsOneWidget);

    await openTab(tester, 'Calendar');
    expect(find.text('October 2026'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('October 5–11'), findsOneWidget);
    expect(find.text('Week 41 · 7 events'), findsOneWidget);

    await openTab(tester, 'To-do');
    expect(find.text('TO-DO LIST'), findsOneWidget);

    // A Free user sees the VIP offer, not the Template Studio.
    await openTab(tester, 'VIP');
    expect(find.text('SuperCalendar VIP'), findsOneWidget);
    expect(find.text('Template Studio'), findsNothing);

    await openTab(tester, 'Settings');
    expect(find.text('Mia Chen · Free'), findsOneWidget);
  });

  testWidgets('a task added in the app is still there after a restart', (
    tester,
  ) async {
    final store = MemoryDocumentStore();
    final app = await pumpApp(tester, app: await loadApp(store: store));
    await openTab(tester, 'To-do');
    expect(find.textContaining('5 remaining'), findsOneWidget);
    // Filter pills sit side by side on one row.
    expect(
      tester.getCenter(find.text('All 6')).dy,
      tester.getCenter(find.text('Upcoming')).dy,
    );

    await tester.enterText(find.byType(TextField), 'Water the plants');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Water the plants'), findsOneWidget);
    expect(find.textContaining('6 remaining'), findsOneWidget);
    expect(find.text('All 7'), findsOneWidget);

    await app.flush();
    final reopened = await loadApp(store: store);
    expect(reopened.tasks.items.first.title, 'Water the plants');
  });

  testWidgets('event: create, open details, edit and delete', (tester) async {
    final app = await pumpApp(tester);
    await openTab(tester, 'Calendar');

    // Tapping the selected date again opens the form for that day.
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('New event'), findsOneWidget);

    // An event needs a title.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('New event'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Board game night');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final day = DateTime(2026, 10, 12);
    expect(app.events.on(day).single.title, 'Board game night');

    await tester.tap(find.text('Board game night'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('SuperCalendar'), findsOneWidget, reason: 'source row');

    await tester.tap(find.text('Edit event'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Board games');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(app.events.on(day).single.title, 'Board games');
    expect(find.text('Board games'), findsOneWidget);

    await tester.ensureVisible(find.text('Delete event'));
    await tester.tap(find.text('Delete event'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(app.events.on(day), isEmpty);
    expect(find.byType(EventDetailScreen), findsNothing);
  });

  testWidgets('task details save subtasks and due date changes', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openTab(tester, 'To-do');
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsOneWidget);
    expect(find.text('Today · 4:00 PM'), findsOneWidget);
    expect(find.text('Subtasks · 1/3'), findsOneWidget);

    await tester.tap(find.text('Attach project timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Subtasks · 2/3'), findsOneWidget);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsNothing);
    expect(
      app.tasks.byId('seed_task_0')!.subtasks.where((s) => s.done),
      hasLength(2),
    );
  });

  testWidgets('notes: list, create, edit and delete', (tester) async {
    final app = await pumpApp(tester);
    await tester.tap(find.text('Edit').at(2)); // Quick Note → Notes
    await tester.pumpAndSettle();
    expect(find.byType(NoteListScreen), findsOneWidget);
    expect(find.text('Java notes'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(find.text('New note'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'English notes');
    await tester.enterText(find.byType(TextField).last, 'Unit 4 vocabulary');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(find.text('English notes'), findsOneWidget);
    expect(app.notes.notes, hasLength(3));

    await tester.tap(find.text('Java notes'));
    await tester.pumpAndSettle();
    expect(find.text('Edit note'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Generics and streams');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    final java = app.notes.notes.firstWhere((n) => n.title == 'Java notes');
    expect(java.content, 'Generics and streams');

    await tester.tap(find.text('Flutter notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      app.notes.notes.map((n) => n.title),
      isNot(contains('Flutter notes')),
    );
    expect(app.notes.notes, hasLength(2));
  });

  testWidgets('habits: skipping an occurrence', (tester) async {
    await pumpApp(tester);
    // Habits "Edit" is the second Edit action on the dashboard.
    await tester.tap(find.text('Edit').at(1));
    await tester.pumpAndSettle();
    expect(find.byType(HabitsScreen), findsOneWidget);
    await tester.tap(find.text('Read 20 minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip occurrence'));
    await tester.pumpAndSettle();
    expect(find.text('Skipped today'), findsOneWidget);
  });

  testWidgets('lock screen: complete a task, add a task, open an event', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openTab(tester, 'Settings');
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview lock screen'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Read only'), findsOneWidget);

    await tester.tap(find.text('Add Task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Call the bank');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(app.tasks.items.first.title, 'Call the bank');
    expect(app.tasks.items.first.isDueOn(testToday), isTrue);

    await tester.tap(find.text('Tap to type'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickNoteNotificationScreen), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.power));
    await tester.pumpAndSettle();

    // The schedule is read-only: tapping an event opens it in the app.
    await tester.tap(find.text('Design review'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);
    expect(find.byType(EventDetailScreen), findsOneWidget);
  });

  testWidgets('VIP: subscribe through the test payment unlocks the studio', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openTab(tester, 'VIP');

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate failed payment'));
    await tester.pumpAndSettle();
    expect(app.isVip, isFalse);
    expect(find.text('Last attempt: payment failed'), findsOneWidget);

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate successful payment'));
    await tester.pumpAndSettle();
    expect(app.isVip, isTrue);
    expect(find.text('Template Studio'), findsOneWidget);
  });

  testWidgets('template store: buy, unlock and apply', (tester) async {
    final app = await pumpApp(tester);
    await openTab(tester, 'Settings');
    await tester.ensureVisible(find.text('Template Store'));
    await tester.tap(find.text('Template Store'));
    await tester.pumpAndSettle();
    expect(find.text('Sakura Morning'), findsOneWidget);
    expect(find.text('29,000đ'), findsOneWidget);

    await tester.tap(find.text('Sakura Morning'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Buy · 29,000đ'));
    await tester.tap(find.text('Buy · 29,000đ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate successful payment'));
    await tester.pumpAndSettle();
    expect(find.text('Apply template'), findsOneWidget);

    await tester.tap(find.text('Apply template'));
    await tester.pumpAndSettle();
    final sakura = app.templates.byId('sakura_morning')!;
    expect(app.user.selectedThemeId, sakura.themeData.id);
    expect(AppTheme.current.primary, sakura.themeData.primary);
    expect(find.text('Applied'), findsOneWidget);
  });

  testWidgets('edit your screen: presets for everyone, free-form for VIP', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await tester.tap(find.text('Edit Your Screen'));
    await tester.pumpAndSettle();
    expect(find.byType(EditScreen), findsOneWidget);
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();

    // Free: a ready-made layout can be applied.
    await tester.tap(find.text('EDIT').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    expect(app.layouts.home.preset, ScreenLayout.presetFocus);
    expect(app.layouts.home.shows(WidgetType.habits), isFalse);
    // Let the confirmation snackbar leave before using the next sheet.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Free: free-form arranging is gated behind VIP.
    await tester.tap(find.text('LET MAKE YOURS'));
    await tester.pumpAndSettle();
    expect(find.text('Free-form layout is a VIP feature'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    // VIP: the arrange sheet opens and changes apply to the real dashboard.
    app.completeVipPayment(PaymentResult.success);
    await tester.pumpAndSettle();
    await tester.tap(find.text('LET MAKE YOURS'));
    await tester.pumpAndSettle();
    expect(find.text('Arrange the home screen'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(app.layouts.home.shows(WidgetType.todo), isFalse);
    expect(app.layouts.home.preset, ScreenLayout.presetCustom);

    await tester.tapAt(const Offset(195, 60));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('To-do'), findsOneWidget, reason: 'only the nav label');
  });

  testWidgets('appearance: dark mode and theme switch repaint the app', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openTab(tester, 'Settings');
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(app.settings.darkMode, isTrue);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, isNull);
    expect(
      Theme.of(tester.element(find.text('Appearance'))).scaffoldBackgroundColor,
      AppTheme.palette.background,
    );
    expect(AppTheme.palette.dark, isTrue);

    await tester.tap(find.text('Pastel Blue'));
    await tester.pumpAndSettle();
    expect(app.user.selectedThemeId, 'pastel_blue');
  });
}
