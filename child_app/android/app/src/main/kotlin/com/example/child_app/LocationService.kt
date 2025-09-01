package com.satellite.child_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

class LocationService : Service(), LocationListener {
    private lateinit var locationManager: LocationManager
    private var isTracking = false

    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "location_tracking"
        private const val MIN_TIME_INTERVAL = 30000L // 30 seconds
        private const val MIN_DISTANCE = 10f // 10 meters
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START_TRACKING" -> startLocationTracking()
            "STOP_TRACKING" -> stopLocationTracking()
        }
        return START_STICKY
    }

    private fun startLocationTracking() {
        if (isTracking) return

        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            stopSelf()
            return
        }

        val notification = createNotification()
        
        // ✅ Use ServiceCompat for proper foreground service type handling
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceCompat.startForeground(
                    this,
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            // Fallback to regular startForeground
            startForeground(NOTIFICATION_ID, notification)
        }

        try {
            locationManager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                MIN_TIME_INTERVAL,
                MIN_DISTANCE,
                this
            )
            
            locationManager.requestLocationUpdates(
                LocationManager.NETWORK_PROVIDER,
                MIN_TIME_INTERVAL,
                MIN_DISTANCE,
                this
            )
            
            isTracking = true
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun stopLocationTracking() {
        if (!isTracking) return

        locationManager.removeUpdates(this)
        isTracking = false
        stopForeground(true)
        stopSelf()
    }

    override fun onLocationChanged(location: Location) {
        // Send location to server
        sendLocationToServer(location)
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
        // Handle provider status changes
    }

    override fun onProviderEnabled(provider: String) {
        // Handle provider enabled
    }

    override fun onProviderDisabled(provider: String) {
        // Handle provider disabled
    }

    private fun sendLocationToServer(location: Location) {
        try {
            val locationData = mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy,
                "timestamp" to System.currentTimeMillis(),
                "provider" to location.provider
            )
            
            // TODO: Send to server via HTTP/WebSocket
            // ServerApi.sendLocation(locationData)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background location tracking for safety"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Location Tracking Active")
            .setContentText("Keeping you safe")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}