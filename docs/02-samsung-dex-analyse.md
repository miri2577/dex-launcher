# Samsung DeX — Technische Analyse

## Was ist Samsung DeX?

Samsung DeX ist Samsungs Desktop-Modus, der Galaxy Phones/Tablets in eine PC-ähnliche Umgebung verwandelt (via Kabel, DeX Station oder kabellos). Es bietet:

- Vollständige Desktop-UI mit Taskbar
- Freeform-Fenster (verschiebbar, skalierbar)
- Maus- und Tastatur-Support

## Technische Architektur

DeX basiert auf Androids Multi-Window-Modus (seit Android 7.0 Nougat). Samsung modifizierte:

- **Windowing-System** — Apps laufen in `WINDOWING_MODE_FREEFORM`
- **ActivityTaskManager** — Erweitert für Freeform-Window-Management
- **Display-Management** — Dual-Display-Support (Phone + externer Monitor)
- **Desktop Launcher** — Dedizierter Launcher für den DeX-Modus

## APIs & Kompatibilität

### Keine proprietären APIs für Basis-Kompatibilität

Apps funktionieren in DeX, wenn sie Standard-Android-Best-Practices befolgen:

```xml
<!-- AndroidManifest.xml -->
<activity android:resizeableActivity="true" />
```

### Multi-Instance Support

Nutzt Standard Android Intent Flags:
- `FLAG_ACTIVITY_LAUNCH_ADJACENT`
- `FLAG_ACTIVITY_NEW_TASK`
- `FLAG_ACTIVITY_MULTIPLE_TASK`

### Enterprise Management

Knox SDK (3.1+) bietet:
- `DexManager.setDexDisabled()`
- `setHomeAlignment`
- `addURLShortcut`

### Wichtig für App-Entwickler

- `android.hardware.touchscreen` NICHT als required deklarieren (blockiert Maus/Tastatur)
- `onConfigurationChanged()` korrekt implementieren (DeX-Wechsel = Config-Change)

## Android 16 Desktop-Modus

Google baut in Android 16 einen eigenen Desktop-Modus **auf den Grundlagen von Samsung DeX**, in direkter Zusammenarbeit mit Samsung. Freeform-Windowing wird damit ein First-Class AOSP Feature.

## Quellen

- [Samsung Developer: How DeX works](https://developer.samsung.com/samsung-dex/how-it-works.html)
- [Samsung Developer: DeX Overview](https://developer.samsung.com/samsung-dex/overview.html)
- [Samsung Knox: DeX and Knox SDK](https://docs.samsungknox.com/dev/knox-sdk/features/mdm-providers/device-management/samsung-dex-and-knox/)
- [Samsung Developer: Optimizing for DeX](https://developer.samsung.com/samsung-dex/modify-optimizing.html)
- [SamMobile: Android 16 Desktop Mode built on DeX](https://www.sammobile.com/news/samsung-dex-android-16-desktop-mode-confirmation/)
