import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/utils/strings.dart';

List<BoxShadow> get softShadow => [
  BoxShadow(
    color: AppTheme.palette.dark
        ? const Color(0x33000000)
        : const Color(0x0F1F2433),
    blurRadius: 12,
    offset: const Offset(0, 3),
  ),
];

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(tr(message)),
        duration: const Duration(milliseconds: 1600),
      ),
    );
}

/// Snack bar with an Undo button, shown for 5 seconds after a delete (BR-13).
void showUndoSnack(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(tr(message)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: tr('Undo'), onPressed: onUndo),
      ),
    );
}

/// Icon of a habit, looked up from the key stored with it.
IconData habitIcon(String key) => switch (key) {
  'brain' => LucideIcons.brain,
  'book' => LucideIcons.bookOpen,
  'walk' => LucideIcons.footprints,
  _ => LucideIcons.check,
};

/// Rounded surface used for every widget card. Radius and inner padding
/// default to the active theme's values.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.radius,
    this.borderColor,
    this.borderWidth = 1,
    this.shadow = true,
    this.onTap,
  });

  final Widget child;

  /// Defaults to the theme surface.
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(AppTheme.current.spacing),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius ?? AppTheme.current.radius),
        border: Border.all(
          color:
              borderColor ??
              (color == null ? AppColors.border : Colors.transparent),
          width: borderWidth,
        ),
        boxShadow: shadow ? softShadow : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

/// Title on the left, optional primary-colored action on the right.
class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tr(title),
            style: AppText.cardTitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Text(tr(action!), style: AppText.action()),
          ),
      ],
    );
  }
}

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 20,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.faint,
            width: 1.5,
          ),
        ),
        child: value
            ? Icon(
                LucideIcons.check,
                size: size * 0.65,
                color: AppColors.onPrimary,
              )
            : null,
      ),
    );
  }
}

/// Small filter chip (`All 6`, `Daily`, `Canvas`...).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(11),
        ),
        // widthFactor keeps the pill as wide as its label inside a Wrap.
        child: Center(
          widthFactor: 1,
          child: Text(
            tr(label),
            style: AppText.s(
              10,
              color: selected ? AppColors.onPrimary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class FilterPillRow extends StatelessWidget {
  const FilterPillRow({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (var i = 0; i < labels.length; i++)
          FilterPill(
            label: labels[i],
            selected: i == index,
            onTap: () => onChanged(i),
          ),
      ],
    );
  }
}

/// Small rounded label, optionally with an icon and a tap action.
class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.textColor,
    this.onTap,
  });

  final String label;
  final IconData? icon;

  /// Defaults to the soft primary tint.
  final Color? color;
  final Color? textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = textColor ?? AppColors.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: color ?? AppColors.primarySoft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(tr(label), style: AppText.s(10, color: foreground)),
          ],
        ),
      ),
    );
  }
}

/// Two-option pill switch (`Month | Week`, `LOCK | HOME`).
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minWidth: 58),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tr(labels[i]),
                  style: AppText.s(
                    11,
                    weight: FontWeight.w600,
                    color: i == index ? AppColors.onPrimary : AppColors.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular button: surface-colored with an icon, or filled primary.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.filled = false,
    this.background,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;
  final Color? background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : background ?? AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: filled ? softShadow : null,
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: filled ? AppColors.onPrimary : iconColor ?? AppColors.text,
        ),
      ),
    );
  }
}

/// Full-width filled call-to-action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 48,
    this.radius = 16,
    this.soft = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;
  final double radius;

  /// Soft tint background with primary text instead of the filled style.
  final bool soft;

  /// Destructive variant (red text on a soft background).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = danger
        ? AppColors.danger
        : soft
        ? AppColors.primary
        : AppColors.onPrimary;
    return Material(
      color: danger
          ? AppColors.pink
          : soft
          ? AppColors.primarySoft
          : AppColors.primary,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(
                    height >= 44 ? 14 : 11.5,
                    weight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Surface button with a primary outline (`+ CREATE MORE`, `EDIT`).
class OutlinedActionButton extends StatelessWidget {
  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.background,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? background;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(
                    12,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 14), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Large page title with a muted subtitle and an optional trailing widget.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      tr(title),
                      style: AppText.title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                tr(subtitle),
                style: AppText.subtitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Top bar of a pushed page: round back/close button, centered title and an
/// optional trailing action.
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    this.close = false,
    this.trailing,
  });

  final String title;

  /// Shows an X instead of a back arrow.
  final bool close;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(
          icon: close ? LucideIcons.x : LucideIcons.arrowLeft,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Center(
            child: Text(
              tr(title),
              style: AppText.s(18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Keeps the title centered when there is no trailing action.
        trailing ?? const SizedBox(width: 38),
      ],
    );
  }
}

/// Text button used as a top bar action (`Save`).
class TopBarAction extends StatelessWidget {
  const TopBarAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          tr(label),
          style: AppText.s(
            13,
            weight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// `M 5  T 6  W 7 ...` strip with a colored dot under each day.
class WeekDots extends StatelessWidget {
  const WeekDots({
    super.key,
    required this.labels,
    required this.colors,
    this.activeIndex = 0,
    this.onTap,
  });

  final List<String> labels;
  final List<Color> colors;
  final int activeIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[i],
                    style: AppText.s(
                      10,
                      weight: i == activeIndex
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == activeIndex
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// `☁ Saved & synced` status line of the quick note.
class SavedStatus extends StatelessWidget {
  const SavedStatus({super.key, this.label = 'Saved & synced', this.size = 9});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.cloudCheck,
          size: size + 2,
          color: AppColors.greenStrong,
        ),
        SizedBox(width: size * 0.5),
        Text(tr(label), style: AppText.s(size, color: AppColors.greenStrong)),
      ],
    );
  }
}

/// Row of selectable accent color dots.
class ColorDots extends StatelessWidget {
  const ColorDots({
    super.key,
    required this.colors,
    required this.index,
    required this.onChanged,
    this.size = 13,
    this.spacing = 7,
  });

  final List<Color> colors;

  /// Selected dot; null when none is selected.
  final int? index;
  final ValueChanged<int> onChanged;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < colors.length; i++)
          Padding(
            padding: EdgeInsets.only(
              right: i == colors.length - 1 ? 0 : spacing,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: i == index
                      ? Border.all(color: AppColors.text, width: 1.5)
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Icon + uppercase label + value row used by the event and task editors.
class FieldTile extends StatelessWidget {
  const FieldTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.chevron = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(label).toUpperCase(), style: AppText.label()),
                  const SizedBox(height: 3),
                  Text(tr(value), style: AppText.s(13, height: 1.35)),
                ],
              ),
            ),
            if (chevron && onTap != null)
              Icon(LucideIcons.chevronRight, size: 14, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

/// Field with an icon and label whose value is edited in place.
class InlineField extends StatelessWidget {
  const InlineField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    required this.hint,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(label).toUpperCase(), style: AppText.label()),
                TextField(
                  controller: controller,
                  maxLines: multiline ? null : 1,
                  style: AppText.s(13, height: 1.4),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 3),
                    hintText: tr(hint),
                    hintStyle: AppText.s(13, color: AppColors.faint),
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

/// Row of a settings list: tinted icon tile, title, optional value/trailing.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? value;

  /// Replaces the chevron (e.g. a switch).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppColors.text),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(title),
                    style: AppText.s(12.5, weight: FontWeight.w600),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      tr(subtitle!),
                      style: AppText.s(
                        9.5,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(tr(value!), style: AppText.s(10.5, color: AppColors.muted)),
            ],
            const SizedBox(width: 10),
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AppColors.faint,
                ),
          ],
        ),
      ),
    );
  }
}

/// A card holding [SettingsRow]s separated by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: Colors.transparent,
      shadow: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.current.radius),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.border),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact on/off switch in the theme's colors.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: FittedBox(
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.onPrimary,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: AppColors.faint,
          inactiveTrackColor: AppColors.subtle,
        ),
      ),
    );
  }
}

/// Centered hint shown when a list has nothing in it (UI-11).
///
/// Every screen uses this widget for its empty state so the icon, spacing and
/// wording stay consistent across the app. [compact] is the tight variant for
/// small dashboard cards and mini previews.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.compact = false,
  });

  final IconData icon;

  /// Already translated when it carries placeholders — [tr] falls back to the
  /// given text.
  final String message;

  /// Smaller icon, text and padding for cards with little room.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 14.0 : 22.0;
    final textSize = compact ? 9.5 : 11.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 6 : 28,
        horizontal: compact ? 4 : 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.faint),
          SizedBox(height: compact ? 5 : 8),
          Text(
            tr(message),
            textAlign: TextAlign.center,
            style: AppText.s(textSize, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with a list of options; resolves to the chosen one.
Future<String?> pickOption(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(tr(title), style: AppText.cardTitle()),
            ),
            for (final option in options)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                title: Text(tr(option), style: AppText.s(13)),
                trailing: option == current
                    ? Icon(
                        LucideIcons.check,
                        size: 16,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// Dialog asking for a single line of text.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr(title), style: AppText.cardTitle()),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: AppText.s(13),
        decoration: InputDecoration(hintText: tr(hint)),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(tr('OK')),
        ),
      ],
    ),
  );
}

/// Yes/no confirmation; resolves to true when confirmed.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr(title), style: AppText.cardTitle()),
      content: Text(tr(message), style: AppText.s(12.5, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr(cancelLabel)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr(confirmLabel)),
        ),
      ],
    ),
  );
  return result ?? false;
}

const reminderOptions = <int?>[null, 5, 15, 30, 60];

/// Bottom sheet for choosing a reminder lead time. Resolves to the minutes,
/// or `-1` for "None"; null when dismissed.
Future<int?> pickReminder(BuildContext context, int? current) async {
  final picked = await pickOption(
    context,
    title: 'Reminder',
    options: [for (final m in reminderOptions) formatReminder(m)],
    current: formatReminder(current),
  );
  if (picked == null) return null;
  return reminderOptions.firstWhere((m) => formatReminder(m) == picked) ?? -1;
}

/// Paints a user-chosen background image behind [child], with a wash of the
/// theme background on top so content stays readable.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({super.key, required this.child, this.imagePath});

  final Widget child;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(path),
          fit: BoxFit.cover,
          // A deleted or unreadable file falls back to the plain background.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        ColoredBox(color: AppColors.background.withValues(alpha: 0.55)),
        child,
      ],
    );
  }
}
