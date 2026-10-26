import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/wallpaper_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/appearance_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/layout_gallery_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/wallpaper_export_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/wallpaper_gallery_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_store_screen.dart';
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';

/// Size of the wallpaper canvas in the design; it is drawn at this size and
/// scaled to the screen, so the design's measures are used as they are.
const _canvasWidth = 330.0;
const _canvasHeight = 520.0;

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
  // Dock view: 0 = Background, 1 = Widgets, 2 = Layers.
  int _tab = 1;
  bool _overlay = true;
  bool _dirty = false;
  bool _closing = false;
  bool _resizing = false;
  bool _busy = false;
  String? _selected;

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

  String get _wallpaperName => wallpaperName(
    _draft.backgroundPath != null ? wallpaperPhoto : _draft.wallpaper,
  );

  /// Size as the design shows it ("3 × 2"): about a third of a row wide.
  String _sizeLabel(LayoutItem item) =>
      '${(item.w / 2.4).round().clamp(1, 5)} × ${(item.h / 2).round()}';

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

  /// Moves the [corner] of a widget to the grid line nearest the finger.
  void _resizeTo(String type, Alignment corner, Offset global) {
    final box = _gridBox;
    if (box == null) return;
    final local = box.globalToLocal(global);
    final lineX = (local.dx / gridPitch(box.size.width)).round();
    final lineY = (local.dy / gridRowPitch(box.size.width)).round();
    final item = _draft.item(type);
    var left = item.x, top = item.y;
    var right = item.x + item.w, bottom = item.y + item.h;
    if (corner.x < 0) {
      left = math.min(lineX, right - ScreenLayout.minWidth);
    } else {
      right = math.max(lineX, left + ScreenLayout.minWidth);
    }
    if (corner.y < 0) {
      top = math.min(lineY, bottom - ScreenLayout.minHeight);
    } else {
      bottom = math.max(lineY, top + ScreenLayout.minHeight);
    }
    if (left == item.x &&
        top == item.y &&
        right - left == item.w &&
        bottom - top == item.h) {
      return;
    }
    setState(() {
      if (_draft.resize(type, left, top, right - left, bottom - top)) {
        _dirty = true;
      }
    });
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
    if (picked == null || !mounted || picked == current) return;
    if (picked == wallpaperPhoto) {
      await _pickPhoto();
      return;
    }
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
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1440,
    );
    if (picked == null) return;
    // Copy out of the picker's cache so the image survives a restart.
    final directory = await getApplicationDocumentsDirectory();
    final name =
        'background_${id}_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(picked.path)}';
    final saved = await File(picked.path).copy(p.join(directory.path, name));
    _newImages.add(saved.path);
    if (!mounted) return;
    _remember();
    setState(() {
      _drafts![id]!.backgroundPath = saved.path;
      _dirty = true;
    });
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone; nothing to clean up.
    }
  }

  // ---- Save / export -----------------------------------------------------------

  /// AC-08: the back arrow (or system back) saves both screens and leaves.
  Future<void> _saveAndClose() async {
    if (_closing) return;
    _closing = true;
    if (_dirty) {
      for (final draft in _drafts!.values) {
        final old = _app.layouts.of(draft.id).backgroundPath;
        _app.layouts.save(draft);
        if (old != null && old != draft.backgroundPath) {
          await _deleteQuietly(old);
        }
      }
      // NFR-04: wait until the layout is on disk before leaving.
      await _app.layouts.flush();
    }
    final kept = {for (final draft in _drafts!.values) draft.backgroundPath};
    for (final path in _newImages) {
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
    final ratio = View.of(context).physicalSize.width / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _saveImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _export();
      if (bytes == null) return;
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImageBytes(
        bytes,
        name: 'supercalendar_wallpaper_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      await pushInTab<void>(
        context,
        WallpaperExportScreen(
          image: bytes,
          wallpaperName: _wallpaperName,
          lockScreen: _lock,
        ),
      );
    } on GalException {
      if (mounted) showAppSnack(context, 'Could not save the image');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setWallpaper() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _export();
      if (bytes == null) return;
      final ok = await WallpaperService.instance.setWallpaper(
        bytes,
        lockScreen: _lock,
      );
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
                child: ListView(
                  // A corner being pulled must not scroll the page.
                  physics: _resizing
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    if (_lock) ...[_overlayControl(), const SizedBox(height: 12)],
                    _canvas(draft),
                    const SizedBox(height: 10),
                    Text(
                      tr('Drag to move · Pull corners to resize · Fit'),
                      textAlign: TextAlign.center,
                      style: AppText.s(12, color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    _dock(app, draft),
                  ],
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
                  StudioButton(label: 'Set Wallpaper', onTap: _setWallpaper),
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
    final gridTop = _lock ? _lockGridTop : _homeGridTop;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(_canvasWidth, constraints.maxWidth);
        return Center(
          child: SizedBox(
            width: width,
            height: width * _canvasHeight / _canvasWidth,
            child: FittedBox(
              child: SizedBox(
                width: _canvasWidth,
                height: _canvasHeight,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (d) => _types.contains(d.data),
                  onAcceptWithDetails: (d) => _drop(d.data, d.offset),
                  builder: (context, candidates, _) => Container(
                    foregroundDecoration: candidates.isEmpty
                        ? null
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              key: _exportKey,
                              child: LayoutBackground(
                                layout: draft,
                                fallback: _lock
                                    ? lockScreenDecoration()
                                    : BoxDecoration(
                                        color: AppColors.background,
                                      ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: _gridSide,
                                      right: _gridSide,
                                      top: gridTop,
                                      child: WidgetGrid(
                                        key: _gridKey,
                                        layout: draft,
                                        minRows: draft.rows,
                                        cellBuilder: _canvasItem,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_lock && _overlay)
                            const Positioned(
                              left: _gridSide,
                              right: _gridSide,
                              top: 15,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.6,
                                  child: _LockOverlay(),
                                ),
                              ),
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
      },
    );
  }

  /// A widget on the canvas: tap to select, long-press to drag, pull a
  /// corner to resize. Released outside the canvas, it leaves the screen.
  Widget _canvasItem(LayoutItem item, Size size, double scale) {
    final type = item.type;
    final selected = type == _selected;
    final card = widgetCell(
      type,
      lock: _lock,
      size: size,
      scale: scale,
      color: item.color,
      textSize: item.textSize,
      surface: item.surface,
    );
    return LongPressDraggable<String>(
      data: type,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _DragFeedback(child: card),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      onDragStarted: () => setState(() => _selected = type),
      onDraggableCanceled: (_, _) => _remove(type),
      child: Semantics(
        button: true,
        selected: selected,
        label: studioName(type),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selected = selected ? null : type),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              if (selected) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                for (final corner in const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ])
                  Positioned(
                    left: corner.x < 0 ? -14 : null,
                    right: corner.x > 0 ? -14 : null,
                    top: corner.y < 0 ? -14 : null,
                    bottom: corner.y > 0 ? -14 : null,
                    child: _ResizeHandle(
                      onStart: _remember,
                      onUpdate: (global) => _resizeTo(type, corner, global),
                      onHold: (down) => setState(() => _resizing = down),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
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
            labels: const ['Background', 'Widgets', 'Layers'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 12),
          switch (_tab) {
            0 => _backgroundTab(app, draft),
            2 => _layersTab(draft),
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
                        _tab = 1;
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
                        item.visible ? _sizeLabel(item) : tr('Hidden'),
                        style: AppText.s(11, color: AppColors.muted),
                      ),
                      const SizedBox(width: 10),
                      AppSwitch(
                        value: item.visible,
                        onChanged: (show) => show
                            ? _place(type, item.x, item.y)
                            : _remove(type),
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
            Text(
              weekdayNames[app.today.weekday - 1],
              style: AppText.s(10),
            ),
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

/// One of the four corner squares of the selected widget.
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onStart,
    required this.onUpdate,
    required this.onHold,
  });

  final VoidCallback onStart;
  final ValueChanged<Offset> onUpdate;

  /// True while the finger is down, so the page does not scroll.
  final ValueChanged<bool> onHold;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onHold(true),
      onPointerUp: (_) => onHold(false),
      onPointerCancel: (_) => onHold(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onStart(),
        onPanUpdate: (details) => onUpdate(details.globalPosition),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
            ),
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
