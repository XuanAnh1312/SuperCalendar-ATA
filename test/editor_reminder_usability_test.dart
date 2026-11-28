import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';
import 'package:flutter_application/features/lock_screen/presentation/widgets/lock_widgets.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/core/services/reminder_plan.dart';
import 'package:flutter_application/core/services/notification_payload.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';

void main() {
  final now = DateTime(2026, 11, 21, 8);
  CalendarEvent event() => CalendarEvent(
    id: 'multi',
    title: 'Meeting',
    startTime: DateTime(2026, 11, 21, 10),
    endTime: DateTime(2026, 11, 21, 11),
    reminderOffsets: [60, 30, 30],
  );
  List<ReminderPlanEntry> plan(
    CalendarEvent e, {
    DateTime? at,
    bool enabled = true,
  }) => buildReminderPlan(
    tasks: [],
    events: [e],
    habits: [],
    now: at ?? now,
    context: ReminderContext(
      settings: AppSettings(notificationsEnabled: enabled),
    ),
  );
  test('multiple leads persist, deduplicate, and produce distinct alarm identities', () {
    final e = CalendarEvent.fromJson(event().toJson());
    final entries = plan(e);
    expect(entries.map((e) => e.at), [
      DateTime(2026, 11, 21, 9),
      DateTime(2026, 11, 21, 9, 30),
    ]);
    expect(entries.map((e) => e.target.reminderLead), [60, 30]);
    expect(
      NotificationTarget.decode(entries.first.target.encode())!.reminderLead,
      60,
    );
  });
  test('past lead is not replayed, explicit empty list disables reminders', () {
    expect(plan(event(), at: DateTime(2026, 11, 21, 9, 15)).length, 1);
    expect(plan(event()..reminderOffsets = []), isEmpty);
    expect(plan(event(), enabled: false), isEmpty);
  });
  test('legacy single lead stays compatible and removed lead invalidates active alarm', () {
    final e = event()
      ..reminderOffsets = null
      ..reminderMinutes = 30;
    expect(plan(e).single.at, DateTime(2026, 11, 21, 9, 30));
    final old = plan(event()).first.target;
    expect(
      reminderTargetIsValid(
        old,
        tasks: [],
        events: [e],
        habits: [],
        now: now,
        context: ReminderContext(),
      ),
      false,
    );
  });
  testWidgets('Home cards follow content height with a 12px gap', (
    tester,
  ) async {
    final store = MemoryDocumentStore();
    await store.put(
      Collections.settings,
      AppSettings.id,
      AppSettings(seeded: true, onboarded: true).toJson(),
    );
    final app = AppState(store: store);
    await app.load();
    app.tasks.add('First task', dueDate: app.today);
    addTearDown(app.dispose);
    final layout = app.layouts.home.copy();
    for (final item in layout.items) {
      item.visible = false;
    }
    layout.item(WidgetType.todo)
      ..visible = true
      ..x = 0
      ..y = 0
      ..w = 12
      ..h = 5;
    layout.item(WidgetType.quickNote)
      ..visible = true
      ..x = 0
      ..y = 10
      ..w = 12
      ..h = 4;
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HomeWidgetGrid(layout: layout)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final todo = tester.getRect(find.byType(TodoWidget));
    final note = tester.getRect(find.byType(QuickNoteWidget));
    expect(note.top - todo.bottom, closeTo(12, 0.01));
    app.tasks.add('Another task', dueDate: app.today);
    await tester.pumpAndSettle();
    final grown = tester.getRect(find.byType(TodoWidget));
    final moved = tester.getRect(find.byType(QuickNoteWidget));
    expect(grown.height, greaterThan(todo.height));
    expect(moved.top - grown.bottom, closeTo(12, 0.01));
    expect(tester.takeException(), isNull);
  });
  testWidgets('AC-39: Quick Note card keeps the newest appended line visible', (
    tester,
  ) async {
    final app = AppState(store: MemoryDocumentStore());
    await app.load();
    addTearDown(app.dispose);
    app.notes.setQuick(
      'First line that is long enough to wrap across the small card\n'
      'Second earlier line\nNewest line from notification',
    );
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 172, child: QuickNoteWidget())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Newest line from notification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('two fingers resize a canvas widget and Undo restores it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 3300);
    tester.view.devicePixelRatio = 3;
    tester.view.display.size = const Size(1170, 3300);
    addTearDown(() {
      tester.view.reset();
      tester.view.display.resetSize();
    });
    final app = AppState(store: MemoryDocumentStore());
    await app.load();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: const MaterialApp(home: EditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    ScreenLayout layout() =>
        tester.widget<WidgetGrid>(find.byType(WidgetGrid)).layout;
    final original = layout().item(WidgetType.weather).toJson();
    final card = find
        .ancestor(
          of: find.text('Mostly sunny'),
          matching: find.byKey(const ValueKey('canvas_${WidgetType.weather}')),
        )
        .first;
    final center = tester.getCenter(card);
    final first = await tester.startGesture(
      center - const Offset(35, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(35, 0),
      pointer: 2,
    );
    await tester.pump();
    await first.moveTo(center - const Offset(20, 0));
    await second.moveTo(center + const Offset(20, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(10, 0));
    await second.moveTo(center + const Offset(10, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(layout().item(WidgetType.weather).w, lessThan(original['w'] as int));
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(layout().item(WidgetType.weather).toJson(), original);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'FR-04: a dragged widget follows the finger and snaps on release',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 3300);
      tester.view.devicePixelRatio = 3;
      tester.view.display.size = const Size(1170, 3300);
      addTearDown(() {
        tester.view.reset();
        tester.view.display.resetSize();
      });
      final app = AppState(store: MemoryDocumentStore());
      await app.load();
      addTearDown(app.dispose);
      final lock = app.layouts.lock.copy();
      for (final item in lock.items) {
        item.visible = false;
      }
      lock.item(WidgetType.weather)
        ..visible = true
        ..x = 0
        ..y = 0;
      app.layouts.save(lock);
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: const MaterialApp(home: EditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      ScreenLayout layout() =>
          tester.widget<WidgetGrid>(find.byType(WidgetGrid)).layout;
      final card = find.byKey(ValueKey('canvas_${WidgetType.weather}'));
      final gesture = await tester.startGesture(tester.getCenter(card));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
      }
      // Nothing is written while the finger is down; the overlay shows it.
      expect(layout().item(WidgetType.weather).x, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(layout().item(WidgetType.weather).x, greaterThan(0));
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(layout().item(WidgetType.weather).x, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('FR-04: scrolling the editor page ends the selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.display.size = const Size(1170, 2532);
    addTearDown(() {
      tester.view.reset();
      tester.view.display.resetSize();
    });
    final app = AppState(store: MemoryDocumentStore());
    await app.load();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: const MaterialApp(home: EditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final handles = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_ResizeHandle',
    );
    await tester.tap(find.byKey(ValueKey('canvas_${WidgetType.weather}')));
    await tester.pumpAndSettle();
    expect(handles, findsNWidgets(4));
    // Drag the page by its left margin, outside the phone preview.
    await tester.dragFrom(const Offset(4, 600), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(handles, findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final height in [106.0, 140.0, 200.0, 320.0]) {
    testWidgets('FR-19: Schedule cards fill a 294 x $height cell, no gap', (
      tester,
    ) async {
      final app = AppState(store: MemoryDocumentStore());
      await app.load();
      addTearDown(app.dispose);
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: widgetCell(
                  WidgetType.schedule,
                  lock: true,
                  size: Size(294, height),
                  scale: 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cell = tester.getRect(find.byType(LockScheduleCard));
      final cards = find.descendant(
        of: find.byType(LockScheduleCard),
        matching: find.byType(AppCard),
      );
      expect(tester.getRect(cards.first).top, closeTo(cell.top, 0.5));
      expect(tester.getRect(cards.last).bottom, closeTo(cell.bottom, 0.5));
      expect(tester.takeException(), isNull);
    });
  }
  for (final height in [140.0, 320.0]) {
    testWidgets(
      'Schedule keeps both cards at full width in a 294 x $height cell',
      (tester) async {
        final app = AppState(store: MemoryDocumentStore());
        await app.load();
        addTearDown(app.dispose);
        await tester.pumpWidget(
          AppScope(
            state: app,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: widgetCell(
                    WidgetType.schedule,
                    lock: true,
                    size: Size(294, height),
                    scale: 1,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final cards = find.descendant(
          of: find.byType(LockScheduleCard),
          matching: find.byType(AppCard),
        );
        expect(cards, findsNWidgets(2));
        for (final card in cards.evaluate()) {
          expect(
            (card.renderObject as RenderBox).size.width,
            closeTo(294, 0.01),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
