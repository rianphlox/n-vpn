import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class VpnTrafficBackgroundService {
  static const MethodChannel _channel = MethodChannel('com.cloud.pira/vpn_traffic');
  
  // Singleton pattern
  static final VpnTrafficBackgroundService _instance = VpnTrafficBackgroundService._internal();
  factory VpnTrafficBackgroundService() => _instance;
  VpnTrafficBackgroundService._internal();
  
  /// Start the background traffic monitoring service
  static Future<bool> startService() async {
    try {
      // Only start on Android
      if (defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      
      final bool result = await _channel.invokeMethod('startTrafficService');
      debugPrint('VPN Traffic Service started: $result');
      return result;
    } catch (e) {
      debugPrint('Error starting VPN traffic service: $e');
      return false;
    }
  }
  
  /// Stop the background traffic monitoring service
  static Future<bool> stopService() async {
    try {
      // Only stop on Android
      if (defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      
      final bool result = await _channel.invokeMethod('stopTrafficService');
      debugPrint('VPN Traffic Service stopped: $result');
      return result;
    } catch (e) {
      debugPrint('Error stopping VPN traffic service: $e');
      return false;
    }
  }
  
  /// Update traffic data in the background service
  static Future<bool> updateTraffic({required int upload, required int download}) async {
    try {
      // Only update on Android
      if (defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      
      final bool result = await _channel.invokeMethod('updateTraffic', {
        'upload': upload,
        'download': download,
      });
      return result;
    } catch (e) {
      debugPrint('Error updating traffic data: $e');
      return false;
    }
  }
  
  /// Check if the background service is running
  static Future<bool> isServiceRunning() async {
    try {
      // Only check on Android
      if (defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      
      final bool result = await _channel.invokeMethod('isServiceRunning');
      return result;
    } catch (e) {
      debugPrint('Error checking service status: $e');
      return false;
    }
  }
  
  /// Get traffic data from the background service
  static Future<Map<String, dynamic>?> getTrafficData() async {
    try {
      // Only get data on Android
      if (defaultTargetPlatform != TargetPlatform.android) {
        return null;
      }
      
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getTrafficData');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Error getting traffic data: $e');
      return null;
    }
  }
  
  /// Reset traffic data in the background service
  static Future<bool> resetTrafficData() async {
    try {
      // Only reset on Android
      if (defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      
      final bool result = await _channel.invokeMethod('resetTrafficData');
      debugPrint('Traffic data reset: $result');
      return result;
    } catch (e) {
      debugPrint('Error resetting traffic data: $e');
      return false;
    }
  }
}

class TrafficData {
  final int uploadBytes;
  final int downloadBytes;
  final int totalConnectedTime;
  final int sessionStartTime;
  
  TrafficData({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.totalConnectedTime,
    required this.sessionStartTime,
  });
  
  factory TrafficData.fromMap(Map<String, dynamic> map) {
    return TrafficData(
      uploadBytes: (map['uploadBytes'] as num?)?.toInt() ?? 0,
      downloadBytes: (map['downloadBytes'] as num?)?.toInt() ?? 0,
      totalConnectedTime: (map['totalConnectedTime'] as num?)?.toInt() ?? 0,
      sessionStartTime: (map['sessionStartTime'] as num?)?.toInt() ?? 0,
    );
  }
  
  int get totalBytes => uploadBytes + downloadBytes;
  
  String get formattedUpload => _formatBytes(uploadBytes);
  String get formattedDownload => _formatBytes(downloadBytes);
  String get formattedTotal => _formatBytes(totalBytes);
  
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}