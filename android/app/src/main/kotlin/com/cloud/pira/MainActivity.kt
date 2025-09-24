package com.cloud.pira

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cloud.pira/vpn_control"
    private var vpnControlChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppListMethodChannel.registerWith(flutterEngine, context)
        PingMethodChannel.registerWith(flutterEngine, context)
        SettingsMethodChannel.registerWith(flutterEngine, context)
        
        // Create VPN control channel
        vpnControlChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "FROM_DISCONNECT_BTN") {
            // Send message to Flutter to disconnect VPN
            vpnControlChannel?.invokeMethod("disconnectFromNotification", null)
        }
    }
}