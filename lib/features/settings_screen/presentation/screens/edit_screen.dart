import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/lock_screen/presentation/widgets/lock_widgets.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/appearance_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_store_screen.dart';
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// "Edit Your Screen": arranges the widgets of the lock screen and the home
/// dashboard. Every change is saved and shows up on the real screens at once.
///
/// Free users pick one of the ready-made layouts; free-form arranging, fonts
/// and background images are VIP.
class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  // 0 = lock screen, 1 = home screen.
  int _target = 0;

  String get _layoutId => _target == 0 ? ScreenLayout.lock : ScreenLayout.home;
  String get _targetName =>
      tr(_target == 0 ? 'lock screen' : 'home screen');

  // ---- Actions ------------------------------------------------------------

  /// Shows or hides a widget (VIP: free-form layout).
  Future<void> _toggleWidget(String type, {bool? visible}) async {
    final app = AppScope.read(context);
    if (!await requireVip(context, feature: VipFeature.freeFormLayout)) return;
    final layout = app.layouts.of(_layoutId);
    final show = visible ?? !layout.shows(type);
    if (layout.shows(type) == show) return;
    app.layouts.setVisible(_layoutId, type, show);
    if (!mounted) return;
    showAppSnack(
      context,
      trf(show ? '{widget} added to the {target}' : '{widget} removed from the {target}', {'widget': tr(WidgetType.labels[type] ?? type), 'target': _targetName}),
    );
  }

  /// Ready-made layouts, available to everyone.
  Future<void> _pickPreset() async {
    final app = AppScope.read(context);
    final picked = await pickOption(
      context,
      title: trf('Layouts for the {target}', {'target': _targetName}),
      options: ScreenLayout.presets,
      current: app.layouts.of(_layoutId).preset,
    );
    if (picked == null) return;
    app.layouts.applyPreset(_layoutId, picked);
    if (mounted) showAppSnack(context, trf('{name} layout applied', {'name': tr(picked)}));
  }

  /// Free-form arranging: order, visibility and size of every widget (VIP).
  Future<void> _arrange() async {
    if (!await requireVip(context, feature: VipFeature.freeFormLayout)) return;
    if (!mounted) return;
    final id = _layoutId;
    final resizable = id == ScreenLayout.home;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final app = AppScope.of(sheetContext);
        final items = app.layouts.of(id).items;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  trf('Arrange the {target}', {'target': _targetName}),
                  style: AppText.s(15, weight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  tr(
                    resizable
                        ? 'Drag to reorder · switch to show or hide · tap the size to resize'
                        : 'Drag to reorder · switch to show or hide',
                  ),
                  style: AppText.s(10.5, color: AppColors.muted),
                ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                onReorderItem: (from, to) => app.layouts.reorder(id, from, to),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Padding(
                    key: ValueKey(item.type),
                    padding: const EdgeInsets.fromLTRB(20, 6, 44, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(WidgetType.labels[item.type] ?? item.type),
                            style: AppText.s(
                              13,
                              color: item.visible
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        if (resizable) ...[
                          SoftPill(
                            label: item.wide ? 'Full width' : 'Half width',
                            icon: LucideIcons.moveHorizontal,
                            color: AppColors.subtle,
                            textColor: AppColors.muted,
                            onTap: () =>
                                app.layouts.setWide(id, item.type, !item.wide),
                          ),
                          const SizedBox(width: 10),
                        ],
                        AppSwitch(
                          value: item.visible,
                          onChanged: (value) =>
                              app.layouts.setVisible(id, item.type, value),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// Background image for the current screen (VIP).
  Future<void> _pickBackground() async {
    final app = AppScope.read(context);
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
    final previous = app.layouts.of(id).backgroundPath;
    app.layouts.setBackground(id, saved.path);
    if (previous != null) await _deleteQuietly(previous);
    if (mounted) showAppSnack(context, trf('Background set for the {target}', {'target': _targetName}));
  }

  Future<void> _removeBackground() async {
    final app = AppScope.read(context);
    final previous = app.layouts.of(_layoutId).backgroundPath;
    app.layouts.setBackground(_layoutId, null);
    if (previous != null) await _deleteQuietly(previous);
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone; nothing to clean up.
    }
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final layout = app.layouts.of(_layoutId);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The preview shrinks on short screens so the options below it
            // always keep some room to scroll in.
            final previewHeight = (constraints.maxHeight * 0.44).clamp(
              190.0,
              333.0,
            );
            return Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PageHeader(
                    title: 'Edit Your Screen',
                    subtitle: 'Drag, resize and make it yours',
                    trailing: SizedBox(
                      width: 61,
                      child: PrimaryButton(
                        label: 'Done',
                        height: 32,
                        radius: 16,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SegmentedToggle(
                        labels: const ['LOCK', 'HOME'],
                        index: _target,
                        onChanged: (i) => setState(() => _target = i),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.hand,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tr('Press and hold any widget, then drag it '
                                  'onto the screen. Tap one to add or remove.'),
                                  style: AppText.s(
                                    10,
                                    color: AppColors.primaryTint,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _canvas(app, layout, previewHeight),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 86,
                        child: OutlinedActionButton(
                          icon: LucideIcons.pencil,
                          label: 'EDIT',
                          onTap: _pickPreset,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedActionButton(
                          icon: LucideIcons.plus,
                          label: 'LET MAKE YOURS',
                          background: AppColors.border,
                          trailing: Text(tr('✨VIP'),
                            style: AppText.s(
                              12,
                              weight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          onTap: _arrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Only this part scrolls; the preview above stays in place.
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    children: [
                      _OptionCard(
                        title: 'BACKGROUND',
                        value: layout.backgroundPath == null
                            ? 'Theme background'
                            : trf('Custom image on the {target}', {'target': _targetName}),
                        action: layout.backgroundPath == null
                            ? '🖼️ ADD IMAGE'
                            : 'REMOVE',
                        vipOnly: !app.isVip,
                        onAction: layout.backgroundPath == null
                            ? _pickBackground
                            : _removeBackground,
                      ),
                      _OptionCard(
                        title: 'FONT',
                        value: app.isVip
                            ? app.settings.typography ??
                                  app.selectedTheme.typography
                            : app.selectedTheme.typography,
                        action: 'EDIT',
                        vipOnly: !app.isVip,
                        onAction: () => pickTypography(context),
                      ),
                      _OptionCard(
                        title: 'TEMPLATE',
                        value:
                            trf('{theme} · {preset} layout', {'theme': app.selectedTheme.name, 'preset': tr(layout.preset)}),
                        action: 'EDIT',
                        onAction: () =>
                            pushInTab(context, const TemplateStoreScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Phone preview in the middle with the widget tray bleeding off both edges.
  Widget _canvas(AppState app, ScreenLayout layout, double height) {
    final width = height * 186 / 333;
    final types = _target == 0 ? WidgetType.lock : WidgetType.home;
    // Left and right trays; wide widgets are laid out at dashboard width so
    // they clip at the screen edge like in the design.
    final leftTypes = _target == 0
        ? const [WidgetType.schedule]
        : const [WidgetType.goals, WidgetType.snapshot, WidgetType.todo];
    final rightTypes = types.where((t) => !leftTypes.contains(t)).toList();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = (constraints.maxWidth - width) / 2;
          final sideGap = constraints.maxWidth - left + 14;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: sideGap,
                top: 0,
                bottom: 0,
                width: 358,
                child: _tray(layout, leftTypes, CrossAxisAlignment.end),
              ),
              Positioned(
                left: sideGap,
                top: 0,
                bottom: 0,
                width: 358,
                child: _tray(layout, rightTypes, CrossAxisAlignment.start),
              ),
              Positioned(
                left: left,
                top: 0,
                width: width,
                height: height,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) =>
                      types.contains(details.data),
                  onAcceptWithDetails: (details) =>
                      _toggleWidget(details.data, visible: true),
                  builder: (context, candidates, _) => AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: candidates.isEmpty
                            ? Colors.transparent
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _target == 0
                          ? () => pushFullScreen(context, const LockScreen())
                          : () => Navigator.of(context).pop(),
                      child: _target == 0
                          ? _LockPreview(layout: layout)
                          : _HomePreview(layout: layout),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tray(
    ScreenLayout layout,
    List<String> types,
    CrossAxisAlignment alignment,
  ) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          for (final type in types)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: _TrayItem(
                type: type,
                lock: _target == 0,
                active: layout.shows(type),
                badgeOnLeft: alignment == CrossAxisAlignment.start,
                onTap: () => _toggleWidget(type),
              ),
            ),
        ],
      ),
    );
  }
}

/// A widget in the tray: tap to add/remove it, or long-press and drag it
/// onto the preview.
class _TrayItem extends StatelessWidget {
  const _TrayItem({
    required this.type,
    required this.lock,
    required this.active,
    required this.badgeOnLeft,
    required this.onTap,
  });

  final String type;
  final bool lock;
  final bool active;
  final bool badgeOnLeft;
  final VoidCallback onTap;

  static const _wideTypes = [WidgetType.week, WidgetType.snapshot];

  Widget _card() {
    if (lock) {
      return switch (type) {
        WidgetType.schedule => const LockScheduleCard(),
        WidgetType.todo => const LockTodoCard(),
        _ => const LockNoteCard(),
      };
    }
    return type == WidgetType.quickNote
        ? const QuickNoteWidget(compact: true)
        : buildHomeWidget(type);
  }

  @override
  Widget build(BuildContext context) {
    final width = lock ? 220.0 : (_wideTypes.contains(type) ? 358.0 : 174.0);
    final card = SizedBox(
      width: width,
      child: Opacity(
        opacity: active ? 1 : 0.55,
        child: IgnorePointer(child: _card()),
      ),
    );
    return LongPressDraggable<String>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(width: width.clamp(0, 220), child: _card()),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            Positioned(
              top: -6,
              left: badgeOnLeft ? -6 : null,
              right: badgeOnLeft ? null : -6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: active ? AppColors.greenStrong : AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Icon(
                  active ? LucideIcons.check : LucideIcons.plus,
                  size: 11,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.value,
    required this.action,
    required this.onAction,
    this.vipOnly = false,
  });

  final String title;
  final String value;
  final String action;
  final VoidCallback onAction;

  /// Shows a lock: the action needs VIP for this user.
  final bool vipOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        onTap: onAction,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(title), style: AppText.s(13, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.s(10.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (vipOnly) ...[
              Icon(LucideIcons.lockKeyhole, size: 12, color: AppColors.faint),
              const SizedBox(width: 6),
            ],
            Text(action, style: AppText.action()),
          ],
        ),
      ),
    );
  }
}

/// Miniature of the real lock screen, scaled to fit the preview.
class _LockPreview extends StatelessWidget {
  const _LockPreview({required this.layout});

  final ScreenLayout layout;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = app.now;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: lockScreenDecoration(),
        child: ScreenBackground(
          imagePath: layout.backgroundPath,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 390,
                height: 698,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(19, 30, 19, 0),
                  child: Column(
                    children: [
                      Text(
                        '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                        style: AppText.s(54, height: 1.1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        longDate(app.today),
                        style: AppText.s(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LockWidgetList(layout: layout),
                      const SizedBox(height: 18),
                      Icon(
                        LucideIcons.lockKeyholeOpen,
                        size: 17,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      Text(tr('Swipe up to unlock'),
                        style: AppText.s(10.5, color: AppColors.muted),
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
  }
}

/// Miniature of the real home dashboard, scaled to fit the preview.
class _HomePreview extends StatelessWidget {
  const _HomePreview({required this.layout});

  final ScreenLayout layout;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ScreenBackground(
          imagePath: layout.backgroundPath,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: 390,
                height: 698,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trf('Hello, {name}', {'name': app.user.firstName}),
                        style: AppText.s(18, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      HomeWidgetGrid(layout: layout),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
