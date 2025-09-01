package com.yourcompany.parental_control_child

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "notification_listener"
    private val SCREEN_CAPTURE_CHANNEL = "screen_capture"
    private val EMERGENCY_CHANNEL = "emergency_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Notification Listener Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationAccess" -> {
                    requestNotificationAccess()
                    result.success(true)
                }
                "hasNotificationAccess" -> {
                    result.success(hasNotificationAccess())
                }
                "startListening" -> {
                    startNotificationListening()
                    result.success(true)
                }
                "stopListening" -> {
                    stopNotificationListening()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Screen Capture Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CAPTURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScreenCapturePermission" -> {
                    requestScreenCapturePermission()
                    result.success(true)
                }
                "captureScreen" -> {
                    captureScreen(result)
                }
                "getCurrentApp" -> {
                    result.success(getCurrentForegroundApp())
                }
                "showMirroringIndicator" -> {
                    showMirroringIndicator()
                    result.success(true)
                }
                "hideMirroringIndicator" -> {
                    hideMirroringIndicator()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Emergency Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EMERGENCY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    result.success(getBatteryLevel())
                }
                "enableLoudMode" -> {
                    enableLoudMode()
                    result.success(true)
                }
                "showMedicalInfo" -> {
                    showMedicalInfo()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestNotificationAccess() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    private fun hasNotificationAccess(): Boolean {
        val enabledNotificationListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        return enabledNotificationListeners?.contains(packageName) == true
    }

    private fun startNotificationListening() {
        val intent = Intent(this, NotificationListenerService::class.java)
        intent.action = "START_LISTENING"
        startService(intent)
    }

    private fun stopNotificationListening() {
        val intent = Intent(this, NotificationListenerService::class.java)
        intent.action = "STOP_LISTENING"
        startService(intent)
    }

    private fun requestScreenCapturePermission() {
        if (!Settings.canDrawOverlays(this)) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            startActivity(intent)
        }
    }

    private fun captureScreen(result: MethodChannel.Result) {
        // Implement screen capture logic
        // This would use MediaProjection API
        try {
            val screenshotBytes = ScreenCaptureHelper.captureScreen(this)
            result.success(screenshotBytes)
        } catch (e: Exception) {
            result.error("CAPTURE_FAILED", e.message, null)
        }
    }

    private fun getCurrentForegroundApp(): String? {
        // Get current foreground app package name
        return ForegroundAppDetector.getCurrentApp(this)
    }

    private fun showMirroringIndicator() {
        // Show subtle overlay indicating screen is being mirrored
        OverlayHelper.showMirroringIndicator(this)
    }

    private fun hideMirroringIndicator() {
        OverlayHelper.hideMirroringIndicator(this)
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
        return batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun enableLoudMode() {
        // Set device to maximum volume for emergency
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
        audioManager.setStreamVolume(
            android.media.AudioManager.STREAM_RING,
            audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_RING),
            0
        )
    }

    private fun showMedicalInfo() {
        // Show emergency medical information
        // This could display stored medical ID info
    }
}