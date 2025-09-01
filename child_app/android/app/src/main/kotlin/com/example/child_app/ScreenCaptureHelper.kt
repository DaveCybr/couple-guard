package com.satellite.child_app

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

object ScreenCaptureHelper {
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null

    fun captureScreen(activity: Activity): ByteArray? {
        try {
            val metrics = DisplayMetrics()
            activity.windowManager.defaultDisplay.getMetrics(metrics)
            
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi

            // Create ImageReader
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            
            // Setup MediaProjection if not already setup
            if (mediaProjection == null) {
                val projectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                // Note: This requires permission intent result from Flutter side
            }

            var screenshotData: ByteArray? = null
            val handler = Handler(Looper.getMainLooper())

            imageReader?.setOnImageAvailableListener({
                val image = imageReader?.acquireLatestImage()
                if (image != null) {
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * width

                    val bitmap = Bitmap.createBitmap(
                        width + rowPadding / pixelStride,
                        height,
                        Bitmap.Config.ARGB_8888
                    )
                    bitmap.copyPixelsFromBuffer(buffer)

                    // Convert to JPEG
                    val outputStream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 70, outputStream)
                    screenshotData = outputStream.toByteArray()

                    bitmap.recycle()
                    image.close()
                }
            }, handler)

            // Create virtual display
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenCapture",
                width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, null
            )

            // Wait for screenshot to be captured
            Thread.sleep(100)

            return screenshotData
            
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        } finally {
            virtualDisplay?.release()
            imageReader?.close()
        }
    }

    fun startScreenMirroring(mediaProjection: MediaProjection, callback: (ByteArray) -> Unit) {
        this.mediaProjection = mediaProjection
        // Implementation for continuous screen capture
    }

    fun stopScreenMirroring() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        mediaProjection = null
    }
}
