package com.example.flutter_application

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and exposes read-only access to the system calendar
 * over the `supercalendar/system_calendar` channel. Everything else in the
 * app is Dart; this is the one place that needs an Android API.
 */
class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasCalendarPermission())
                    "requestPermission" -> requestCalendarPermission(result)
                    "events" -> {
                        val from = call.argument<Number>("from")?.toLong()
                        val to = call.argument<Number>("to")?.toLong()
                        if (from == null || to == null) {
                            result.error("bad_args", "from and to are required", null)
                        } else {
                            result.success(queryEvents(from, to))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasCalendarPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestCalendarPermission(result: MethodChannel.Result) {
        if (hasCalendarPermission()) {
            result.success(true)
            return
        }
        // Only one system prompt can be open; answer an older request first.
        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CALENDAR),
            CALENDAR_REQUEST,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CALENDAR_REQUEST) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    /** Event instances between [from] and [to] (epoch millis), recurring ones expanded. */
    private fun queryEvents(from: Long, to: Long): List<Map<String, Any?>> {
        if (!hasCalendarPermission()) return emptyList()
        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().let {
            ContentUris.appendId(it, from)
            ContentUris.appendId(it, to)
            it.build()
        }
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.DESCRIPTION,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.CALENDAR_DISPLAY_NAME,
        )
        val events = mutableListOf<Map<String, Any?>>()
        contentResolver.query(
            uri,
            projection,
            null,
            null,
            "${CalendarContract.Instances.BEGIN} ASC",
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                events.add(
                    mapOf(
                        "id" to cursor.getLong(0),
                        "title" to cursor.getString(1),
                        "description" to cursor.getString(2),
                        "begin" to cursor.getLong(3),
                        "end" to cursor.getLong(4),
                        "location" to cursor.getString(5),
                        "calendar" to cursor.getString(6),
                    ),
                )
            }
        }
        return events
    }

    private companion object {
        const val CHANNEL = "supercalendar/system_calendar"
        const val CALENDAR_REQUEST = 4107
    }
}
