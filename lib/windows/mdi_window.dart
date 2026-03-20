import 'package:flutter/material.dart';

/// Ein Fenster in der In-App Desktop-Umgebung
class MDIWindow {
  final String id;
  final String appType;
  String title;
  Offset position;
  Size size;
  Size minSize;
  int zOrder;
  bool isMinimized;
  bool isFocused;
  IconData icon;

  Map<String, dynamic>? initialData;
  int desktop;

  MDIWindow({
    required this.id,
    required this.appType,
    required this.title,
    required this.position,
    required this.size,
    this.minSize = const Size(300, 200),
    this.zOrder = 0,
    this.isMinimized = false,
    this.isFocused = true,
    this.icon = Icons.window,
    this.initialData,
    this.desktop = 0,
  });

  Rect get bounds => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}
