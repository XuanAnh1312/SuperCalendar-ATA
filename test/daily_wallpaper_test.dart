import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/auto_wallpaper_service.dart';
import 'package:flutter_application/core/services/daily_wallpaper_renderer.dart';
import 'package:flutter_application/core/services/wallpaper_export.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  bool asked = false, enabled = false;
  setUp(() {
    calls.clear();
    asked = false;
    enabled = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AutoWallpaperService.channel, (call) async {
          calls.add(call);
          if (call.method == 'status')
            return {'enabled': enabled, 'asked': asked, 'hasDesign': true};
          if (call.method == 'setEnabled') {
            asked = true;
            enabled = (call.arguments as Map)['enabled'] == true;
          }
          return null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AutoWallpaperService.channel, null);
  });
  testWidgets(
    'Later records refusal and does not ask again on next wallpaper',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const Scaffold();
            },
          ),
        ),
      );
      final layout = ScreenLayout(id: ScreenLayout.lock, items: []);
      final first = offerDailyWallpaper(
        context,
        layout: layout,
        dimensions: WallpaperDimensions(const Size(1080, 2400)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Automatically update your lock screen?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      await first;
      expect(enabled, false);
      expect(asked, true);
      await offerDailyWallpaper(
        context,
        layout: layout,
        dimensions: WallpaperDimensions(const Size(1080, 2400)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(calls.where((c) => c.method == 'setEnabled').length, 1);
    },
  );
  testWidgets('only explicit acceptance enables background updates', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold();
          },
        ),
      ),
    );
    final pending = offerDailyWallpaper(
      context,
      layout: ScreenLayout(id: ScreenLayout.lock, items: []),
      dimensions: WallpaperDimensions(const Size(1080, 2400)),
    );
    await tester.pumpAndSettle();
    expect(enabled, false);
    await tester.tap(find.text('Enable auto-update'));
    await tester.pumpAndSettle();
    await pending;
    expect(enabled, true);
    await AutoWallpaperService.setEnabled(false);
    expect(enabled, false);
  });
  testWidgets('Home wallpaper never asks for lock screen auto-update', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold();
          },
        ),
      ),
    );
    await offerDailyWallpaper(
      context,
      layout: ScreenLayout(id: ScreenLayout.home, items: []),
      dimensions: WallpaperDimensions(const Size(1080, 2400)),
    );
    expect(calls, isEmpty);
  });

  testWidgets(
    'saved tasks and Quick Note request a same-day wallpaper refresh',
    (tester) async {
      final store = MemoryDocumentStore();
      final app = AppState(
        store: store,
        clock: () => DateTime(2026, 11, 21, 10),
      );
      await app.load(seedDemoData: false);
      addTearDown(app.dispose);
      await tester.pumpWidget(SuperCalendarApp(state: app));
      await tester.pump();
      calls.clear();

      app.notes.add(title: 'Private draft', content: 'Regular note');
      await tester.pump(const Duration(seconds: 1));
      expect(calls, isEmpty);

      final task = app.quickAddTask('Pick up the package')!;
      expect(calls, isEmpty);
      await tester.pump(const Duration(seconds: 1));

      expect((await store.readAll(Collections.tasks)).single, task.toJson());
      expect(calls.map((call) => call.method), ['catchUp']);
      expect(calls.single.arguments, {
        'contentRevision': AutoWallpaperService.contentRevision(app),
      });
      calls.clear();

      app.notes.setQuick('Bring the receipt');
      await tester.pump(const Duration(seconds: 1));
      expect(
        (await store.readAll(Collections.notes)).last['content'],
        'Bring the receipt',
      );
      expect(calls.map((call) => call.method), ['catchUp']);
      expect(calls.single.arguments, {
        'contentRevision': AutoWallpaperService.contentRevision(app),
      });
    },
  );

  testWidgets(
    'headless renderer uses the same saved design with new-day data',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final store = MemoryDocumentStore();
      await store.put(
        Collections.settings,
        AppSettings.id,
        AppSettings(seeded: true, onboarded: true).toJson(),
      );
      var day = DateTime(2026, 11, 21, 23, 59);
      final app = AppState(store: store, clock: () => day);
      await app.load();
      addTearDown(app.dispose);
      app.events.add(
        CalendarEvent(
          id: 'today',
          title: 'Meeting today',
          startTime: DateTime(2026, 11, 21, 10),
          endTime: DateTime(2026, 11, 21, 11),
        ),
      );
      app.events.add(
        CalendarEvent(
          id: 'tomorrow',
          title: 'Different tomorrow',
          startTime: DateTime(2026, 11, 22, 15),
          endTime: DateTime(2026, 11, 22, 16),
        ),
      );
      final layout = app.layouts.lock.copy()
        ..wallpaper = Wallpaper.theme
        ..backgroundPath = null;
      final dimensions = WallpaperDimensions(const Size(540, 1200));
      final first = await tester.runAsync(
        () => renderDailyWallpaper(app, layout, dimensions),
      );
      day = DateTime(2026, 11, 22, 0, 1);
      final second = await tester.runAsync(
        () => renderDailyWallpaper(app, layout, dimensions),
      );
      expect(first, isNotNull);
      expect(second, isNot(orderedEquals(first!)));
      final codec = await tester.runAsync(
        () => ui.instantiateImageCodec(second!),
      );
      final frame = await tester.runAsync(() => codec!.getNextFrame());
      expect(frame!.image.width, 540);
      expect(frame.image.height, 1200);
      frame.image.dispose();
      codec!.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
