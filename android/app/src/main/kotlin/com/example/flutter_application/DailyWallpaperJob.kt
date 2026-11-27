package com.example.flutter_application

import android.app.WallpaperManager
import android.app.job.JobService
import android.app.job.JobParameters
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.graphics.PixelFormat
import android.media.ImageReader
import io.flutter.embedding.engine.renderer.FlutterRenderer
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Short-lived headless Flutter engine. Never launches/unlocks an Activity. */
class DailyWallpaperJob : JobService() {
    private var engine: FlutterEngine? = null
    private var surface: ImageReader? = null
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    @Volatile private var parameters: JobParameters? = null
    private var generation: String? = null
    private val timeout = Runnable { finish(false) }

    override fun onStartJob(params: JobParameters): Boolean {
        if (parameters != null) { jobFinished(params, true); return true }
        val p = DailyWallpaper.prefs(this)
        val preview = params.extras.getBoolean("preview",false)
        val force = params.extras.getBoolean("force", false)
        if (!preview && !p.getBoolean("enabled", false)) return false
        if (preview && !p.contains("layout")) return false
        if (!preview && !force && !DailyWallpaper.needsRefresh(p)) {
            DailyWallpaper.schedule(this, jobId = if(params.jobId == DailyWallpaper.FIRST_JOB) DailyWallpaper.SECOND_JOB else DailyWallpaper.FIRST_JOB)
            return false
        }
        parameters = params
        generation = p.getString("generation", null)
        val renderGeneration = generation
        val contentRequestId = p.getLong("contentRequestId", 0)
        main.postDelayed(timeout, 120_000)
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val flutter = FlutterEngine(applicationContext)
            engine = flutter
            // Impeller needs a real render target even for toImage(). This
            // off-screen buffer is never attached to a window or Activity.
            val width = 330
            val height = (330.0 * p.getInt("height",2400) / p.getInt("width",1080)).toInt().coerceAtLeast(1)
            val buffer = ImageReader.newInstance(width,height,PixelFormat.RGBA_8888,2)
            surface = buffer
            buffer.setOnImageAvailableListener({ reader -> reader.acquireLatestImage()?.close() },main)
            flutter.renderer.startRenderingToSurface(buffer.surface,false)
            flutter.renderer.surfaceChanged(width,height)
            flutter.renderer.setViewportMetrics(FlutterRenderer.ViewportMetrics().apply {
                this.width=width;this.height=height;devicePixelRatio=1.0f
            })
            flutter.lifecycleChannel.appIsResumed()
            MethodChannel(flutter.dartExecutor.binaryMessenger, "supercalendar/system_calendar").setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CALENDAR) == android.content.pm.PackageManager.PERMISSION_GRANTED)
                    "events" -> try {
                        result.success(SystemCalendarQuery.events(this, call.argument<Number>("from")!!.toLong(), call.argument<Number>("to")!!.toLong()))
                    } catch(e: Exception) { result.error("calendar", e.message, null) }
                    else -> result.notImplemented()
                }
            }
            MethodChannel(flutter.dartExecutor.binaryMessenger, "supercalendar/daily_wallpaper_worker").setMethodCallHandler { call, result ->
                when(call.method) {
                    "configuration" -> {
                        val config = DailyWallpaper.prefs(this)
                        if ((!preview && !config.getBoolean("enabled", false)) || config.getString("generation", null) != renderGeneration) result.success(null)
                        else result.success(mapOf("layout" to config.getString("layout", null), "width" to config.getInt("width",1080), "height" to config.getInt("height",2400), "generation" to renderGeneration, "renderDay" to if(preview) java.time.LocalDate.now().plusDays(1).toString() else DailyWallpaper.today()))
                    }
                    "complete" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val expected = call.argument<String>("generation")
                        val renderedDay = call.argument<String>("renderedDay")
                        val contentRevision = call.argument<Int>("contentRevision") ?: -1
                        io.execute {
                            var ok = false
                            try {
                                synchronized(DailyWallpaper.lock) {
                                    val current = DailyWallpaper.prefs(this)
                                    if (parameters === params && expected == renderGeneration &&
                                        current.getString("generation", null) == renderGeneration) {
                                        if (preview) {
                                            check(bytes != null)
                                            java.io.File(filesDir, "daily-wallpaper-preview.png").writeBytes(bytes)
                                            current.edit().putBoolean("previewReady", true).commit()
                                            ok = true
                                        } else if (renderedDay == DailyWallpaper.today() && current.getBoolean("enabled", false)) {
                                            val alreadyApplied = current.getString("updatedDay", null) == renderedDay &&
                                                current.getInt("contentRevision", -1) == contentRevision
                                            ok = if (!force && alreadyApplied) true else applyWallpaper(bytes, current, renderedDay, contentRevision)
                                            // Edits arriving during rendering still have a pending request.
                                            if (ok) current.edit().putLong("handledContentRequestId", contentRequestId).commit()
                                        }
                                    }
                                }
                            } catch(e: Exception) { android.util.Log.w("DailyWallpaper", "Background wallpaper update failed", e) }
                            main.post { result.success(null); if (parameters === params) finish(ok) }
                        }
                    }
                    "failed" -> { result.success(null); if (parameters === params) finish(false) }
                    else -> result.notImplemented()
                }
            }
            flutter.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(),"dailyWallpaperMain"))
            return true
        } catch(e: Exception) { android.util.Log.w("DailyWallpaper","Could not start renderer",e); finish(false); return true }
    }

    private fun applyWallpaper(bytes: ByteArray?, current: SharedPreferences, day: String, revision: Int): Boolean {
        val manager = WallpaperManager.getInstance(this)
        val previous = current.getInt("wallpaperId", -1)
        val actual = manager.getWallpaperId(WallpaperManager.FLAG_LOCK)
        if (previous > 0 && actual != previous) {
            current.edit().putBoolean("enabled", false).putString("error", "wallpaper_changed").commit()
            DailyWallpaper.cancel(this)
            return false
        }
        val bitmap = bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) } ?: error("Invalid PNG")
        try {
            val bounds = Rect(0, 0, bitmap.width, bitmap.height)
            val id = manager.setBitmap(bitmap, bounds, true, WallpaperManager.FLAG_LOCK)
            check(id != 0)
            current.edit().putInt("wallpaperId", id).putString("updatedDay", day)
                .putInt("contentRevision", revision).putLong("updatedAt", System.currentTimeMillis())
                .remove("error").commit()
            return true
        } finally { bitmap.recycle() }
    }

    private fun finish(ok: Boolean) {
        val params = parameters ?: return
        parameters = null
        main.removeCallbacks(timeout)
        destroyEngine()
        val p = DailyWallpaper.prefs(this)
        if (params.extras.getBoolean("preview",false)) {
            if (!ok) p.edit().putBoolean("previewError",true).commit()
            jobFinished(params,false)
            return
        }
        if (!ok && p.getBoolean("enabled",false) && p.getString("generation",null) == generation) p.edit().putString("error","render_failed").commit()
        // Retry failures through Android's backoff, not a busy loop. Successful
        // work schedules the other ID, so finishing this job cannot remove it.
        jobFinished(params, !ok && p.getBoolean("enabled",false))
        if (ok) DailyWallpaper.schedule(
            this,
            immediate = DailyWallpaper.needsRefresh(p),
            jobId = if (params.jobId == DailyWallpaper.FIRST_JOB) DailyWallpaper.SECOND_JOB else DailyWallpaper.FIRST_JOB,
        )
    }
    override fun onStopJob(params: JobParameters): Boolean {
        if (parameters?.jobId != params.jobId) return false
        parameters=null; main.removeCallbacks(timeout); destroyEngine()
        return DailyWallpaper.prefs(this).getBoolean("enabled",false)
    }
    private fun destroyEngine() {
        engine?.renderer?.stopRenderingToSurface()
        engine?.destroy(); engine=null
        surface?.close();surface=null
    }
    override fun onDestroy() { main.removeCallbacks(timeout);destroyEngine();io.shutdown();super.onDestroy() }
}
