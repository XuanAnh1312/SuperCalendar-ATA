import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/background_photo.dart';
import 'package:flutter_application/core/services/device_frame_service.dart';
import 'package:flutter_application/core/services/wallpaper_service.dart';
import 'package:flutter_application/core/services/wallpaper_export.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/core/widgets/device_preview_frame.dart';
import 'package:flutter_application/core/widgets/wallpaper_scene.dart';
import 'package:flutter_application/core/services/auto_wallpaper_service.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/appearance_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/layout_gallery_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/wallpaper_export_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/wallpaper_gallery_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_store_screen.dart';
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';

/// Design width; canvas height follows the target display's aspect ratio.
const _canvasWidth = 330.0;
const _referenceCanvasHeight = 520.0;

/// Where the widget grid starts on the canvas (below the clock on the lock
/// screen) and how far it is from the sides.
const _gridSide = 18.0;
const _lockGridTop = 242.0;
const _homeGridTop = 18.0;

/// The "Add a widget" library of the design.
const _library = [
  WidgetType.week,
  WidgetType.weather,
  WidgetType.quickNote,
  WidgetType.habits,
];

/// "Edit Your Screen" studio (FR-04, SCR-02, Personalize 23): arranges the
/// widgets of the lock screen and the home dashboard on a grid.
///
/// Edits are made on drafts with undo and saved when the user leaves with
/// the back arrow (AC-08). Arranging is open to every user; photos and fonts
/// are VIP (AC-10, BR-06). Save Image and Set Wallpaper export the wallpaper
/// and widgets only, never the preview overlay.
class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  // 0 = lock screen, 1 = home screen (OI-08).
  int _target = 0;
  // Dock view: 0 = Background, 1 = Layers, 2 = Widgets.
  int _tab = 2;
  bool _overlay = true;
  bool _dirty = false;
  bool _closing = false;
  bool _saving = false;
  final _replacedPhotos = <String>{};
  bool _resizing = false;
  bool _busy = false;
  String? _selected;
  // ---- Live move / resize (FR-04, NFR-03) -----------------------------------
  //
  // While a finger is down the widget follows it pixel by pixel in an overlay;
  // only that overlay rebuilds. The grid cell is applied once, when the finger
  // lifts, as one Undo step.

  /// The widget being moved or resized; null when no gesture is running.
  final _live = ValueNotifier<_LiveEdit?>(null);

  /// Ties the overlay (selection, handles, live card) to a canvas cell. Every
  /// cell keeps its own link so selecting one does not rebuild its gestures.
  final _links = <String, LayerLink>{};
  final _canvasKey = GlobalKey();

  LayoutItem? _gestureItem;
  Offset? _gestureOrigin;
  Offset? _gestureLast;
  Offset? _downPosition;
  int _gesturePointers = 0;
  int _fingersDown = 0;

  /// Grid width over design width, as last given to the canvas cells.
  double _cellScale = 1;

  /// Screen pixels per grid pixel, measured when a finger touches the
  /// canvas; sizes the handles for the real screen (NFR-08).
  double _previewScale = 1;

  /// A finger on a widget or handle stops the page from scrolling at once,
  /// so a vertical drag moves the widget instead of the page.
  void _fingerDown(PointerDownEvent event) {
    _downPosition = event.position;
    final box = _gridBox;
    if (box != null) {
      final scale =
          (box.localToGlobal(const Offset(100, 0)) -
                  box.localToGlobal(Offset.zero))
              .distance /
          100;
      if (scale > 0) _previewScale = scale;
    }
    if (_fingersDown++ == 0) setState(() => _resizing = true);
  }

  void _fingerUp(PointerEvent _) {
    if (_fingersDown == 0) return;
    if (--_fingersDown == 0) setState(() => _resizing = false);
  }

  _Grid _metrics(RenderBox box) => _metricsFor(box.size.width);

  _Grid _metricsFor(double width) {
    return (
      pitch: gridPitch(width),
      row: gridRowPitch(width),
      gap: gridGap(width),
    );
  }

  Rect _cellRect(LayoutItem item, _Grid m) =>
      _cellAt(item.x, item.y, item.w, item.h, m);

  Rect _cellAt(int x, int y, int w, int h, _Grid m) => Rect.fromLTWH(
    x * m.pitch,
    y * m.row,
    w * m.pitch - m.gap,
    h * m.row - m.gap,
  );

  /// The grid cell nearest to [rect] (grid pixels) and whether it is free.
  _LiveEdit _snap(String type, Rect rect, _Grid m) {
    var x = (rect.left / m.pitch).round();
    var y = (rect.top / m.row).round();
    final w = (((rect.right + m.gap) / m.pitch).round() - x).clamp(
      ScreenLayout.minWidth,
      ScreenLayout.columns,
    );
    final h = (((rect.bottom + m.gap) / m.row).round() - y).clamp(
      ScreenLayout.minHeight,
      _draft.rows,
    );
    x = x.clamp(0, ScreenLayout.columns - w);
    y = y.clamp(0, _draft.rows - h);
    return _LiveEdit(
      type,
      rect,
      x,
      y,
      w,
      h,
      fits: _draft.isFree(x, y, w, h, ignore: _draft.item(type)),
    );
  }

  void _beginLive(String type, Offset globalOrigin) {
    final box = _gridBox;
    if (box == null) return;
    final item = _draft.item(type).copy();
    _gestureItem = item;
    _gestureOrigin = box.globalToLocal(globalOrigin);
    _gestureLast = globalOrigin;
    final m = _metrics(box);
    _live.value = _snap(type, _cellRect(item, m), m);
    if (_selected != type) setState(() => _selected = type);
  }

  void _endLive() {
    _live.value = null;
    _gestureItem = null;
    _gestureOrigin = null;
    _gestureLast = null;
    _gesturePointers = 0;
  }

  /// Applies the snapped cell. A blocked move goes to the nearest free spot
  /// (AC-09); a blocked resize keeps the old size.
  void _commit(LayoutItem original, _LiveEdit live, {required bool move}) {
    if (live.x == original.x &&
        live.y == original.y &&
        live.w == original.w &&
        live.h == original.h) {
      setState(() {});
      return;
    }
    if (live.fits) {
      _edit((draft) => draft.resize(live.type, live.x, live.y, live.w, live.h));
    } else if (move &&
        live.w == original.w &&
        live.h == original.h &&
        // Nearest free spot being where it started means nothing changes.
        _draft.nearestFree(
              live.w,
              live.h,
              live.x,
              live.y,
              ignore: _draft.item(live.type),
            ) !=
            (original.x, original.y)) {
      _place(live.type, live.x, live.y);
    } else {
      setState(() {});
    }
  }

  void _transformStart(String type, ScaleStartDetails details) {
    // One finger: measure from where it touched down, not from where the
    // gesture was recognized, so the widget does not trail the finger.
    final origin = details.pointerCount == 1
        ? _downPosition ?? details.focalPoint
        : details.focalPoint;
    _gesturePointers = details.pointerCount;
    _beginLive(type, origin);
    if (details.pointerCount == 1) _gestureLast = details.focalPoint;
  }

  void _transformUpdate(String type, ScaleUpdateDetails details) {
    final box = _gridBox;
    final original = _gestureItem;
    final origin = _gestureOrigin;
    if (box == null || original == null || origin == null) return;
    _gestureLast = details.focalPoint;
    _gesturePointers = math.max(_gesturePointers, details.pointerCount);
    final m = _metrics(box);
    final start = _cellRect(original, m);
    final delta = box.globalToLocal(details.focalPoint) - origin;
    final width = (start.width * details.scale).clamp(
      ScreenLayout.minWidth * m.pitch - m.gap,
      ScreenLayout.columns * m.pitch - m.gap,
    );
    final height = (start.height * details.scale).clamp(
      ScreenLayout.minHeight * m.row - m.gap,
      _draft.rows * m.row - m.gap,
    );
    _live.value = _snap(
      type,
      Rect.fromCenter(
        center: start.center + delta,
        width: width,
        height: height,
      ),
      m,
    );
  }

  void _transformEnd(String type) {
    final live = _live.value;
    final original = _gestureItem;
    final last = _gestureLast;
    final singleFinger = _gesturePointers <= 1;
    _endLive();
    if (live == null || original == null) return;
    final canvas = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (singleFinger &&
        last != null &&
        canvas != null &&
        !(Offset.zero & canvas.size).contains(canvas.globalToLocal(last))) {
      _remove(type); // Dragged off the screen: removed, with Undo (BR-13).
      return;
    }
    _commit(original, live, move: true);
  }

  late AppState _app;
  Map<String, ScreenLayout>? _drafts;
  final _undo = <Map<String, dynamic>>[];

  /// Photos picked in this session; the unused ones are deleted on leave.
  final _newImages = <String>[];

  final _gridKey = GlobalKey();
  final _exportKey = GlobalKey();

  bool get _lock => _target == 0;
  String get _layoutId => _lock ? ScreenLayout.lock : ScreenLayout.home;
  ScreenLayout get _draft => _drafts![_layoutId]!;
  List<String> get _types => _lock ? WidgetType.lock : WidgetType.home;

  WallpaperDimensions get _wallpaperDimensions {
    final view = View.of(context);
    // A browser's emulated viewport is the target; Android needs the whole
    // display, including system bars and outside a split-screen app window.
    final viewport = MediaQuery.sizeOf(context) * view.devicePixelRatio;
    final display = kIsWeb ? viewport : view.display.size;
    return WallpaperDimensions(display.isEmpty ? viewport : display);
  }

  String get _wallpaperName => wallpaperName(
    _draft.backgroundPath != null ? wallpaperPhoto : _draft.wallpaper,
  );

  /// Size as the design shows it ("3 × 2"): about a third of a row wide.
  String _sizeLabel(LayoutItem item) =>
      '${(item.w / 2.4).round().clamp(1, 5)} × ${(item.h / 2).round()}';

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.read(context);
    _drafts ??= {
      ScreenLayout.lock: _app.layouts.lock.copy(),
      ScreenLayout.home: _app.layouts.home.copy(),
    };
  }

  // ---- History ---------------------------------------------------------------

  Map<String, dynamic> _snapshot() => {
    for (final draft in _drafts!.values) draft.id: draft.toJson(),
  };

  void _remember() {
    _undo.add(_snapshot());
    if (_undo.length > 50) _undo.removeAt(0);
  }

  void _edit(void Function(ScreenLayout draft) change) {
    _remember();
    setState(() {
      change(_draft);
      _dirty = true;
    });
  }

  void _undoStep() => setState(() {
    _drafts = {
      for (final entry in _undo.removeLast().entries)
        entry.key: ScreenLayout.fromJson(
          (entry.value as Map).cast<String, dynamic>(),
        ),
    };
    final selected = _selected;
    if (selected != null && !_draft.shows(selected)) _selected = null;
    _dirty = true;
  });

  // ---- Arranging (every user) ----------------------------------------------

  RenderBox? get _gridBox =>
      _gridKey.currentContext?.findRenderObject() as RenderBox?;

  /// AC-08: a widget dropped on the canvas lands where the finger is.
  void _drop(String type, Offset global) {
    final box = _gridBox;
    if (box == null) return;
    final local = box.globalToLocal(global);
    final item = _draft.item(type);
    _place(
      type,
      (local.dx / gridPitch(box.size.width) - item.w / 2).round(),
      (local.dy / gridRowPitch(box.size.width) - item.h / 2).round(),
    );
  }

  /// AC-09: a spot on the clock or on another widget snaps to the nearest
  /// free one.
  void _place(String type, int x, int y) {
    var result = PlaceResult.full;
    _edit((draft) => result = draft.place(type, x, y));
    if (result == PlaceResult.full) {
      _undo.removeLast();
      showAppSnack(context, 'No room for this widget');
      return;
    }
    setState(() => _selected = type);
    if (result == PlaceResult.snapped) {
      showAppSnack(context, 'Moved to the nearest free spot');
    }
  }

  /// Takes a widget off the screen, with Undo (BR-13).
  void _remove(String type) {
    final item = _draft.item(type);
    final (x, y) = (item.x, item.y);
    final target = _target;
    _edit((draft) => draft.hide(type));
    setState(() => _selected = null);
    showUndoSnack(
      context,
      trf('{widget} removed', {'widget': studioName(type)}),
      onUndo: () {
        if (!mounted) return;
        setState(() => _target = target);
        if (!_draft.shows(type)) _place(type, x, y);
      },
    );
  }

  /// Moves the [side] (a corner or an edge) of a widget with the finger; the
  /// size snaps to the grid when the finger lifts.
  void _resizeTo(String type, Alignment side, Offset global) {
    final box = _gridBox;
    final original = _gestureItem;
    final origin = _gestureOrigin;
    if (box == null || original == null || origin == null) return;
    final m = _metrics(box);
    final start = _cellRect(original, m);
    final delta = box.globalToLocal(global) - origin;
    final minW = ScreenLayout.minWidth * m.pitch - m.gap;
    final minH = ScreenLayout.minHeight * m.row - m.gap;
    final maxRight = box.size.width;
    final maxBottom = _draft.rows * m.row - m.gap;
    var (left, top, right, bottom) = (
      start.left,
      start.top,
      start.right,
      start.bottom,
    );
    if (side.x < 0) {
      left = (start.left + delta.dx).clamp(0, right - minW).toDouble();
    } else if (side.x > 0) {
      right = (start.right + delta.dx).clamp(left + minW, maxRight).toDouble();
    }
    if (side.y < 0) {
      top = (start.top + delta.dy).clamp(0, bottom - minH).toDouble();
    } else if (side.y > 0) {
      bottom = (start.bottom + delta.dy)
          .clamp(top + minH, math.max(top + minH, maxBottom))
          .toDouble();
    }
    _live.value = _snap(type, Rect.fromLTRB(left, top, right, bottom), m);
  }

  void _resizeEnd() {
    final live = _live.value;
    final original = _gestureItem;
    _endLive();
    if (live != null && original != null) _commit(original, live, move: false);
  }

  Future<void> _openStyle() async {
    final type = _selected;
    if (type == null) return;
    final item = _draft.item(type);
    final style = await pushInTab<WidgetStyle>(
      context,
      WidgetStyleScreen(
        type: type,
        lock: _lock,
        item: item,
        layoutName: _draft.preset,
      ),
    );
    if (style == null || !mounted) return;
    var fits = true;
    _edit((draft) {
      draft.setStyle(
        type,
        color: style.color,
        textSize: style.textSize,
        surface: style.surface,
      );
      final target = draft.item(type);
      final (oldW, oldH) = (target.w, target.h);
      target
        ..w = style.size.$1
        ..h = style.size.$2;
      if (draft.place(type, target.x, target.y) == PlaceResult.full) {
        target
          ..w = oldW
          ..h = oldH;
        fits = false;
      }
    });
    if (!fits) showAppSnack(context, 'Not enough room for that size');
  }

  /// "Find your calm": ready-made layouts (VIP ones checked there).
  Future<void> _pickPreset() async {
    final picked = await pushInTab<String>(
      context,
      LayoutGalleryScreen(current: _draft.preset),
    );
    if (picked == null || !mounted) return;
    _edit((draft) => draft.applyPreset(picked));
    setState(() => _selected = null);
    showAppSnack(context, trf('{name} layout applied', {'name': tr(picked)}));
  }

  // ---- Background -------------------------------------------------------------

  Future<void> _openGallery() async {
    final current = _draft.backgroundPath != null
        ? wallpaperPhoto
        : _draft.wallpaper;
    final picked = await pushInTab<String>(
      context,
      WallpaperGalleryScreen(current: current),
    );
    if (picked == null || !mounted) return;
    if (picked == wallpaperPhoto) {
      await _pickPhoto();
      return;
    }
    if (picked == current) return;
    _edit((draft) {
      draft
        ..wallpaper = picked
        ..backgroundPath = null;
    });
  }

  /// A photo of the user's own as the background (VIP).
  Future<void> _pickPhoto() async {
    if (!await requireVip(context, feature: VipFeature.backgroundImages)) {
      return;
    }
    final id = _layoutId;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
      );
      if (picked == null) return;
      // Reject unreadable/unsupported images before replacing the current photo.
      final codec = await ui.instantiateImageCodec(await picked.readAsBytes());
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (!mounted) return;
      final saved = await storeBackgroundPhoto(picked, id);
      if (!mounted) {
        await deleteBackgroundPhoto(saved);
        return;
      }
      _newImages.add(saved);
      _remember();
      setState(() {
        _drafts![id]!.backgroundPath = saved;
        _dirty = true;
      });
    } catch (_) {
      if (mounted)
        showAppSnack(
          context,
          'Could not load this photo. Please try another image.',
        );
    }
  }

  Future<void> _deleteQuietly(String path) async {
    await deleteBackgroundPhoto(path);
  }

  // ---- Save / export -----------------------------------------------------------

  Future<void> _saveDrafts() async {
    if (!_dirty) return;
    for (final draft in _drafts!.values) {
      final old = _app.layouts.of(draft.id).backgroundPath;
      if (old != null && old != draft.backgroundPath) {
        _replacedPhotos.add(old);
      }
      _app.layouts.save(draft.copy());
    }
    await _app.layouts.flush();
    if (mounted) setState(() => _dirty = false);
  }

  /// AC-08: the back arrow (or system back) saves both screens and leaves.
  Future<void> _saveAndClose() async {
    if (_saving || _closing) return;
    _saving = true;
    try {
      await _saveDrafts();
    } catch (_) {
      if (mounted)
        showAppSnack(context, 'Could not save changes. Please try again.');
      return;
    } finally {
      _saving = false;
    }
    _closing = true;
    final kept = {for (final draft in _drafts!.values) draft.backgroundPath};
    for (final path in {..._newImages, ..._replacedPhotos}) {
      if (!kept.contains(path)) await _deleteQuietly(path);
    }
    if (!mounted) return;
    // Rebuild so the PopScope lets this pop through.
    setState(() {});
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  /// PNG of the wallpaper and widgets at the phone's resolution (AC-28),
  /// without the clock, status bar or notifications.
  Future<Uint8List?> _export() async {
    setState(() => _selected = null);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return null;
    final boundary =
        _exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return _wallpaperDimensions.capture(boundary);
  }

  Future<void> _saveImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final revision = _lock && supportsDailyWallpaper
          ? AutoWallpaperService.contentRevision(AppScope.read(context))
          : null;
      final bytes = await _export();
      if (bytes == null) return;
      await _saveDrafts();
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImageBytes(
        bytes,
        name:
            'supercalendar_wallpaper_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      await pushInTab<void>(
        context,
        WallpaperExportScreen(
          image: bytes,
          wallpaperName: _wallpaperName,
          lockScreen: _lock,
          layout: _draft.copy(),
          dimensions: _wallpaperDimensions,
          contentRevision: revision,
        ),
      );
    } on GalException {
      if (mounted) showAppSnack(context, 'Could not save the image');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setWallpaper() async {
    if (requiresManualWallpaperSetup) {
      await _saveImage();
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final revision = _lock && supportsDailyWallpaper
          ? AutoWallpaperService.contentRevision(AppScope.read(context))
          : null;
      final bytes = await _export();
      if (bytes == null) return;
      await _saveDrafts();
      final ok = await WallpaperService.instance.setWallpaper(
        bytes,
        lockScreen: _lock,
      );
      if (!mounted) return;
      if (ok && _lock) {
        await offerDailyWallpaper(
          context,
          layout: _draft.copy(),
          dimensions: _wallpaperDimensions,
          contentRevision: revision,
        );
      }
      if (!mounted) return;
      showAppSnack(
        context,
        ok ? 'Wallpaper set' : 'Could not set the wallpaper',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final draft = _draft;
    return PopScope(
      canPop: _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              StudioHeader(
                title: 'Edit Your Screen',
                subtitle:
                    '$_wallpaperName · ${tr(_dirty ? 'Unsaved changes' : 'Draft saved')}',
                onBack: _saveAndClose,
                trailing: StudioIconButton(
                  icon: LucideIcons.undo2,
                  tooltip: 'Undo',
                  onTap: _undo.isEmpty ? null : _undoStep,
                ),
              ),
              Expanded(
                // Scrolling the page ends the selection, so its frame and
                // handles never stay behind over other content.
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: (notification) {
                    if (notification.dragDetails != null &&
                        _selected != null &&
                        _live.value == null) {
                      setState(() => _selected = null);
                    }
                    return false;
                  },
                  child: ListView(
                    // A corner being pulled must not scroll the page.
                    physics: _resizing
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      if (_lock) ...[
                        _overlayControl(),
                        const SizedBox(height: 12),
                      ],
                      _canvas(draft),
                      const SizedBox(height: 10),
                      Text(
                        tr('Drag to move · Pull corners to resize · Fit'),
                        textAlign: TextAlign.center,
                        style: AppText.s(
                          12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dock(app, draft),
                    ],
                  ),
                ),
              ),
              StudioActions(
                note: 'Exports wallpaper + widgets only. No system overlays.',
                children: [
                  StudioButton(
                    label: 'Save Image',
                    soft: true,
                    onTap: _saveImage,
                  ),
                  StudioButton(
                    label: requiresManualWallpaperSetup
                        ? 'Save for Lock Screen'
                        : 'Set Wallpaper',
                    onTap: _setWallpaper,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayControl() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Live Overlay · Preview only'),
                style: AppText.s(13, weight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 3),
              Text(
                tr('Clock, battery, Wi-Fi and notifications won’t export.'),
                style: AppText.s(12, color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppSwitch(
          value: _overlay,
          onChanged: (value) => setState(() => _overlay = value),
        ),
      ],
    );
  }

  Widget _canvas(ScreenLayout draft) {
    final dimensions = _wallpaperDimensions;
    final canvasHeight = dimensions.canvasHeight(_canvasWidth);
    final gridTop = _lock
        ? canvasHeight * _lockGridTop / _referenceCanvasHeight
        : _homeGridTop;
    final frame = DevicePreviewFrame(
      device: DeviceFrameService.instance.frameFor(
        Size(dimensions.width.toDouble(), dimensions.height.toDouble()),
      ),
      screenSize: Size(_canvasWidth, canvasHeight),
      child: SizedBox(
        key: _canvasKey,
        width: _canvasWidth,
        height: canvasHeight,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (d) => _types.contains(d.data),
          onAcceptWithDetails: (d) => _drop(d.data, d.offset),
          builder: (context, candidates, _) => Container(
            foregroundDecoration: candidates.isEmpty
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      key: _exportKey,
                      child: WallpaperScene(
                        layout: draft,
                        dimensions: dimensions,
                        gridKey: _gridKey,
                        cellBuilder: _canvasItem,
                      ),
                    ),
                  ),
                  if (_lock && _overlay)
                    Positioned(
                      left: _gridSide,
                      right: _gridSide,
                      top: 15,
                      height: math.max(1, gridTop - 30),
                      child: IgnorePointer(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: _canvasWidth - 2 * _gridSide,
                            child: const Opacity(
                              opacity: 0.6,
                              child: _LockOverlay(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // The selection layer lives inside the scrolling page, so the list clips
    // it; the device bezel around the screen leaves room for whole handles.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        frame,
        Positioned.fill(child: _selectionOverlay(context)),
      ],
    );
  }

  /// Drag to move, pinch to resize, or pull a handle. The card itself never
  /// rebuilds during the gesture; the overlay draws it under the finger.
  Widget _canvasItem(LayoutItem item, Size size, double scale) {
    final type = item.type;
    final selected = type == _selected;
    _cellScale = scale;
    final card = widgetCell(
      type,
      lock: _lock,
      size: size,
      scale: scale,
      color: item.color,
      textSize: item.textSize,
      surface: item.surface,
    );
    final cell = Semantics(
      key: ValueKey('canvas_$type'),
      button: true,
      selected: selected,
      label: studioName(type),
      child: Listener(
        onPointerDown: _fingerDown,
        onPointerUp: _fingerUp,
        onPointerCancel: _fingerUp,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selected = selected ? null : type),
          onScaleStart: (details) => _transformStart(type, details),
          onScaleUpdate: (details) => _transformUpdate(type, details),
          onScaleEnd: (_) => _transformEnd(type),
          child: RepaintBoundary(
            child: ValueListenableBuilder<_LiveEdit?>(
              valueListenable: _live,
              builder: (context, live, child) =>
                  Opacity(opacity: live?.type == type ? 0.3 : 1, child: child),
              child: IgnorePointer(child: card),
            ),
          ),
        ),
      ),
    );
    return CompositedTransformTarget(
      link: _links.putIfAbsent(type, LayerLink.new),
      child: cell,
    );
  }

  /// Selection frame, handles and the live card of the selected widget,
  /// drawn above the canvas so handles are fully touchable and the card being
  /// moved stays on top of the others.
  Widget _selectionOverlay(BuildContext context) {
    return ValueListenableBuilder<_LiveEdit?>(
      valueListenable: _live,
      builder: (context, live, _) {
        final type = live?.type ?? _selected;
        if (type == null || !_draft.shows(type)) {
          return const SizedBox.shrink();
        }
        // Read from the cells, not the render tree: this builds while the
        // canvas itself may be rebuilding.
        final gridWidth = _cellScale * gridDesignWidth;
        final m = _metricsFor(gridWidth);
        final item = _draft.item(type);
        final cell = _cellRect(item, m);
        final rect = live?.rect ?? cell;
        // NFR-08: about 48 dp on the real screen, whatever the preview scale.
        final handle = (48 / _previewScale).clamp(28.0, 80.0);
        final pad = handle;
        Rect shift(Rect r) => r.shift(Offset(pad, pad));
        Widget at(Rect r, Widget child, {Key? key}) =>
            Positioned.fromRect(key: key, rect: shift(r), child: child);
        // Corners sit mostly outside the widget, leaving its middle free for
        // dragging.
        Rect handleAt(Offset point, Alignment side) => Rect.fromCenter(
          center: point + Offset(side.x, side.y) * handle / 4,
          width: handle,
          height: handle,
        );
        final children = <Widget>[
          if (live != null) ...[
            at(
              _cellAt(live.x, live.y, live.w, live.h, m),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: (live.fits ? AppColors.primary : AppColors.danger)
                        .withValues(alpha: 0.12),
                    border: Border.all(
                      color: live.fits ? AppColors.primary : AppColors.danger,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            at(
              rect,
              IgnorePointer(
                child: Opacity(
                  opacity: 0.92,
                  child: widgetCell(
                    type,
                    lock: _lock,
                    size: rect.size,
                    scale: _cellScale,
                    color: item.color,
                    textSize: item.textSize,
                    surface: item.surface,
                  ),
                ),
              ),
            ),
          ],
          at(
            rect,
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (live == null || _gesturePointers == 0) ...[
            for (final corner in const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              at(
                handleAt(corner.withinRect(rect), corner),
                key: ValueKey(corner),
                _ResizeHandle(
                  onStart: (global) => _beginLive(type, global),
                  onUpdate: (global) => _resizeTo(type, corner, global),
                  onEnd: _resizeEnd,
                  onDown: _fingerDown,
                  onUp: _fingerUp,
                ),
              ),
            for (final edge in const [
              Alignment.topCenter,
              Alignment.bottomCenter,
              Alignment.centerLeft,
              Alignment.centerRight,
            ])
              // Edges only where they leave room between the corners.
              if ((edge.x == 0 ? rect.width : rect.height) >= handle * 2.6)
                at(
                  handleAt(edge.withinRect(rect), edge),
                  key: ValueKey(edge),
                  _EdgeHandle(
                    vertical: edge.x != 0,
                    onStart: (global) => _beginLive(type, global),
                    onUpdate: (global) => _resizeTo(type, edge, global),
                    onEnd: _resizeEnd,
                    onDown: _fingerDown,
                    onUp: _fingerUp,
                  ),
                ),
          ],
        ];
        return OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: CompositedTransformFollower(
            link: _links.putIfAbsent(type, LayerLink.new),
            showWhenUnlinked: false,
            offset: -cell.topLeft - Offset(pad, pad),
            child: SizedBox(
              width: gridWidth + 2 * pad,
              height: _draft.rows * m.row - m.gap + 2 * pad,
              child: Stack(clipBehavior: Clip.none, children: children),
            ),
          ),
        );
      },
    );
  }

  Widget _dock(AppState app, ScreenLayout draft) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillSwitch(
            labels: const ['Background', 'Layers', 'Widgets'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 12),
          switch (_tab) {
            0 => _backgroundTab(app, draft),
            1 => _layersTab(draft),
            _ => _widgetsTab(draft),
          },
        ],
      ),
    );
  }

  Widget _widgetsTab(ScreenLayout draft) {
    final selected = _selected;
    final item = selected == null ? null : draft.item(selected);
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item == null
                      ? tr('Tap a widget to edit it')
                      : '${studioName(item.type)} · ${_sizeLabel(item)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: item == null
                      ? AppText.s(13, color: AppColors.muted, height: 1.4)
                      : AppText.s(13, weight: FontWeight.w600, height: 1.4),
                ),
              ),
              if (item != null) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openStyle,
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        tr('Style'),
                        style: AppText.s(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: tr('Remove'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _remove(item.type),
                    child: SizedBox(
                      width: 40,
                      height: 48,
                      child: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < _library.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _LibraryItem(
                  type: _library[i],
                  label: _libraryLabels[i],
                  color: _libraryColors[i],
                  onTap: draft.shows(_library[i])
                      ? () => setState(() => _selected = _library[i])
                      : () => _place(_library[i], 0, 0),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static const _libraryLabels = ['Calendar', 'Weather', 'Mini notes', 'Habits'];

  static List<Color> get _libraryColors => [
    AppColors.purple,
    AppColors.yellow,
    AppColors.pink,
    AppColors.green,
  ];

  Widget _backgroundTab(AppState app, ScreenLayout draft) {
    final fonts = app.canAccess(VipFeature.customTypography);
    return Column(
      children: [
        PillSwitch(
          labels: const ['Lock screen', 'Home screen'],
          index: _target,
          onChanged: (i) => setState(() {
            _target = i;
            _selected = null;
          }),
        ),
        const SizedBox(height: 4),
        _DockRow(
          icon: LucideIcons.image,
          title: 'Wallpaper',
          value: _wallpaperName,
          action: 'Change',
          onTap: _openGallery,
        ),
        _DockRow(
          icon: LucideIcons.type,
          title: 'Font',
          value: fonts
              ? app.settings.typography ?? app.selectedTheme.typography
              : app.selectedTheme.typography,
          action: 'Choose font',
          locked: !fonts,
          // AC-10: a Free user gets the paywall here.
          onTap: () => pickTypography(context),
        ),
        _DockRow(
          icon: LucideIcons.layoutGrid,
          title: 'Layouts',
          value: tr(draft.preset),
          action: 'Change',
          onTap: _pickPreset,
        ),
        _DockRow(
          icon: LucideIcons.palette,
          title: 'Templates',
          value: app.selectedTheme.name,
          action: 'Browse',
          onTap: () => pushInTab<void>(context, const TemplateStoreScreen()),
        ),
      ],
    );
  }

  Widget _layersTab(ScreenLayout draft) {
    return Column(
      children: [
        for (final type in _types)
          Builder(
            builder: (context) {
              final item = draft.item(type);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: item.visible
                    ? () => setState(() {
                        _selected = type;
                        _tab = 2;
                      })
                    : null,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Icon(
                        widgetIcons[type],
                        size: 17,
                        color: item.visible
                            ? AppColors.primary
                            : AppColors.faint,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          studioName(type),
                          style: AppText.s(
                            13,
                            color: item.visible
                                ? AppColors.text
                                : AppColors.muted,
                          ),
                        ),
                      ),
                      Text(
                        item.visible ? '' : tr('Hidden'),
                        style: AppText.s(11, color: AppColors.muted),
                      ),
                      const SizedBox(width: 10),
                      AppSwitch(
                        value: item.visible,
                        onChanged: (show) =>
                            show ? _place(type, item.x, item.y) : _remove(type),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Status bar, clock and a notification over the lock preview, as the
/// phone would show them. Drawn outside the exported area.
class _LockOverlay extends StatelessWidget {
  const _LockOverlay();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = app.now;
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    return Column(
      children: [
        Row(
          children: [
            Text(weekdayNames[app.today.weekday - 1], style: AppText.s(10)),
            const Spacer(),
            Icon(LucideIcons.signal, size: 12, color: AppColors.text),
            const SizedBox(width: 5),
            Icon(LucideIcons.wifi, size: 12, color: AppColors.text),
            const SizedBox(width: 5),
            Text('86%', style: AppText.s(10)),
            const SizedBox(width: 5),
            Icon(LucideIcons.batteryFull, size: 16, color: AppColors.text),
          ],
        ),
        const SizedBox(height: 12),
        Icon(LucideIcons.lockKeyhole, size: 15, color: AppColors.text),
        const SizedBox(height: 2),
        Text(time, style: AppText.s(58, height: 1.2)),
        const SizedBox(height: 2),
        Text(longDate(app.today), style: AppText.s(12)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.69),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.messageCircle, size: 16, color: AppColors.text),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Messages · now'), style: AppText.s(9)),
                    const SizedBox(height: 4),
                    Text(
                      tr('Alex · Here’s to a fresh start ☀'),
                      style: AppText.s(10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The widget under the finger while dragging, centered on it.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.88, child: child),
      ),
    );
  }
}

/// Grid spacing in pixels: column pitch, row pitch and gap.
typedef _Grid = ({double pitch, double row, double gap});

/// A widget under the finger: where it is drawn ([rect], grid pixels) and
/// the grid cell it will snap to when released.
class _LiveEdit {
  const _LiveEdit(
    this.type,
    this.rect,
    this.x,
    this.y,
    this.w,
    this.h, {
    required this.fits,
  });

  final String type;
  final Rect rect;
  final int x, y, w, h;

  /// False when the cell is taken or off the grid.
  final bool fits;
}

/// Shared touch handling of the resize handles. Starts from where the finger
/// touched down, so the edge does not jump by the drag slop.
class _HandleGestures extends StatelessWidget {
  const _HandleGestures({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onDown,
    required this.onUp,
    required this.child,
  });

  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  /// Finger down / up, so the page does not scroll while a handle is held.
  final ValueChanged<PointerDownEvent> onDown;
  final ValueChanged<PointerEvent> onUp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onDown,
      onPointerUp: onUp,
      onPointerCancel: onUp,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) => onStart(details.globalPosition),
        onPanUpdate: (details) => onUpdate(details.globalPosition),
        onPanEnd: (_) => onEnd(),
        onPanCancel: onEnd,
        child: child,
      ),
    );
  }
}

/// One of the four corner squares of the selected widget.
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onDown,
    required this.onUp,
  });

  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final ValueChanged<PointerDownEvent> onDown;
  final ValueChanged<PointerEvent> onUp;

  @override
  Widget build(BuildContext context) {
    return _HandleGestures(
      onStart: onStart,
      onUpdate: onUpdate,
      onEnd: onEnd,
      onDown: onDown,
      onUp: onUp,
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

/// A bar in the middle of an edge: resizes in one direction only.
class _EdgeHandle extends StatelessWidget {
  const _EdgeHandle({
    required this.vertical,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onDown,
    required this.onUp,
  });

  /// True for the left and right edges.
  final bool vertical;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final ValueChanged<PointerDownEvent> onDown;
  final ValueChanged<PointerEvent> onUp;

  @override
  Widget build(BuildContext context) {
    return _HandleGestures(
      onStart: onStart,
      onUpdate: onUpdate,
      onEnd: onEnd,
      onDown: onDown,
      onUp: onUp,
      child: Center(
        child: Container(
          width: vertical ? 6 : 22,
          height: vertical ? 22 : 6,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// A tile of the "Add a widget" library: tap to add it, or hold and drag it
/// onto the canvas.
class _LibraryItem extends StatelessWidget {
  const _LibraryItem({
    required this.type,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String type;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget tile({double? width}) => Container(
      width: width,
      height: 67,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widgetIcons[type], size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            tr(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(11, weight: FontWeight.w500),
          ),
        ],
      ),
    );
    return LongPressDraggable<String>(
      data: type,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _DragFeedback(child: tile(width: 80)),
      child: Semantics(
        button: true,
        label: tr(label),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: tile(),
        ),
      ),
    );
  }
}

/// A row of the Background tab.
class _DockRow extends StatelessWidget {
  const _DockRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.action,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String action;
  final VoidCallback onTap;

  /// Shows a lock: the action needs VIP for this user.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(title),
                    style: AppText.s(13, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.s(11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (locked) ...[
              Icon(LucideIcons.lockKeyhole, size: 12, color: AppColors.faint),
              const SizedBox(width: 6),
            ],
            Text(
              tr(action),
              style: AppText.s(
                13,
                weight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
