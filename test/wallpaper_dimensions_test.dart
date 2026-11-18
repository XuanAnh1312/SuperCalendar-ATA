import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/wallpaper_export.dart';
import 'package:flutter_application/core/services/wallpaper_service.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/edit_screen.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';

void main() {
  for (final pixels in const [Size(1536, 2048), Size(2048, 1536)]) {
    testWidgets(
      'editor keeps its grid inside a ${pixels.width} x ${pixels.height} wallpaper',
      (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = pixels;
        tester.view.display.size = pixels;
        addTearDown(tester.view.reset);
        addTearDown(tester.view.display.resetSize);
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
        final canvas = tester.getRect(find.byType(LayoutBackground));
        final grid = tester.getRect(find.byType(WidgetGrid));
        expect(grid.left, greaterThanOrEqualTo(canvas.left - 0.01));
        expect(grid.right, lessThanOrEqualTo(canvas.right + 0.01));
        expect(grid.top, greaterThanOrEqualTo(canvas.top));
        expect(grid.bottom, lessThanOrEqualTo(canvas.bottom + 0.01));
        expect(
          canvas.width / canvas.height,
          closeTo(pixels.width / pixels.height, 0.001),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final pixels in const [
    Size(1080, 1920),
    Size(1080, 2400),
    Size(1440, 3200),
    Size(1536, 2048),
    Size(2048, 1536),
    Size(1081, 2401),
  ]) {
    testWidgets(
      'PNG matches ${pixels.width} x ${pixels.height} without losing edges',
      (tester) async {
        final dimensions = WallpaperDimensions(pixels);
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: OverflowBox(
                  maxWidth: 330,
                  maxHeight: 1200,
                  child: SizedBox(
                    width: 330,
                    height: dimensions.canvasHeight(330),
                    child: RepaintBoundary(
                      key: key,
                      child: const Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(color: Colors.white),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 12,
                            child: ColoredBox(color: Color(0xFFFF0000)),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 12,
                            child: ColoredBox(color: Color(0xFF0000FF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(() async {
          final bytes = await dimensions.capture(
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary,
          );
          final codec = await ui.instantiateImageCodec(bytes);
          final image = (await codec.getNextFrame()).image;
          expect(image.width, pixels.width.toInt());
          expect(image.height, pixels.height.toInt());
          final rgba = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final middle = image.width ~/ 2;
          expect(
            rgba.getUint8(middle * 4),
            255,
          ); // Red top edge remains visible.
          expect(
            rgba.getUint8(((image.height - 1) * image.width + middle) * 4 + 2),
            255,
          );
          image.dispose();
          codec.dispose();
        });
      },
    );
  }

  testWidgets('editor exports the full display in a smaller app window', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.display.size = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    addTearDown(tester.view.display.resetSize);
    final app = AppState(store: MemoryDocumentStore());
    await app.load();
    final previous = WallpaperService.instance;
    final fake = FakeWallpaperService();
    WallpaperService.instance = fake;
    addTearDown(() {
      WallpaperService.instance = previous;
      app.dispose();
    });
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: const MaterialApp(home: EditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Wallpaper'));
    await tester.runAsync(() async {
      for (var i = 0; i < 80 && fake.images.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
    });
    expect(fake.calls, [true]);
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(fake.images.single);
      final image = (await codec.getNextFrame()).image;
      expect(
        Size(image.width.toDouble(), image.height.toDouble()),
        const Size(1080, 2400),
      );
      image.dispose();
      codec.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
