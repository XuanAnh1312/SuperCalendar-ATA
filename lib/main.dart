import 'package:flutter/material.dart';

import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/app/startup_screens.dart';
import 'package:flutter_application/core/data/sqlite_document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/local_notification_service.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _boot();
}

/// Shows the loading screen, opens the database and starts the app.
///
/// If the database cannot be opened the error screen takes over and its
/// "Try again" button re-runs this same sequence (UI-11).
Future<void> _boot() async {
  runApp(const StartupScreen());
  try {
    // One local database for the app, the lock screen and notifications.
    final state = AppState(
      store: await SqliteDocumentStore.open(),
      notifications: LocalNotificationService(),
      systemCalendar: AndroidSystemCalendarService(),
    );
    await state.load();
    runApp(SuperCalendarApp(state: state));
  } catch (error, stackTrace) {
    debugPrint('SuperCalendar failed to start: $error\n$stackTrace');
    runApp(
      StartupErrorScreen(
        error: error,
        stackTrace: stackTrace,
        onRetry: _boot,
      ),
    );
  }
}
