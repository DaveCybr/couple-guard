package com.satellite.child_app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class MyNotificationListenerService : NotificationListenerService() {
    private var methodChannel: MethodChannel? = null
    private var isListening = true

    override fun onCreate() {
        super.onCreate()
        initializeFlutterEngine()
    }

    private fun initializeFlutterEngine() {
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "notification_listener"
        )
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isListening = true
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isListening = false
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (!isListening || sbn == null) return

        try {
            val notification = sbn.notification
            val extras = notification.extras

            val notificationData = mapOf(
                "packageName" to sbn.packageName,
                "title" to (extras.getString("android.title") ?: ""),
                "text" to (extras.getString("android.text") ?: ""),
                "priority" to notification.priority,
                "category" to notification.category,
                "timestamp" to sbn.postTime
            )

            methodChannel?.invokeMethod("onNotificationReceived", notificationData)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (!isListening || sbn == null) return

        val notificationData = mapOf(
            "packageName" to sbn.packageName,
            "timestamp" to sbn.postTime
        )

        methodChannel?.invokeMethod("onNotificationRemoved", notificationData)
    }
}
