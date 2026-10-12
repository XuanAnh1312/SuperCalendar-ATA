import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';

abstract final class AppText {
  static const family = 'Inter';

  /// Inter text style. The bundled font is variable, so the weight is also
  /// passed as a `wght` variation. The active theme's typography shifts the
  /// weight or tracking.
  static TextStyle s(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.21,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    final typography = AppTheme.current.typography;
    var wght = weight.value;
    // Slight tightening so text widths match the Figma rendering of Inter.
    var tracking = -0.011 * size;
    if (typography == AppThemeData.typographyBold) {
      wght = (wght + 100).clamp(100, 900);
    } else if (typography == AppThemeData.typographyAiry) {
      wght = (wght - 100).clamp(300, 900);
      tracking = 0.012 * size;
    }
    final resolved = color ?? AppColors.text;
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.values[(wght ~/ 100) - 1],
      fontVariations: [FontVariation('wght', wght.toDouble())],
      color: resolved,
      height: height,
      decoration: decoration,
      decorationColor: resolved,
      letterSpacing: letterSpacing ?? tracking,
    );
  }

  static TextStyle title({Color? color}) => s(24, color: color);
  static TextStyle subtitle() => s(12, color: AppColors.muted);
  static TextStyle cardTitle() => s(14, weight: FontWeight.w700);
  static TextStyle action() =>
      s(12, weight: FontWeight.w600, color: AppColors.primary);
  static TextStyle label() => s(
    10,
    weight: FontWeight.w600,
    color: AppColors.muted,
    letterSpacing: 0.2,
  );
}
