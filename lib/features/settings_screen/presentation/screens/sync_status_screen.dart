import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

/// "Sync status" (Settings 29). Prototype mock: there is no cloud sync
/// (README §10), so this always shows the design's offline state. Everything
/// stays saved on this device either way.
class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'Sync status',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(
                        LucideIcons.cloudOff,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('Couldn’t sync yet'),
                    textAlign: TextAlign.center,
                    style: AppText.s(26, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'Your latest changes are saved on this device. Connect '
                      'to the internet to sync them.',
                    ),
                    textAlign: TextAlign.center,
                    style: AppText.s(14, color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    shadow: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _StatusRow(
                          icon: LucideIcons.wifiOff,
                          label: 'Connection',
                          value: tr('Offline · Waiting to reconnect'),
                        ),
                        _StatusRow(
                          icon: LucideIcons.clock3,
                          label: 'Last successful sync',
                          value: tr('Not synced yet'),
                        ),
                        _StatusRow(
                          icon: LucideIcons.smartphone,
                          label: 'Connected devices',
                          value: tr('3 devices'),
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    color: AppColors.green,
                    borderColor: Colors.transparent,
                    shadow: false,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.shieldCheck,
                              size: 18,
                              color: AppColors.greenStrong,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr('Your local data remains saved'),
                                style: AppText.s(
                                  14,
                                  weight: FontWeight.w600,
                                  color: AppColors.greenStrong,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            'You can keep planning. Your changes haven’t '
                            'reached your other devices yet.',
                          ),
                          style: AppText.s(
                            12.5,
                            color: AppColors.greenStrong,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  StudioButton(
                    label: 'Try again',
                    onTap: () => showAppSnack(
                      context,
                      'Still offline · your changes are saved on this device',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr('Waiting for a connection · Not synced yet'),
                    style: AppText.s(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(label), style: AppText.s(11, color: AppColors.muted)),
                const SizedBox(height: 3),
                Text(value, style: AppText.s(15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
