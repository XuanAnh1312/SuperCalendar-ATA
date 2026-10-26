import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';

/// "Find your calm" (Personalize 20): the ready-made layouts. Three are free
/// (AC-30), the others need VIP (BR-06). Resolves to the picked layout name.
class LayoutGalleryScreen extends StatefulWidget {
  const LayoutGalleryScreen({super.key, required this.current});

  /// Layout in use, marked "Current layout".
  final String current;

  @override
  State<LayoutGalleryScreen> createState() => _LayoutGalleryScreenState();
}

class _LayoutGalleryScreenState extends State<LayoutGalleryScreen> {
  int _filter = 0;

  static const _filters = ['All', 'Free', 'VIP'];

  Future<void> _pick(String name) async {
    if (ScreenLayout.vipPresets.contains(name) &&
        !await requireVip(context, feature: VipFeature.premiumLayouts)) {
      return;
    }
    if (mounted) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final names = [
      if (_filter != 2) ...ScreenLayout.presets,
      if (_filter != 1) ...ScreenLayout.vipPresets,
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'Find your calm',
              subtitle: tr('3 free layouts · More ways to make it yours'),
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: PillSwitch(
                labels: _filters,
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final column = (constraints.maxWidth - 40 - 12) / 2;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 18,
                        children: [
                          for (final name in names)
                            _LayoutCard(
                              width: column,
                              name: name,
                              current: name == widget.current,
                              onTap: () => _pick(name),
                            ),
                          if (_filter != 1)
                            SizedBox(
                              width: column,
                              child: _VipNote(vip: app.isVip),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Look of each layout's thumbnail: background, heading and kind of mock-up.
({Color color, String heading, bool schedule, int blocks}) _look(
  String name,
) => switch (name) {
  ScreenLayout.presetFocus => (
    color: AppColors.blue,
    heading: 'Today’s focus',
    schedule: true,
    blocks: 0,
  ),
  ScreenLayout.presetPlanner => (
    color: AppColors.green,
    heading: 'A fresh start',
    schedule: false,
    blocks: 1,
  ),
  ScreenLayout.presetFocusedWork => (
    color: AppColors.subtle,
    heading: 'Today’s focus',
    schedule: true,
    blocks: 0,
  ),
  ScreenLayout.presetDailyReset => (
    color: AppColors.yellow,
    heading: 'A fresh start',
    schedule: false,
    blocks: -1,
  ),
  _ => (
    color: AppColors.purple,
    heading: 'My calm week',
    schedule: false,
    blocks: 2,
  ),
};

class _LayoutCard extends StatelessWidget {
  const _LayoutCard({
    required this.width,
    required this.name,
    required this.current,
    required this.onTap,
  });

  final double width;
  final String name;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vip = ScreenLayout.vipPresets.contains(name);
    final look = _look(name);
    final subtitle = vip
        ? tr('VIP template')
        : current
        ? '${tr('Free')} · ${tr('Current layout')}'
        : tr('Free layout');
    return Semantics(
      button: true,
      selected: current,
      label: tr(name),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: width * 0.73,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: look.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: current ? AppColors.primary : AppColors.border,
                    width: current ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(look.heading),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.s(9, weight: FontWeight.w600),
                          ),
                        ),
                        if (current)
                          Icon(
                            LucideIcons.circleCheck,
                            size: 13,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: look.schedule
                          ? const _ScheduleMock()
                          : _WeekMock(blocks: look.blocks),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.s(15, weight: FontWeight.w600),
                    ),
                  ),
                  if (vip)
                    Icon(
                      LucideIcons.lockKeyhole,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppText.s(
                  12,
                  color: current ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Today" card with three bars and up to two side blocks.
/// [blocks]: 2 = both, 1 = bottom only, -1 = top only.
class _WeekMock extends StatelessWidget {
  const _WeekMock({required this.blocks});

  final int blocks;

  @override
  Widget build(BuildContext context) {
    Widget bar(Color color) => Container(
      height: 6,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    Widget block(Color? color) => Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('Today'),
                  style: AppText.s(8, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                bar(AppColors.blue),
                bar(AppColors.green),
                bar(AppColors.pink),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              block(blocks == 2 || blocks == -1 ? AppColors.green : null),
              const SizedBox(height: 6),
              block(blocks >= 1 ? AppColors.yellow : null),
            ],
          ),
        ),
      ],
    );
  }
}

/// White card listing three times of the day.
class _ScheduleMock extends StatelessWidget {
  const _ScheduleMock();

  @override
  Widget build(BuildContext context) {
    Widget line(String time, String title) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$time  ${tr(title)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.s(7, color: AppColors.muted),
      ),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            line('09:00', 'Team sync'),
            line('11:30', 'Lunch'),
            line('14:00', 'Design review'),
          ],
        ),
      ),
    );
  }
}

/// Explains the lock badges, as the last tile of the gallery.
class _VipNote extends StatelessWidget {
  const _VipNote({required this.vip});

  final bool vip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.gem, size: 20, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            tr(vip ? 'Your VIP is active' : 'More with VIP'),
            style: AppText.s(15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              vip
                  ? 'Lock badges identify VIP styles. They’re included in your membership.'
                  : 'Lock badges identify VIP styles. Tap one to see what VIP adds.',
            ),
            style: AppText.s(12, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
