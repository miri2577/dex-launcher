import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/cinnamon_theme.dart';
import '../models/desktop_state.dart';
import '../services/system_status_service.dart';
import '../desktop/desktop_background.dart';

/// Zentrales Control Center — ersetzt das alte Settings Panel
/// Kategorisiert wie Linux Mint Systemeinstellungen
class ControlCenterApp extends StatefulWidget {
  const ControlCenterApp({super.key});
  @override
  State<ControlCenterApp> createState() => _ControlCenterAppState();
}

class _ControlCenterAppState extends State<ControlCenterApp> {
  String _activeSection = 'desktop';
  String _userName = 'Benutzer';
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('user_name') ?? 'Benutzer');
    _nameController.text = _userName;
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_name', name);
    setState(() => _userName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.windowBg,
      child: Row(
        children: [
          // Sidebar
          Container(
            width: 180,
            color: C.sidebarBg,
            child: Column(
              children: [
                // User
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: C.accent.withValues(alpha: 0.3),
                      child: Text(_userName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300)),
                    ),
                    const SizedBox(height: 8),
                    Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                ),
                Container(height: 1, color: C.separator),
                // Kategorien
                Expanded(child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    _SideItem('desktop', 'Desktop', Icons.desktop_windows),
                    _SideItem('erscheinung', 'Erscheinungsbild', Icons.palette),
                    _SideItem('fenster', 'Fenster', Icons.window),
                    _SideItem('tastatur', 'Tastenkuerzel', Icons.keyboard),
                    _SideItem('benutzer', 'Benutzer', Icons.person),
                    _SideItem('system', 'System', Icons.info_outline),
                  ],
                )),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _SideItem(String id, String label, IconData icon) {
    final active = _activeSection == id;
    return GestureDetector(
      onTap: () => setState(() => _activeSection = id),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? C.accentDim : Colors.transparent,
          border: active ? const Border(left: BorderSide(color: C.accent, width: 2)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: active ? Colors.white : Colors.white54, size: 16),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final state = context.watch<DesktopState>();
    return switch (_activeSection) {
      'desktop' => _desktopSettings(state),
      'erscheinung' => _appearanceSettings(state),
      'fenster' => _windowSettings(state),
      'tastatur' => _keyboardSettings(),
      'benutzer' => _userSettings(),
      'system' => _systemSettings(state),
      _ => const SizedBox(),
    };
  }

  Widget _desktopSettings(DesktopState state) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Title('Hintergrund'),
      const SizedBox(height: 8),
      // Wallpaper Grid
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, childAspectRatio: 16/9, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemCount: wallpaperGradients.length,
        itemBuilder: (context, i) {
          final selected = state.customWallpaperPath == null && state.wallpaperIndex == i;
          return GestureDetector(
            onTap: () => state.setWallpaper(i),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: wallpaperGradients[i], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: selected ? Colors.white : C.border, width: selected ? 2 : 1),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      // Custom wallpaper
      GestureDetector(
        onTap: () async {
          final ctrl = TextEditingController(text: state.customWallpaperPath ?? '/storage/emulated/0/Pictures/');
          final path = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
            backgroundColor: C.windowChromeUnfocused,
            title: const Text('Bild-Pfad', style: TextStyle(color: Colors.white, fontSize: 14)),
            content: TextField(controller: ctrl, keyboardType: TextInputType.none, autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(filled: true, fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none)),
              onSubmitted: (v) => Navigator.of(ctx).pop(v)),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text), child: const Text('Setzen')),
            ],
          ));
          if (path != null && path.isNotEmpty) state.setCustomWallpaper(path);
        },
        child: _SettingsRow(Icons.image, 'Eigenes Bild waehlen...', state.customWallpaperPath?.split('/').last),
      ),
      if (state.customWallpaperPath != null)
        GestureDetector(
          onTap: () => state.setWallpaper(state.wallpaperIndex),
          child: _SettingsRow(Icons.close, 'Eigenes Bild entfernen', null),
        ),
      const SizedBox(height: 20),
      _Title('Desktop-Icons'),
      const SizedBox(height: 8),
      _Toggle('Icons anzeigen', state.showDesktopIcons, (v) => state.setShowDesktopIcons(v)),
      _SliderRow('Icon-Groesse', state.iconSize, 32, 72, (v) => state.setIconSize(v)),
      const SizedBox(height: 20),
      _Title('Widgets'),
      const SizedBox(height: 8),
      _Toggle('Uhr', state.isWidgetActive('clock'), (_) => state.toggleWidget('clock')),
      _Toggle('Kalender', state.isWidgetActive('calendar'), (_) => state.toggleWidget('calendar')),
      _Toggle('System-Status', state.isWidgetActive('system'), (_) => state.toggleWidget('system')),
    ]);
  }

  Widget _appearanceSettings(DesktopState state) {
    const colors = [
      Color(0xFF86BE43), Color(0xFF4CAF50), Color(0xFF009688), Color(0xFF00BCD4),
      Color(0xFF2196F3), Color(0xFF448AFF), Color(0xFF9C27B0), Color(0xFFE91E63),
      Color(0xFFF44336), Color(0xFFFF5722), Color(0xFFFF9800), Color(0xFF607D8B),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Title('Akzentfarbe'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: colors.map((c) {
        final selected = c.toARGB32() == state.accentColor.toARGB32();
        return GestureDetector(
          onTap: () => state.setAccentColor(c),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: c, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        );
      }).toList()),
      const SizedBox(height: 20),
      _Title('Bildschirmschoner'),
      const SizedBox(height: 8),
      _DropdownRow('Timeout', state.screensaverTimeout, {
        0: 'Aus', 1: '1 Min', 5: '5 Min', 10: '10 Min', 30: '30 Min',
      }, (v) => state.setScreensaverTimeout(v)),
    ]);
  }

  Widget _windowSettings(DesktopState state) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Title('Fenster-Verhalten'),
      const SizedBox(height: 8),
      _InfoRow('Snap Links/Rechts', 'Fenster an Bildschirmrand ziehen'),
      _InfoRow('Snap Oben', 'Maximieren beim Ziehen nach oben'),
      _InfoRow('Doppelklick Titelleiste', 'Maximieren/Wiederherstellen'),
      _InfoRow('Rechtsklick Titelleiste', 'Fenstermenue'),
      const SizedBox(height: 20),
      _Title('Auto-Start'),
      const SizedBox(height: 8),
      Text('Rechtsklick auf Tool im Startmenue → "Bei Start oeffnen"',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      const SizedBox(height: 8),
      ...state.autoStartTools.map((id) => _SettingsRow(Icons.play_arrow, id, 'Aktiv')),
      if (state.autoStartTools.isEmpty)
        Text('Keine Auto-Start Tools konfiguriert',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
    ]);
  }

  Widget _keyboardSettings() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Title('Tastenkuerzel'),
      const SizedBox(height: 8),
      _InfoRow('Alt + Tab', 'Zwischen Fenstern wechseln'),
      _InfoRow('Alt + F4 / Ctrl + W', 'Fenster schliessen'),
      _InfoRow('Meta + D', 'Alle Fenster minimieren'),
      _InfoRow('Meta + S', 'Einstellungen oeffnen'),
      _InfoRow('Meta + Links', 'Fenster links tilen'),
      _InfoRow('Meta + Rechts', 'Fenster rechts tilen'),
      _InfoRow('Meta + Oben', 'Fenster maximieren'),
      _InfoRow('Ctrl + 1 / 2 / 3', 'Desktop wechseln'),
      _InfoRow('F5', 'Apps aktualisieren'),
      _InfoRow('Escape', 'Startmenue schliessen'),
    ]);
  }

  Widget _userSettings() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Title('Benutzer'),
      const SizedBox(height: 16),
      Center(child: CircleAvatar(
        radius: 40,
        backgroundColor: C.accent.withValues(alpha: 0.3),
        child: Text(_userName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w200)),
      )),
      const SizedBox(height: 16),
      Container(
        height: 36,
        decoration: BoxDecoration(color: C.inputBg, borderRadius: BorderRadius.circular(6)),
        child: TextField(
          controller: _nameController,
          keyboardType: TextInputType.none,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
          onSubmitted: _saveUserName,
        ),
      ),
      const SizedBox(height: 8),
      Center(child: GestureDetector(
        onTap: () => _saveUserName(_nameController.text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: C.accentDim, borderRadius: BorderRadius.circular(6)),
          child: const Text('Speichern', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      )),
    ]);
  }

  Widget _systemSettings(DesktopState state) {
    return Consumer<SystemStatusService>(
      builder: (context, service, _) {
        final s = service.status;
        return ListView(padding: const EdgeInsets.all(16), children: [
          _Title('System'),
          const SizedBox(height: 8),
          _InfoRow('Cursor', s.hasExternalMouse ? 'System-Maus' : 'D-Pad Cursor'),
          _InfoRow('Netzwerk', s.wifiConnected ? (s.wifiName ?? 'WLAN') : s.ethernetConnected ? 'Ethernet' : 'Nicht verbunden'),
          _InfoRow('Lautstaerke', '${s.volumePercent}%'),
          if (s.hasBattery) _InfoRow('Akku', '${s.batteryLevel}%${s.isCharging ? ' (Laden)' : ''}'),
          const SizedBox(height: 20),
          _Title('Ueber'),
          const SizedBox(height: 8),
          _InfoRow('DeX Launcher', 'v2.0.0'),
          _InfoRow('Apps', '${state.allApps.length} installiert'),
          _InfoRow('Design', 'Linux Mint Cinnamon (Mint-Y-Dark)'),
          _InfoRow('Framework', 'Flutter / Dart'),
          _InfoRow('Repository', 'github.com/miri2577/dex-launcher'),
        ]);
      },
    );
  }

  // --- Shared Widgets ---
  Widget _Title(String text) => Text(text,
    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5));

  Widget _Toggle(String label, bool value, ValueChanged<bool> onChanged) => Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: C.hover, borderRadius: BorderRadius.circular(6)),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
      Switch(value: value, onChanged: onChanged, activeColor: C.accent),
    ]),
  );

  Widget _SliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) => Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: C.hover, borderRadius: BorderRadius.circular(6)),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
      Text('${value.round()}px', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
      SizedBox(width: 120, child: Slider(value: value, min: min, max: max, activeColor: C.accent, onChanged: onChanged)),
    ]),
  );

  Widget _DropdownRow(String label, int value, Map<int, String> options, ValueChanged<int> onChanged) => Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: C.hover, borderRadius: BorderRadius.circular(6)),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
      DropdownButton<int>(
        value: value, dropdownColor: C.menuBg,
        style: const TextStyle(color: Colors.white, fontSize: 12), underline: const SizedBox(),
        items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ]),
  );

  Widget _InfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 180, child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12))),
    ]),
  );

  Widget _SettingsRow(IconData icon, String label, String? value) => Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: C.hover, borderRadius: BorderRadius.circular(6)),
    child: Row(children: [
      Icon(icon, color: Colors.white54, size: 16), const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
      if (value != null) Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
    ]),
  );
}
