package com.example.flutter_application

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.view.FlutterMain

/**
 * Handles [BOOT_COMPLETED] and [QUICKBOOT_POWERON] to re-create notification
 * channels after the device restarts (AC-36, NFR-05).
 *
 * Why:
 *   - flutter_local_notifications' ScheduledNotificationBootReceiver
 *     already re-schedules all [zonedSchedule] alarms after reboot.
 *   - Ongoing notifications (lock screen, Quick Note) are dropped by Android
 *     when the device powers off; they must be re-posted on boot.
 *   - Notification channels must exist before any notification is posted.
 *
 * This receiver creates the required notification channels so that the next
 * app launch (which re-posts ongoing notifications via syncNotifications) can
 * use them even when the channels were not created on this cold boot.
 *
 * Note: Re-posting ongoing notifications from a BroadcastReceiver requires
 * starting a foreground service or a full app launch, which is too heavy for
 * a boot receiver.  Instead this receiver ensures channels exist; the
 * notification plugin's own receiver handles the scheduled alarms, and the
 * app reposts ongoing notifications the next time it is opened.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != "com.htc.intent.action.QUICKBOOT_POWERON" &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        ensureNotificationChannels(context)
    }

    /**
     * Creates the notification channels that SuperCalendar uses.
     *
     * Creating a channel is idempotent — safe to call on every boot even when
     * the channel already exists.  Channels are required on Android 8+ before
     * a notification can be posted.
     */
    private fun ensureNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as? NotificationManager ?: return

        // Reminders: event and task alarms (high-priority, sound on).
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_REMINDERS,
                "Reminders",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Event and task reminders"
                enableVibration(true)
            },
        )

        // Lock screen: today's schedule (low-priority, silent, ongoing).
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_LOCK_SCREEN,
                "Lock screen",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Today's schedule and to-do on the lock screen"
                setSound(null, null)
                enableVibration(false)
            },
        )

        // Quick Note: ongoing note-editing notification (low-priority, silent).
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_QUICK_NOTE,
                "Quick Note",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Quick Note for fast capture from the shade"
                setSound(null, null)
                enableVibration(false)
            },
        )
    }

    companion object {
        const val CHANNEL_REMINDERS = "reminders"
        const val CHANNEL_LOCK_SCREEN = "lock_screen"
        const val CHANNEL_QUICK_NOTE = "quick_note"
    }
}
