import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/lock_screen/presentation/widgets/lock_widgets.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/appearance_screen.dart';

const widgetIcons = <String, IconData>{
  WidgetType.todo: LucideIcons.listTodo,
  WidgetType.habits: LucideIcons.circleCheck,
  WidgetType.week: LucideIcons.calendarDays,
  WidgetType.goals: LucideIcons.target,
  WidgetType.quickNote: LucideIcons.stickyNote,
  WidgetType.snapshot: LucideIcons.image,
  WidgetType.schedule: LucideIcons.calendarClock,
  WidgetType.weather: LucideIcons.sun,
};

/// Names used in the Personalize screens, as in the design.
String studioName(String type) => tr(switch (type) {
  WidgetType.week => 'Calendar',
  WidgetType.quickNote => 'Mini note',
  _ => WidgetType.labels[type] ?? type,
});

/// The card of a widget [type] as it looks on the lock or home screen,
/// without actions.
Widget widgetCard(String type, {required bool lock}) =>
    IgnorePointer(child: lock ? buildLockWidget(type) : buildHomeWidget(type));

/// A widget card sized for a grid cell of [size].
Widget widgetCell(
  String type, {
  required bool lock,
  required Size size,
  required double scale,
  int? color,
  int? textSize,
  String? surface,
}) {
  return GridCell(
    size: size,
    color: color,
    textSize: textSize,
    surface: surface,
    minWidth: lock ? minLockCardWidth : minCardWidth,
    scale: lock && wallpaperWidgets.contains(type) ? scale : null,
    child: widgetCard(type, lock: lock),
  );
}

/// Header of the Personalize screens: back button, title, subtitle and an
/// optional action on the right.
class StudioHeader extends StatelessWidget {
  const StudioHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            StudioIconButton(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Back',
              onTap: onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.s(20, weight: FontWeight.w600, height: 1.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.s(12, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

/// White rounded 40 × 40 icon button of the Personalize header, with a
/// 48 dp touch area.
class StudioIconButton extends StatelessWidget {
  const StudioIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;

  /// Null shows the button disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tr(tooltip),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: onTap == null ? AppColors.faint : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented switch of the Personalize screens: lavender track, white
/// selected option.
class PillSwitch extends StatelessWidget {
  const PillSwitch({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tr(labels[i]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.s(
                        12,
                        weight: i == index ? FontWeight.w600 : FontWeight.w400,
                        color: i == index ? AppColors.primary : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 48-high button of the Personalize screens: filled, or soft lavender.
class StudioButton extends StatelessWidget {
  const StudioButton({
    super.key,
    required this.label,
    required this.onTap,
    this.soft = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: soft ? AppColors.primarySoft : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            tr(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.s(
              14,
              weight: FontWeight.w600,
              color: soft ? AppColors.primary : AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// White bar pinned to the bottom of a Personalize screen.
class StudioActions extends StatelessWidget {
  const StudioActions({super.key, required this.children, this.note});

  final List<Widget> children;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note != null) ...[
            Text(
              tr(note!),
              style: AppText.s(12, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// What the Style screen returns.
typedef WidgetStyle = ({
  int? color,
  int? textSize,
  String? surface,
  (int, int) size,
});

/// "Style your widget" (Personalize 22): color, typography, text size,
/// layout (width), size (height) and surface of one widget.
class WidgetStyleScreen extends StatefulWidget {
  const WidgetStyleScreen({
    super.key,
    required this.type,
    required this.lock,
    required this.item,
    required this.layoutName,
  });

  final String type;
  final bool lock;

  /// The widget as it is now; its values are the starting choices.
  final LayoutItem item;

  /// Layout the widget belongs to, shown under the title.
  final String layoutName;

  @override
  State<WidgetStyleScreen> createState() => _WidgetStyleScreenState();
}

class _WidgetStyleScreenState extends State<WidgetStyleScreen> {
  late int? _color = widget.item.color;
  late int _textSize = widget.item.textSize ?? CardTint.baseTextSize;
  late String _surface = widget.item.surface ?? CardSurface.soft;
  late int _width = widget.item.w;
  late int _height = widget.item.h;

  static final _widthNames = ScreenLayout.widths.keys.toList();
  static final _heightNames = ScreenLayout.heights.keys.toList();
  static const _widthWords = {
    'Stacked': 'NARROW',
    'Two columns': 'WIDE',
    'Wide': 'FULL WIDTH',
  };
  static const _heightWords = {'S': 'SMALL', 'M': 'MEDIUM', 'L': 'LARGE'};
  static const _textSizes = [12, 13, 14, 15, 16, 18];

  int get _widthIndex =>
      ScreenLayout.widths.values.toList().indexOf(_width);
  int get _heightIndex =>
      ScreenLayout.heights.values.toList().indexOf(_height);

  Future<void> _pickTextSize() async {
    final picked = await pickOption(
      context,
      title: 'Text size',
      options: [for (final size in _textSizes) '$size px'],
      current: '$_textSize px',
    );
    if (picked == null || !mounted) return;
    setState(() => _textSize = int.parse(picked.split(' ').first));
  }

  Future<void> _pickSurface() async {
    final picked = await pickOption(
      context,
      title: 'Widget style',
      options: [for (final s in CardSurface.all) CardSurface.names[s]!],
      current: CardSurface.names[_surface]!,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _surface = CardSurface.all.firstWhere(
        (s) => CardSurface.names[s] == picked,
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop<WidgetStyle>((
      color: _color,
      // The design size is stored as "not changed".
      textSize: _textSize == CardTint.baseTextSize ? null : _textSize,
      surface: _surface == CardSurface.soft ? null : _surface,
      size: (_width, _height),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final color = _color;
    final label = AppText.s(13, color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'Style your widget',
              subtitle:
                  '${studioName(widget.type)} · ${tr(widget.layoutName)}',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _preview(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('Color'),
                          style: AppText.s(15, weight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        tr(
                          color == null
                              ? 'Default'
                              : AppColors.accentNames[color],
                        ),
                        style: AppText.s(12, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < AppColors.accents.length; i++)
                        _ColorDot(
                          color: AppColors.accents[i],
                          label: AppColors.accentNames[i],
                          selected: color == i,
                          // Tapping the chosen color again goes back to the
                          // widget's own color.
                          onTap: () =>
                              setState(() => _color = color == i ? null : i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceBox(
                          label: 'Typography',
                          value:
                              app.settings.typography ??
                              app.selectedTheme.typography,
                          onTap: () => pickTypography(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChoiceBox(
                          label: 'Text size',
                          value: '$_textSize px',
                          onTap: _pickTextSize,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('Layout'),
                    style: AppText.s(15, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  PillSwitch(
                    labels: _widthNames,
                    index: _widthIndex,
                    onChanged: (i) => setState(
                      () => _width = ScreenLayout.widths[_widthNames[i]]!,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Widget size'), style: label),
                            const SizedBox(height: 8),
                            PillSwitch(
                              labels: _heightNames,
                              index: _heightIndex,
                              onChanged: (i) => setState(
                                () => _height =
                                    ScreenLayout.heights[_heightNames[i]]!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Widget style'), style: label),
                            const SizedBox(height: 8),
                            _ChoiceBox(
                              label: 'Surface',
                              value: tr(CardSurface.names[_surface]!),
                              onTap: _pickSurface,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(tr(CardSurface.notes[_surface]!), style: label),
                ],
              ),
            ),
            StudioActions(
              children: [
                StudioButton(
                  label: 'Cancel',
                  soft: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                StudioButton(label: 'Save style', onTap: _save),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final height = _heightIndex < 0
        ? ''
        : _heightWords[_heightNames[_heightIndex]]!;
    final width = _widthIndex < 0
        ? ''
        : _widthWords[_widthNames[_widthIndex]]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trf('PREVIEW · {size}', {
              'size': [tr(height), tr(width)].where((w) => w.isNotEmpty).join(' / '),
            }),
            style: AppText.s(10, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final full = constraints.maxWidth;
              final gap = gridGap(full);
              final size = Size(
                _width * gridPitch(full) - gap,
                _height * gridRowPitch(full) - gap,
              );
              return Center(
                child: widgetCell(
                  widget.type,
                  lock: widget.lock,
                  size: size,
                  scale: full / gridDesignWidth,
                  color: _color,
                  textSize: _textSize,
                  surface: _surface,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Bordered box with a label, a value and a chevron.
class _ChoiceBox extends StatelessWidget {
  const _ChoiceBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(label),
                    style: AppText.s(10, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: AppText.s(13)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tr(label),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: selected
                  ? Icon(
                      LucideIcons.check,
                      size: 16,
                      color: AppColors.onPrimary,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
