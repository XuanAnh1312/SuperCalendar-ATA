import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';

const softShadow = [
  BoxShadow(color: Color(0x0F1F2433), blurRadius: 12, offset: Offset(0, 3)),
];

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
      ),
    );
}

/// Rounded surface used for every widget card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(12),
    this.radius = 18,
    this.borderColor,
    this.borderWidth = 1,
    this.shadow = true,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              (color == AppColors.surface
                  ? AppColors.border
                  : Colors.transparent),
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
            title,
            style: AppText.cardTitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Text(action!, style: AppText.action()),
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
            ? Icon(LucideIcons.check, size: size * 0.65, color: Colors.white)
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
            label,
            style: AppText.s(
              10,
              color: selected ? Colors.white : AppColors.muted,
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
                  labels[i],
                  style: AppText.s(
                    11,
                    weight: FontWeight.w600,
                    color: i == index ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular button: white with an icon, or filled primary.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.filled = false,
    this.background = AppColors.surface,
    this.iconColor = AppColors.text,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : background,
          shape: BoxShape.circle,
          boxShadow: filled ? softShadow : null,
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: filled ? Colors.white : iconColor,
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
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;
  final double radius;

  /// Lavender background with primary text instead of the filled style.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final foreground = soft ? AppColors.primary : Colors.white;
    return Material(
      color: soft ? AppColors.primarySoft : AppColors.primary,
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
              Text(
                label,
                style: AppText.s(
                  height >= 44 ? 14 : 11.5,
                  weight: FontWeight.w700,
                  color: foreground,
                ),
              ),
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
                      title,
                      style: AppText.title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.subtitle()),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
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
        Text(label, style: AppText.s(size, color: AppColors.greenStrong)),
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
  final int index;
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
                  Text(label.toUpperCase(), style: AppText.label()),
                  const SizedBox(height: 3),
                  Text(value, style: AppText.s(13, height: 1.35)),
                ],
              ),
            ),
            if (chevron)
              const Icon(
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
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(title, style: AppText.cardTitle()),
          ),
          for (final option in options)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(option, style: AppText.s(13)),
              trailing: option == current
                  ? const Icon(
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
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(title, style: AppText.cardTitle()),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: AppText.s(13),
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
