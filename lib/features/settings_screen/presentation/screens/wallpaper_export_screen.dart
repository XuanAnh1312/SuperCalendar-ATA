import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/wallpaper_service.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

/// "Your wallpaper is ready" (Personalize 24): the clean export was saved to
/// Photos (AC-28); it is applied only when the user taps Set Wallpaper.
class WallpaperExportScreen extends StatefulWidget {
  const WallpaperExportScreen({
    super.key,
    required this.image,
    required this.wallpaperName,
    required this.lockScreen,
  });

  /// PNG of the wallpaper and widgets, without system overlays.
  final Uint8List image;
  final String wallpaperName;
  final bool lockScreen;

  @override
  State<WallpaperExportScreen> createState() => _WallpaperExportScreenState();
}

class _WallpaperExportScreenState extends State<WallpaperExportScreen> {
  bool _applied = false;
  bool _busy = false;

  Future<void> _setWallpaper() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await WallpaperService.instance.setWallpaper(
      widget.image,
      lockScreen: widget.lockScreen,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _applied = ok;
    });
    showAppSnack(context, ok ? 'Wallpaper set' : 'Could not set the wallpaper');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'Your wallpaper is ready',
              subtitle: '${widget.wallpaperName} · ${tr('Clean export')}',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleCheck,
                          size: 22,
                          color: AppColors.greenStrong,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Image saved'),
                                style: AppText.s(
                                  14,
                                  weight: FontWeight.w600,
                                  color: AppColors.greenStrong,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tr('Your clean wallpaper is saved to Photos.'),
                                style: AppText.s(11, color: AppColors.text),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        widget.image,
                        width: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      tr('Wallpaper artwork + widgets only'),
                      style: AppText.s(11, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(_applied ? 'Applied' : 'Saved, not applied'),
                          style: AppText.s(14, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(
                            _applied
                                ? 'It is now your wallpaper.'
                                : 'Choose Set Wallpaper to apply it. Your current wallpaper hasn’t changed.',
                          ),
                          style: AppText.s(
                            12,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            StudioActions(
              children: [
                StudioButton(
                  label: 'Back to studio',
                  soft: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                StudioButton(label: 'Set Wallpaper', onTap: _setWallpaper),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
