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
    id: 'calculator',
    name: 'Rechner',
    icon: Icons.calculate,
    iconColor: Colors.tealAccent,
    defaultSize: Size(280, 380),
  ),
  BuiltinApp(
    id: 'wifi_manager',
    name: 'WLAN',
    icon: Icons.wifi,
    iconColor: Colors.lightBlueAccent,
    defaultSize: Size(400, 420),
  ),
  BuiltinApp(
    id: 'bluetooth_manager',
    name: 'Bluetooth',
    icon: Icons.bluetooth,
    iconColor: Colors.blue,
    defaultSize: Size(400, 400),
  ),
  BuiltinApp(
    id: 'system_monitor',
    name: 'Systemmonitor',
    icon: Icons.monitor_heart,
    iconColor: Colors.greenAccent,
    defaultSize: Size(450, 350),
  ),
  BuiltinApp(
    id: 'terminal',
    name: 'Terminal',
    icon: Icons.terminal,
    iconColor: Colors.green,
    defaultSize: Size(650, 400),
  ),
];

BuiltinApp? getBuiltinApp(String id) {
  return builtinApps.where((a) => a.id == id).firstOrNull;
}
