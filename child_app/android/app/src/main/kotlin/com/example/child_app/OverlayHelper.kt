package com.satellite.child_app

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.ImageView

object OverlayHelper {
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    fun showMirroringIndicator(context: Context) {
        try {
            if (overlayView != null) return

            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Create overlay view programmatically since R.layout might not be available
            overlayView = createMirroringIndicatorView(context)

            val layoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
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

    private fun createMirroringIndicatorView(context: Context): View {
        val linearLayout = LinearLayout(context)
        linearLayout.orientation = LinearLayout.HORIZONTAL
        linearLayout.setPadding(16, 8, 16, 8)
        
        // Set background color
        linearLayout.setBackgroundColor(0xAA000000.toInt()) // Semi-transparent black
        
        // Create red dot indicator
        val textView = TextView(context)
        textView.text = "🔴 REC"
        textView.setTextColor(0xFFFFFFFF.toInt()) // White text
        textView.textSize = 10f
        
        linearLayout.addView(textView)
        
        return linearLayout
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