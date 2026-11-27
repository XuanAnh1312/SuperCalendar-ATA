package com.example.flutter_application

import android.content.ContentUris
import android.provider.CalendarContract

object SystemCalendarQuery {
    fun events(context: android.content.Context, from: Long, to: Long): List<Map<String, Any?>> {
        if (androidx.core.content.ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_CALENDAR) != android.content.pm.PackageManager.PERMISSION_GRANTED) return emptyList()

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

        context.contentResolver.query(
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

}
