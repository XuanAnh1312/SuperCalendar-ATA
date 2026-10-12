import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/vip/domain/template.dart';

/// Feature gate: true for a VIP user. A Free user gets a sheet explaining
/// that [feature] needs VIP, with a shortcut to the offer, and false.
Future<bool> requireVip(BuildContext context, {required String feature}) async {
  final app = AppScope.read(context);
  if (app.isVip) return true;
  final seeOffer = await showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.gem, size: 18, color: AppColors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '$feature is a VIP feature',
                    style: AppText.s(15, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Free includes the default theme, the built-in layouts and '
              'templates you buy. VIP adds the Theme Builder, free-form '
              'layouts, custom fonts, background images and template '
              'publishing.',
              style: AppText.s(11.5, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'See VIP',
              icon: LucideIcons.gem,
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Not now',
              soft: true,
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    ),
  );
  if (seeOffer == true && context.mounted) goToTab(context, AppTab.vip);
  return false;
}

/// The test payment step. Nothing is charged: the buttons simply pick which
/// outcome the "payment provider" reports. Dismissing counts as cancelled.
Future<PaymentResult> showMockPayment(
  BuildContext context, {
  required String product,
  required String priceLabel,
}) async {
  final result = await showModalBottomSheet<PaymentResult>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test payment', style: AppText.s(15, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '$product · $priceLabel',
              style: AppText.s(12.5, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Prototype checkout. No card is asked for and no money moves; '
              'choose the result to simulate.',
              style: AppText.s(11, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Simulate successful payment',
              icon: LucideIcons.circleCheck,
              onTap: () => Navigator.pop(sheetContext, PaymentResult.success),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Simulate failed payment',
              danger: true,
              onTap: () => Navigator.pop(sheetContext, PaymentResult.failed),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Cancel',
              soft: true,
              onTap: () => Navigator.pop(sheetContext, PaymentResult.cancelled),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? PaymentResult.cancelled;
}

/// Message shown after a payment attempt for [product].
String paymentMessage(PaymentResult result, String product) => switch (result) {
  PaymentResult.success => 'Payment successful · $product unlocked',
  PaymentResult.failed => 'Payment failed · nothing was unlocked',
  PaymentResult.cancelled => 'Payment cancelled',
};
