import 'dart:typed_data';

class AppInfo {
  final String name;
  final String packageName;
  final Uint8List? icon;
  final bool isSystemApp;
  bool isPinned;
  bool isOnDesktop;

  AppInfo({
    required this.name,
    required this.packageName,
    this.icon,
    this.isSystemApp = false,
    this.isPinned = false,
    this.isOnDesktop = true,
  });
}
