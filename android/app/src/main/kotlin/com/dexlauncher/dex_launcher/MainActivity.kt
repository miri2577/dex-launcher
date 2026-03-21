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
import android.app.ActivityManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Bildschirmtastatur permanent unterdrücken bei Hardware-Tastatur
        try {
            Settings.Secure.putInt(contentResolver, "show_ime_with_hard_keyboard", 0)
        } catch (_: Exception) {
            // Fallback per Shell
            try { Runtime.getRuntime().exec(arrayOf("sh", "-c", "settings put secure show_ime_with_hard_keyboard 0")) } catch (_: Exception) {}
        }

        // Runtime permission for reading images (needed for wallpaper picker)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.READ_MEDIA_IMAGES), 100)
        } else {
            requestPermissions(arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE), 100)
        }

        // Soft keyboard aggressiv unterdrücken
        window.setSoftInputMode(android.view.WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN)

        // Optimize density for 1080p desktop use
        // density 240 on 1080p gives more screen real estate while keeping text readable
        try {
            Runtime.getRuntime().exec(arrayOf("sh", "-c", "wm density 240"))
        } catch (_: Exception) {}
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Keyboard bei jedem Focus-Wechsel verstecken
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager
            imm?.hideSoftInputFromWindow(window.decorView.windowToken, 0)
            // Setting nochmal setzen (kann von System zurückgesetzt werden)
            try { Settings.Secure.putInt(contentResolver, "show_ime_with_hard_keyboard", 0) } catch (_: Exception) {}
        }
    }

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
                "getUsbDevices" -> {
                    result.success(getUsbDevices())
                }
                "getNotifications" -> {
                    // Notifications brauchen NotificationListenerService — Platzhalter
                    result.success(emptyList<Map<String, Any?>>())
                }
                "searchFiles" -> {
                    val query = call.argument<String>("query") ?: ""
                    result.success(searchFiles(query))
                }
                "runSpeedTest" -> {
                    result.success(runSpeedTest())
                }
                "getRunningApps" -> {
                    result.success(getRunningApps())
                }
                "killApp" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    @Suppress("DEPRECATION")
                    am.killBackgroundProcesses(pkg)
                    result.success(true)
                }
                "takeScreenshot" -> {
                    // Screenshot per Tastenkombination simulieren
                    executeCommand("input keyevent KEYCODE_SYSRQ")
                    result.success(true)
                }
                "scanNetwork" -> {
                    result.success(scanNetwork())
                }
                "getAudioFiles" -> {
                    result.success(getAudioFiles())
                }
                "downloadFile" -> {
                    val url = call.argument<String>("url") ?: ""
                    val savePath = call.argument<String>("savePath") ?: ""
                    Thread {
                        try {
                            val connection = java.net.URL(url).openConnection() as java.net.HttpURLConnection
                            connection.connectTimeout = 15000
                            connection.readTimeout = 30000
                            connection.instanceFollowRedirects = true
                            val input = connection.inputStream
                            val file = java.io.File(savePath)
                            file.parentFile?.mkdirs()
                            val output = java.io.FileOutputStream(file)
                            input.copyTo(output)
                            output.close()
                            input.close()
                            connection.disconnect()
                            runOnUiThread { result.success(mapOf("success" to true, "path" to savePath, "size" to file.length())) }
                        } catch (e: Exception) {
                            runOnUiThread { result.success(mapOf("success" to false, "error" to (e.message ?: "Download fehlgeschlagen"))) }
                        }
                    }.start()
                    return@setMethodCallHandler // result wird im Thread gesendet
                }
                "installApk" -> {
                    val path = call.argument<String>("path") ?: ""
                    try {
                        val file = java.io.File(path)
                        val uri = androidx.core.content.FileProvider.getUriForFile(
                            this@MainActivity,
                            "${packageName}.fileprovider",
                            file
                        )
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "exitApp" -> {
                    finishAndRemoveTask()
                    result.success(true)
                }
                "goToSleep" -> {
                    // Bildschirm ausschalten
                    executeCommand("input keyevent KEYCODE_SLEEP")
                    result.success(true)
                }
                "playVideo" -> {
                    val path = call.argument<String>("path") ?: ""
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(
                            androidx.core.content.FileProvider.getUriForFile(
                                this@MainActivity,
                                "${packageName}.fileprovider",
                                java.io.File(path)
                            ),
                            "video/*"
                        )
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback: direct file URI
                        val fallback = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(Uri.parse("file://$path"), "video/*")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        try { startActivity(fallback); result.success(true) }
                        catch (_: Exception) { result.success(false) }
                    }
                }
                "executeCommand" -> {
                    val command = call.argument<String>("command") ?: ""
                    result.success(executeCommand(command))
                }
                "getBluetoothDevices" -> {
                    result.success(getBluetoothDevices())
                }
                "isBluetoothEnabled" -> {
                    result.success(isBluetoothEnabled())
                }
                "getSystemInfo" -> {
                    result.success(getSystemInfo())
                }
                "scanWifiNetworks" -> {
                    result.success(scanWifiNetworks())
                }
                "connectWifi" -> {
                    val ssid = call.argument<String>("ssid") ?: ""
                    val password = call.argument<String>("password")
                    result.success(connectWifi(ssid, password))
                }
                "getCurrentWifiInfo" -> {
                    result.success(getCurrentWifiInfo())
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
        // Wenn das Setting aktiviert ist, versuchen wir es einfach.
        // setLaunchBounds() wird stillschweigend ignoriert wenn es nicht geht.
        return try {
            Settings.Global.getInt(contentResolver, "enable_freeform_support", 0) == 1
        } catch (e: Exception) {
            false
        }
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

    private fun getUsbDevices(): List<Map<String, String>> {
        val usbManager = getSystemService(Context.USB_SERVICE) as? android.hardware.usb.UsbManager
            ?: return emptyList()
        return usbManager.deviceList.values.map { device ->
            mapOf(
                "name" to (device.productName ?: "USB Geraet"),
                "vendor" to "VID:${device.vendorId} PID:${device.productId}",
                "class" to "Klasse ${device.deviceClass}",
            )
        }.toList()
    }

    private fun searchFiles(query: String): List<Map<String, String>> {
        if (query.length < 2) return emptyList()
        val results = mutableListOf<Map<String, String>>()
        val root = java.io.File("/storage/emulated/0")
        val q = query.lowercase()
        root.walkTopDown().maxDepth(4).take(5000).forEach { file ->
            if (file.name.lowercase().contains(q)) {
                results.add(mapOf("path" to file.absolutePath, "name" to file.name, "isDir" to file.isDirectory.toString()))
                if (results.size >= 50) return@forEach
            }
        }
        return results
    }

    private fun runSpeedTest(): Map<String, Any?> {
        return try {
            val start = System.currentTimeMillis()
            val url = java.net.URL("https://speed.cloudflare.com/__down?bytes=1000000")
            val conn = url.openConnection() as java.net.HttpURLConnection
            conn.connectTimeout = 10000
            conn.readTimeout = 10000
            val bytes = conn.inputStream.readBytes()
            val elapsed = System.currentTimeMillis() - start
            conn.disconnect()
            val mbps = if (elapsed > 0) (bytes.size * 8.0 / 1000.0 / elapsed) else 0.0
            mapOf("mbps" to "%.1f".format(mbps), "bytes" to bytes.size, "ms" to elapsed)
        } catch (e: Exception) {
            mapOf("mbps" to "0", "bytes" to 0, "ms" to 0, "error" to (e.message ?: "Fehler"))
        }
    }

    @Suppress("DEPRECATION")
    private fun getRunningApps(): List<Map<String, Any?>> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        am.getMemoryInfo(memInfo)

        return am.getRunningAppProcesses()?.map { process ->
            val memArr = am.getProcessMemoryInfo(intArrayOf(process.pid))
            val memMB = if (memArr.isNotEmpty()) memArr[0].totalPss / 1024 else 0
            mapOf(
                "name" to process.processName,
                "pid" to process.pid,
                "memoryMB" to memMB,
                "importance" to process.importance,
            )
        }?.sortedByDescending { it["memoryMB"] as Int }?.take(30) ?: emptyList()
    }

    private fun scanNetwork(): List<Map<String, String>> {
        val results = mutableListOf<Map<String, String>>()
        try {
            // ARP-Tabelle auslesen
            val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", "cat /proc/net/arp"))
            val output = process.inputStream.bufferedReader().readText()
            for (line in output.lines().drop(1)) { // Header überspringen
                val parts = line.trim().split("\\s+".toRegex())
                if (parts.size >= 4 && parts[2] != "0x0") {
                    results.add(mapOf(
                        "ip" to parts[0],
                        "mac" to parts[3],
                        "device" to (parts.getOrNull(5) ?: ""),
                    ))
                }
            }
        } catch (_: Exception) {}
        return results
    }

    private fun getAudioFiles(): List<Map<String, Any?>> {
        val files = mutableListOf<Map<String, Any?>>()
        val extensions = setOf("mp3", "flac", "wav", "ogg", "aac", "m4a", "wma")
        val dirs = listOf(
            java.io.File("/storage/emulated/0/Music"),
            java.io.File("/storage/emulated/0/Download"),
        )
        for (dir in dirs) {
            if (!dir.exists()) continue
            dir.walkTopDown().maxDepth(3).forEach { file ->
                if (file.isFile && file.extension.lowercase() in extensions) {
                    files.add(mapOf(
                        "path" to file.absolutePath,
                        "name" to file.nameWithoutExtension,
                        "size" to file.length(),
                    ))
                }
            }
        }
        return files.sortedBy { (it["name"] as String).lowercase() }
    }

    private fun executeCommand(command: String): Map<String, Any?> {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", command))
            val stdout = process.inputStream.bufferedReader().readText()
            val stderr = process.errorStream.bufferedReader().readText()
            val exitCode = process.waitFor()

            mapOf(
                "stdout" to stdout,
                "stderr" to stderr,
                "exitCode" to exitCode,
            )
        } catch (e: Exception) {
            mapOf(
                "stdout" to "",
                "stderr" to "Error: ${e.message}",
                "exitCode" to -1,
            )
        }
    }

    @Suppress("MissingPermission")
    private fun getBluetoothDevices(): List<Map<String, Any?>> {
        val bm = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = bm?.adapter ?: return emptyList()

        return try {
            adapter.bondedDevices?.map { device ->
                mapOf(
                    "name" to (device.name ?: "Unbekannt"),
                    "address" to device.address,
                    "type" to when (device.type) {
                        1 -> "Classic"
                        2 -> "LE"
                        3 -> "Dual"
                        else -> "Unbekannt"
                    },
                    "bonded" to true,
                )
            }?.toList() ?: emptyList()
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun isBluetoothEnabled(): Boolean {
        val bm = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return bm?.adapter?.isEnabled == true
    }

    private fun getSystemInfo(): Map<String, Any?> {
        val runtime = Runtime.getRuntime()
        val usedMem = (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024
        val totalMem = runtime.totalMemory() / 1024 / 1024
        val maxMem = runtime.maxMemory() / 1024 / 1024

        // Storage
        val stat = android.os.StatFs(android.os.Environment.getDataDirectory().path)
        val totalStorage = stat.totalBytes / 1024 / 1024
        val freeStorage = stat.availableBytes / 1024 / 1024

        return mapOf(
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT,
            "usedMemoryMB" to usedMem,
            "totalMemoryMB" to totalMem,
            "maxMemoryMB" to maxMem,
            "totalStorageMB" to totalStorage,
            "freeStorageMB" to freeStorage,
            "cpuCores" to runtime.availableProcessors(),
        )
    }

    @Suppress("DEPRECATION")
    private fun scanWifiNetworks(): List<Map<String, Any?>> {
        val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return emptyList()

        wm.startScan()
        val results = wm.scanResults ?: return emptyList()

        val seen = mutableSetOf<String>()
        return results
            .filter { it.SSID.isNotEmpty() && seen.add(it.SSID) }
            .sortedByDescending { it.level }
            .map { sr ->
                mapOf(
                    "ssid" to sr.SSID,
                    "level" to WifiManager.calculateSignalLevel(sr.level, 5),
                    "rssi" to sr.level,
                    "secure" to (sr.capabilities.contains("WPA") || sr.capabilities.contains("WEP")),
                    "capabilities" to sr.capabilities,
                    "frequency" to sr.frequency,
                )
            }
    }

    @Suppress("DEPRECATION")
    private fun connectWifi(ssid: String, password: String?): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+: WifiNetworkSpecifier
                val specifier = android.net.wifi.WifiNetworkSpecifier.Builder()
                    .setSsid(ssid)

                if (password != null && password.isNotEmpty()) {
                    specifier.setWpa2Passphrase(password)
                }

                val request = android.net.NetworkRequest.Builder()
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .setNetworkSpecifier(specifier.build())
                    .build()

                val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                cm.requestNetwork(request, object : ConnectivityManager.NetworkCallback() {
                    override fun onAvailable(network: android.net.Network) {
                        cm.bindProcessToNetwork(network)
                    }
                })
                true
            } else {
                // Android 9 und darunter
                val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val config = android.net.wifi.WifiConfiguration().apply {
                    SSID = "\"$ssid\""
                    if (password != null && password.isNotEmpty()) {
                        preSharedKey = "\"$password\""
                    } else {
                        allowedKeyManagement.set(android.net.wifi.WifiConfiguration.KeyMgmt.NONE)
                    }
                }
                val netId = wm.addNetwork(config)
                wm.disconnect()
                wm.enableNetwork(netId, true)
                wm.reconnect()
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun getCurrentWifiInfo(): Map<String, Any?> {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        val network = cm?.activeNetwork
        val caps = cm?.getNetworkCapabilities(network)
        val wifiConnected = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true

        var ssid: String? = null
        var rssi = 0
        var ip: String? = null
        var linkSpeed = 0

        if (wifiConnected) {
            val transportInfo = caps?.transportInfo
            if (transportInfo is android.net.wifi.WifiInfo) {
                ssid = transportInfo.ssid?.replace("\"", "")
                if (ssid == "<unknown ssid>") ssid = null
                rssi = transportInfo.rssi
                linkSpeed = transportInfo.linkSpeed
                val ipInt = transportInfo.ipAddress
                if (ipInt != 0) {
                    ip = "${ipInt and 0xff}.${ipInt shr 8 and 0xff}.${ipInt shr 16 and 0xff}.${ipInt shr 24 and 0xff}"
                }
            }
        }

        return mapOf(
            "connected" to wifiConnected,
            "ssid" to ssid,
            "rssi" to rssi,
            "signalLevel" to if (rssi != 0) WifiManager.calculateSignalLevel(rssi, 5) else 0,
            "ip" to ip,
            "linkSpeed" to linkSpeed,
        )
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
