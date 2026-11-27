import 'package:flutter/material.dart';
import 'package:flutter_application/core/services/daily_wallpaper_renderer.dart';
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
    // One local database for the app, the lock screen and notifications.
    final state = AppState(
      store: await SqliteDocumentStore.open(),
      notifications: kIsWeb
          ? NoopNotificationService(permissionGranted: false)
          : LocalNotificationService(),
      systemCalendar: AndroidSystemCalendarService(),
    );
    await state.load(seedDemoData: false);
    final app = SuperCalendarApp(state: state);
    runApp(_PlannerWithOptionalAuth(app: app));
  } catch (error, stackTrace) {
    debugPrint('SuperCalendar failed to start: $error\n$stackTrace');
    runApp(
      StartupErrorScreen(error: error, stackTrace: stackTrace, onRetry: _boot),
    );
  }
}

/// Separate native background-engine entry point; retained in release AOT.
@pragma('vm:entry-point')
Future<void> dailyWallpaperMain() => runDailyWallpaperWorker();

/// Keep the native planner available even if sign-in initialization is slow
/// or fails on a device without the relevant services.
class _PlannerWithOptionalAuth extends StatefulWidget {
  const _PlannerWithOptionalAuth({required this.app});
  final SuperCalendarApp app;

  @override
  State<_PlannerWithOptionalAuth> createState() =>
      _PlannerWithOptionalAuthState();
}

class _PlannerWithOptionalAuthState extends State<_PlannerWithOptionalAuth> {
  AuthController? _auth;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await initializeFirebase();
      if (mounted && Firebase.apps.isNotEmpty) {
        setState(() => _auth = AuthController(FirebaseAuthRepository()));
      }
    } catch (error) {
      debugPrint('Sign-in initialization failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the planner element in the same position as auth becomes available.
    return AuthSession(controller: _auth, child: widget.app);
  }
}
