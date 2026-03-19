package com.dexlauncher.dex_launcher

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout

/**
 * Overlay Service — zeigt eine transparente Touch-Leiste am unteren Bildschirmrand.
 * Wenn der User den Bereich berührt, wird der DeX Launcher in den Vordergrund gebracht.
 *
 * Benötigt: adb shell appops set com.dexlauncher.dex_launcher SYSTEM_ALERT_WINDOW allow
 */
class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val TAG = "DexOverlay"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "OverlayService onCreate")
        setupOverlay()
    }

    private fun setupOverlay() {
        try {
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Touch-Bereich am unteren Rand (12dp) — etwas größer für bessere Erkennung
            val density = resources.displayMetrics.density
            val heightPx = (12 * density).toInt()

            overlayView = FrameLayout(this).apply {
                // Leicht sichtbar zum Debuggen (sehr dezent)
                setBackgroundColor(0x08FFFFFF)
                setOnTouchListener { _, event ->
                    if (event.action == MotionEvent.ACTION_DOWN) {
                        Log.d(TAG, "Overlay touched — bringing launcher to front")
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        launchIntent?.addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        )
                        if (launchIntent != null) {
                            startActivity(launchIntent)
                        }
                    }
                    false
                }
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                heightPx,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.BOTTOM
            }

            windowManager?.addView(overlayView, params)
            Log.d(TAG, "Overlay view added successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create overlay: ${e.message}")
            stopSelf()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "OverlayService onDestroy")
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (_: Exception) {}
        overlayView = null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "OverlayService onStartCommand")
        // Falls View noch nicht erstellt, nochmal versuchen
        if (overlayView == null) {
            setupOverlay()
        }
        return START_STICKY
    }
}
