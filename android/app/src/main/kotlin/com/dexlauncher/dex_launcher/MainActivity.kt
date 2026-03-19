package com.dexlauncher.dex_launcher

import android.app.ActivityOptions
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Rect
import android.hardware.input.InputManager
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.view.InputDevice
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dexlauncher/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        launchApp(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    }
                }
                "openAppInfo" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openAppInfo(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    }
                }
                "getRecentApps" -> {
                    val limit = call.argument<Int>("limit") ?: 10
                    val recentApps = getRecentApps(limit)
                    result.success(recentApps)
                }
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        uninstallApp(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    }
                }
                "getSystemStatus" -> {
                    result.success(getSystemStatus())
                }
                "startOverlay" -> {
                    try {
                        startService(Intent(this@MainActivity, OverlayService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopOverlay" -> {
                    stopService(Intent(this@MainActivity, OverlayService::class.java))
                    result.success(true)
                }
                "canDrawOverlays" -> {
                    // Auf Android TV gibt canDrawOverlays oft false zurück
                    // obwohl appops SYSTEM_ALERT_WINDOW allow gesetzt ist.
                    // Wir versuchen es einfach — der Service fängt den Fehler ab.
                    result.success(true)
                }
                "getWallpaperImages" -> {
                    result.success(getWallpaperImages())
                }
                "setVolume" -> {
                    val percent = call.argument<Int>("percent") ?: 50
                    setVolume(percent)
                    result.success(true)
                }
                "isFreeformEnabled" -> {
                    result.success(isFreeformEnabled())
                }
                "launchAppFreeform" -> {
                    val packageName = call.argument<String>("packageName")
                    val left = call.argument<Int>("left") ?: 100
                    val top = call.argument<Int>("top") ?: 100
                    val right = call.argument<Int>("right") ?: 900
                    val bottom = call.argument<Int>("bottom") ?: 600
                    if (packageName != null) {
                        val success = launchAppFreeform(packageName, left, top, right, bottom)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    }
                }
                "hasExternalMouse" -> {
                    result.success(hasExternalMouse())
                }
                "enableFreeform" -> {
                    val success = enableFreeform()
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val myPackage = packageName

        // Standard-Apps (LAUNCHER Kategorie)
        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val launcherApps = pm.queryIntentActivities(launcherIntent, 0)

        // TV-only Apps (LEANBACK_LAUNCHER Kategorie)
        val leanbackIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER)
        }
        val leanbackApps = pm.queryIntentActivities(leanbackIntent, 0)

        // Zusammenführen, Duplikate per packageName entfernen
        val seen = mutableSetOf<String>()
        val apps = mutableListOf<ResolveInfo>()
        for (info in launcherApps + leanbackApps) {
            val pkg = info.activityInfo.packageName
            if (pkg != myPackage && seen.add(pkg)) {
                apps.add(info)
            }
        }

        return apps
            .map { resolveInfo ->
                val appInfo = resolveInfo.activityInfo.applicationInfo
                val icon = try {
                    drawableToBytes(pm.getApplicationIcon(appInfo))
                } catch (e: Exception) {
                    null
                }

                val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    appInfo.category
                } else {
                    -1
                }

                mapOf(
                    "name" to (pm.getApplicationLabel(appInfo)?.toString() ?: "Unknown"),
                    "packageName" to resolveInfo.activityInfo.packageName,
                    "icon" to icon,
                    "isSystemApp" to (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM != 0),
                    "category" to category
                )
            }
            .sortedBy { (it["name"] as String).lowercase() }
    }

    private fun launchApp(packageName: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    private fun openAppInfo(packageName: String) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun uninstallApp(packageName: String) {
        val intent = Intent(Intent.ACTION_DELETE).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun hasExternalMouse(): Boolean {
        val inputDevices = InputDevice.getDeviceIds()
        for (id in inputDevices) {
            val device = InputDevice.getDevice(id) ?: continue
            val sources = device.sources
            // SOURCE_MOUSE = echte Maus (USB/Bluetooth)
            if (sources and InputDevice.SOURCE_MOUSE == InputDevice.SOURCE_MOUSE) {
                return true
            }
        }
        return false
    }

    private fun isFreeformEnabled(): Boolean {
        // Prüfe ob das Setting aktiviert ist UND das Gerät Freeform unterstützt
        val settingEnabled = try {
            Settings.Global.getInt(contentResolver, "enable_freeform_support", 0) == 1
        } catch (e: Exception) {
            false
        }

        if (!settingEnabled) return false

        // Prüfe ob das Gerät die Feature-Flag hat
        val hasFeature = packageManager.hasSystemFeature("android.software.freeform_window_management")

        // Auf manchen Geräten fehlt die Feature-Flag aber es geht trotzdem.
        // Google TV (Leanback) blockiert Freeform aktiv.
        val isGoogleTV = packageManager.hasSystemFeature("android.software.leanback")

        return hasFeature || !isGoogleTV
    }

    private fun enableFreeform(): Boolean {
        return try {
            // Funktioniert nur mit WRITE_SECURE_SETTINGS (per ADB gewährt)
            Settings.Global.putInt(contentResolver, "enable_freeform_support", 1)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun launchAppFreeform(
        packageName: String,
        left: Int, top: Int, right: Int, bottom: Int
    ): Boolean {
        val pm = getPackageManager()
        val launchIntent = pm.getLaunchIntentForPackage(packageName) ?: return false

        launchIntent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_MULTIPLE_TASK or
            Intent.FLAG_ACTIVITY_LAUNCH_ADJACENT
        )

        val options = ActivityOptions.makeBasic()
        options.setLaunchBounds(Rect(left, top, right, bottom))

        try {
            startActivity(launchIntent, options.toBundle())
            return true
        } catch (e: Exception) {
            // Fallback: normaler Launch ohne Freeform
            launchApp(packageName)
            return false
        }
    }

    private fun getRecentApps(limit: Int): List<String> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            now - 24 * 60 * 60 * 1000, // letzte 24 Stunden
            now
        )

        if (stats.isNullOrEmpty()) return emptyList()

        val myPackage = packageName
        return stats
            .filter { it.packageName != myPackage && it.totalTimeInForeground > 0 }
            .sortedByDescending { it.lastTimeUsed }
            .take(limit)
            .map { it.packageName }
    }

    private fun getWallpaperImages(): List<String> {
        val images = mutableListOf<String>()
        val extensions = setOf("jpg", "jpeg", "png", "webp", "bmp")

        // Suche in Downloads, Pictures, und DCIM
        val dirs = listOf(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM),
            // App-eigener Wallpaper-Ordner
            java.io.File(getExternalFilesDir(null), "wallpapers"),
        )

        for (dir in dirs) {
            if (!dir.exists()) continue
            dir.walkTopDown().maxDepth(2).forEach { file ->
                if (file.isFile && file.extension.lowercase() in extensions) {
                    images.add(file.absolutePath)
                }
            }
        }

        return images.sorted()
    }

    private fun setVolume(percent: Int) {
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val vol = (percent * maxVol) / 100
        am.setStreamVolume(AudioManager.STREAM_MUSIC, vol, 0)
    }

    private fun getSystemStatus(): Map<String, Any?> {
        // Batterie
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val batteryLevel = batteryIntent?.let { intent ->
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (level >= 0 && scale > 0) (level * 100) / scale else -1
        } ?: -1
        val isCharging = batteryIntent?.let { intent ->
            val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        } ?: false

        // WLAN
        var wifiConnected = false
        var wifiName: String? = null
        var wifiStrength = -1
        var ethernetConnected = false
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        if (cm != null) {
            try {
                val network = cm.activeNetwork
                val caps = cm.getNetworkCapabilities(network)
                wifiConnected = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
                ethernetConnected = caps?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true

                if (wifiConnected) {
                    // Android 14+: SSID über TransportInfo aus NetworkCapabilities
                    val transportInfo = caps?.transportInfo
                    if (transportInfo is android.net.wifi.WifiInfo) {
                        val ssid = transportInfo.ssid
                        if (ssid != null && ssid != "<unknown ssid>") {
                            wifiName = ssid.replace("\"", "")
                        }
                        wifiStrength = WifiManager.calculateSignalLevel(transportInfo.rssi, 5)
                    }

                    // Fallback: WifiManager (braucht evtl. Location-Permission)
                    if (wifiName == null || wifiName == "<unknown ssid>") {
                        val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                        @Suppress("DEPRECATION")
                        val info = wm?.connectionInfo
                        if (info != null) {
                            val ssid = info.ssid?.replace("\"", "")
                            if (ssid != null && ssid != "<unknown ssid>") {
                                wifiName = ssid
                            }
                            if (wifiStrength < 0) {
                                wifiStrength = WifiManager.calculateSignalLevel(info.rssi, 5)
                            }
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        // Lautstärke
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val volume = am?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
        val maxVolume = am?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 1
        val volumePercent = (volume * 100) / maxVolume
        val isMuted = am?.isStreamMute(AudioManager.STREAM_MUSIC) == true

        return mapOf(
            "batteryLevel" to batteryLevel,
            "isCharging" to isCharging,
            "wifiConnected" to wifiConnected,
            "wifiName" to wifiName,
            "wifiStrength" to wifiStrength,
            "ethernetConnected" to ethernetConnected,
            "volumePercent" to volumePercent,
            "isMuted" to isMuted,
            "hasExternalMouse" to hasExternalMouse()
        )
    }

    private fun drawableToBytes(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val bmp = Bitmap.createBitmap(
                drawable.intrinsicWidth.coerceAtLeast(1),
                drawable.intrinsicHeight.coerceAtLeast(1),
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
