import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// First-run screen (FR-01, SCR-13): a short intro, the local account's name
/// and an optional reminder permission. Calls [onDone] when finished.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  bool _reminders = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Tell us your name first');
      return;
    }
    final app = AppScope.read(context);
    app.finishOnboarding(name);
    // AC-05: a refusal is fine; the app works without notifications.
    if (_reminders) await app.enableNotifications();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                LucideIcons.calendarHeart,
                size: 26,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(tr('Welcome to SuperCalendar'),
              style: AppText.s(24, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Your calendar, to-dos, habits and notes in one place. '
              'Everything stays on this phone.'),
              style: AppText.s(13, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 28),
            Text(tr('What should we call you?'), style: AppText.cardTitle()),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: AppText.s(15),
              onSubmitted: (_) => _start(),
              decoration: InputDecoration(
                hintText: tr('Your name'),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: LucideIcons.bell,
                  color: AppColors.purple,
                  title: 'Remind me about events and tasks',
                  subtitle: 'Android will ask for permission',
                  trailing: AppSwitch(
                    value: _reminders,
                    onChanged: (v) => setState(() => _reminders = v),
                  ),
                  onTap: () => setState(() => _reminders = !_reminders),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Get started',
              icon: LucideIcons.arrowRight,
              onTap: () => unawaited(_start()),
            ),
          ],
        ),
      ),
    );
  }
}
