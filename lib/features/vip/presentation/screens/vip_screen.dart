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
import 'package:flutter_application/features/vip/presentation/widgets/vip_gate.dart';

/// VIP tab. A VIP user gets the Template Studio (the Theme Builder); a Free
/// user sees what VIP adds and can subscribe through the test payment.
class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return app.isVip ? const TemplateStudioScreen() : const _VipOffer();
  }
}

/// Runs Subscribe → Test Payment → result. Only a success grants VIP.
Future<void> subscribeToVip(BuildContext context) async {
  final app = AppScope.read(context);
  final result = await showMockPayment(
    context,
    product: 'SuperCalendar VIP',
    priceLabel: '${AppState.vipPrice ~/ 1000},000đ / month',
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
        .where((p) => p.templateId == Purchase.vipProduct)
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
                        child: Text(
                          'VIP',
                          style: AppText.s(18, weight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${AppState.vipPrice ~/ 1000},000đ / month',
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
                    child: Text(
                      'Prototype · test payment only, nothing is charged',
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
                'Last attempt: payment ${lastAttempt.status.name}',
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
                      Expanded(child: Text('Free', style: AppText.cardTitle())),
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
          Expanded(child: Text(text, style: AppText.s(11.5, height: 1.35))),
        ],
      ),
    );
  }
}
