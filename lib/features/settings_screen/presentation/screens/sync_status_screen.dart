import 'package:flutter/material.dart';

import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioHeader(
              title: 'Planner storage',
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                tr(
                  'Your planner data stays on this device. Cloud sync is not available yet.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
