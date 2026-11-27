import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/app/theme/app_theme.dart';
import 'package:flutter_application/core/data/sqlite_document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/auto_wallpaper_service.dart';
import 'package:flutter_application/core/services/background_photo.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/core/services/wallpaper_export.dart';
import 'package:flutter_application/core/widgets/wallpaper_scene.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';

/// Builds an isolated render tree. It never opens an Activity or changes the
/// foreground app's widget tree. The same clean scene is used by the editor.
Future<Uint8List> renderDailyWallpaper(
  AppState app,
  ScreenLayout layout,
  WallpaperDimensions dimensions,
) async {
  final size = Size(330, dimensions.canvasHeight(330));
  final boundary = RenderRepaintBoundary();
  final pipeline = PipelineOwner();
  final view = RenderView(
    view: ui.PlatformDispatcher.instance.views.first,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      physicalConstraints: BoxConstraints.tight(size),
      devicePixelRatio: 1,
    ),
    child: boundary,
  );
  pipeline.rootNode = view;
  view.prepareInitialFrame();
  final owner = BuildOwner(focusManager: FocusManager());
  final tree = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Localizations(
          locale: const Locale('en'),
          delegates: const [
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          child: AppScope(
            state: app,
            child: Theme(
              data: buildAppTheme(),
              child: Material(
                type: MaterialType.transparency,
                child: WallpaperScene(layout: layout, dimensions: dimensions),
              ),
            ),
          ),
        ),
      ),
    ),
  ).attachToRenderTree(owner);
  void frame() {
    owner.buildScope(tree);
    owner.finalizeTree();
    pipeline.flushLayout();
    pipeline.flushCompositingBits();
    pipeline.flushPaint();
  }

  try {
    frame();
    Object? imageError;
    final photo = layout.backgroundPath;
    final ImageProvider? provider = photo != null
        ? backgroundPhotoProvider(photo)
        : layout.wallpaper == Wallpaper.softMorning
        ? const AssetImage(Wallpaper.softMorningAsset)
        : null;
    if (provider != null) {
      await precacheImage(provider, tree, onError: (e, _) => imageError = e);
      if (imageError != null)
        throw StateError('Wallpaper photo could not be loaded');
    }
    frame();
    return await dimensions.capture(boundary);
  } finally {
    RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
        .attachToRenderTree(owner, tree);
    owner.buildScope(tree);
    owner.finalizeTree();
    pipeline.rootNode = null;
    view.dispose();
    pipeline.dispose();
    owner.focusManager.dispose();
  }
}

/// Native JobScheduler starts a short-lived engine at this entry point.
/// No Firebase, notification permission prompt or interactive route is used.
Future<void> runDailyWallpaperWorker() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('supercalendar/daily_wallpaper_worker');
  AppState? app;
  SqliteDocumentStore? store;
  try {
    final data = await channel.invokeMapMethod<String, dynamic>(
      'configuration',
    );
    if (data == null) throw StateError('Daily wallpaper is disabled');
    store = await SqliteDocumentStore.open();
    final renderedAt = DateTime.parse(data['renderDay'] as String);
    app = AppState(store: store, clock: () => renderedAt);
    await app.load(seedDemoData: false);
    if (app.settings.useSystemCalendar) {
      final calendar = AndroidSystemCalendarService();
      if (await calendar.hasPermission()) {
        app.events.setSystemEvents(
          await calendar.events(
            app.today.subtract(const Duration(days: 7)),
            app.today.add(const Duration(days: 14)),
          ),
        );
      }
    }
    final layout = ScreenLayout.fromJson(
      (jsonDecode(data['layout'] as String) as Map).cast<String, dynamic>(),
    );
    final revision = AutoWallpaperService.contentRevision(app);
    final png = await renderDailyWallpaper(
      app,
      layout,
      WallpaperDimensions(
        Size(
          (data['width'] as num).toDouble(),
          (data['height'] as num).toDouble(),
        ),
      ),
    );
    await app.flush();
    app.dispose();
    app = null;
    await channel.invokeMethod<void>('complete', {
      'bytes': png,
      'generation': data['generation'],
      'renderedDay': renderedAt.toIso8601String().substring(0, 10),
      'contentRevision': revision,
    });
  } catch (error, stack) {
    debugPrint('Daily wallpaper render failed: $error\n$stack');
    await channel.invokeMethod<void>('failed');
  } finally {
    if (app != null) {
      await app.flush();
      app.dispose();
    }
    // sqflite may share its process-wide connection with the UI; do not close it here.
  }
}
