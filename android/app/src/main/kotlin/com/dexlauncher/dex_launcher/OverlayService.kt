package com.dexlauncher.dex_launcher

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.provider.Settings
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

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()

        if (!Settings.canDrawOverlays(this)) return

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // Schmaler unsichtbarer Touch-Bereich am unteren Rand (8dp)
        val density = resources.displayMetrics.density
        val heightPx = (8 * density).toInt()

        overlayView = FrameLayout(this).apply {
            setBackgroundColor(0x00000000) // komplett transparent
            setOnTouchListener { _, event ->
                if (event.action == MotionEvent.ACTION_DOWN) {
                    // DeX Launcher in den Vordergrund bringen
                    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                    launchIntent?.addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    )
                    if (launchIntent != null) startActivity(launchIntent)
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
    }

    override fun onDestroy() {
        super.onDestroy()
        overlayView?.let { windowManager?.removeView(it) }
        overlayView = null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }
}
