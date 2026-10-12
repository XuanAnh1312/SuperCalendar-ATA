import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';

/// Runs the "connect the phone calendar" flow: the system permission prompt
/// is only shown from here, after the user asked for the feature.
Future<void> connectSystemCalendar(BuildContext context) async {
  final app = AppScope.read(context);
  final granted = await app.connectSystemCalendar();
  if (!context.mounted) return;
  showAppSnack(
    context,
    granted
        ? 'Phone calendar connected · ${app.events.systemEvents.length} events'
        : 'Permission not granted · using your SuperCalendar events only',
  );
}

/// Card on the Calendar tab explaining why the calendar permission is useful
/// before anything is requested.
class SystemCalendarPrompt extends StatelessWidget {
  const SystemCalendarPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AppCard(
      color: AppColors.blue,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.smartphone, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Show your phone calendar here',
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'SuperCalendar can read the events already on this phone and show '
            'them next to yours. They stay read-only and never leave the '
            'device. Android will ask for calendar access.',
            style: AppText.s(10.5, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SoftPill(
                label: 'Connect',
                icon: LucideIcons.link,
                color: AppColors.primary,
                textColor: AppColors.onPrimary,
                onTap: () => connectSystemCalendar(context),
              ),
              const SizedBox(width: 8),
              SoftPill(
                label: 'Not now',
                color: AppColors.surface,
                textColor: AppColors.muted,
                onTap: app.dismissCalendarBanner,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
