package com.example.flutter_application

import android.Manifest
import android.app.WallpaperManager
import android.content.ContentUris
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.IOException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and exposes read-only access to the system calendar
 * over the `supercalendar/system_calendar` channel (FR-22).
 *
 * Channel methods:
 *   hasPermission    → Boolean
 *   requestPermission → Boolean
 *   events(from: Long, to: Long) → List<Map<String, Any?>>
 *
 * Each event map contains:
 *   id          Long    CalendarContract.Instances.EVENT_ID
 *   title       String?
 *   description String?
 *   begin       Long    epoch ms
 *   end         Long    epoch ms
 *   allDay      Int     1 = all-day, 0 = timed
 *   location    String?
 *   calendar    String? display name of the owning calendar
 *   calendarId  Long    _ID of the owning calendar
 *   color       Int?    ARGB event colour (may be null)
 *
 * Also sets the wallpaper exported by Edit Your Screen over the
 * `supercalendar/wallpaper` channel (FR-04):
 *   setWallpaper(bytes: ByteArray PNG, target: "lock" | "home") → Boolean
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "setWallpaper") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val target = call.argument<String>("target")
                if (bytes == null || (target != "lock" && target != "home")) {
                    result.error("bad_args", "bytes and target are required", null)
                    return@setMethodCallHandler
                }
                // Decoding and writing a full-screen bitmap is slow; keep it
                // off the UI thread.
                Thread {
                    val ok = setWallpaper(bytes, target == "lock")
                    runOnUiThread { result.success(ok) }
                }.start()
            }
    }

    private fun setWallpaper(bytes: ByteArray, lockScreen: Boolean): Boolean {
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return false
        val flag = if (lockScreen) WallpaperManager.FLAG_LOCK else WallpaperManager.FLAG_SYSTEM
        return try {
            WallpaperManager.getInstance(this).setBitmap(bitmap, null, true, flag) != 0
        } catch (e: IOException) {
            false
        } catch (e: SecurityException) {
            false
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

    /**
     * Event instances between [from] and [to] (epoch millis), recurring ones
     * expanded by the CalendarContract.Instances provider.
     *
     * Returns a list of maps, one per expanded occurrence.  Fields marked with
     * `?` may be null when the system calendar does not provide a value.
     */
    private fun queryEvents(from: Long, to: Long): List<Map<String, Any?>> {
        if (!hasCalendarPermission()) return emptyList()

        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().let {
            ContentUris.appendId(it, from)
            ContentUris.appendId(it, to)
            it.build()
        }

        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,            // 0 Long
            CalendarContract.Instances.TITLE,               // 1 String?
            CalendarContract.Instances.DESCRIPTION,         // 2 String?
            CalendarContract.Instances.BEGIN,               // 3 Long
            CalendarContract.Instances.END,                 // 4 Long
            CalendarContract.Instances.ALL_DAY,             // 5 Int (0 or 1)
            CalendarContract.Instances.EVENT_LOCATION,      // 6 String?
            CalendarContract.Instances.CALENDAR_DISPLAY_NAME, // 7 String?
            CalendarContract.Instances.CALENDAR_ID,         // 8 Long
            CalendarContract.Instances.DISPLAY_COLOR,       // 9 Int? (ARGB, may be null)
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
                // DISPLAY_COLOR can be null in the cursor
                val colorIndex = cursor.getColumnIndex(CalendarContract.Instances.DISPLAY_COLOR)
                val color: Int? = if (!cursor.isNull(colorIndex)) cursor.getInt(colorIndex) else null

                events.add(
                    mapOf(
                        "id"          to cursor.getLong(0),
                        "title"       to cursor.getString(1),
                        "description" to cursor.getString(2),
                        "begin"       to cursor.getLong(3),
                        "end"         to cursor.getLong(4),
                        "allDay"      to cursor.getInt(5),
                        "location"    to cursor.getString(6),
                        "calendar"    to cursor.getString(7),
                        "calendarId"  to cursor.getLong(8),
                        "color"       to color,
                    ),
                )
            }
        }

        return events
    }

    private companion object {
        const val CHANNEL = "supercalendar/system_calendar"
        const val WALLPAPER_CHANNEL = "supercalendar/wallpaper"
        const val CALENDAR_REQUEST = 4107
    }
}
