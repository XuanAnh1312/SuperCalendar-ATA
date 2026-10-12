import 'package:flutter/material.dart';
import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/features/calendar/presentation/screens/habits_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/note/presentation/screens/quick_note_notification_screen.dart';
import 'package:flutter_application/features/todo/presentation/screens/task_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the app on a 390x844 phone, the frame size used in the design.
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SuperCalendarApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home dashboard renders and bottom navigation switches tabs', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Good morning, Mia'), findsOneWidget);
    expect(find.text('October snapshot'), findsOneWidget);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('October 5–11'), findsOneWidget);
    expect(find.text('Week 41 · 7 events'), findsOneWidget);

    await tester.tap(find.text('To-do').last);
    await tester.pumpAndSettle();
    expect(find.text('TO-DO LIST'), findsOneWidget);

    await tester.tap(find.text('VIP'));
    await tester.pumpAndSettle();
    expect(find.text('Template Studio'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Mia Chen · VIP'), findsOneWidget);
  });

  testWidgets('adding and completing a task updates the remaining count', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('To-do').last);
    await tester.pumpAndSettle();
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
  });

  testWidgets('secondary screens open from the dashboard and settings', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Edit Your Screen'));
    await tester.pumpAndSettle();
    expect(find.byType(EditScreen), findsOneWidget);
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Habits "Edit" is the second Edit action on the dashboard.
    await tester.tap(find.text('Edit').at(1));
    await tester.pumpAndSettle();
    expect(find.byType(HabitsScreen), findsOneWidget);
    await tester.tap(find.text('Read 20 minutes'));
    await tester.pumpAndSettle();
    expect(find.text('Skip occurrence'), findsOneWidget);
    await tester.tap(find.text('Skip occurrence'));
    await tester.pumpAndSettle();
    expect(find.text('Skipped today'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mobile Screen'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
    await tester.tap(find.text('Tap to type'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickNoteNotificationScreen), findsOneWidget);
    await tester.tap(find.text('Open app'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('event form and task details open and save', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('New event'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Design review'), findsOneWidget);

    await tester.tap(find.text('To-do').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsOneWidget);
    expect(find.text('Subtasks · 1/3'), findsOneWidget);
    await tester.tap(find.text('Attach project timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Subtasks · 2/3'), findsOneWidget);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsNothing);
  });
}
