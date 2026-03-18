# Android TV — Limitierungen & Möglichkeiten

## Maus/Tastatur-Input

- Android TV unterstützt USB/Bluetooth Mäuse und Tastaturen auf OS-Ebene
- **Kein nativer Maus-Cursor** in der Standard-Android-TV-Erfahrung (Ausnahme: Nvidia Shield)
- Primäres Navigationsmodell: D-Pad/Fernbedienung mit Fokus-basierter Navigation
- Mouse Toggle simuliert Cursor per D-Pad, hat aber Einschränkungen

## Window Management

- **Offiziell nur Picture-in-Picture (PiP)** für Multi-Window
- Kein Split-Screen oder Freeform auf Android TV vorgesehen
- Freeform-Fenster technisch möglich via ADB:
  ```bash
  adb shell settings put global enable_freeform_support 1
  ```
- Nicht offiziell unterstützt, funktioniert nicht auf allen TV-Hardware

## Multi-Tasking

- Single-App-Experience designet
- Kein eingebauter Task-Switcher
- Background-Apps laufen, aber kein Multi-Window-UI

## Leanback Launcher vs. Custom Launcher

### Leanback Launcher (Stock)
- Optimiert für 10-Foot-Experience mit großen Kacheln
- Sideloaded Apps erscheinen NICHT im Leanback Launcher
- Begrenzte Anpassungsmöglichkeiten

### Custom Launcher — Was möglich ist
- Können per Sideload installiert werden
- Zeigen alle Apps (auch sideloaded)
- Können als Default gesetzt werden (klassisches Android TV)

### Google TV Einschränkungen
- Google TV blockiert aktiv Custom-Launcher-Overrides
- Override-Toggle funktioniert nach Updates nicht mehr
- System setzt auf Google TV Launcher zurück
- **Empfehlung: Klassische Android TV Boxen als Zielgeräte**

## Overlay-Berechtigungen auf Android TV

- `SYSTEM_ALERT_WINDOW` nötig für persistente Taskleiste
- Android TV bietet **keine Settings-UI** zum Gewähren dieser Permission
- Workaround per ADB:
  ```bash
  adb shell appops set <package-name> SYSTEM_ALERT_WINDOW allow
  ```

## Existierende Desktop-Lösungen für Android TV

### Taskbar (farmerbb)
- Open Source: [github.com/farmerbb/Taskbar](https://github.com/farmerbb/Taskbar)
- PC-Style Startmenü und Taskbar als Overlay
- Startet Apps in Freeform-Fenstern (Android 7.0+)
- Nutzt Reflection für versteckte `ActivityOptions`-Methoden

### Flow Desktop
- Desktop-Launcher für Android 10 Hidden Desktop Mode
- Windows-ähnliche Oberfläche mit Freeform-Fenstern
- Primär für Phone-to-Monitor, nicht speziell für TV

### Projectivy Launcher
- Populärer Custom Launcher für Android TV/Google TV
- Kein vollständiges Desktop-Environment, aber mehr Anpassungsmöglichkeiten

## Quellen

- [GitHub: farmerbb/Taskbar](https://github.com/farmerbb/Taskbar)
- [XDA: Flow Desktop](https://www.xda-developers.com/flow-desktop-launcher-android-10-hidden-desktop-mode/)
- [Android Authority: Google TV blocks Projectivy](https://www.androidauthority.com/google-tv-update-blocks-projectivy-override-3649445/)
- [XDA: Freeform Window Mode](https://www.xda-developers.com/android-nougats-freeform-window-mode-what-it-is-and-how-developers-can-utilize-it/)
