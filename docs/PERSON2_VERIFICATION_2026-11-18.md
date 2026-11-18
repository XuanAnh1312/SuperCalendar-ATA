# Person 2 — To-do, Note, Notification/Reminder

Branch: `fix/feature-todo-note-notification`, based on `origin/main` (`6c1d4b4`). Reuses issue #26 / `f9f4a04`. No Firebase, authentication, VIP, or wallpaper rendering changes.

## Automated verification

- `flutter test --reporter expanded`: **98 passed** (69 existing, 29 new). Existing test files are unchanged.
- Original `test/system_audit_probes.dart`, copied unchanged from audit snapshot `3683169`: **13 scoped probes passed**. Run with `--name AUD-[NTQ]0[1-5]`, then `--plain-name AUD-C02`. Probes owned by other features are retained but are not claimed as passing.
- `flutter analyze --no-fatal-infos`: no errors or warnings; 51 informational notices about deprecated Material APIs under Flutter 3.50.0.
- Integration into the original working directory, preserving its Firebase and wallpaper work: **114 tests passed**. These additional local changes are not included in this feature branch.
- Tests using the Android plugin method channel are mocks. They are **not native Android acceptance evidence**.

## Implemented behavior

| References | Behavior and automated coverage |
| --- | --- |
| T01 / AC-35 | UI checkbox creates the next repeat, including Friday → Monday, with fresh subtasks. Notification Done completes only the source task. |
| T02 | Upcoming contains future dated tasks. Undated tasks remain in All; overdue tasks do not appear in Upcoming. |
| T03 | Quick Add, AppState/Lock Screen, and notification Add task use the configured reminder and priority. A null default means at due time; explicit task reminders remain intact. |
| T04–T05 | Persistent hide-completed setting controls rows and counts. Reorder is disabled while filtered. Enter clears Quick Add and retains focus. |
| CRUD / Undo | Persistence tests cover task ordering, subtasks, deletion/undo and reopening repositories. |
| Q01–Q02 / AC-39 | Old note is above an empty preview input. Shared UI/background capture limits notes to 500 grapheme clusters, including emoji, with Append/Replace and empty/full input handling. Labels remain Saved / Saved just now. |
| N01 / FR-18 / BR-02 | Snooze is 10 minutes. Skip writes only today's Habit occurrence; the rule remains unchanged. |
| N02–N03 | Disabled categories are removed from the plan. Habit eligibility checks start/end dates, RRULE and Done/Skipped/Deleted occurrences; defaults and occurrence overrides apply. |
| N04–N05 | Global disable persists settings and hides both ongoing notifications. Reload also reads habits, occurrences, events and exceptions before resynchronizing. |
| C02 | Deleted event occurrences are excluded; overrides, including occurrences moved from a past original date into the future, are resolved before choosing the next valid reminder. |
| REVIEW-03 | Open app launches UI and routes warm/cold notification opens to the Quick Note composer. Schedule has a UI action and routes to Calendar. |
| REVIEW-04 | Stable IDs, pending Snooze reconciliation, and tagged active reminders support cancellation when a source is removed/completed/disabled. A valid Snooze suppresses the normal pending reminder for the same source. |

## Android acceptance — deferred by user

Target available: Android Studio emulator `emulator-5554`, Google gphone64 x86_64, Android 13 / API 33. User confirms PIN/password is enabled. Device database is backed up locally before fixture changes; backups contain private data and are not committed.

During preparation ADB lost the emulator (`device 'emulator-5554' not found`). The user chose to test Android later. No fixture data was written and no test APK was installed. The backup is retained locally. These native acceptance cases remain unverified.

The APK build was stopped when Android testing was deferred; this branch does not yet have a verified successful APK build.

| Acceptance | Status | Required evidence |
| --- | --- | --- |
| AND-07–10 / AC-35, AC-39 | NOT YET VERIFIED | Actual System UI RemoteInput Save note, Done/Snooze with UI backgrounded and process killed, then persisted result after reopening. |
| REVIEW-03 | NOT YET VERIFIED NATIVELY | Cold Open app goes to composer. Widget tests alone do not satisfy this row. |
| AND-11 / AC-36 / NFR-05 | NOT RUN | Schedule at T, reboot before T, record expected and actual delivery time. No simulated reboot broadcast. |
| AND-12 / AC-37 | NOT RUN | On the actual secure lock screen, Schedule presents Android authentication before app UI. A preview or swipe-only screen does not count. |
| AND-13 / AC-05 / NFR-11 | NOT RUN | Actual notification denial/revocation and Android 12 exact-alarm permission behavior. API 33 alone does not verify API 31/32. |

## Limits and completion criteria

- Habit scheduling retains the existing daily planning model: it schedules eligible occurrences for today and replenishes on application synchronization. Continuous multi-day delivery without reopening/synchronizing requires additional scheduling work; it is not claimed as verified here.
- Event reminder selection searches up to 366 days ahead. This is a bounded search, not an unlimited recurrence scheduler.
- At 500 characters, Append leaves the old note unchanged; the preview directs the user to open the composer to edit it. Incoming content is truncated only at a grapheme boundary when space remains.
- No real-device or reboot acceptance may be checked off based on fake/Noop/channel tests.
- Issue closure and merge remain pending native evidence and review. This report does not assert that the entire issue is done.
