package com.satellite.child_app

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView

object OverlayHelper {
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    fun showMirroringIndicator(context: Context) {
        try {
            if (overlayView != null) return

            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Create overlay view
            overlayView = LayoutInflater.from(context).inflate(R.layout.mirroring_indicator, null)

            val layoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.TRANSLUCENT
            )

            layoutParams.gravity = Gravity.TOP or Gravity.END
            layoutParams.x = 20
            layoutParams.y = 100

            windowManager?.addView(overlayView, layoutParams)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun hideMirroringIndicator(context: Context) {
        try {
            if (overlayView != null && windowManager != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
                windowManager = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
