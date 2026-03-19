import 'dart:ui';

class WindowInfo {
  final String packageName;
  final String appName;
  Rect bounds;
  bool isMinimized;
  final DateTime launchedAt;

  WindowInfo({
    required this.packageName,
    required this.appName,
    required this.bounds,
    this.isMinimized = false,
    DateTime? launchedAt,
  }) : launchedAt = launchedAt ?? DateTime.now();

  int get left => bounds.left.toInt();
  int get top => bounds.top.toInt();
  int get right => bounds.right.toInt();
  int get bottom => bounds.bottom.toInt();
  int get width => bounds.width.toInt();
  int get height => bounds.height.toInt();
}
