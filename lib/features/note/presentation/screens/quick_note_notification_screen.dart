import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';

/// In-app preview of the notification shade with the Quick Note
/// notification. The note is saved to the same database the dashboard reads.
class QuickNoteNotificationScreen extends StatefulWidget {
  const QuickNoteNotificationScreen({super.key});

  @override
  State<QuickNoteNotificationScreen> createState() =>
      _QuickNoteNotificationScreenState();
}

class _QuickNoteNotificationScreenState
    extends State<QuickNoteNotificationScreen> {
  static const _maxLength = 500;

  TextEditingController? _note;
  final _toggles = [true, true, false, false];
  double _brightness = 0.64;
  bool _expanded = true;
  bool _dirty = false;
  bool _mailVisible = true;

  static const _toggleIcons = [
    LucideIcons.wifi,
    LucideIcons.bluetooth,
    LucideIcons.bell,
    LucideIcons.flashlight,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _note ??= TextEditingController(
      text: AppScope.read(context).notes.quickText,
    );
  }

  @override
  void dispose() {
    _note?.dispose();
    super.dispose();
  }

  void _save() {
    AppScope.read(context).notes.setQuick(_note!.text);
    FocusScope.of(context).unfocus();
    setState(() => _dirty = false);
    showAppSnack(context, 'Note saved');
  }

  void _openApp() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final note = _note!;
    final now = app.now;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.shadeTop, AppColors.shadeBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                          style: AppText.s(24),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          shortDate(app.today),
                          style: AppText.s(10, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  for (final icon in const [
                    LucideIcons.penLine,
                    LucideIcons.power,
                    LucideIcons.settings,
                  ])
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: icon == LucideIcons.power
                          ? () => Navigator.of(context).pop()
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Icon(icon, size: 18, color: AppColors.text),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < _toggles.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _toggles[i] = !_toggles[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 66,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _toggles[i]
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _toggleIcons[i],
                          size: 16,
                          color: _toggles[i]
                              ? AppColors.onPrimary
                              : AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.sunMedium,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.primary,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 2.5,
                            elevation: 0,
                            pressedElevation: 0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Slider(
                            value: _brightness,
                            onChanged: (v) => setState(() => _brightness = v),
                          ),
                        ),
                      ),
                    ),
                    Icon(LucideIcons.sun, size: 16, color: AppColors.text),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CONVERSATIONS & NOTES',
                style: AppText.s(10, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              AppCard(
                radius: 24,
                padding: const EdgeInsets.all(14),
                borderColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              LucideIcons.notebookPen,
                              size: 16,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SuperCalendar',
                                  style: AppText.s(
                                    11.5,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'now · notification access',
                                  style: AppText.s(9.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _expanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 15,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(minHeight: 108),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        decoration: BoxDecoration(
                          color: AppColors.note,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUICK NOTE',
                              style: AppText.s(9.5, color: AppColors.primary),
                            ),
                            TextField(
                              controller: note,
                              maxLines: null,
                              maxLength: _maxLength,
                              style: AppText.s(13, height: 1.35),
                              onChanged: (_) => setState(() => _dirty = true),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                hintText: 'Type a quick note',
                                hintStyle: AppText.s(
                                  13,
                                  color: AppColors.faint,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _dirty
                                      ? Text(
                                          'Not saved yet',
                                          style: AppText.s(
                                            9.5,
                                            color: AppColors.amber,
                                          ),
                                        )
                                      : const Align(
                                          alignment: Alignment.centerLeft,
                                          child: SavedStatus(
                                            label: 'Saved & synced just now',
                                            size: 9.5,
                                          ),
                                        ),
                                ),
                                Text(
                                  '${note.text.length}/$_maxLength',
                                  style: AppText.s(9.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Save note',
                              height: 38,
                              radius: 19,
                              onTap: _save,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Open app',
                              height: 38,
                              radius: 19,
                              soft: true,
                              onTap: _openApp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_mailVisible) ...[
                const SizedBox(height: 14),
                AppCard(
                  color: AppColors.lockCard,
                  radius: 20,
                  shadow: false,
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          LucideIcons.mail,
                          size: 15,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mail · 12 min',
                              style: AppText.s(10.5, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Weekly project summary is ready',
                              style: AppText.s(10.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SoftPill(
                    label: 'Notification settings',
                    color: AppColors.subtle,
                    textColor: AppColors.muted,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  SoftPill(
                    label: 'Clear',
                    color: AppColors.subtle,
                    textColor: AppColors.muted,
                    onTap: () => setState(() => _mailVisible = false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
