import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';

/// Width of the widget area in the Personalize design; every grid measure is
/// a fraction of it so the grid looks the same at any size.
const gridDesignWidth = 294.0;

/// Space between cells, as in the design (12 of 294).
double gridGap(double width) => width * 12 / gridDesignWidth;

/// Width of one column plus its gap.
double gridPitch(double width) =>
    (width + gridGap(width)) / ScreenLayout.columns;

/// Height of one row plus its gap; rows are a little taller than columns.
double gridRowPitch(double width) => gridPitch(width) * 1.2;

/// Narrowest width a home card is laid out at.
const minCardWidth = 172.0;

/// Narrowest width a lock screen card is laid out at.
const minLockCardWidth = 220.0;

/// Lays the visible widgets of a [layout] out on its grid (FR-03, FR-19).
/// Home, Lock Screen and Edit Your Screen all use it, so a widget shows up
/// where it was placed (AC-08).
class WidgetGrid extends StatelessWidget {
  const WidgetGrid({
    super.key,
    required this.layout,
    required this.cellBuilder,
    this.minRows = 0,
  });

  final ScreenLayout layout;

  /// Builds one widget; [scale] is the grid width over the design width.
  final Widget Function(LayoutItem item, Size size, double scale) cellBuilder;

  /// Rows to reserve even when they are empty (the editor canvas).
  final int minRows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gap = gridGap(width);
        final pitch = gridPitch(width);
        final rowPitch = gridRowPitch(width);
        final scale = width / gridDesignWidth;
        final items = layout.visibleItems;
        var rows = minRows;
        for (final item in items) {
          if (item.y + item.h > rows) rows = item.y + item.h;
        }
        return SizedBox(
          height: rows == 0 ? 0 : rows * rowPitch - gap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final item in items)
                Positioned(
                  key: ValueKey(item.type),
                  left: item.x * pitch,
                  top: item.y * rowPitch,
                  width: item.w * pitch - gap,
                  height: item.h * rowPitch - gap,
                  child: cellBuilder(
                    item,
                    Size(item.w * pitch - gap, item.h * rowPitch - gap),
                    scale,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Fits a widget card into its grid cell and applies its Style choices.
///
/// With [scale], the card is laid out at design size and scaled to the cell,
/// so a wallpaper widget keeps the design's proportions on every screen.
/// Without it, the card is laid out at least [minWidth] wide and scaled down
/// when its content is taller than the cell.
class GridCell extends StatelessWidget {
  const GridCell({
    super.key,
    required this.size,
    required this.child,
    this.color,
    this.textSize,
    this.surface,
    this.minWidth = minCardWidth,
    this.scale,
  });

  /// Shortcut taking the Style choices from a layout [item].
  GridCell.of(
    LayoutItem item, {
    Key? key,
    required Size size,
    required Widget child,
    double minWidth = minCardWidth,
    double? scale,
  }) : this(
         key: key,
         size: size,
         color: item.color,
         textSize: item.textSize,
         surface: item.surface,
         minWidth: minWidth,
         scale: scale,
         child: child,
       );

  final Size size;
  final Widget child;
  final double minWidth;
  final double? scale;

  /// Accent index chosen in Style; null keeps the widget's own color.
  final int? color;

  /// Text size in px chosen in Style; null keeps the design size (14 px).
  final int? textSize;

  /// A [CardSurface]; null is soft cards.
  final String? surface;

  @override
  Widget build(BuildContext context) {
    final index = color;
    final size = textSize;
    Widget tinted = CardTint(
      color: index == null ? null : AppColors.accentSurface(index),
      surface: surface ?? CardSurface.soft,
      child: child,
    );
    if (size != null) {
      tinted = MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(size / CardTint.baseTextSize),
        ),
        child: tinted,
      );
    }
    final factor = scale;
    if (factor != null) {
      return SizedBox.fromSize(
        size: this.size,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: this.size.width / factor,
            height: this.size.height / factor,
            child: tinted,
          ),
        ),
      );
    }
    return SizedBox.fromSize(
      size: this.size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          // Cards are designed for about half a phone width; narrower cells
          // get the card at that width, scaled down, instead of overflowing.
          width: math.max(this.size.width, minWidth),
          child: tinted,
        ),
      ),
    );
  }
}

/// Style choices for the widget card below it: color and surface.
class CardTint extends InheritedWidget {
  const CardTint({
    super.key,
    required this.color,
    this.surface = CardSurface.soft,
    required super.child,
  });

  /// Text size the cards are designed at.
  static const baseTextSize = 14;

  final Color? color;
  final String surface;

  static CardTint? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardTint>();

  /// Color picked in Style, or null.
  static Color? of(BuildContext context) => _of(context)?.color;

  /// Fill of a card whose own color is [base] (null: the theme surface).
  static Color? fill(BuildContext context, Color? base) {
    final tint = _of(context);
    final color = tint?.color ?? base;
    return switch (tint?.surface) {
      CardSurface.solid => (color ?? AppColors.surface).withValues(alpha: 1),
      CardSurface.outline => Colors.transparent,
      _ => color,
    };
  }

  /// Border of an outline card; null keeps the card's own border.
  static Color? border(BuildContext context) =>
      _of(context)?.surface == CardSurface.outline ? AppColors.primary : null;

  @override
  bool updateShouldNotify(CardTint oldWidget) =>
      oldWidget.color != color || oldWidget.surface != surface;
}

/// Decoration of a built-in [Wallpaper]; null for the theme background.
BoxDecoration? wallpaperDecoration(String key) {
  if (key == Wallpaper.softMorning) {
    return const BoxDecoration(
      image: DecorationImage(
        image: AssetImage(Wallpaper.softMorningAsset),
        fit: BoxFit.cover,
      ),
    );
  }
  final solid = Wallpaper.solidIndex(key);
  if (solid != null) {
    return BoxDecoration(color: AppColors.accentSurface(solid));
  }
  List<Color>? colors = switch (key) {
    Wallpaper.quietGarden => [AppColors.green, AppColors.surface, AppColors.green],
    Wallpaper.lavenderHaze => [
      AppColors.purple,
      AppColors.pink,
      AppColors.primarySoft,
    ],
    _ => null,
  };
  if (colors == null) return null;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ),
  );
}

/// Paints a layout's wallpaper (or [fallback] for the theme background),
/// with the VIP photo on top when there is one.
class LayoutBackground extends StatelessWidget {
  const LayoutBackground({
    super.key,
    required this.layout,
    required this.child,
    this.fallback,
  });

  final ScreenLayout layout;
  final Widget child;
  final BoxDecoration? fallback;

  @override
  Widget build(BuildContext context) {
    final decoration = wallpaperDecoration(layout.wallpaper) ?? fallback;
    final content = ScreenBackground(
      imagePath: layout.backgroundPath,
      child: child,
    );
    if (decoration == null) return content;
    return DecoratedBox(decoration: decoration, child: content);
  }
}
