import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';

/// VIP template builder: a live canvas plus the style controls that drive it.
class TemplateStudioScreen extends StatefulWidget {
  const TemplateStudioScreen({super.key});

  @override
  State<TemplateStudioScreen> createState() => _TemplateStudioScreenState();
}

class _TemplateStudioScreenState extends State<TemplateStudioScreen> {
  int _section = 0;
  int _color = 0;
  int _layout = 1;
  int _size = 1;
  int _style = 0;
  String _font = 'Inter · Clean';

  static const _palette = [
    AppColors.primary,
    AppColors.pinkStrong,
    AppColors.greenDot,
    Color(0xFFE2B53D),
    AppColors.blueStrong,
  ];
  static const _paletteNames = ['Lavender', 'Rose', 'Mint', 'Honey', 'Sky'];

  // Flex of the "Today" column against the side column, per layout option.
  static const _layoutFlex = [(1, 1), (5, 3), (2, 1)];
  static const _barHeights = [28.0, 34.0, 40.0];

  Color get _accent => _palette[_color];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            PageHeader(
              title: 'Template Studio',
              subtitle: 'Build a dashboard that feels like you',
              leading: const Icon(
                LucideIcons.gem,
                size: 20,
                color: AppColors.primary,
              ),
              trailing: SizedBox(
                width: 55,
                child: PrimaryButton(
                  label: 'Save',
                  height: 31,
                  radius: 16,
                  onTap: () =>
                      showAppSnack(context, 'Template "My Calm Week" saved'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilterPillRow(
              labels: const ['Canvas', 'Styles', 'Presets'],
              index: _section,
              onChanged: (i) => setState(() => _section = i),
            ),
            const SizedBox(height: 12),
            _canvas(app),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _colorsCard(),
                      const SizedBox(height: 8),
                      _typographyCard(),
                      const SizedBox(height: 8),
                      _sizeCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _layoutCard(),
                      const SizedBox(height: 8),
                      _styleCard(),
                      const SizedBox(height: 8),
                      AppCard(
                        color: AppColors.pink,
                        shadow: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.wandSparkles,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mix any style and save unlimited templates.',
                              style: AppText.s(10, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _canvas(AppState app) {
    final events = app.eventsOn(app.today);
    final doneHabits = app.habits.where((h) => h.done).length;
    final radius = _style == 0 ? 16.0 : 10.0;
    final shadow = _style == 0 ? softShadow : null;
    final flex = _layoutFlex[_layout];

    return Container(
      constraints: const BoxConstraints(minHeight: 238),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          _accent.withValues(alpha: 0.1),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Calm Week', style: AppText.s(15)),
                    const SizedBox(height: 3),
                    Text(
                      weekRangeLabel(app.today, longMonth: true),
                      style: AppText.s(9, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.sparkles, size: 16, color: _accent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: flex.$1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: shadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: AppText.s(11, weight: FontWeight.w700),
                      ),
                      for (final event in events.take(3))
                        Container(
                          height: _barHeights[_size],
                          margin: const EdgeInsets.only(top: 7),
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                          decoration: BoxDecoration(
                            color: event.color,
                            borderRadius: BorderRadius.circular(radius * 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 2.5,
                                height: _barHeights[_size] - 14,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${event.startLabel}  ${event.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.s(8.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: flex.$2,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habits · $doneHabits/${app.habits.length}',
                            style: AppText.s(9.5, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              for (final habit in app.habits)
                                Container(
                                  width: 17,
                                  height: 17,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: habit.done
                                        ? AppColors.greenStrong
                                        : AppColors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Note',
                            style: AppText.s(9.5, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            app.quickNote,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.s(8.5, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) => AppCard(
    shadow: false,
    borderColor: Colors.transparent,
    padding: const EdgeInsets.all(11),
    child: SizedBox(width: double.infinity, child: child),
  );

  Text _panelTitle(String text) =>
      Text(text, style: AppText.s(12.5, weight: FontWeight.w700));

  Widget _colorsCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _panelTitle('Colors')),
              Text(
                _paletteNames[_color],
                style: AppText.s(9.5, color: _accent),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ColorDots(
            colors: _palette,
            index: _color,
            size: 20,
            onChanged: (i) => setState(() => _color = i),
          ),
        ],
      ),
    );
  }

  Widget _typographyCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final picked = await pickOption(
          context,
          title: 'Typography',
          options: const ['Inter · Clean', 'Inter · Bold', 'Inter · Airy'],
          current: _font,
        );
        if (picked != null) setState(() => _font = picked);
      },
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelTitle('Typography'),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(child: Text(_font, style: AppText.s(10.5))),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppColors.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeCard() {
    const labels = ['S', 'M', 'L'];
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Widget size'),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _size = i),
                  child: Container(
                    width: i == _size ? 27 : 24,
                    height: 21,
                    margin: const EdgeInsets.only(right: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == _size
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      labels[i],
                      style: AppText.s(
                        10,
                        color: i == _size ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _layoutCard() {
    // Widths of the two bars drawn inside each layout thumbnail.
    const bars = [(11.0, 11.0), (11.0, 11.0), (18.0, 10.0)];
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Layout'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < bars.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _layout = i),
                  child: Container(
                    width: 39,
                    height: 39,
                    margin: const EdgeInsets.only(right: 7),
                    decoration: BoxDecoration(
                      color: i == _layout
                          ? AppColors.primarySoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: i == _layout
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final width in [bars[i].$1, bars[i].$2])
                          Container(
                            width: width,
                            height: 26,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: i == _layout
                                  ? AppColors.primary
                                  : AppColors.faint,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _styleCard() {
    const options = [
      (LucideIcons.layoutGrid, 'Soft cards'),
      (LucideIcons.squareRoundCorner, 'Round 16'),
    ];
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Widget style'),
          for (var i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => setState(() => _style = i),
              child: Container(
                height: 22,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: i == _style
                      ? AppColors.primarySoft
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      options[i].$1,
                      size: 11,
                      color: i == _style ? AppColors.primary : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      options[i].$2,
                      style: AppText.s(
                        10,
                        color: i == _style
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
