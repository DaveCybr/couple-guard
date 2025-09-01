# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }
-dontwarn id.flutter.flutter_background_service.**

# Custom Services
-keep class com.satellite.child_app.LocationService { *; }
-keep class com.satellite.child_app.MyNotificationListenerService { *; }
-keep class com.satellite.child_app.BootReceiver { *; }

# Foreground Service
-keep class androidx.core.app.ServiceCompat { *; }
-dontwarn androidx.core.app.ServiceCompat

# Location Services
-keep class android.location.** { *; }
-dontwarn android.location.**

# Notification Services
-keep class android.service.notification.** { *; }
-dontwarn android.service.notification.**