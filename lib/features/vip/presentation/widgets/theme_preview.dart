import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_palette.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// Miniature dashboard drawn with [theme]'s colors, radius and spacing, so a
/// template can be judged before it is applied.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.theme, this.height = 150});

  final AppThemeData theme;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.build(
      primary: theme.primary,
      dark: AppTheme.palette.dark,
    );
    final radius = theme.radius * 0.6;
    Widget card(Color color, {required Widget child}) => Container(
      padding: EdgeInsets.all(theme.spacing * 0.6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    Widget line(double width, Color color) => Container(
      width: width,
      height: 5,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );

    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: palette.primary, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: card(
              palette.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Today'),
                    style: AppText.s(
                      10,
                      weight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  for (final color in [
                    palette.blue,
                    palette.green,
                    palette.pink,
                  ])
                    Container(
                      height: 18,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(radius * 0.5),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 5),
                      child: Container(
                        width: 2.5,
                        height: 10,
                        color: palette.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: card(
                    palette.green,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        line(34, palette.text),
                        line(22, palette.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Text(
                    tr(theme.typography.split(' · ').last),
                    style: AppText.s(
                      9,
                      weight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
