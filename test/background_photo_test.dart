import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/background_photo.dart';
import 'package:flutter_application/core/services/background_photo_web.dart'
    as web;
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/data/layout_repository.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
  );

  test(
    'browser photo keeps bytes rather than a temporary picker URL',
    () async {
      final photo = XFile.fromData(
        png,
        mimeType: 'image/png',
        name: 'photo.png',
      );
      final saved = await web.storeBackgroundPhoto(photo, ScreenLayout.lock);
      expect(saved, startsWith('data:image/png;base64,'));
      expect(Uri.parse(saved).data!.contentAsBytes(), png);
      expect(backgroundPhotoProvider(saved), isA<MemoryImage>());
    },
  );

  testWidgets('saved browser background renders after layout reload', (
    tester,
  ) async {
    final store = MemoryDocumentStore();
    final first = LayoutRepository(store);
    await first.load();
    final photo = XFile.fromData(png, mimeType: 'image/png', name: 'photo.png');
    first.setBackground(
      ScreenLayout.lock,
      await web.storeBackgroundPhoto(photo, ScreenLayout.lock),
    );
    await first.flush();

    final reopened = LayoutRepository(store);
    await reopened.load();
    final restored = reopened.lock.backgroundPath!;
    expect(Uri.parse(restored).data!.contentAsBytes(), png);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenBackground(
            imagePath: restored,
            child: const Text('Calendar'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
    final loadedProvider = tester.widget<Image>(find.byType(Image)).image;
    // Export clears the selected widget and rebuilds the canvas. Keep the
    // loaded photo available rather than starting a fresh image decode.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenBackground(
            imagePath: restored,
            child: const Text('Updated calendar'),
          ),
        ),
      ),
    );
    expect(
      identical(tester.widget<Image>(find.byType(Image)).image, loadedProvider),
      isTrue,
    );
    expect(find.text('Updated calendar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    first.dispose();
    reopened.dispose();
  });
}
