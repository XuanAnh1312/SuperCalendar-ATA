import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/app/startup_screens.dart';

/// UI-11: the loading state shown while the database opens and the error
/// state shown when it fails to open.
void main() {
  testWidgets('startup shows the loading state before the app is ready',
      (tester) async {
    await tester.pumpWidget(const StartupScreen());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Opening SuperCalendar…'), findsOneWidget);
  });

  testWidgets('a failed database shows the error state and can retry',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      StartupErrorScreen(
        error: StateError('database is locked'),
        stackTrace: StackTrace.current,
        onRetry: () async => retries++,
      ),
    );

    expect(find.text('Could not open your data'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // The technical detail stays folded away until it is asked for.
    expect(find.textContaining('database is locked'), findsNothing);

    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('database is locked'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    // The retry yields to the event loop first so runApp() never runs inside
    // a pointer callback, so let that deferred call happen.
    await tester.pump(const Duration(milliseconds: 1));
    expect(retries, 1);
  });
}
