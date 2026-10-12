import 'package:flutter/material.dart';

import 'package:flutter_application/core/services/app_state.dart';

/// Tab order of the bottom navigation.
abstract final class AppTab {
  static const home = 0;
  static const calendar = 1;
  static const todo = 2;
  static const vip = 3;
  static const settings = 4;
}

/// Navigator above the bottom navigation; also used to open a screen from a
/// notification, where no `BuildContext` is at hand.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// One navigator per tab so pushed pages keep the bottom navigation visible.
final tabNavigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

/// Switches to [tab] and shows its root page.
void goToTab(BuildContext context, int tab) {
  AppScope.read(context).setTab(tab);
  tabNavigatorKeys[tab].currentState?.popUntil((route) => route.isFirst);
}

/// Pushes [page] inside the current tab, keeping the bottom navigation.
Future<T?> pushInTab<T>(BuildContext context, Widget page) {
  return Navigator.of(context)
      .push<T>(MaterialPageRoute<T>(builder: (_) => page));
}

/// Switches to [tab] and pushes [page] inside it.
void openInTab(BuildContext context, int tab, Widget page) {
  goToTab(context, tab);
  tabNavigatorKeys[tab].currentState?.push(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

/// Pushes [page] above the bottom navigation.
Future<T?> pushFullScreen<T>(BuildContext context, Widget page) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(MaterialPageRoute<T>(builder: (_) => page));
}
