# DeX Launcher

A Samsung DeX-inspired desktop environment for Android TV, built entirely in Flutter. Turns any Android TV into a full desktop workstation with draggable/resizable windows, built-in apps, and a familiar desktop paradigm.

## Features

### Desktop Environment
- **Top Bar** — Desktop switcher, focused window title, system tray (WiFi, Bluetooth, volume, battery), clock
- **Dock** — Auto-sizing, pinnable tools and Android apps, running window indicators
- **Start Menu** — Searchable list with Tools, Streaming, Google services, and all installed apps
- **Multi-Desktop** — 3 virtual desktops, switch with Ctrl+1/2/3
- **Window Management** — Drag, resize, snap to edges, minimize, close
- **Window Snapping** — Drag to left/right edge = half screen, top = maximize
- **Desktop Widgets** — Clock, calendar, system status (optional, toggle in settings)
- **Screensaver** — Bouncing clock, configurable timeout
- **Themes** — 12 accent colors, 12 gradient wallpapers, custom image backgrounds
- **Keyboard Shortcuts** — Alt+Tab, Meta+D, Meta+S, F5, Ctrl+1/2/3, Escape

### Built-in Mini-Apps (23)
| App | Description |
|-----|-------------|
| File Manager | Browse, copy, move, delete, rename, open files in other apps |
| Web Browser | Tabs, zoom (50-200%), bookmarks, history, desktop mode, find on page |
| Terminal | Shell command execution, history, cd support |
| Calculator | Full arithmetic with expression display |
| Text Editor | Create/edit files, save to storage |
| Image Viewer | Browse images, prev/next, pinch-to-zoom |
| Video Player | Scan and play video files |
| Music Player | Scan and play audio files |
| WiFi Manager | Scan networks, connect, show signal strength |
| Bluetooth Manager | View paired devices |
| System Monitor | CPU, RAM, storage with live refresh |
| Task Manager | Running processes, RAM per app, kill button |
| Network Scanner | Devices on local network (IP/MAC) |
| Weather | Temperature, humidity, wind via wttr.in API |
| Speed Test | Download speed via Cloudflare |
| Clipboard Manager | Copy history (last 20 entries) |
| Quick Settings | WiFi/BT toggle, volume, brightness sliders |
| USB Manager | Connected USB devices |
| VPN Manager | VPN status, system settings link |
| Notification Center | System notifications via dumpsys |
| Developer Options | Shell commands, system properties, settings toggles |
| Global Search | Search apps and files simultaneously |
| Settings | Wallpaper, widgets, themes, screensaver, icon size |

### Games
| Game | Type |
|------|------|
| Snake | Native Flutter |
| Tetris | Native Flutter |
| 2048 | Native Flutter |
| Minesweeper | Native Flutter |
| DOOM | Browser (dos.zone) |
| Duke Nukem 3D | Browser (dos.zone) |
| Commander Keen | Browser (dos.zone) |
| Prince of Persia | Browser (dos.zone) |
| Wolfenstein 3D | Browser (dos.zone) |
| Pac-Man | Browser (dos.zone) |
| Wordle | Browser |
| Chess | Browser (chess.com) |

### Google Services Integration
Direct browser shortcuts: Google Search, Drive, Docs, Sheets, Slides, Gmail, YouTube, Maps

### Streaming
Launch or open in browser: YouTube, Netflix, Disney+, Amazon Prime, Spotify

## Requirements

- Android TV device (tested on PEAQ PGS1000 / Amlogic S805X3)
- Bluetooth/USB mouse recommended
- Bluetooth/USB keyboard for full functionality

## ADB Setup (one-time)

```bash
# Install
adb install dex-launcher.apk

# Permissions
adb shell appops set com.dexlauncher.dex_launcher GET_USAGE_STATS allow
adb shell appops set com.dexlauncher.dex_launcher SYSTEM_ALERT_WINDOW allow
adb shell pm grant com.dexlauncher.dex_launcher android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.dexlauncher.dex_launcher android.permission.BLUETOOTH_CONNECT
adb shell pm grant com.dexlauncher.dex_launcher android.permission.BLUETOOTH_SCAN
adb shell pm grant com.dexlauncher.dex_launcher android.permission.WRITE_SECURE_SETTINGS

# Set as default launcher
adb shell cmd package set-home-activity com.dexlauncher.dex_launcher/.MainActivity

# Optional: disable soft keyboard with hardware keyboard
adb shell settings put secure show_ime_with_hard_keyboard 0
```

## Building

```bash
flutter clean && flutter pub get && flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider (ChangeNotifier)
- **Native Bridge:** Platform Channels (MethodChannel)
- **WebView:** webview_flutter
- **Storage:** SharedPreferences
- **Weather API:** wttr.in (no key required)
- **Speed Test:** Cloudflare
- **DOS Games:** dos.zone (js-dos emulator)

## Architecture

```
lib/
├── main.dart                 # App entry, providers
├── desktop/
│   ├── desktop_shell.dart    # Main layout, keyboard shortcuts
│   ├── desktop_background.dart
│   └── desktop_icons.dart
├── dock/
│   ├── dock.dart             # Auto-sizing dock
│   └── start_menu.dart       # List-based start menu
├── windows/
│   ├── mdi_window.dart       # Window data model
│   ├── window_manager.dart   # Window lifecycle
│   └── window_chrome.dart    # Title bar, resize, snap
├── widgets/
│   ├── top_bar.dart          # System bar
│   ├── desktop_widgets.dart  # Clock, calendar, system
│   ├── settings_panel.dart
│   ├── screensaver.dart
│   └── ...
├── apps/                     # 23 built-in mini-apps
│   ├── file_manager.dart
│   ├── web_browser.dart
│   ├── terminal.dart
│   ├── games.dart            # Snake, Tetris, 2048, Minesweeper, DOOM
│   └── ...
├── models/
│   ├── desktop_state.dart    # Main state
│   ├── app_info.dart
│   └── builtin_apps.dart
├── services/
│   ├── app_service.dart      # Native bridge
│   ├── storage_service.dart
│   └── system_status_service.dart
└── cursor/
    └── cursor_overlay.dart   # Smart cursor (system vs D-pad)
```

## License

MIT
