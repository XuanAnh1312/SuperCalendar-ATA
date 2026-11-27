package com.example.flutter_application

import android.app.WallpaperManager
import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/** Native preferences are the single consent source, also readable without Dart. */
object DailyWallpaper {
    const val FIRST_JOB = 8301
    const val SECOND_JOB = 8302
    const val PREVIEW_JOB = 8303
    val lock = Any()
    fun prefs(context: Context) = context.getSharedPreferences("daily_wallpaper", Context.MODE_PRIVATE)
    fun today(): String = LocalDate.now().toString()
    fun needsRefresh(p: SharedPreferences): Boolean {
        val requested = p.getInt("requestedContentRevision", -1)
        val changed = requested >= 0 && requested != p.getInt("contentRevision", -1) &&
            p.getLong("contentRequestId", 0) != p.getLong("handledContentRequestId", -1)
        return p.getString("updatedDay", null) != today() || changed
    }
    fun status(context: Context): Map<String, Any?> {
        val p = prefs(context)
        return mapOf("enabled" to p.getBoolean("enabled", false), "asked" to p.getBoolean("asked", false),
            "hasDesign" to p.contains("layout"), "updatedAt" to p.getLong("updatedAt", 0).takeIf { it > 0 },
            "contentRevision" to p.getInt("contentRevision", -1).takeIf { it >= 0 },
            "error" to p.getString("error", null))
    }
    private fun scheduler(context: Context) = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
    fun cancel(context: Context) { scheduler(context).cancel(FIRST_JOB); scheduler(context).cancel(SECOND_JOB) }
    fun schedule(context: Context, immediate: Boolean = false, jobId: Int = FIRST_JOB, force: Boolean = false) {
        if (!prefs(context).getBoolean("enabled", false)) return
        val zone = ZoneId.systemDefault()
        val next = LocalDate.now(zone).plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val extras = android.os.PersistableBundle().apply {
            putBoolean("force", force)
            putBoolean("immediate", immediate)
        }
        val builder = JobInfo.Builder(jobId, ComponentName(context, DailyWallpaperJob::class.java))
            .setPersisted(true).setMinimumLatency(if (immediate) 0 else (next-System.currentTimeMillis()).coerceAtLeast(0))
            .setExtras(extras).setBackoffCriteria(30 * 60 * 1000L, JobInfo.BACKOFF_POLICY_EXPONENTIAL)
        if (Build.VERSION.SDK_INT >= 26) builder.setRequiresBatteryNotLow(true)
        check(scheduler(context).schedule(builder.build()) == JobScheduler.RESULT_SUCCESS) { "Android refused the background job" }
    }
    fun catchUp(context: Context, contentRevision: Int? = null) {
        synchronized(lock) {
            val p = prefs(context)
            if (contentRevision != null && p.contains("layout") &&
                contentRevision != p.getInt("requestedContentRevision", -1)) {
                p.edit().putInt("requestedContentRevision", contentRevision)
                    .putLong("contentRequestId", p.getLong("contentRequestId", 0) + 1).apply()
            }
            if (!p.getBoolean("enabled", false)) return
            // Avoid replacing work that is already queued or running.
            val jobs = scheduler(context).allPendingJobs.filter { it.id == FIRST_JOB || it.id == SECOND_JOB }
            val immediate = needsRefresh(p)
            if (jobs.isEmpty()) {
                schedule(context, immediate = immediate)
            } else if (immediate && jobs.size == 1 && jobs.none { it.extras.getBoolean("immediate", false) }) {
                val otherJob = if (jobs.single().id == FIRST_JOB) SECOND_JOB else FIRST_JOB
                schedule(context, immediate = true, jobId = otherJob)
            }
        }
    }
    fun register(context: Context, messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, "supercalendar/auto_wallpaper").setMethodCallHandler { call, result ->
            try {
                when(call.method) {
                    "status" -> result.success(status(context))
                    "saveDesign" -> {
                        val layout = JSONObject(call.argument<String>("layout") ?: error("Missing design"))
                        require(layout.getString("id") == "lock")
                        val width = call.argument<Number>("width")!!.toInt()
                        val height = call.argument<Number>("height")!!.toInt()
                        require(width in 1..8192 && height in 1..8192)
                        synchronized(lock) {
                            // A built-in wallpaper has JSON null here. optString would return "null".
                            val photo = layout.opt("backgroundPath") as? String
                            if (!photo.isNullOrBlank() && !photo.startsWith("data:")) {
                                // Keep the applied design's photo even if an
                                // unapplied editor draft later replaces it.
                                val source = File(photo)
                                val target = File(context.filesDir, "daily-wallpaper-photo")
                                if (source.absolutePath != target.absolutePath) source.copyTo(target, overwrite=true)
                                layout.put("backgroundPath", target.absolutePath)
                            }
                            val id = WallpaperManager.getInstance(context).getWallpaperId(WallpaperManager.FLAG_LOCK)
                            prefs(context).edit().putString("layout", layout.toString()).putInt("width", width).putInt("height", height)
                                .putString("generation", UUID.randomUUID().toString()).putString("updatedDay", today())
                                .putInt("contentRevision", call.argument<Int>("contentRevision") ?: -1)
                                .remove("requestedContentRevision").remove("handledContentRequestId")
                                .putLong("updatedAt", System.currentTimeMillis()).putInt("wallpaperId", id).remove("error").commit()
                            cancel(context); schedule(context)
                        }
                        result.success(null)
                    }
                    "setEnabled" -> {
                        synchronized(lock) {
                            val enabled = call.argument<Boolean>("enabled") == true
                            val p = prefs(context)
                            check(!enabled || p.contains("layout")) { "Apply a lock wallpaper first" }
                            p.edit().putBoolean("asked", true).putBoolean("enabled", enabled)
                                .putString("generation", UUID.randomUUID().toString()).remove("error").commit()
                            cancel(context)
                            try { schedule(context, immediate = needsRefresh(p)) }
                            catch(e: Exception) { p.edit().putBoolean("enabled", false).commit(); throw e }
                        }
                        result.success(null)
                    }
                    "previewTomorrow" -> {
                        check(prefs(context).contains("layout")) { "Apply a lock wallpaper first" }
                        prefs(context).edit().remove("previewReady").remove("previewError").commit()
                        val extras = android.os.PersistableBundle().apply { putBoolean("preview",true) }
                        val job = JobInfo.Builder(PREVIEW_JOB, ComponentName(context,DailyWallpaperJob::class.java)).setMinimumLatency(0).setExtras(extras).build()
                        check(scheduler(context).schedule(job) == JobScheduler.RESULT_SUCCESS)
                        result.success(null)
                    }
                    "previewResult" -> {
                        check(!prefs(context).getBoolean("previewError",false)) { "Preview failed" }
                        val file = File(context.filesDir,"daily-wallpaper-preview.png")
                        result.success(if (prefs(context).getBoolean("previewReady",false) && file.exists()) file.readBytes() else null)
                    }
                    "updateNow" -> { synchronized(lock) { check(prefs(context).getBoolean("enabled", false)); cancel(context); schedule(context, immediate=true, force=true) }; result.success(null) }
                    "catchUp" -> { catchUp(context, call.argument<Int>("contentRevision")); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch(e: Exception) { result.error("daily_wallpaper", e.message, null) }
        }
    }
}

/** Recompute local midnight when the clock/time zone changes. JobScheduler
 * itself restores persisted work after reboot; no exact-alarm permission. */
class DailyWallpaperClockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            synchronized(DailyWallpaper.lock) {
                DailyWallpaper.cancel(context)
                DailyWallpaper.catchUp(context)
            }
        } catch(e: Exception) { android.util.Log.w("DailyWallpaper", "Could not reschedule after clock change", e) }
    }
}
