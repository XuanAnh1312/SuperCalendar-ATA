import 'package:flutter/material.dart';

import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/core/data/sqlite_document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/local_notification_service.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // One local database for the app, the lock screen and notifications.
  final state = AppState(
    store: await SqliteDocumentStore.open(),
    notifications: LocalNotificationService(),
    systemCalendar: AndroidSystemCalendarService(),
  );
  await state.load();
  runApp(SuperCalendarApp(state: state));
}
