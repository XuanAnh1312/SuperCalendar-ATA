import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/app/startup_screens.dart';
import 'package:flutter_application/core/data/sqlite_document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/firebase_bootstrap.dart';
import 'package:flutter_application/core/services/device_frame_service.dart';
import 'package:flutter_application/core/services/local_notification_service.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_application/features/auth/presentation/auth_controller.dart';
import 'package:flutter_application/features/auth/presentation/google_account_card.dart';

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
  await DeviceFrameService.instance.initialize();
  try {
    await initializeFirebase();
  } catch (error, stackTrace) {
    runApp(
      StartupErrorScreen(
        error: error,
        stackTrace: stackTrace,
        onRetry: _boot,
        title: 'Could not connect to Firebase',
        message:
            'Firebase could not initialize. Please try again. '
            'Your local data has not been changed.',
      ),
    );
    return;
  }
  try {
    // One local database for the app, the lock screen and notifications.
    final state = AppState(
      store: await SqliteDocumentStore.open(),
      notifications: kIsWeb
          ? NoopNotificationService(permissionGranted: false)
          : LocalNotificationService(),
      systemCalendar: AndroidSystemCalendarService(),
    );
    await state.load();
    final app = SuperCalendarApp(state: state);
    runApp(
      Firebase.apps.isEmpty
          ? app
          : AuthSession(
              controller: AuthController(FirebaseAuthRepository()),
              child: app,
            ),
    );
  } catch (error, stackTrace) {
    debugPrint('SuperCalendar failed to start: $error\n$stackTrace');
    runApp(
      StartupErrorScreen(error: error, stackTrace: stackTrace, onRetry: _boot),
    );
  }
}
