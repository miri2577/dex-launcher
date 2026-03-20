import 'package:flutter/material.dart';
import 'mdi_window.dart';

class WindowManager extends ChangeNotifier {
  final List<MDIWindow> _windows = [];
  int _nextZ = 1;
  int _currentDesktop = 0;
  static const int maxDesktops = 3;

  int get currentDesktop => _currentDesktop;
  List<MDIWindow> get allWindows => List.unmodifiable(_windows);
  List<MDIWindow> get windows => _windows.where((w) => w.desktop == _currentDesktop).toList();
  List<MDIWindow> get sortedWindows =>
      (List<MDIWindow>.from(windows)..sort((a, b) => a.zOrder.compareTo(b.zOrder)));

  bool get hasWindows => windows.isNotEmpty;

  MDIWindow? get focusedWindow =>
      windows.where((w) => w.isFocused && !w.isMinimized).firstOrNull;

  void switchDesktop(int index) {
    if (index < 0 || index >= maxDesktops || index == _currentDesktop) return;
    // Unfocus alle auf aktuellem Desktop
    for (final w in windows) { w.isFocused = false; }
    _currentDesktop = index;
    // Focus oberstes Fenster auf neuem Desktop
    final visible = sortedWindows.where((w) => !w.isMinimized);
    if (visible.isNotEmpty) visible.last.isFocused = true;
    notifyListeners();
  }

  MDIWindow openWindow({
    required String appType,
    required String title,
    Offset? position,
    Size? size,
    IconData icon = Icons.window,
    Map<String, dynamic>? initialData,
  }) {
    // Kaskadierte Position
    final offset = (_windows.length % 6) * 30.0;
    final window = MDIWindow(
      id: '${appType}_${DateTime.now().millisecondsSinceEpoch}',
      appType: appType,
      title: title,
      position: position ?? Offset(80 + offset, 30 + offset),
      size: size ?? const Size(600, 400),
      zOrder: _nextZ++,
      isFocused: true,
      icon: icon,
      initialData: initialData,
      desktop: _currentDesktop,
    );

    // Alle anderen Fenster unfocusen
    for (final w in _windows) {
      w.isFocused = false;
    }

    _windows.add(window);
    notifyListeners();
    return window;
  }

  void closeWindow(String id) {
    _windows.removeWhere((w) => w.id == id);
    // Oberstes Fenster fokussieren
    if (_windows.isNotEmpty) {
      final top = sortedWindows.last;
      top.isFocused = true;
    }
    notifyListeners();
  }

  void focusWindow(String id) {
    for (final w in _windows) {
      w.isFocused = w.id == id;
      if (w.id == id) {
        w.zOrder = _nextZ++;
        w.isMinimized = false;
      }
    }
    notifyListeners();
  }

  void minimizeWindow(String id) {
    final window = _windows.where((w) => w.id == id).firstOrNull;
    if (window != null) {
      window.isMinimized = true;
      window.isFocused = false;
      // Nächstes sichtbares Fenster fokussieren
      final visible = sortedWindows.where((w) => !w.isMinimized);
      if (visible.isNotEmpty) {
        visible.last.isFocused = true;
      }
      notifyListeners();
    }
  }

  void updatePosition(String id, Offset position) {
    final window = _windows.where((w) => w.id == id).firstOrNull;
    if (window != null) {
      window.position = position;
      // Kein notifyListeners — wird vom Drag direkt gehandelt
    }
  }

  void updateSize(String id, Size size) {
    final window = _windows.where((w) => w.id == id).firstOrNull;
    if (window != null) {
      window.size = Size(
        size.width.clamp(window.minSize.width, double.infinity),
        size.height.clamp(window.minSize.height, double.infinity),
      );
    }
  }

  void updateWindowTitle(String id, String title) {
    final window = _windows.where((w) => w.id == id).firstOrNull;
    if (window != null) {
      window.title = title;
      notifyListeners();
    }
  }

  void closeAll() {
    _windows.clear();
    notifyListeners();
  }
}
