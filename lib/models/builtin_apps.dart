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
  BuiltinApp(
    id: 'file_manager',
    name: 'Dateimanager',
    icon: Icons.folder,
    iconColor: Colors.amber,
    defaultSize: Size(550, 380),
  ),
  BuiltinApp(
    id: 'browser',
    name: 'Browser',
    icon: Icons.language,
    iconColor: Colors.blueAccent,
    defaultSize: Size(700, 450),
  ),
  BuiltinApp(
    id: 'settings_app',
    name: 'Systemeinstellungen',
    icon: Icons.settings,
    iconColor: Colors.grey,
    defaultSize: Size(500, 400),
  ),
  BuiltinApp(
    id: 'terminal',
    name: 'Terminal',
    icon: Icons.terminal,
    iconColor: Colors.greenAccent,
    defaultSize: Size(600, 350),
  ),
];

BuiltinApp? getBuiltinApp(String id) {
  return builtinApps.where((a) => a.id == id).firstOrNull;
}
