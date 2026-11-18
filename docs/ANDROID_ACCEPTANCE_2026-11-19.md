# Android native acceptance — 19 November 2026

Status: selected native tests completed; full acceptance remains pending. Times below are Asia/Saigon (UTC+07:00). Tests use temporary `QA_NATIVE_*` fixtures; the original database and preferences are backed up privately outside version control.

## Environment

- Android Studio emulator `emulator-5554`, `sdk_gphone64_x86_64`, Android 13 / API 33, Google Play production image (`ro.debuggable=0`).
- Installed app `com.supercalendar.app`, version 1.0.0, debug APK last installed 18 November at 23:13:16. Includes the current device-frame implementation.
- Notification permission was already granted at baseline.
- Emulator CPU/startup latency and transient UI Automator failures are recorded as environment limits, not automatically classified as app defects.
- No real Google sign-in, cloud account isolation, paid purchase, iOS, or Android 12 permission acceptance is claimed by these tests.

## Results

| Case | Expected | Actual | Status |
| --- | --- | --- | --- |
| Scheduled task notification | QA task due at 00:12:00 | Android notification creation time 00:12:00.193 (+193 ms) | PASS for this delivery |
| Scheduled Habit notification | Due at 00:13:00 | Notification creation time 00:13:04.573 (+4.573 s) on this emulator | Delivered; latency recorded |
| Done with app UI backgrounded | Complete source, persist state | `qa_native_done.completed=true`; callback logged 00:12:59.208 | PASS — background, not proof of process-kill behavior |
| Task Snooze | Schedule after 10 minutes, remove active original | Click 00:18:55; exact alarm at 00:28:55; original tagged task notification removed | PASS scheduling/cancellation; punctual delivery not established |
| Habit Skip | Only today's occurrence becomes skipped | Persisted occurrence for 2026-11-19 has `status=skipped` | PASS occurrence write; unchanged-rule comparison not performed |
| Cold-process Quick Note RemoteInput | Start background handling and append `QA_COLD_APPEND` | New process 24724 started but note remained `QA_NATIVE_BASE`; Android recorded receiver ANR and killed it | FAIL on this debug APK/API 33 |
| Reboot recovery | Receive without manually reopening app | Real reboot at 00:27; boot completed about 00:31; Snooze appeared at 00:34:44.840 after manually opening app | INCONCLUSIVE |

## Cold Quick Note failure evidence

1. The old application process was deliberately terminated using `am crash` for test setup. The resulting `CrashedByAdbException` at 00:21:46 is intentional and is **not** reported as an application defect.
2. Process absence was confirmed before using Quick Note's actual Android RemoteInput.
3. `QA_COLD_APPEND` was typed and sent from the notification. A new process, PID 24724, started at 00:22:43.965.
4. At 00:22:54.027 Android logged `am_anr` for `com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver.ACTION_TAPPED` in this new process.
5. At 00:22:56.597 Android killed process 24724 with reason `bg anr`.
6. Database readback after the action still contained `QA_NATIVE_BASE`, without the appended text. The notification input remained pending.

This is an observed failed native test on the tested debug/emulator combination. A release build and another device are needed to separate release behavior from debug startup overhead. Root cause is not yet established; no claim is made that Firebase alone caused it.

## Reboot test qualification

The normal reminder fixture was moved to 00:33, but an active 00:33 OS alarm was not confirmed immediately before reboot. Therefore that fixture must **not** be marked as a successful scheduled-before-reboot acceptance case without further evidence. The previously scheduled Snooze at 00:28:55 provides a separate recovery observation. Unlocking after the target time or manually opening the app changes what can be concluded.

## Additional native results

| Case | Actual | Status |
| --- | --- | --- |
| Warm Quick Note RemoteInput Append | Callback at 00:40:37.104; database contained `QA_NATIVE_BASE\nQA_WARM_APPEND`; dashboard reflected it after resume | PASS |
| Quick Note Open app | Actual notification action opened the Quick Note composer with saved content after settling | PASS warm route; cold route untested |
| Schedule behind secure keyguard | Before action: showing=true, secure=true. After action: bouncerShowing=true. User confirmed PIN prompt, entered PIN locally; Calendar opened afterward | PASS on API 33 |
| Notification permission revoked | POST_NOTIFICATIONS granted=false; after resume, notificationsEnabled/quickNoteNotification/lockScreenEnabled all false; no active app notifications; Home and To-do navigation remained usable | PASS revocation and navigation; task creation and warning UI not verified |

## Still required

- Repeat reboot test with a confirmed OS alarm and sufficient time to finish boot/unlock before target; AC-36/NFR-05 remain unaccepted.
- Investigate cold Quick Note receiver ANR; repeat on a release build and another device.
- Cold Open app, cold Done/Snooze, first-time permission denial UI, Settings warning, Android 12 Exact Alarm permission flow.
- Native Replace, emoji/500-character boundaries, recurring task creation/Undo, wallpaper/export and full device-frame interaction matrix.
- iOS and physical-device acceptance. This report does not establish full system readiness.

## Cleanup and restoration

Original database and shared preferences were restored from private backups. Before reopening the app, SHA-256 comparison of every database archive member confirmed exact equality with the original backup. POST_NOTIFICATIONS was restored to granted=true, the original screen timeout was restored, and the app was reopened. No product code was changed during this audit. Private backups and raw device dumps remain under ignored `.dart_tool/`; they must not be committed.
