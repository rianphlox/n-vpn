package com.cloud.pira

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.Log
import java.text.SimpleDateFormat
import java.util.*

class VpnTrafficService : Service() {
    companion object {
        const val CHANNEL_ID = "VPN_TRAFFIC_CHANNEL"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START_SERVICE = "START_VPN_TRAFFIC_SERVICE"
        const val ACTION_STOP_SERVICE = "STOP_VPN_TRAFFIC_SERVICE"
        const val ACTION_UPDATE_TRAFFIC = "UPDATE_TRAFFIC"
        
        private const val PREFS_NAME = "vpn_traffic_prefs"
        private const val KEY_UPLOAD_BYTES = "upload_bytes"
        private const val KEY_DOWNLOAD_BYTES = "download_bytes"
        private const val KEY_SESSION_START = "session_start_time"
        private const val KEY_TOTAL_CONNECTED_TIME = "total_connected_time"
        private const val KEY_LAST_UPDATE_TIME = "last_update_time"
        
        private var isServiceRunning = false
        
        fun isRunning(): Boolean {
            return isServiceRunning
        }
    }
    
    private lateinit var notificationManager: NotificationManagerCompat
    private lateinit var sharedPreferences: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private var updateRunnable: Runnable? = null
    
    private var sessionStartTime: Long = 0
    private var lastUpdateTime: Long = 0
    private var uploadBytes: Long = 0
    private var downloadBytes: Long = 0
    private var totalConnectedTime: Long = 0
    
    override fun onCreate() {
        super.onCreate()
        notificationManager = NotificationManagerCompat.from(this)
        sharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        createNotificationChannel()
        loadTrafficData()
        Log.d("VpnTrafficService", "Service created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                startTrafficMonitoring()
                isServiceRunning = true
            }
            ACTION_STOP_SERVICE -> {
                stopTrafficMonitoring()
                isServiceRunning = false
                stopSelf()
            }
            ACTION_UPDATE_TRAFFIC -> {
                val upload = intent.getLongExtra("upload", 0)
                val download = intent.getLongExtra("download", 0)
                updateTrafficData(upload, download)
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Traffic Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows VPN traffic usage in real-time"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun startTrafficMonitoring() {
        sessionStartTime = System.currentTimeMillis()
        lastUpdateTime = sessionStartTime
        saveSessionStartTime()
        
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Update notification every 2 seconds
        updateRunnable = object : Runnable {
            override fun run() {
                updateNotification()
                handler.postDelayed(this, 2000)
            }
        }
        updateRunnable?.let { handler.post(it) }
        
        Log.d("VpnTrafficService", "Traffic monitoring started")
    }
    
    private fun stopTrafficMonitoring() {
        updateRunnable?.let { handler.removeCallbacks(it) }
        saveTrafficData()
        stopForeground(true)
        Log.d("VpnTrafficService", "Traffic monitoring stopped")
    }
    
    private fun updateTrafficData(upload: Long, download: Long) {
        uploadBytes = upload
        downloadBytes = download
        
        // Update total connected time
        val currentTime = System.currentTimeMillis()
        if (lastUpdateTime > 0) {
            totalConnectedTime += (currentTime - lastUpdateTime) / 1000
        }
        lastUpdateTime = currentTime
        
        saveTrafficData()
        updateNotification()
    }
    
    private fun createNotification(): Notification {
        val stopIntent = Intent(this, VpnTrafficService::class.java).apply {
            action = ACTION_STOP_SERVICE
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VPN Connected")
            .setContentText(getTrafficSummary())
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openAppPendingIntent)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Disconnect",
                stopPendingIntent
            )
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText(getDetailedTrafficInfo()))
            .build()
    }
    
    private fun updateNotification() {
        val notification = createNotification()
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun getTrafficSummary(): String {
        val totalTraffic = uploadBytes + downloadBytes
        val connectedTime = getFormattedConnectedTime()
        return "↑${formatBytes(uploadBytes)} ↓${formatBytes(downloadBytes)} | $connectedTime"
    }
    
    private fun getDetailedTrafficInfo(): String {
        val totalTraffic = uploadBytes + downloadBytes
        val connectedTime = getFormattedConnectedTime()
        val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        
        return """
            Total Traffic: ${formatBytes(totalTraffic)}
            Upload: ${formatBytes(uploadBytes)}
            Download: ${formatBytes(downloadBytes)}
            Connected Time: $connectedTime
            Last Update: $currentTime
        """.trimIndent()
    }
    
    private fun getFormattedConnectedTime(): String {
        val currentSessionTime = if (sessionStartTime > 0) {
            (System.currentTimeMillis() - sessionStartTime) / 1000
        } else 0
        
        val totalTime = totalConnectedTime + currentSessionTime
        val hours = totalTime / 3600
        val minutes = (totalTime % 3600) / 60
        val seconds = totalTime % 60
        
        return String.format("%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private fun formatBytes(bytes: Long): String {
        return when {
            bytes < 1024 -> "${bytes}B"
            bytes < 1024 * 1024 -> "${(bytes / 1024.0).let { "%.1f".format(it) }}KB"
            bytes < 1024 * 1024 * 1024 -> "${(bytes / (1024.0 * 1024)).let { "%.1f".format(it) }}MB"
            else -> "${(bytes / (1024.0 * 1024 * 1024)).let { "%.1f".format(it) }}GB"
        }
    }
    
    private fun loadTrafficData() {
        uploadBytes = sharedPreferences.getLong(KEY_UPLOAD_BYTES, 0)
        downloadBytes = sharedPreferences.getLong(KEY_DOWNLOAD_BYTES, 0)
        totalConnectedTime = sharedPreferences.getLong(KEY_TOTAL_CONNECTED_TIME, 0)
        sessionStartTime = sharedPreferences.getLong(KEY_SESSION_START, 0)
        lastUpdateTime = sharedPreferences.getLong(KEY_LAST_UPDATE_TIME, 0)
    }
    
    private fun saveTrafficData() {
        sharedPreferences.edit().apply {
            putLong(KEY_UPLOAD_BYTES, uploadBytes)
            putLong(KEY_DOWNLOAD_BYTES, downloadBytes)
            putLong(KEY_TOTAL_CONNECTED_TIME, totalConnectedTime)
            putLong(KEY_LAST_UPDATE_TIME, lastUpdateTime)
            apply()
        }
    }
    
    private fun saveSessionStartTime() {
        sharedPreferences.edit().apply {
            putLong(KEY_SESSION_START, sessionStartTime)
            apply()
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        updateRunnable?.let { handler.removeCallbacks(it) }
        saveTrafficData()
        isServiceRunning = false
        Log.d("VpnTrafficService", "Service destroyed")
    }
}