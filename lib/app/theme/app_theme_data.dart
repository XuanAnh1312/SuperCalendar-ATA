import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_palette.dart';

/// The Theme model of the spec: a named bundle of colors, typography,
/// spacing, radius and lock screen style. It holds no user data.
class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.primary,
    this.typography = typographyClean,
    this.spacing = 12,
    this.radius = 18,
    this.lockScreenStyle = lockStyleGradient,
    this.builtIn = false,
  });

  factory AppThemeData.fromJson(Map<String, dynamic> json) {
    final colors = (json['colors'] as Map?) ?? const {};
    return AppThemeData(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Custom',
      primary: Color((colors['primary'] as int?) ?? 0xFF6D66D9),
      typography: json['typography'] as String? ?? typographyClean,
      spacing: (json['spacing'] as num?)?.toDouble() ?? 12,
      radius: (json['radius'] as num?)?.toDouble() ?? 18,
      lockScreenStyle: json['lockScreenStyle'] as String? ?? lockStyleGradient,
    );
  }

  static const typographyClean = 'Inter · Clean';
  static const typographyBold = 'Inter · Bold';
  static const typographyAiry = 'Inter · Airy';
  static const typographies = [typographyClean, typographyBold, typographyAiry];

  static const lockStyleGradient = 'gradient';
  static const lockStylePlain = 'plain';

  final String id;
  final String name;

  /// Seed of the color set; the rest of the palette is derived from it.
  final Color primary;
  final String typography;

  /// Inner padding of cards.
  final double spacing;

  /// Corner radius of cards.
  final double radius;
  final String lockScreenStyle;
  final bool builtIn;

  AppThemeData copyWith({
    String? id,
    String? name,
    Color? primary,
    String? typography,
    double? spacing,
    double? radius,
    String? lockScreenStyle,
  }) {
    return AppThemeData(
      id: id ?? this.id,
      name: name ?? this.name,
      primary: primary ?? this.primary,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      lockScreenStyle: lockScreenStyle ?? this.lockScreenStyle,
      builtIn: builtIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colors': {'primary': primary.toARGB32()},
    'typography': typography,
    'spacing': spacing,
    'radius': radius,
    'lockScreenStyle': lockScreenStyle,
  };
}

/// Themes shipped with the app. `pastel_minimal` is the default.
const builtInThemes = [
  AppThemeData(
    id: 'pastel_minimal',
    name: 'Pastel Minimal',
    primary: Color(0xFF6D66D9),
    builtIn: true,
  ),
  AppThemeData(
    id: 'pastel_blue',
    name: 'Pastel Blue',
    primary: Color(0xFF4F8FD9),
    builtIn: true,
  ),
  AppThemeData(
    id: 'pastel_green',
    name: 'Pastel Green',
    primary: Color(0xFF3F9B72),
    builtIn: true,
  ),
  AppThemeData(
    id: 'minimal_gray',
    name: 'Minimal Gray',
    primary: Color(0xFF4B5563),
    lockScreenStyle: AppThemeData.lockStylePlain,
    builtIn: true,
  ),
];

/// The theme currently applied to the app. Set through [apply]; read by
/// `AppColors`, `AppText` and the shared widgets.
abstract final class AppTheme {
  static AppThemeData _current = builtInThemes.first;
  static AppPalette _palette = AppPalette.build(
    primary: builtInThemes.first.primary,
    dark: false,
  );

  static AppThemeData get current => _current;
  static AppPalette get palette => _palette;

  /// Applies [theme]. [accent] and [typography] are the user's overrides from
  /// Settings → Appearance and win over the theme's own values.
  static void apply(
    AppThemeData theme, {
    bool dark = false,
    Color? accent,
    String? typography,
  }) {
    _current = theme.copyWith(primary: accent, typography: typography);
    _palette = AppPalette.build(primary: _current.primary, dark: dark);
  }
}
