# Projekt-Übersicht: Samsung DeX für Android TV

## Konzept

Eine Flutter-App, die Android TV in eine vollwertige Desktop-Umgebung verwandelt — ähnlich Samsung DeX — mit:

- **Desktop-Oberfläche** wie Windows/Mac/Linux
- **Dock und Taskleiste** mit App-Shortcuts, Uhr, System-Tray
- **App-Launcher** mit Kategorien und Suchfunktion
- **Fenstersystem** mit verschiebbaren/skalierbaren App-Fenstern
- **Maus- und Tastatursteuerung** für produktives Arbeiten

## Zielgeräte

- Nvidia Shield (beste Kompatibilität, nativer Maus-Cursor)
- Xiaomi Mi Box
- Günstige AOSP-basierte Android TV Boxen
- **Nicht empfohlen:** Google TV Geräte (blockieren aktiv Custom-Launcher-Overrides)

## Technische Basis

- **Framework:** Flutter (Android TV ist nicht offiziell unterstützt, funktioniert aber)
- **Referenzprojekt:** [FLauncher](https://gitlab.com/flauncher/flauncher) — Open-Source Flutter Android TV Launcher
- **Architektur:** Flutter UI + Native Android Platform Channels für System-APIs

## Machbarkeits-Bewertung

| Aspekt | Machbarkeit | Anmerkung |
|--------|-------------|-----------|
| Custom Launcher | Hoch | Standard Android Intent-Filter |
| App-Discovery & Launch | Hoch | PackageManager API |
| Freeform-Fenster | Mittel | Versteckte APIs, ADB nötig |
| Persistente Taskleiste | Mittel | SYSTEM_ALERT_WINDOW per ADB |
| Maus/Tastatur | Mittel | Eigener Cursor in Flutter + AccessibilityService |
| Fenster-Management anderer Apps | Niedrig | Root oder signature-level Permission nötig |

## Geplante Entwicklungsstufen

| Stufe | Komplexität | Beschreibung |
|-------|-------------|--------------|
| **MVP** | Mittel | Flutter-Launcher mit App-Grid, Dock, Kategorien, Maus/Tastatur-Support |
| **v2** | Hoch | Persistente Taskleiste (Overlay), Recent-Apps, virtueller Cursor per Accessibility |
| **v3** | Sehr hoch | Freeform-Fenster, Desktop-Metapher mit verschiebbaren/skalierbaren App-Fenstern |
