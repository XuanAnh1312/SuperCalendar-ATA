import 'dart:ui' as ui;

import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/device_frame_service.dart';
import 'package:flutter_application/core/services/wallpaper_export.dart';
import 'package:flutter_application/core/services/wallpaper_service.dart';
import 'package:flutter_application/core/widgets/device_preview_frame.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pixels = Size(1080, 2400);

  Future<DeviceFrameService> device(
    TargetPlatform platform,
    String model, {
    String manufacturer = '',
  }) async {
    final service = DeviceFrameService(
      detector: () async => DeviceFrameIdentity(
        platform: platform,
        model: model,
        manufacturer: manufacturer,
      ),
    );
    await service.initialize();
    return service;
  }

  test(
    'exact iPhone models select notch or Dynamic Island catalog art',
    () async {
      final notch = await device(TargetPlatform.iOS, 'iPhone13,2');
      final island = await device(TargetPlatform.iOS, 'iPhone16,2');
      expect(notch.frameFor(pixels), same(Devices.ios.iPhone12));
      expect(island.frameFor(pixels), same(Devices.ios.iPhone15ProMax));
    },
  );

  test('missing iPhone model uses the matching screen family', () async {
    final iphone14Pro = await device(TargetPlatform.iOS, 'iPhone15,2');
    final iphone16e = await device(TargetPlatform.iOS, 'iPhone17,5');
    expect(iphone14Pro.frameFor(pixels), same(Devices.ios.iPhone15Pro));
    expect(iphone16e.frameFor(pixels), same(Devices.ios.iPhone13));
  });

  test('Android matches exact models before same-series fallback', () async {
    final s20 = await device(
      TargetPlatform.android,
      'SM-G981B',
      manufacturer: 'Samsung',
    );
    final s24 = await device(
      TargetPlatform.android,
      'SM-S928B',
      manufacturer: 'SAMSUNG',
    );
    final pixel = await device(
      TargetPlatform.android,
      'Pixel 9 Pro XL',
      manufacturer: 'Google',
    );
    expect(s20.frameFor(pixels), same(Devices.android.samsungGalaxyS20));
    expect(s24.frameFor(pixels), same(Devices.android.samsungGalaxyS25));
    expect(pixel.frameFor(pixels), same(Devices.android.googlePixel9ProXL));
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test(
      'unknown $platform uses cached generic art with actual display ratio',
      () async {
        final service = await device(
          platform,
          'unknown-phone',
          manufacturer: 'unknown',
        );
        for (final display in [
          pixels,
          const Size(2400, 1080),
          const Size(1536, 2048),
        ]) {
          final info = service.frameFor(display)!;
          expect(info.identifier.platform, platform);
          expect(
            info.screenSize.aspectRatio,
            closeTo(display.aspectRatio, 0.000001),
          );
          expect(service.frameFor(display), same(info));
        }
      },
    );
  }

  test(
    'hardware initialization is shared across repeated and concurrent callers',
    () async {
      var reads = 0;
      final service = DeviceFrameService(
        detector: () async {
          reads++;
          return const DeviceFrameIdentity(
            platform: TargetPlatform.android,
            model: 'Pixel 9',
          );
        },
      );
      await Future.wait([service.initialize(), service.initialize()]);
      await service.initialize();
      service.frameFor(pixels);
      service.frameFor(pixels);
      expect(reads, 1);
    },
  );

  test(
    'missing native device-info plugin is recoverable and not retried',
    () async {
      var reads = 0;
      final service = DeviceFrameService(
        detector: () async {
          reads++;
          throw MissingPluginException('test');
        },
      );
      await service.initialize();
      await service.initialize();
      expect(reads, 1);
      expect(() => service.frameFor(pixels), returnsNormally);
    },
  );

  test(
    'web hides the frame and never invokes the native hardware API',
    () async {
      final service = DeviceFrameService(
        isWeb: true,
        detector: () async => throw StateError('Must not call'),
      );
      await service.initialize();
      expect(service.frameFor(pixels), isNull);
    },
  );

  for (final info in [
    Devices.ios.iPhone12,
    Devices.ios.iPhone15ProMax,
    Devices.android.googlePixel9,
  ]) {
    testWidgets(
      '${info.name}: PNG is byte-identical with and without the frame',
      (tester) async {
        const size = Size(330, 330 * 2400 / 1080);
        final boundaryKey = GlobalKey();
        Widget scene(DeviceInfo? frame) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: DevicePreviewFrame(
                device: frame,
                screenSize: size,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: const Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: Colors.green)),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 20,
                        child: ColoredBox(color: Colors.red),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 20,
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(scene(null));
        final plain = await tester.runAsync(
          () => captureWallpaper(boundaryKey),
        );
        await tester.pumpWidget(scene(info));
        await tester.pumpAndSettle();
        final frame = find.byType(DeviceFrame);
        expect(frame, findsOneWidget);
        expect(
          find.descendant(of: find.byKey(boundaryKey), matching: frame),
          findsNothing,
        );
        final rect = tester.getRect(find.byKey(boundaryKey));
        expect(rect.width / rect.height, closeTo(pixels.aspectRatio, 0.000001));
        final framed = await tester.runAsync(
          () => captureWallpaper(boundaryKey),
        );
        expect(framed, orderedEquals(plain!));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('known frame keeps resize, drag out and Undo hit testing', (
    tester,
  ) async {
    final previous = DeviceFrameService.instance;
    DeviceFrameService.instance = await device(
      TargetPlatform.iOS,
      'iPhone16,2',
    );
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 3300);
    tester.view.display.size = const Size(1170, 3300);
    final app = AppState(store: MemoryDocumentStore());
    await app.load();
    addTearDown(() {
      DeviceFrameService.instance = previous;
      tester.view.reset();
      tester.view.display.resetSize();
      app.dispose();
    });
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: const MaterialApp(home: EditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DeviceFrame), findsOneWidget);
    ScreenLayout layout() =>
        tester.widget<WidgetGrid>(find.byType(WidgetGrid)).layout;
    final original = layout().item(WidgetType.weather).toJson();
    Finder weatherCard() => find
        .ancestor(
          of: find.text('Mostly sunny'),
          matching: find.byType(LongPressDraggable<String>),
        )
        .first;
    await tester.tap(weatherCard());
    await tester.pumpAndSettle();
    final handles = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_ResizeHandle',
    );
    expect(handles, findsNWidgets(4));
    final handleBox = tester.renderObject<RenderBox>(handles.first);
    final resizeStart = handleBox.localToGlobal(const Offset(20, 20));
    expect(
      tester
          .hitTestOnBinding(resizeStart)
          .path
          .any((entry) => entry.target == handleBox),
      isTrue,
    );
    final resizeGesture = await tester.startGesture(resizeStart);
    await tester.pump();
    await resizeGesture.moveBy(const Offset(20, 20));
    await tester.pump();
    await resizeGesture.moveBy(const Offset(15, 15));
    await tester.pump();
    await resizeGesture.up();
    await tester.pumpAndSettle();
    final resized = layout().item(WidgetType.weather);
    expect(
      resized.w < (original['w'] as int) || resized.h < (original['h'] as int),
      isTrue,
      reason: 'before=$original after=${resized.toJson()}',
    );
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(layout().item(WidgetType.weather).toJson(), original);
    final gesture = await tester.startGesture(tester.getCenter(weatherCard()));
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveTo(const Offset(4, 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Mostly sunny'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Mostly sunny'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'editor export keeps actual display pixels with a same-series frame',
    (tester) async {
      final previous = DeviceFrameService.instance;
      final previousWallpaper = WallpaperService.instance;
      DeviceFrameService.instance = await device(
        TargetPlatform.android,
        'SM-S928B',
        manufacturer: 'Samsung',
      );
      final wallpaper = FakeWallpaperService();
      WallpaperService.instance = wallpaper;
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1080, 1500);
      tester.view.display.size = pixels;
      final app = AppState(store: MemoryDocumentStore());
      await app.load();
      addTearDown(() {
        DeviceFrameService.instance = previous;
        WallpaperService.instance = previousWallpaper;
        tester.view.reset();
        tester.view.display.resetSize();
        app.dispose();
      });
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: const MaterialApp(home: EditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DeviceFrame), findsOneWidget);
      final canvas = tester.getRect(find.byType(LayoutBackground));
      expect(
        canvas.width / canvas.height,
        closeTo(pixels.aspectRatio, 0.000001),
      );
      await tester.tap(find.text('Set Wallpaper'));
      await tester.runAsync(() async {
        for (var i = 0; i < 80 && wallpaper.images.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          await tester.pump();
        }
      });
      expect(wallpaper.calls, [true]);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(wallpaper.images.single);
        final image = (await codec.getNextFrame()).image;
        expect(Size(image.width.toDouble(), image.height.toDouble()), pixels);
        image.dispose();
        codec.dispose();
      });
      expect(tester.takeException(), isNull);
    },
  );
}

Future<List<int>> captureWallpaper(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  return WallpaperDimensions(const Size(1080, 2400)).capture(boundary);
}
