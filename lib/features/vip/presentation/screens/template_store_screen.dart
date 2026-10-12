import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/vip/domain/template.dart';
import 'package:flutter_application/features/vip/presentation/widgets/theme_preview.dart';
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';

/// Label of a template's state for the current user.
String templateStatus(AppState app, Template template) {
  if (app.isTemplateApplied(template)) return 'Applied';
  if (template.creatorId == app.user.id) return 'Yours';
  if (app.ownsTemplate(template)) {
    return template.price == 0 ? 'Free' : 'Purchased';
  }
  return template.priceLabel;
}

/// The (mock) marketplace: published templates, with what you own on top.
class TemplateStoreScreen extends StatefulWidget {
  const TemplateStoreScreen({super.key});

  @override
  State<TemplateStoreScreen> createState() => _TemplateStoreScreenState();
}

class _TemplateStoreScreenState extends State<TemplateStoreScreen> {
  // 0 = store, 1 = purchased / owned, 2 = created by me.
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final userId = app.user.id;
    final templates = switch (_filter) {
      1 =>
        app.templates
            .ownedBy(userId)
            .where((t) => t.creatorId != userId)
            .toList(),
      2 => app.templates.createdBy(userId),
      _ => app.templates.published,
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const TopBar(title: 'Template Store'),
            const SizedBox(height: 12),
            FilterPillRow(
              labels: const ['Store', 'Purchased', 'Created'],
              index: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 12),
            if (templates.isEmpty)
              EmptyState(
                icon: LucideIcons.store,
                message: switch (_filter) {
                  1 => 'Templates you unlock show up here.',
                  2 =>
                    app.isVip
                        ? 'Build a template in the Template Studio (VIP tab).'
                        : 'Creating templates is a VIP feature.',
                  _ => 'No templates in the store yet.',
                },
              ),
            for (final template in templates)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TemplateCard(
                  template: template,
                  status: templateStatus(app, template),
                  owned: app.ownsTemplate(template),
                  onTap: () => pushInTab(
                    context,
                    TemplateDetailScreen(templateId: template.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.status,
    required this.owned,
    required this.onTap,
  });

  final Template template;
  final String status;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.lerp(
                AppColors.surface,
                template.themeData.primary,
                0.16,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(template.preview, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  template.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SoftPill(
            label: status,
            color: owned ? AppColors.green : AppColors.primarySoft,
            textColor: owned ? AppColors.greenStrong : AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Template detail: preview, description, creator and price, with the
/// Buy → Purchase success → unlocked → Apply flow.
class TemplateDetailScreen extends StatelessWidget {
  const TemplateDetailScreen({super.key, required this.templateId});

  final String templateId;

  Future<void> _buy(BuildContext context, Template template) async {
    final app = AppScope.read(context);
    final result = await showMockPayment(
      context,
      product: template.name,
      priceLabel: template.priceLabel,
    );
    app.completeTemplatePayment(template, result);
    if (!context.mounted) return;
    showAppSnack(context, paymentMessage(result, template.name));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final template = app.templates.byId(templateId);
    if (template == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              children: [
                TopBar(title: 'Template'),
                EmptyState(
                  icon: LucideIcons.store,
                  message: 'This template is no longer available.',
                ),
              ],
            ),
          ),
        ),
      );
    }
    final owned = app.ownsTemplate(template);
    final applied = app.isTemplateApplied(template);
    final mine = template.creatorId == app.user.id;
    final creator = mine
        ? 'You'
        : template.creatorId == Template.systemCreator
        ? 'SuperCalendar'
        : template.creatorId;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const TopBar(title: 'Template'),
            const SizedBox(height: 12),
            ThemePreview(theme: template.themeData, height: 170),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(template.preview, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    template.name,
                    style: AppText.s(20, weight: FontWeight.w600),
                  ),
                ),
                Text(
                  template.priceLabel,
                  style: AppText.s(
                    14,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.description.isEmpty
                  ? 'No description.'
                  : template.description,
              style: AppText.s(12, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 6),
            FieldTile(
              icon: LucideIcons.circleUserRound,
              label: 'Creator',
              value: creator,
            ),
            FieldTile(
              icon: LucideIcons.type,
              label: 'Typography',
              value: template.themeData.typography,
            ),
            FieldTile(
              icon: LucideIcons.squareRoundCorner,
              label: 'Corners',
              value: 'Radius ${template.themeData.radius.round()}',
            ),
            FieldTile(
              icon: LucideIcons.lockKeyhole,
              label: 'Lock screen style',
              value: template.themeData.lockScreenStyle,
            ),
            const SizedBox(height: 12),
            if (!owned)
              PrimaryButton(
                label: 'Buy · ${template.priceLabel}',
                icon: LucideIcons.shoppingBag,
                onTap: () => _buy(context, template),
              )
            else if (applied)
              PrimaryButton(
                label: 'Applied',
                icon: LucideIcons.check,
                soft: true,
                onTap: () => showAppSnack(context, 'Already in use'),
              )
            else
              PrimaryButton(
                label: 'Apply template',
                icon: LucideIcons.wandSparkles,
                onTap: () {
                  app.applyTemplate(template);
                  showAppSnack(context, '${template.name} applied');
                },
              ),
            if (owned && !mine && template.price > 0) ...[
              const SizedBox(height: 10),
              Center(
                child: SavedStatus(label: 'Purchased · unlocked', size: 10),
              ),
            ],
            if (mine) ...[
              const SizedBox(height: 10),
              PrimaryButton(
                label: template.published
                    ? 'Remove from store'
                    : 'Publish to store',
                icon: template.published
                    ? LucideIcons.eyeOff
                    : LucideIcons.upload,
                soft: true,
                onTap: () async {
                  if (!await requireVip(
                    context,
                    feature: 'Publishing templates',
                  )) {
                    return;
                  }
                  final published = !template.published;
                  app.publishTemplate(template, published: published);
                  if (!context.mounted) return;
                  showAppSnack(
                    context,
                    published
                        ? '${template.name} is now in the store'
                        : '${template.name} removed from the store',
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
