package com.satellite.child_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                // Auto-start monitoring services after boot
                startMonitoringServices(context)
            }
        }
    }
    
    private fun startMonitoringServices(context: Context) {
        try {
            // ✅ REMOVED: Don't start LocationService manually
            // Let FlutterBackgroundService handle everything
            
            // Start notification listener service only
            val notificationIntent = Intent(context, MyNotificationListenerService::class.java)
            notificationIntent.action = "START_LISTENING"
            context.startService(notificationIntent)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}