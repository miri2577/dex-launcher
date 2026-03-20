import 'package:flutter/material.dart';

/// Eingebaute Mini-Apps die als Fenster laufen
class BuiltinApp {
  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
  final Size defaultSize;

  const BuiltinApp({
    required this.id,
    required this.name,
    required this.icon,
    this.iconColor = Colors.white,
    this.defaultSize = const Size(600, 400),
  });
}

const builtinApps = [
  BuiltinApp(id: 'file_manager', name: 'Dateimanager', icon: Icons.folder, defaultSize: Size(550, 380)),
  BuiltinApp(id: 'browser', name: 'Browser', icon: Icons.language, defaultSize: Size(700, 450)),
  BuiltinApp(id: 'calculator', name: 'Rechner', icon: Icons.calculate, defaultSize: Size(280, 380)),
  BuiltinApp(id: 'wifi_manager', name: 'WLAN', icon: Icons.wifi, defaultSize: Size(400, 420)),
  BuiltinApp(id: 'bluetooth_manager', name: 'Bluetooth', icon: Icons.bluetooth, defaultSize: Size(400, 400)),
  BuiltinApp(id: 'system_monitor', name: 'Systemmonitor', icon: Icons.monitor_heart, defaultSize: Size(450, 350)),
  BuiltinApp(id: 'terminal', name: 'Terminal', icon: Icons.terminal, defaultSize: Size(650, 400)),
  BuiltinApp(id: 'text_editor', name: 'Editor', icon: Icons.edit_note, defaultSize: Size(550, 400)),
  BuiltinApp(id: 'image_viewer', name: 'Bilder', icon: Icons.image, defaultSize: Size(600, 450)),
  BuiltinApp(id: 'video_player', name: 'Video', icon: Icons.movie, defaultSize: Size(500, 400)),
  BuiltinApp(id: 'clipboard', name: 'Clipboard', icon: Icons.content_paste, defaultSize: Size(350, 400)),
  BuiltinApp(id: 'task_manager', name: 'Task Manager', icon: Icons.memory, defaultSize: Size(500, 380)),
  BuiltinApp(id: 'network_scanner', name: 'Netzwerk-Scanner', icon: Icons.lan, defaultSize: Size(420, 350)),
  BuiltinApp(id: 'music_player', name: 'Musik', icon: Icons.music_note, defaultSize: Size(450, 380)),
  BuiltinApp(id: 'weather', name: 'Wetter', icon: Icons.cloud, defaultSize: Size(320, 340)),
  BuiltinApp(id: 'developer', name: 'Entwickleroptionen', icon: Icons.developer_mode, defaultSize: Size(550, 450)),
];

BuiltinApp? getBuiltinApp(String id) {
  return builtinApps.where((a) => a.id == id).firstOrNull;
}
