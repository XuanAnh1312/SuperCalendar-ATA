import 'package:flutter/material.dart';

/// Color tokens of the default "Pastel Minimal" theme, taken from the Figma file.
abstract final class AppColors {
  static const background = Color(0xFFF8F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6E8EC);

  static const text = Color(0xFF202124);
  static const muted = Color(0xFF767B85);
  static const faint = Color(0xFFA9AEB7);

  static const primary = Color(0xFF6D66D9);
  static const primaryTint = Color(0xFF827CDF);
  static const primarySoft = Color(0xFFEFEDFF);

  // Pastel surfaces.
  static const pink = Color(0xFFF7DDE7);
  static const blue = Color(0xFFDDEBFA);
  static const green = Color(0xFFDDF1E6);
  static const yellow = Color(0xFFF8EFCB);
  static const purple = Color(0xFFE9E2FA);
  static const note = Color(0xFFFFF9DA);

  // Accents.
  static const greenStrong = Color(0xFF3F9B72);
  static const greenDot = Color(0xFF54A77B);
  static const pinkStrong = Color(0xFFE47B98);
  static const yellowStrong = Color(0xFFD3A938);
  static const blueStrong = Color(0xFF699AD1);
  static const yellowText = Color(0xFF8B7021);
  static const amber = Color(0xFFA8751F);
  static const danger = Color(0xFFD95766);

  /// Accent choices offered by the color pickers.
  static const accents = [primary, pinkStrong, greenDot, yellowStrong];

  /// Pastel surface matching each entry of [accents].
  static const accentSurfaces = [purple, pink, green, yellow];
}
