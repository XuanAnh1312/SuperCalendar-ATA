import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/app/theme/app_theme.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';

/// First frame of the app: shown while the local database opens, so the user
/// never looks at a blank screen during startup (UI-11, loading state).
///
/// It runs before [AppState] exists, so it only uses the default theme tokens.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  LucideIcons.calendarDays,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 22),
              CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
              const SizedBox(height: 18),
              Text(
                tr('Opening SuperCalendar…'),
                style: AppText.s(12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the local database cannot be opened (UI-11, error state).
///
/// Nothing is written before this point, so the screen only offers a retry;
/// the technical detail is folded away behind an expander for bug reports.
class StartupErrorScreen extends StatefulWidget {
  const StartupErrorScreen({
    super.key,
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  /// Failure thrown while opening or reading the database.
  final Object error;

  final StackTrace? stackTrace;

  /// Re-runs the boot sequence; it shows [StartupScreen] again and either
  /// starts the app or comes back here.
  final Future<void> Function() onRetry;

  @override
  State<StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<StartupErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    // [runApp] runs a warm-up frame synchronously, which must not happen
    // inside a pointer callback: the remaining queued events would be
    // dispatched while the binding is locked (assertion `!locked`). Yielding
    // to the event loop first lets the gesture dispatch finish.
    await Future<void>.delayed(Duration.zero);
    await widget.onRetry();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      LucideIcons.triangleAlert,
                      size: 24,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('Could not open your data'),
                    textAlign: TextAlign.center,
                    style: AppText.s(16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'SuperCalendar could not open its local database. '
                      'Your existing data has not been changed.',
                    ),
                    textAlign: TextAlign.center,
                    style: AppText.s(11.5, color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Try again',
                    icon: LucideIcons.rotateCw,
                    onTap: _retry,
                  ),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      iconColor: AppColors.muted,
                      collapsedIconColor: AppColors.muted,
                      title: Text(
                        tr('Technical details'),
                        textAlign: TextAlign.center,
                        style: AppText.s(10.5, color: AppColors.muted),
                      ),
                      children: [
                        SelectableText(
                          '${widget.error}\n\n${widget.stackTrace ?? ''}',
                          style: AppText.s(
                            9.5,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
