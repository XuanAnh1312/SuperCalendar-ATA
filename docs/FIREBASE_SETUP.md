# Firebase — Super Calendar

Project: `super-calendar-e4e6e` (number `397687149185`).
Android application ID and iOS bundle ID: `com.supercalendar.app`. Registered platforms: Android, Web and iOS.

## Run

`flutter run -d chrome` initializes Firebase before opening the local planner.
For offline feature development, use
`flutter run -d chrome --dart-define=USE_FIREBASE=false`.
Windows keeps using the local planner. iOS Firebase and Google Sign-In configuration
is included; its native build and sign-in still require verification on an iPhone.
See [iPhone test preparation](IOS_TEST_SETUP.md).
Firebase configuration does not upload the existing SQLite data.

## Console setup

1. Open Authentication, choose Get started, and enable **Google**. This project
   currently uses Google only; Email/Password is not required.
2. In Authentication > Settings > Authorized domains, add `localhost` for local
   Chrome development if it is absent. Use `http://localhost:7357`, rather than
   an extension's own URL or a LAN IP, when testing Google sign-in.
3. Android debug SHA-1 registered for this development machine:
   `3A:7C:52:83:0B:69:00:33:2B:46:8E:67:7C:C4:C7:A3:F9:05:3D:91`.
   Other developers and release signing keys require their own fingerprints.
   The refreshed `android/app/google-services.json` includes Google OAuth clients.
4. Before implementing cloud profiles, create a Cloud Firestore database and
   choose its region deliberately. Do not use unrestricted production rules.
5. Configure per-user access rules before adding cloud profile writes.

## Current milestone

Firebase SDK dependencies, generated platform configuration, and startup
initialization, plus a Google account card in Settings with sign-in, restored
SDK sessions, sign-out, loading, and recoverable errors. Firebase initialization errors have their own retry message;
they are not reported as local database errors.

The Google identity is currently shown separately from the existing local
profile. Signing in or out does not move, erase, or synchronize planner data.
The device-local planner is shared on this installation; per-account local
data isolation must be implemented before treating it as an account workspace.

Per-account local data isolation, cloud profiles,
trusted VIP entitlements, and cloud synchronization remain separate work.
Existing VIP purchases are still the prototype's mock flow.

## Verification

`flutter test test/firebase_auth_test.dart` covers restored sessions, duplicate
sign-in taps, cancelled sign-in and retry, failed sign-out, and card interactions
with a fake repository. Actual Google consent and sign-in require manual testing
with a Google account; these unit tests do not verify production OAuth.

Manual Chrome acceptance:

1. Run `flutter run -d web-server --web-hostname localhost --web-port 7357`.
2. Open `http://localhost:7357` in the browser that has your preferred Google account.
3. Open Settings and choose Continue with Google. Cancel once and retry; cancelling
   must leave the planner usable and show a recoverable message.
4. Complete Google consent. The card must show the authenticated email.
5. Reload the same browser origin. The email must be restored without signing in again.
6. Sign out and reload. The card must offer Continue with Google again.
7. Verify the new user appears in Firebase Console > Authentication > Users.

Automated verification for this milestone: 74 tests pass. Static analysis reports
only Flutter Material deprecation information; no errors or warnings. Real Google
OAuth consent, Android sign-in, and release certificate configuration are not yet
verified by these checks.

The debug Web build succeeds. A separate headless Chrome profile reaches
onboarding with no startup exceptions and creates Firebase session/heartbeat
IndexedDB stores alongside the existing persistent SQLite Web store. The project's
public Authentication configuration confirms `localhost` is authorized.

Do not add service-account private keys, CLI login tokens, or user passwords
to the repository. The generated client Firebase options identify the app;
access to cloud data must be enforced by Firebase security rules.
