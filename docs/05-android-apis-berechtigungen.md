# Benötigte Android APIs & Berechtigungen

## API-Übersicht

| API | Zweck | Permission | Vergabe-Methode |
|-----|-------|------------|-----------------|
| **PackageManager** | Apps auflisten, Icons/Labels, Launch-Intents | `QUERY_ALL_PACKAGES` | Manifest |
| **UsageStatsManager** | Zuletzt verwendete Apps, Nutzungsdauer | `PACKAGE_USAGE_STATS` | ADB: `appops set ... GET_USAGE_STATS allow` |
| **AccessibilityService** | Vordergrund-App erkennen, Input-Events injizieren, Cursor | — | User aktiviert in Accessibility Settings |
| **SYSTEM_ALERT_WINDOW** | Persistentes Overlay (Taskbar, Cursor) über anderen Apps | Special Permission | ADB: `appops set ... SYSTEM_ALERT_WINDOW allow` |
| **WindowManager** | Overlay-Views hinzufügen/entfernen | Mit SYSTEM_ALERT_WINDOW | — |
| **ActivityOptions** | Apps in Freeform-Modus starten (`setLaunchBounds()`) | Keine | Freeform muss per ADB aktiviert sein |
| **DevicePolicyManager** | Kiosk-Modus, Lock-Task-Mode | Device Owner | ADB: `dpm set-device-owner` |
| **NotificationListenerService** | Benachrichtigungen in Desktop spiegeln | — | User gewährt in Settings |
| **MediaSession/Controller** | Now-Playing Info, Media-Steuerung | `MEDIA_CONTENT_CONTROL` | — |
| **WallpaperManager** | Desktop-Hintergrund | `SET_WALLPAPER` | Manifest |
| **AppWidgetManager** | Android Widgets auf Desktop hosten | `BIND_APPWIDGET` | Device Admin oder User-Grant |

## App-Discovery & Launch

### Installierte Apps auflisten

```java
// Java (Platform Channel)
Intent mainIntent = new Intent(Intent.ACTION_MAIN, null);
mainIntent.addCategory(Intent.CATEGORY_LAUNCHER);
// Für TV-spezifische Apps:
// mainIntent.addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER);

List<ResolveInfo> apps = packageManager.queryIntentActivities(mainIntent, 0);
```

### App starten

```java
Intent launchIntent = packageManager.getLaunchIntentForPackage(packageName);
startActivity(launchIntent);
```

### Als Launcher registrieren (AndroidManifest.xml)

```xml
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.HOME" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
    </intent-filter>
</activity>
```

### Android 11+ Package Visibility

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

## Freeform-Fenster starten

```java
Rect bounds = new Rect(100, 100, 900, 700);
ActivityOptions options = ActivityOptions.makeBasic();
options.setLaunchBounds(bounds);

Intent intent = new Intent();
intent.setComponent(new ComponentName(packageName, activityName));
intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_MULTIPLE_TASK);

startActivity(intent, options.toBundle());
```

> **Wichtig:** `setLaunchBounds()` wird **stillschweigend ignoriert**, wenn Freeform nicht aktiviert ist.

## Persistentes Overlay (Taskbar)

```java
// Native Android — via Platform Channel
WindowManager.LayoutParams params = new WindowManager.LayoutParams(
    WindowManager.LayoutParams.MATCH_PARENT,
    dpToPx(48), // Taskbar-Höhe
    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
    PixelFormat.TRANSLUCENT
);
params.gravity = Gravity.BOTTOM;

WindowManager wm = (WindowManager) getSystemService(WINDOW_SERVICE);
wm.addView(taskbarView, params);
```

## Einmaliges ADB-Setup für Endbenutzer

```bash
# Freeform-Fenster aktivieren
adb shell settings put global enable_freeform_support 1

# Overlay-Permission gewähren
adb shell appops set com.your.app SYSTEM_ALERT_WINDOW allow

# Usage-Stats-Permission gewähren
adb shell appops set com.your.app GET_USAGE_STATS allow

# Als Default-Launcher setzen
adb shell cmd package set-home-activity com.your.app/.MainActivity

# Optional: Accessibility Service aktivieren
adb shell settings put secure enabled_accessibility_services com.your.app/.CursorService

# Optional: Pointer-Speed anpassen
adb shell settings put system pointer_speed 5
```

## Root vs. Non-Root

### Ohne Root möglich

| Feature | Methode |
|---------|---------|
| Custom Launcher Home Screen | Standard Intent-Filter |
| App Discovery & Launch | PackageManager API |
| Custom Wallpapers | Render innerhalb der Launcher Activity |
| Recent Apps Liste | UsageStatsManager (ADB Permission) |
| Persistente Taskbar | SYSTEM_ALERT_WINDOW (ADB Permission) |
| Virtueller Maus-Cursor | AccessibilityService |
| Freeform-Fenster | ADB enable_freeform_support + setLaunchBounds() |
| Default Launcher setzen | ADB set-home-activity |
| Kiosk-Modus | DevicePolicyManager als Device Owner (ADB) |

### Root erforderlich

| Feature | Grund |
|---------|-------|
| System-Cursor forcieren | PointerController ist native C++, signature-level |
| Andere Apps Fenster verschieben/skalieren | `MANAGE_ACTIVITY_STACKS` (signature-level) |
| System-Apps deaktivieren (permanent) | `pm disable` für alle User braucht Root |
| Apps ohne User-Prompt installieren | `INSTALL_PACKAGES` ist system-level |
| System-Navigation-Bar modifizieren | `WRITE_SECURE_SETTINGS` (ADB möglich) oder Root |
| 4K UI Rendering forcieren | System Display Properties ändern |

## Quellen

- [Android Developer: PackageManager](https://developer.android.com/reference/android/content/pm/PackageManager)
- [Android Developer: UsageStatsManager](https://developer.android.com/reference/android/app/usage/UsageStatsManager)
- [Android Developer: Multi-Window Support](https://developer.android.com/guide/topics/ui/multi-window)
- [Android Developer: ActivityOptions](https://developer.android.com/reference/android/app/ActivityOptions)
- [How Taskbar starts apps in freeform mode](https://utzcoz.github.io/2021/09/12/How-Taskbar-start-app-in-freeform-windowing-mode.html)
