import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_colors.dart';

abstract final class AppText {
  static const family = 'Inter';

  /// Inter text style. The bundled font is variable, so the weight is also
  /// passed as a `wght` variation.
  static TextStyle s(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double height = 1.21,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: color,
      // Slight tightening so text widths match the Figma rendering of Inter.
      letterSpacing: letterSpacing ?? -0.011 * size,
    );
  }

  static TextStyle title({Color color = AppColors.text}) => s(24, color: color);
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
