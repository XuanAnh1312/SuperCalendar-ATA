import 'package:flutter/material.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/core/services/wallpaper_export.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/widget_grid.dart';
import 'package:flutter_application/features/lock_screen/presentation/screens/lock_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

/// Clean scene shared by manual exports and the daily background renderer.
/// Device frames, selection handles and simulated system UI are outside it.
class WallpaperScene extends StatelessWidget {
  const WallpaperScene({
    super.key,
    required this.layout,
    required this.dimensions,
    this.gridKey,
    this.cellBuilder,
  });
  final ScreenLayout layout;
  final WallpaperDimensions dimensions;
  final Key? gridKey;
  final Widget Function(LayoutItem, Size, double)? cellBuilder;
  @override
  Widget build(BuildContext context) {
    final lock = layout.id == ScreenLayout.lock;
    final height = dimensions.canvasHeight(330);
    return LayoutBackground(
      layout: layout,
      fallback: lock
          ? lockScreenDecoration()
          : BoxDecoration(color: AppColors.background),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            right: 18,
            top: lock ? height * 242 / 520 : 18,
            bottom: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 294,
                child: WidgetGrid(
                  key: gridKey,
                  layout: layout,
                  minRows: layout.rows,
                  cellBuilder:
                      cellBuilder ??
                      (item, size, scale) => widgetCell(
                        item.type,
                        lock: lock,
                        size: size,
                        scale: scale,
                        color: item.color,
                        textSize: item.textSize,
                        surface: item.surface,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
