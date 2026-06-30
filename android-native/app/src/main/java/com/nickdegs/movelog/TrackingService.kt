package com.nickdegs.movelog

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

// Canlı rota kaydı: foreground service + FusedLocation -> Traccar OsmAnd ingest (iOS Tracker.swift karşılığı).
// Konumlar sunucuya gider, backend aktiviteyi otomatik algılar.
class TrackingService : Service() {
    companion object {
        var active = false; private set
        private const val CH = "movelog_tracking"
        private const val NID = 42
        fun start(ctx: Context, deviceId: String, url: String) {
            val i = Intent(ctx, TrackingService::class.java).putExtra("id", deviceId).putExtra("url", url)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) ctx.startForegroundService(i) else ctx.startService(i)
        }
        fun stop(ctx: Context) { ctx.stopService(Intent(ctx, TrackingService::class.java)) }
    }

    private lateinit var fused: FusedLocationProviderClient
    private var deviceId: String = ""
    private var ingestUrl: String = ""
    private var lastSent: Location? = null

    private val cb = object : LocationCallback() {
        override fun onLocationResult(res: LocationResult) {
            val loc = res.lastLocation ?: return
            // ışınlanma filtresi (>252 km/h imkansız)
            lastSent?.let { p ->
                val dt = (loc.time - p.time) / 1000.0
                if (dt > 0 && loc.distanceTo(p) / dt > 70) return
            }
            lastSent = loc
            send(loc)
        }
    }

    override fun onCreate() {
        super.onCreate()
        fused = LocationServices.getFusedLocationProviderClient(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        deviceId = intent?.getStringExtra("id") ?: ""
        ingestUrl = intent?.getStringExtra("url") ?: ""
        startForeground(NID, notification())
        active = true
        val req = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000L)
            .setMinUpdateIntervalMillis(3000L).setMinUpdateDistanceMeters(5f).build()
        try { fused.requestLocationUpdates(req, cb, mainLooper) } catch (e: SecurityException) {}
        return START_STICKY
    }

    private fun send(loc: Location) {
        if (deviceId.isEmpty() || ingestUrl.isEmpty()) return
        Thread {
            try {
                val sep = if (ingestUrl.contains("?")) "&" else "?"
                fun e(v: String) = URLEncoder.encode(v, "UTF-8")
                val q = "${sep}id=${e(deviceId)}&lat=${loc.latitude}&lon=${loc.longitude}" +
                    "&timestamp=${loc.time / 1000}&speed=${(loc.speed * 1.94384)}" +   // m/s -> knot
                    "&altitude=${loc.altitude}&accuracy=${loc.accuracy}&bearing=${loc.bearing}"
                val c = (URL(ingestUrl + q).openConnection() as HttpURLConnection)
                c.requestMethod = "POST"; c.connectTimeout = 10000; c.readTimeout = 10000
                c.doOutput = true; OutputStreamWriter(c.outputStream).use { it.write("") }
                c.responseCode
                c.disconnect()
            } catch (e: Exception) {}
        }.start()
    }

    private fun notification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CH, "Rota kaydı", NotificationManager.IMPORTANCE_LOW)
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        }
        val tap = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CH)
            .setContentTitle("Move Log")
            .setContentText("Rotan kaydediliyor…")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true).setContentIntent(tap).build()
    }

    override fun onDestroy() {
        active = false
        try { fused.removeLocationUpdates(cb) } catch (e: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
