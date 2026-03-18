# Architektur-Konzept

## System-Übersicht

```
┌──────────────────────────────────────────────────────────┐
│                    Flutter Desktop Shell                  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Desktop-Oberfläche                    │  │
│  │                                                    │  │
│  │   Wallpaper   │   App-Icons   │   Widgets          │  │
│  │                                                    │  │
│  │   ┌──────────────┐  ┌──────────────┐              │  │
│  │   │  App-Fenster  │  │  App-Fenster  │   In-App   │  │
│  │   │  (MDI)        │  │  (MDI)        │   MDI      │  │
│  │   │  Draggable    │  │  Draggable    │            │  │
│  │   │  Resizable    │  │  Resizable    │            │  │
│  │   └──────────────┘  └──────────────┘              │  │
│  │                                                    │  │
│  │   Software-Cursor ← folgt Maus-Input              │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Dock / Taskleiste                                 │  │
│  │  [Start] [Pinned Apps] [Running Apps] [Tray] [Uhr] │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
└──────────────────────────────────────────────────────────┘
         │                           │
    Flutter Layer               Native Layer
    (Dart)                      (Platform Channels)
         │                           │
    ┌────┴────┐              ┌───────┴────────┐
    │ UI      │              │ Android APIs   │
    │ Widgets │              │                │
    │ State   │              │ PackageManager │
    │ Cursor  │              │ UsageStats     │
    │ Windows │              │ Overlay Service│
    │ Dock    │              │ Accessibility  │
    └─────────┘              │ ActivityOptions│
                             └────────────────┘
```

## Zwei Betriebsmodi

### Modus 1: Launcher-Modus (MVP)

```
User klickt App-Icon → App startet fullscreen → Taskbar-Overlay bleibt sichtbar
                                                       ↓
                                                 User kann zurück
                                                 zum Desktop wechseln
```

- Flutter-App als Home-Screen
- Apps werden normal (fullscreen) gestartet
- Taskbar als natives Android Overlay (`SYSTEM_ALERT_WINDOW`)
- Software-Cursor nur innerhalb der Flutter-App

### Modus 2: Desktop-Modus (v3)

```
User klickt App-Icon → App startet in Freeform-Fenster → Desktop bleibt sichtbar
                              ↓
                    setLaunchBounds(Rect(x, y, w, h))
                    FLAG_ACTIVITY_NEW_TASK
                    FLAG_ACTIVITY_MULTIPLE_TASK
```

- Freeform-Fenster per `ActivityOptions.setLaunchBounds()`
- Mehrere Apps gleichzeitig sichtbar
- AccessibilityService-Cursor für Mausbedienung über allen Apps
- Erfordert einmaliges ADB-Setup

## Komponenten-Architektur

### Flutter-Seite (Dart)

```
lib/
├── main.dart
├── app.dart
│
├── desktop/
│   ├── desktop_shell.dart        # Haupt-Desktop-Widget
│   ├── desktop_background.dart   # Wallpaper & Icons
│   ├── window_manager.dart       # In-App MDI Fenster-Verwaltung
│   └── desktop_icon.dart         # App-Icons auf dem Desktop
│
├── dock/
│   ├── dock.dart                 # Dock/Taskleiste
│   ├── dock_item.dart            # Einzelnes Dock-Element
│   ├── system_tray.dart          # System-Tray (Uhr, Batterie, etc.)
│   └── start_menu.dart           # Startmenü
│
├── launcher/
│   ├── app_launcher.dart         # App-Grid/Liste
│   ├── app_model.dart            # App-Datenmodell
│   ├── app_search.dart           # App-Suche
│   └── category_filter.dart      # App-Kategorien
│
├── cursor/
│   ├── cursor_overlay.dart       # Software-Maus-Cursor
│   └── cursor_controller.dart    # Cursor-Position & State
│
├── input/
│   ├── input_handler.dart        # Maus/Tastatur/D-Pad Handler
│   ├── keyboard_shortcuts.dart   # Tastenkürzel (Alt+Tab, etc.)
│   └── focus_manager.dart        # Custom Focus Navigation
│
├── services/
│   ├── app_service.dart          # App-Discovery via Platform Channel
│   ├── recent_apps_service.dart  # Recent Apps via UsageStats
│   └── settings_service.dart     # User-Einstellungen
│
└── platform/
    └── platform_channel.dart     # Bridge zu nativen APIs
```

### Native-Seite (Kotlin/Java)

```
android/app/src/main/java/com/.../
├── MainActivity.kt               # Flutter Activity als Launcher
├── AppDiscoveryPlugin.kt         # PackageManager Wrapper
├── OverlayService.kt             # SYSTEM_ALERT_WINDOW Taskbar
├── CursorAccessibilityService.kt # AccessibilityService Cursor
├── FreeformLauncher.kt           # ActivityOptions.setLaunchBounds()
└── RecentAppsPlugin.kt           # UsageStatsManager Wrapper
```

## Datenfluss

```
                    ┌─────────────┐
                    │   User      │
                    │   Input     │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────┴────┐  ┌───┴───┐  ┌────┴────┐
         │  Maus   │  │ Tast. │  │ D-Pad   │
         │  USB/BT │  │ USB/BT│  │ Remote  │
         └────┬────┘  └───┬───┘  └────┬────┘
              │            │            │
              └────────────┼────────────┘
                           │
                    ┌──────┴──────┐
                    │   Flutter   │
                    │   Engine    │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
    ┌─────────┴──┐  ┌─────┴─────┐  ┌──┴─────────┐
    │  Cursor    │  │  Desktop  │  │  Dock      │
    │  Position  │  │  State    │  │  State     │
    │  Update    │  │  (Fenster,│  │  (Apps,    │
    │            │  │   Icons)  │  │   Tray)    │
    └────────────┘  └───────────┘  └────────────┘
```

## Technologie-Stack

| Schicht | Technologie |
|---------|-------------|
| UI Framework | Flutter |
| Desktop-UI Style | `fluent_ui` oder Custom |
| In-App Windows | `flutter_box_transform` |
| D-Pad Navigation | `dpad` + Custom Focus |
| State Management | Provider / Riverpod |
| Native Bridge | Platform Channels (MethodChannel) |
| App Discovery | PackageManager (Kotlin) |
| Overlay | SYSTEM_ALERT_WINDOW (Kotlin) |
| Cursor | AccessibilityService (Kotlin) |
| Freeform Launch | ActivityOptions (Kotlin) |
| Persistence | SharedPreferences / Hive |
