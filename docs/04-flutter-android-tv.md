# Flutter auf Android TV — Status & Möglichkeiten

## Offizieller Support-Status

Android TV ist **nicht offiziell** von Flutter unterstützt. Es gibt:
- Kein eingebauter D-Pad Support
- Keine TV-spezifischen Widgets
- Keine offizielle Dokumentation für TV

**Aber:** Da Android TV auf Android basiert, können Flutter-Apps kompiliert und deployed werden.

### Andere TV-Plattformen
- **Samsung Tizen TVs:** Offizielles Flutter-Tizen SDK
- **LG webOS TVs:** Flutter-Support angekündigt, SDK erwartet H1 2026
- **Apple TV:** Kein Support

## Bekannte Probleme

### D-Pad / Fernbedienung
- Kein eingebauter D-Pad-Support
- Remote "OK"-Taste wird nicht als Tap erkannt
- Workaround nötig:
  ```dart
  Shortcuts(
    shortcuts: {
      LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
    },
    child: MaterialApp(...),
  )
  ```

### Focus Management
- Muss manuell implementiert werden
- Widgets: `Focus`, `FocusNode`, `FocusableActionDetector`
- Geometrisches Focus-Traversal passt oft nicht zur User-Erwartung

### Performance
- Impeller (neuer Renderer) kann auf Low-End TV-Hardware Probleme machen
- Schwache GPUs (PowerVR, Mali) haben dokumentierte Issues
- Transparenz/Blur-Effekte sind teuer auf TV-Hardware
- **Testen auf echter Hardware essentiell**

## Nützliche Flutter Packages

### D-Pad Navigation
| Package | Beschreibung |
|---------|-------------|
| [dpad](https://pub.dev/packages/dpad) | D-Pad Navigation mit Focus-Memory |
| [dpad_container](https://pub.dev/packages/dpad_container) | Einfacher Wrapper für Focus-Navigation |
| [Flutter_DPad](https://github.com/UmairKhalid786/Flutter_DPad) | Controller-Event Widget |

### Desktop-UI Frameworks
| Package | Beschreibung |
|---------|-------------|
| [fluent_ui](https://pub.dev/packages/fluent_ui) | Windows Fluent Design in Flutter |
| [macos_ui](https://pub.dev/packages/macos_ui) | macOS Design Language |
| [yaru](https://pub.dev/packages/yaru) | Ubuntu-Style Desktop Widgets |

### In-App Window Management (kritisch für Desktop-Umgebung)
| Package | Beschreibung |
|---------|-------------|
| [flutter_box_transform](https://pub.dev/packages/flutter_box_transform) | Drag & Resize mit Constraints — **beste Option** |
| [resizable_widget](https://pub.dev/packages/resizable_widget) | Resizable Divider zwischen Widgets |
| [flutter_resizable_container](https://pub.dev/packages/flutter_resizable_container) | Nestbare resizable Container |

### Drag & Drop
| Package | Beschreibung |
|---------|-------------|
| Built-in `Draggable`/`DragTarget` | In-App Drag & Drop |
| [super_drag_and_drop](https://pub.dev/packages/super_drag_and_drop) | Natives Cross-App Drag & Drop |
| [desktop_drop](https://pub.dev/packages/desktop_drop) | Datei-Drop in Desktop-Apps |

### OS-Level Window Management (nur für Desktop-Plattformen)
| Package | Beschreibung |
|---------|-------------|
| [window_manager](https://pub.dev/packages/window_manager) | Fenster-Größe, Position, Events |
| [bitsdojo_window](https://pub.dev/packages/bitsdojo_window) | Custom Titlebars, Borders |

> **Hinweis:** OS-Level Window-Packages funktionieren nur auf Desktop-Plattformen (Windows/Mac/Linux), NICHT auf Android TV. Für Android TV muss ein In-App MDI (Multi-Document Interface) mit `flutter_box_transform` o.ä. gebaut werden.

## Referenzprojekt: FLauncher

[FLauncher](https://gitlab.com/flauncher/flauncher) ist ein Open-Source Android TV Launcher komplett in Flutter:
- Nutzt `device_apps` Package + Platform Channels
- Beweist grundsätzliche Machbarkeit
- Nur Home-Screen-Replacement, keine Desktop-Features

## Weitere Ressourcen

- [flutter-for-tv GitHub](https://github.com/dmt195/flutter-for-tv) — Sammlung von TV-spezifischen Ressourcen
- [Promwad: Flutter auf Set-Top-Boxen](https://promwad.com/news/how-port-flutter-sdk-set-top-boxes-android-tv-apps-running-and-development)
- [Desktop GUI mit draggable/resizable Windows in Flutter](https://itnext.io/desktop-gui-implementation-using-flutter-web-part-3-draggable-resizable-windows-46ea26049605)

## Quellen

- [Flutter Supported Platforms](https://docs.flutter.dev/reference/supported-platforms)
- [Medium: Adding Android TV support to Flutter](https://medium.com/@pcmushthaq/adding-android-tv-support-to-your-flutter-app-dcc5c1196231)
- [Flutter Issue #106817: TV remote enter button](https://github.com/flutter/flutter/issues/106817)
- [Flutter Issue #35346: Android TV DPAD support](https://github.com/flutter/flutter/issues/35346)
- [XDA: FLauncher](https://www.xda-developers.com/flauncher-android-tv/)
