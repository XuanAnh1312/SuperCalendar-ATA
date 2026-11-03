import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/vip/domain/template.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_store_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_studio_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// VIP tab. A VIP user sees the membership page (VIP 25) that leads to the
/// Template Studio; a Free user sees what VIP adds and can subscribe through
/// the test payment.
class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return app.canAccess(VipFeature.themeBuilder)
        ? const _VipMembership()
        : const _VipOffer();
  }
}

/// "Make it yours" (VIP 25): the active membership and Free vs VIP.
class _VipMembership extends StatelessWidget {
  const _VipMembership();

  static const _rows = [
    ('Ready-made layouts', '3 free', 'More styles'),
    ('Template saving', 'Free layouts', 'Unlimited'),
    ('Colors & typography', 'Standard', 'Premium'),
    ('Widget styling', 'Basic', 'Personalized'),
    ('Calendar & tasks', 'Included', 'Included'),
  ];

  Future<void> _managePlan(BuildContext context) async {
    final app = AppScope.read(context);
    final ok = await confirm(
      context,
      title: 'Switch back to Free?',
      message:
          'For testing the Free plan. Your templates are kept; VIP '
          'features lock again.',
      confirmLabel: 'Switch to Free',
    );
    if (ok) app.cancelVip();
  }

  Widget _row(String feature, String free, String vip, {bool header = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        border: header
            ? null
            : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              tr(feature),
              style: header
                  ? AppText.s(12, color: AppColors.muted)
                  : AppText.s(13.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                tr(free),
                style: header
                    ? AppText.s(13, weight: FontWeight.w700)
                    : AppText.s(12, color: AppColors.muted),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tr(vip),
              style: AppText.s(
                header ? 13 : 12.5,
                weight: header ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
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
            const PageHeader(
              title: 'Make it yours',
              subtitle: 'SuperCalendar VIP',
            ),
            const SizedBox(height: 14),
            AppCard(
              color: AppColors.primarySoft,
              borderColor: Colors.transparent,
              shadow: false,
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.gem, size: 26, color: AppColors.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trf('You’re a VIP, {name}', {
                                'name': app.user.firstName,
                              }),
                              style: AppText.s(19, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tr('Your membership is active'),
                              style: AppText.s(12.5, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr(
                      'More room for personal layouts, colors and typography.',
                    ),
                    style: AppText.s(
                      13.5,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('Free & VIP, at a glance'),
              style: AppText.s(16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            _row('Personalization', 'Free', 'VIP · Yours', header: true),
            for (final (feature, free, vip) in _rows) _row(feature, free, vip),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StudioButton(
                    label: 'Explore styles',
                    onTap: () =>
                        pushInTab(context, const TemplateStudioScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StudioButton(
                    label: 'Manage plan',
                    soft: true,
                    onTap: () => _managePlan(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                tr('Core planning stays available with Free.'),
                style: AppText.s(12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs Subscribe → Test Payment → result. Only a success grants VIP.
Future<void> subscribeToVip(BuildContext context) async {
  final app = AppScope.read(context);
  final result = await showMockPayment(
    context,
    product: 'SuperCalendar VIP',
    priceLabel: '${AppState.vipPrice ~/ 1000},000đ / ${tr('month')}',
  );
  app.completeVipPayment(result);
  if (!context.mounted) return;
  showAppSnack(context, paymentMessage(result, 'VIP'));
}

class _VipOffer extends StatelessWidget {
  const _VipOffer();

  static const _free = [
    'Default theme and built-in themes',
    'Light / dark and accent color',
    '3 ready-made layouts',
    'Template Store · buy and apply',
  ];
  static const _vip = [
    'Full Theme Builder · Template Studio',
    'Custom colors, typography and corners',
    'Free-form layouts for Home and Lock screen',
    'Background images',
    'Create and publish your own templates',
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lastAttempt = app.templates.purchases
        .where(
          (p) =>
              p.productType == ProductType.vip &&
              p.productId == Purchase.vipProductId,
        )
        .lastOrNull;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            PageHeader(
              title: 'SuperCalendar VIP',
              subtitle: 'Make every screen feel like you',
              leading: Icon(
                LucideIcons.gem,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              color: AppColors.primarySoft,
              borderColor: AppColors.primary,
              borderWidth: 1.5,
              radius: 24,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(tr('VIP'),
                          style: AppText.s(18, weight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${AppState.vipPrice ~/ 1000},000đ / ${tr('month')}',
                        style: AppText.s(
                          12.5,
                          weight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final line in _vip) _bullet(line, AppColors.primary),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Subscribe',
                    icon: LucideIcons.gem,
                    onTap: () => subscribeToVip(context),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(tr('Prototype · test payment only, nothing is charged'),
                      style: AppText.s(9.5, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            if (lastAttempt != null &&
                lastAttempt.status != PaymentResult.success) ...[
              const SizedBox(height: 10),
              Text(
                trf('Last attempt: payment {status}', {'status': tr(lastAttempt.status.name)}),
                style: AppText.s(10, color: AppColors.amber),
              ),
            ],
            const SizedBox(height: 12),
            AppCard(
              shadow: false,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(tr('Free'), style: AppText.cardTitle())),
                      SoftPill(
                        label: 'Your plan',
                        color: AppColors.green,
                        textColor: AppColors.greenStrong,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  for (final line in _free)
                    _bullet(line, AppColors.greenStrong),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedActionButton(
              icon: LucideIcons.store,
              label: 'BROWSE TEMPLATE STORE',
              onTap: () => pushInTab(context, const TemplateStoreScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.check, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(tr(text), style: AppText.s(11.5, height: 1.35))),
        ],
      ),
    );
  }
}
