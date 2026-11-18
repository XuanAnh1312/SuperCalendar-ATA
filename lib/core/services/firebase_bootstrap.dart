import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_application/firebase_options.dart';

/// Firebase can be disabled for offline development with USE_FIREBASE=false.
Future<void> initializeFirebase() async {
  const enabled = bool.fromEnvironment('USE_FIREBASE', defaultValue: true);
  if (!enabled) return;
  // These are the platforms registered for this project so far.
  if (!kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
