import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

/// Returned by the gallery when the user wants a photo of their own.
const wallpaperPhoto = 'photo';

/// Name of a wallpaper key, a solid color or [wallpaperPhoto].
String wallpaperName(String key) {
  if (key == wallpaperPhoto) return tr('Your photo');
  final solid = Wallpaper.solidIndex(key);
  if (solid != null) return tr(AppColors.accentNames[solid]);
  return tr(Wallpaper.names[key] ?? Wallpaper.names[Wallpaper.theme]!);
}

/// "A softer backdrop" (Personalize 21): picks the wallpaper behind the
/// widgets. Resolves to a [Wallpaper] key or [wallpaperPhoto].
class WallpaperGalleryScreen extends StatefulWidget {
  const WallpaperGalleryScreen({super.key, required this.current});

  final String current;

  @override
  State<WallpaperGalleryScreen> createState() => _WallpaperGalleryScreenState();
}

class _WallpaperGalleryScreenState extends State<WallpaperGalleryScreen> {
  late String _picked = widget.current;
  int _filter = 0;

  static const _filters = ['All', 'Photos', 'Textures', 'Colors'];

  /// Solid colors in the order of the design (lavender, mint, rose, honey).
  static const _solids = [0, 2, 1, 3];

  bool _shows(int filter) => _filter == 0 || _filter == filter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final photoLocked = !app.canAccess(VipFeature.backgroundImages);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'A softer backdrop',
              subtitle: tr('Wallpaper gallery'),
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: PillSwitch(
                labels: _filters,
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final column = (constraints.maxWidth - 40 - 12) / 2;
                  Widget tile(String key, String hint, {bool locked = false}) =>
                      _Tile(
                        width: column,
                        keyName: key,
                        hint: hint,
                        locked: locked,
                        selected: _picked == key,
                        onTap: () => setState(() => _picked = key),
                      );
                  final tiles = <Widget>[
                    if (_shows(1)) tile(Wallpaper.softMorning, 'Landscape art'),
                    if (_shows(1)) tile(Wallpaper.quietGarden, 'Soft greens'),
                    if (_shows(2))
                      tile(Wallpaper.lavenderHaze, 'Texture · Gentle gradient'),
                    if (_shows(3))
                      SizedBox(
                        width: column,
                        child: _SolidColors(
                          picked: _picked,
                          solids: _solids,
                          onPick: (key) => setState(() => _picked = key),
                        ),
                      ),
                    if (_shows(1))
                      tile(wallpaperPhoto, 'Photo · VIP', locked: photoLocked),
                    if (_shows(2)) tile(Wallpaper.theme, 'Follows your theme'),
                  ];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      Wrap(spacing: 12, runSpacing: 16, children: tiles),
                      const SizedBox(height: 16),
                      Text(
                        tr(
                          'Your widgets stay in place when you change the background.',
                        ),
                        style: AppText.s(
                          12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            StudioActions(
              children: [
                StudioButton(
                  label: trf('Use {name}', {'name': wallpaperName(_picked)}),
                  onTap: () => Navigator.of(context).pop(_picked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.width,
    required this.keyName,
    required this.hint,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final double width;
  final String keyName;
  final String hint;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = keyName == wallpaperPhoto;
    final decoration = photo
        ? BoxDecoration(color: AppColors.subtle)
        : wallpaperDecoration(keyName) ??
              BoxDecoration(color: AppColors.background);
    return Semantics(
      button: true,
      selected: selected,
      label: wallpaperName(keyName),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: width * 1.4,
                decoration: decoration.copyWith(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: photo
                    ? Center(
                        child: Icon(
                          locked ? LucideIcons.lockKeyhole : LucideIcons.image,
                          size: 26,
                          color: AppColors.muted,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                wallpaperName(keyName),
                style: AppText.s(15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                selected ? '✓ ${tr('Selected')} · ${tr(hint)}' : tr(hint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.s(
                  12,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Solid colors": a 2 × 2 grid of plain backgrounds.
class _SolidColors extends StatelessWidget {
  const _SolidColors({
    required this.picked,
    required this.solids,
    required this.onPick,
  });

  final String picked;
  final List<int> solids;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final swatch = (constraints.maxWidth - 10) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Solid colors'),
              style: AppText.s(15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final i in solids)
                  Semantics(
                    button: true,
                    selected: picked == Wallpaper.solid(i),
                    label: tr(AppColors.accentNames[i]),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onPick(Wallpaper.solid(i)),
                      child: Container(
                        width: swatch,
                        height: swatch,
                        decoration: BoxDecoration(
                          color: AppColors.accentSurface(i),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: picked == Wallpaper.solid(i)
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tr('Keep things simple'),
              style: AppText.s(12, color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }
}
