import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/dashboard/presentation/widgets/home_widgets.dart';
import 'package:flutter_application/features/vip/domain/template.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_store_screen.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// The VIP Theme Builder: style controls drive a live canvas, and the result
/// can be saved as a template, applied, and published to the store.
class TemplateStudioScreen extends StatefulWidget {
  const TemplateStudioScreen({super.key});

  @override
  State<TemplateStudioScreen> createState() => _TemplateStudioScreenState();
}

class _TemplateStudioScreenState extends State<TemplateStudioScreen> {
  // 0 = canvas, 1 = styles, 2 = presets (my templates).
  int _section = 0;

  // The draft being designed.
  int _color = 0;
  int _size = 1;
  int _style = 0;
  String _typography = AppThemeData.typographyClean;
  String _name = 'My Calm Week';
  String _description = 'My own SuperCalendar look.';
  int _price = 0;

  /// Template being edited; null while designing a new one.
  String? _editingId;

  static const _spacings = [10.0, 12.0, 14.0];
  static const _radii = [18.0, 16.0];
  static const _prices = [0, 9000, 19000, 29000];

  // Flex of the "Today" column against the side column, per layout preset.
  static const _layoutFlex = [(5, 3), (1, 1), (2, 1)];

  Color get _accent => AppColors.accent(_color);

  AppThemeData get _draft => AppThemeData(
    id: 'draft',
    name: _name,
    primary: _accent,
    typography: _typography,
    spacing: _spacings[_size],
    radius: _radii[_style],
  );

  void _load(Template template) {
    final theme = template.themeData;
    final color = AppColors.accents.indexWhere(
      (c) => c.toARGB32() == theme.primary.toARGB32(),
    );
    final size = _spacings.indexOf(theme.spacing);
    setState(() {
      _editingId = template.id;
      _name = template.name;
      _description = template.description;
      _price = template.price;
      _color = color < 0 ? 0 : color;
      _size = size < 0 ? 1 : size;
      _style = theme.radius <= 16 ? 1 : 0;
      _typography = theme.typography;
      _section = 0;
    });
  }

  void _startNew() {
    setState(() {
      _editingId = null;
      _name = 'My Calm Week';
      _description = 'My own SuperCalendar look.';
      _price = 0;
      _section = 0;
    });
  }

  Future<void> _save({bool apply = false}) async {
    final app = AppScope.read(context);
    final name = TextEditingController(text: _name);
    final description = TextEditingController(text: _description);
    var price = _price;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(_editingId == null ? 'Save as template' : 'Update template'),
                style: AppText.s(15, weight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(tr('NAME'), style: AppText.label()),
              TextField(
                controller: name,
                style: AppText.s(14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: tr('Template name'),
                ),
              ),
              const SizedBox(height: 12),
              Text(tr('DESCRIPTION'), style: AppText.label()),
              TextField(
                controller: description,
                style: AppText.s(13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: tr('What makes it yours?'),
                ),
              ),
              const SizedBox(height: 12),
              Text(tr('PRICE'), style: AppText.label()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                children: [
                  for (final option in _prices)
                    FilterPill(
                      label: option == 0 ? 'Free' : '${option ~/ 1000},000đ',
                      selected: option == price,
                      onTap: () => setSheetState(() => price = option),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: apply ? 'Save & apply' : 'Save template',
                icon: LucideIcons.check,
                onTap: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    _name = name.text.trim().isEmpty ? _name : name.text.trim();
    _description = description.text.trim();
    _price = price;
    final template = app.createTemplate(
      id: _editingId,
      name: _name,
      description: _description,
      price: _price,
      preview: '🎨',
      theme: _draft,
    );
    if (template == null) {
      showAppSnack(context, 'Creating templates needs VIP');
      return;
    }
    if (apply) app.applyTemplate(template);
    setState(() {
      _editingId = template.id;
      _section = 2;
    });
    showAppSnack(
      context,
      apply
          ? trf('Template "{name}" saved and applied', {'name': template.name})
          : trf('Template "{name}" saved', {'name': template.name}),
    );
  }

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
              leading: Icon(
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
                  onTap: _save,
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
            if (_section == 2)
              ..._presets(app)
            else ...[
              if (_section == 0) ...[_canvas(app), const SizedBox(height: 12)],
              _controls(app),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedActionButton(
                      icon: LucideIcons.wandSparkles,
                      label: 'SAVE & APPLY',
                      onTap: () => _save(apply: true),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---- Presets: my templates ---------------------------------------------

  List<Widget> _presets(AppState app) {
    final mine = app.templates.createdBy(app.user.id);
    return [
      if (mine.isEmpty)
        const EmptyState(
          icon: LucideIcons.wandSparkles,
          message:
              'No templates yet.\nDesign one on the Canvas tab and press Save.',
        ),
      for (final template in mine)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: template.themeData.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.s(13, weight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${tr(template.priceLabel)} · '
                      '${tr(template.published ? 'Published' : 'Draft')}',
                      style: AppText.s(10, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    SoftPill(
                      label: app.isTemplateApplied(template)
                          ? 'Applied'
                          : 'Apply',
                      icon: LucideIcons.check,
                      color: app.isTemplateApplied(template)
                          ? AppColors.green
                          : null,
                      textColor: app.isTemplateApplied(template)
                          ? AppColors.greenStrong
                          : null,
                      onTap: () {
                        app.applyTemplate(template);
                        showAppSnack(context, trf('{name} applied', {'name': template.name}));
                      },
                    ),
                    SoftPill(
                      label: 'Edit',
                      icon: LucideIcons.pencil,
                      onTap: () => _load(template),
                    ),
                    SoftPill(
                      label: template.published ? 'Unpublish' : 'Publish',
                      icon: template.published
                          ? LucideIcons.eyeOff
                          : LucideIcons.upload,
                      onTap: () {
                        final published = !template.published;
                        app.publishTemplate(template, published: published);
                        showAppSnack(
                          context,
                          published
                              ? trf('{name} published to the store', {'name': template.name})
                              : trf('{name} removed from the store', {'name': template.name}),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 4),
      OutlinedActionButton(
        icon: LucideIcons.plus,
        label: 'NEW TEMPLATE',
        onTap: _startNew,
      ),
      const SizedBox(height: 10),
      OutlinedActionButton(
        icon: LucideIcons.store,
        label: 'OPEN TEMPLATE STORE',
        onTap: () => pushInTab(context, const TemplateStoreScreen()),
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () async {
            final ok = await confirm(
              context,
              title: 'Switch back to Free?',
              message:
                  'For testing the Free plan. Your templates are kept; VIP '
                  'features lock again.',
              confirmLabel: 'Switch to Free',
            );
            if (ok) app.cancelVip();
          },
          child: Text(tr('Cancel VIP (test)'),
            style: AppText.s(10, color: AppColors.muted),
          ),
        ),
      ),
    ];
  }

  // ---- Canvas -------------------------------------------------------------

  Widget _canvas(AppState app) {
    final events = app.events.on(app.today);
    final habits = app.habits.occurrences(app.today);
    final doneHabits = habits
        .where((h) => app.habits.isDone(h, app.today))
        .length;
    final draft = _draft;
    final radius = draft.radius * 0.9;
    final pad = draft.spacing * 0.7;
    final shadow = _style == 0 ? softShadow : null;
    final preset = ScreenLayout.presets.indexOf(app.layouts.home.preset);
    final flex = _layoutFlex[preset < 0 ? 0 : preset];
    final barHeight = 22 + draft.spacing;

    return Container(
      constraints: const BoxConstraints(minHeight: 238),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.surface, _accent, 0.1),
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
                    Text(_name, style: AppText.s(15)),
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
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: shadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Today'),
                        style: AppText.s(11, weight: FontWeight.w700),
                      ),
                      if (events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(tr('No events today'),
                            style: AppText.s(8.5, color: AppColors.muted),
                          ),
                        ),
                      for (final event in events.take(3))
                        Container(
                          height: barHeight,
                          margin: const EdgeInsets.only(top: 7),
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface(event.colorIndex),
                            borderRadius: BorderRadius.circular(radius * 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 2.5,
                                height: barHeight - 14,
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
                      padding: EdgeInsets.all(pad),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tr('Habits')} · $doneHabits/${habits.length}',
                            style: AppText.s(9.5, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              for (final habit in habits.take(4))
                                Container(
                                  width: 17,
                                  height: 17,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: app.habits.isDone(habit, app.today)
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
                      padding: EdgeInsets.all(pad),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('Quick Note'),
                            style: AppText.s(9.5, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            app.notes.quickText,
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

  // ---- Controls -----------------------------------------------------------

  Widget _controls(AppState app) {
    return Row(
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
              _layoutCard(app),
              const SizedBox(height: 8),
              _styleCard(),
              const SizedBox(height: 8),
              AppCard(
                color: AppColors.pink,
                shadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.wandSparkles,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(tr('Mix any style and save unlimited templates.'),
                      style: AppText.s(10, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel({required Widget child}) => AppCard(
    shadow: false,
    borderColor: Colors.transparent,
    padding: const EdgeInsets.all(11),
    child: SizedBox(width: double.infinity, child: child),
  );

  Text _panelTitle(String text) =>
      Text(tr(text), style: AppText.s(12.5, weight: FontWeight.w700));

  Widget _colorsCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _panelTitle('Colors')),
              Text(
                AppColors.accentNames[_color],
                style: AppText.s(9.5, color: _accent),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ColorDots(
            colors: AppColors.accents,
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
          options: AppThemeData.typographies,
          current: _typography,
        );
        if (picked != null) setState(() => _typography = picked);
      },
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelTitle('Typography'),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(child: Text(_typography, style: AppText.s(10.5))),
                Icon(LucideIcons.chevronDown, size: 14, color: AppColors.muted),
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
                        color: i == _size
                            ? AppColors.onPrimary
                            : AppColors.muted,
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

  /// The three home layout presets; picking one rearranges the dashboard.
  Widget _layoutCard(AppState app) {
    // Widths of the two bars drawn inside each layout thumbnail.
    const bars = [(11.0, 11.0), (18.0, 6.0), (18.0, 10.0)];
    final current = ScreenLayout.presets.indexOf(app.layouts.home.preset);
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _panelTitle('Layout')),
              Text(
                app.layouts.home.preset,
                style: AppText.s(9.5, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < bars.length; i++)
                GestureDetector(
                  onTap: () => app.layouts.applyPreset(
                    ScreenLayout.home,
                    ScreenLayout.presets[i],
                  ),
                  child: Container(
                    width: 39,
                    height: 39,
                    margin: const EdgeInsets.only(right: 7),
                    decoration: BoxDecoration(
                      color: i == current
                          ? AppColors.primarySoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: i == current
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
                              color: i == current
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
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SoftPill(
                label: options[i].$2,
                icon: options[i].$1,
                color: i == _style
                    ? AppColors.primarySoft
                    : AppColors.background,
                textColor: i == _style ? AppColors.primary : AppColors.muted,
                onTap: () => setState(() => _style = i),
              ),
            ),
        ],
      ),
    );
  }
}
