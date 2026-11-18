import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_payload.dart';
import '../utils/strings.dart';

/// iOS actions must be registered as categories before notifications arrive.
DarwinInitializationSettings iosNotificationConfiguration() =>
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'task_reminder',
          actions: [
            DarwinNotificationAction.plain(
              NotificationActions.done,
              tr('Done'),
            ),
            DarwinNotificationAction.plain(
              NotificationActions.snooze,
              tr('Snooze'),
            ),
          ],
        ),
        DarwinNotificationCategory(
          'habit_reminder',
          actions: [
            DarwinNotificationAction.plain(
              NotificationActions.snooze,
              tr('Snooze'),
            ),
            DarwinNotificationAction.plain(
              NotificationActions.skip,
              tr('Skip'),
            ),
          ],
        ),
        DarwinNotificationCategory(
          'event_reminder',
          actions: [
            DarwinNotificationAction.plain(
              NotificationActions.snooze,
              tr('Snooze'),
            ),
          ],
        ),
        DarwinNotificationCategory(
          'quick_note',
          actions: [
            DarwinNotificationAction.text(
              NotificationActions.saveNote,
              tr('Save note'),
              buttonTitle: tr('Save note'),
              placeholder: tr('Type a note…'),
            ),
            DarwinNotificationAction.plain(
              NotificationActions.openApp,
              tr('Open app'),
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
        for (final hasTask in [false, true])
          DarwinNotificationCategory(
            hasTask ? 'schedule_task' : 'schedule',
            actions: [
              DarwinNotificationAction.plain(
                NotificationActions.schedule,
                tr('Schedule'),
                options: {
                  DarwinNotificationActionOption.foreground,
                  DarwinNotificationActionOption.authenticationRequired,
                },
              ),
              if (hasTask)
                DarwinNotificationAction.plain(
                  NotificationActions.done,
                  tr('Done'),
                ),
              DarwinNotificationAction.text(
                NotificationActions.addTask,
                tr('Add task'),
                buttonTitle: tr('Add task'),
                placeholder: tr('New task'),
              ),
            ],
          ),
      ],
    );
