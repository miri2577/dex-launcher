# Maus-Cursor auf Android TV — Technische Deep-Dive

## Kernproblem

Android TV **verarbeitet Maus-Events** — der Cursor wird nur **visuell unterdrückt**.

```
USB-Maus → Kernel HID → EventHub → InputReader → CursorInputMapper → PointerController
                                                                          ↓
                                                              setPointerIconVisibility(false)
                                                                          ↓
                                                              Cursor-Sprite wird NICHT gerendert
                                                              Events werden trotzdem dispatcht
```

## System-Architektur des Maus-Cursors

### Kernel Layer
- USB/BT Maus → Linux HID Driver → `/dev/input/eventN`
- Kernel meldet `EV_REL` (Mausbewegung) und `EV_KEY` (Buttons)

### Native Layer (C++)
| Datei | Funktion |
|-------|----------|
| `EventHub.cpp` | Überwacht `/dev/input/`, klassifiziert Geräte (`INPUT_DEVICE_CLASS_CURSOR`) |
| `InputReader.cpp` | Erstellt `CursorInputMapper` für Mäuse |
| `PointerController.cpp` | Verwaltet Cursor-Sprite, Position, Sichtbarkeit |
| `SpriteController` | Rendert Cursor als Hardware-Overlay via SurfaceFlinger |
| `com_android_server_input_InputManagerService.cpp` | JNI-Bridge, enthält `setPointerIconVisibility()` |

### Java Framework Layer
| Klasse | Funktion |
|--------|----------|
| `InputManagerService.java` | System-Service für alle Input-Geräte |
| `PointerIcon.java` | Definiert Cursor-Typen (Arrow, Hand, Crosshair, etc.) |
| `WindowManagerService` | Aktualisiert Cursor basierend auf View unter Pointer |

### Cursor-Ressourcen
Gespeichert in `framework-res.apk`:
- `res/drawable-mdpi/pointer_arrow.png`
- `res/drawable-hdpi/pointer_arrow.png`
- `res/drawable-xhdpi/pointer_arrow.png`
- `res/drawable-xxhdpi/pointer_arrow.png`

## Warum Android TV den Cursor unterdrückt

| Aspekt | Phone/Tablet | Android TV |
|--------|-------------|------------|
| Feature Flag | `android.software.home_screen` | `android.software.leanback` |
| Pointer Visibility | Aktiviert | **Unterdrückt** |
| Mouse Events | Mit sichtbarem Cursor | Events fließen, Cursor unsichtbar |
| Navigationsmodell | Touch/Pointer | D-Pad/Focus |
| PointerController | unfade() bei Mausbewegung | Kann komplett unterdrückt sein |

Unterdrückung passiert durch:
1. `setPointerIconVisibility(displayId, false)` in NativeInputManager
2. Device Overlay `config.xml` in `/vendor/overlay/`
3. Leanback UI Design-Philosophie (10-Foot-Experience)
4. OEM-spezifische Entscheidung

## Systemdateien per ADB nachrüsten — Geht das?

### Kurze Antwort: NEIN (ohne Root)

| Partition | Schreibbar per ADB? | Relevante Dateien |
|-----------|---------------------|-------------------|
| `/system` | **Nein** (Verified Boot, dm-verity) | `framework-res.apk` (Cursor-Bilder) |
| `/vendor` | **Nein** (Verified Boot) | Device-Overlays, Input-Config |
| `/product` | **Nein** (Verified Boot) | Zusätzliche Overlays |
| `/data` | **Teilweise** | App-Daten, `/data/local/tmp/` |
| Settings DB | **Ja** (`settings put`) | Pointer-Speed, aber KEIN Visibility-Toggle |

### Warum nicht?
- **dm-verity / Android Verified Boot (AVB)** — System-Partition kryptografisch verifiziert
- **Dynamic Partitions** (Android 10+) — Zusätzlicher Schutz
- **Production Builds** — `adb root` verweigert, `adb remount` schlägt fehl
- Jede Änderung an `/system` → Boot-Verification Fehler

### ADB-Befehle die NICHT den Cursor aktivieren

```bash
# Ändert nur Geschwindigkeit, Cursor bleibt unsichtbar
adb shell settings put system pointer_speed 7

# Zeigt Koordinaten-Overlay, KEIN Cursor
adb shell settings put system pointer_location 1

# Zeigt Tap-Kreise, KEIN Cursor
adb shell settings put system show_touches 1

# Es gibt KEIN:
# adb shell settings put system show_cursor 1  ← existiert nicht!
```

## Lösungen für Maus-Cursor

### Option 1: Eigener Software-Cursor in Flutter (EMPFOHLEN)

**Vorteile:**
- Kein Root, kein ADB-Setup nötig
- Volle Kontrolle über Aussehen und Verhalten
- Flutter empfängt Maus-Events auch wenn System-Cursor unsichtbar

**Nachteile:**
- Funktioniert nur innerhalb der Flutter-App
- Nicht verfügbar wenn andere Apps im Vordergrund

```
Flutter App empfängt MotionEvent → Custom Cursor Widget folgt Position
```

### Option 2: AccessibilityService-Cursor (kein Root)

**Funktionsweise:**
1. App registriert als `AccessibilityService`
2. Erstellt `TYPE_ACCESSIBILITY_OVERLAY` Window
3. Zeichnet Cursor-Bitmap im Overlay
4. Bewegt Cursor basierend auf Maus/D-Pad Input
5. Injiziert Taps per `AccessibilityService.dispatchGesture()`

**Existierende Open-Source Implementierungen:**
- [MATVT](https://github.com/virresh/matvt) — Virtueller Cursor per Fernbedienung
- [DPTV-Cursor](https://github.com/Crealivity/DPTV-Cursor) — Floating Overlay Cursor
- [android-mouse-cursor](https://github.com/chetbox/android-mouse-cursor) — Proof-of-Concept

**Setup:**
```bash
adb install cursor-app.apk
adb shell appops set <package> SYSTEM_ALERT_WINDOW allow
adb shell settings put secure enabled_accessibility_services <package>/<service>
```

**Einschränkungen:**
- Overlay, kein echter System-Pointer
- Kann nicht über System-UI zeichnen (Statusleiste)
- Nicht bei DRM-geschützten Inhalten
- Amazon Fire TV blockiert teilweise

### Option 3: Magisk-Module (Root nötig)

- [pointer_replacer](https://github.com/thesandipv/pointer_replacer) — Hookt framework-res.apk zur Laufzeit
- [replaceCursor](https://github.com/Young-Lord/replaceCursor) — Xposed-Modul für Custom Cursor
- Oder: `setPointerIconVisibility` per Xposed auf `true` forcen

→ Ergibt **echten System-Cursor** wie auf Phones/Tablets

### Option 4: Custom ROM

LineageOS/Custom ROMs für TV-Boxen (Amlogic-basiert):
- Basieren auf Tablet-AOSP statt Android TV
- Cursor von Haus aus aktiviert
- Box wird zum "Tablet mit HDMI-Ausgang"

### Option 5: Nvidia Shield

Einziges populäres Android TV Gerät mit **nativem Maus-Cursor** bei USB-Maus-Verbindung (OEM-Entscheidung).

## Empfohlene Strategie für das Projekt

```
┌─────────────────────────────────────────────────────┐
│  Innerhalb der Flutter Desktop-App:                 │
│  → Eigener Software-Cursor (Option 1)              │
│  → Volle Kontrolle, kein Setup nötig               │
│                                                     │
│  Außerhalb der App (andere Apps mit Maus bedienen): │
│  → AccessibilityService-Cursor (Option 2)          │
│  → Einmaliges ADB-Setup                            │
│                                                     │
│  Für Power-User mit Root:                           │
│  → Magisk-Modul für echten System-Cursor (Option 3)│
└─────────────────────────────────────────────────────┘
```

## Quellen

- [AOSP PointerController.cpp](https://github.com/aosp-mirror/platform_frameworks_base/blob/master/libs/input/PointerController.cpp)
- [AOSP InputManagerService.cpp JNI](https://github.com/aosp-mirror/platform_frameworks_base/blob/master/services/core/jni/com_android_server_input_InputManagerService.cpp)
- [MATVT — Virtual Mouse for Android TV](https://github.com/virresh/matvt)
- [DPTV-Cursor](https://github.com/Crealivity/DPTV-Cursor)
- [Mouse Toggle for Android TV](https://androidtvnews.com/mouse-toggle-android-tv/)
- [pointer_replacer (Magisk)](https://github.com/thesandipv/pointer_replacer)
- [XDA: Change mouse cursor (root)](https://xdaforums.com/t/guide-change-the-mouse-cursor-on-android-for-otg-root-required.3401147/)
- [Nvidia Shield cursor discussion](https://www.nvidia.com/en-us/geforce/forums/shield-tv/9/249092/mouse-pointer-shield-tv-2017/)
