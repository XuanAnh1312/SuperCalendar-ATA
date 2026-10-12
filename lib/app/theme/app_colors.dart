import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_palette.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';

/// Color tokens of the active theme. Screens read colors only from here, so
/// switching theme, dark mode or accent recolors the whole app.
abstract final class AppColors {
  static AppPalette get _p => AppTheme.palette;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get border => _p.border;
  static Color get subtle => _p.subtle;

  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get faint => _p.faint;

  static Color get primary => _p.primary;
  static Color get primaryTint => _p.primaryTint;
  static Color get primarySoft => _p.primarySoft;

  /// Text and icons drawn on top of [primary].
  static const onPrimary = Colors.white;

  // Pastel surfaces.
  static Color get pink => _p.pink;
  static Color get blue => _p.blue;
  static Color get green => _p.green;
  static Color get yellow => _p.yellow;
  static Color get purple => _p.purple;
  static Color get note => _p.note;

  static Color get lockTop => _p.lockTop;
  static Color get lockMid => _p.lockMid;
  static Color get lockBottom => _p.lockBottom;
  static Color get lockCard => _p.lockCard;
  static Color get shadeTop => _p.shadeTop;
  static Color get shadeBottom => _p.shadeBottom;
  static Color get dotDone => _p.dotDone;
  static Color get dotIdle => _p.dotIdle;

  // Fixed accents: these label data (event colors, status), so they do not
  // follow the theme.
  static const lavender = Color(0xFF6D66D9);
  static const greenStrong = Color(0xFF3F9B72);
  static const greenDot = Color(0xFF54A77B);
  static const pinkStrong = Color(0xFFE47B98);
  static const yellowStrong = Color(0xFFD3A938);
  static const blueStrong = Color(0xFF699AD1);
  static const amber = Color(0xFFA8751F);
  static const danger = Color(0xFFD95766);

  static Color get yellowText =>
      _p.dark ? const Color(0xFFE3C768) : const Color(0xFF8B7021);

  /// Label colors offered by the color pickers (index is what gets stored).
  static const accents = [
    lavender,
    pinkStrong,
    greenDot,
    yellowStrong,
    blueStrong,
  ];
  static const accentNames = ['Lavender', 'Rose', 'Mint', 'Honey', 'Sky'];

  /// Pastel surface matching each entry of [accents].
  static List<Color> get accentSurfaces => [purple, pink, green, yellow, blue];

  static Color accent(int index) => accents[index % accents.length];
  static Color accentSurface(int index) =>
      accentSurfaces[index % accents.length];
}
