package com.cloud.pira

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class VpnTrafficMethodChannel {
    companion object {
        private const val CHANNEL = "com.cloud.pira/vpn_traffic"
        
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTrafficService" -> {
                        startTrafficService(context)
                        result.success(true)
                    }
                    "stopTrafficService" -> {
                        stopTrafficService(context)
                        result.success(true)
                    }
                    "updateTraffic" -> {
                        val upload = call.argument<Long>("upload") ?: 0L
                        val download = call.argument<Long>("download") ?: 0L
                        updateTraffic(context, upload, download)
                        result.success(true)
                    }
                    "isServiceRunning" -> {
                        result.success(VpnTrafficService.isRunning())
                    }
                    "getTrafficData" -> {
                        val data = getTrafficData(context)
                        result.success(data)
                    }
                    "resetTrafficData" -> {
                        resetTrafficData(context)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
        
        private fun startTrafficService(context: Context) {
            val intent = Intent(context, VpnTrafficService::class.java).apply {
                action = VpnTrafficService.ACTION_START_SERVICE
            }
            context.startForegroundService(intent)
        }
        
        private fun stopTrafficService(context: Context) {
            val intent = Intent(context, VpnTrafficService::class.java).apply {
                action = VpnTrafficService.ACTION_STOP_SERVICE
            }
            context.startService(intent)
        }
        
        private fun updateTraffic(context: Context, upload: Long, download: Long) {
            val intent = Intent(context, VpnTrafficService::class.java).apply {
                action = VpnTrafficService.ACTION_UPDATE_TRAFFIC
                putExtra("upload", upload)
                putExtra("download", download)
            }
            context.startService(intent)
        }
        
        private fun getTrafficData(context: Context): Map<String, Any> {
            val prefs = context.getSharedPreferences("vpn_traffic_prefs", Context.MODE_PRIVATE)
            return mapOf(
                "uploadBytes" to prefs.getLong("upload_bytes", 0),
                "downloadBytes" to prefs.getLong("download_bytes", 0),
                "totalConnectedTime" to prefs.getLong("total_connected_time", 0),
                "sessionStartTime" to prefs.getLong("session_start_time", 0)
            )
        }
        
        private fun resetTrafficData(context: Context) {
            val prefs = context.getSharedPreferences("vpn_traffic_prefs", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putLong("upload_bytes", 0)
                putLong("download_bytes", 0)
                putLong("total_connected_time", 0)
                putLong("session_start_time", System.currentTimeMillis())
                putLong("last_update_time", System.currentTimeMillis())
                apply()
            }
        }
    }
}