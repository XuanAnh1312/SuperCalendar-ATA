import 'package:flutter/material.dart';

import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/auth/presentation/auth_controller.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}

/// Owns the controller for the lifetime of the application widget tree.
class AuthSession extends StatefulWidget {
  const AuthSession({super.key, required this.controller, required this.child});
  final AuthController controller;
  final Widget child;

  @override
  State<AuthSession> createState() => _AuthSessionState();
}

class _AuthSessionState extends State<AuthSession> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AuthSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller)
      oldWidget.controller.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AuthScope(controller: widget.controller, child: widget.child);
}

/// This card deliberately keeps the local profile and planner separate until
/// per-account data migration and cloud synchronization are implemented.
class GoogleAccountCard extends StatelessWidget {
  const GoogleAccountCard({super.key, required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final account = controller.account;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Google account'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (account != null)
                Text(account.email ?? account.displayName ?? tr('Signed in')),
              Text(
                tr(
                  'Your planner data stays on this device. Cloud sync is not available yet.',
                ),
              ),
              if (controller.message case final message?) ...[
                const SizedBox(height: 8),
                Text(
                  tr(message),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              if (controller.busy)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: account == null
                      ? controller.signInWithGoogle
                      : controller.signOut,
                  child: Text(
                    tr(account == null ? 'Continue with Google' : 'Sign out'),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
