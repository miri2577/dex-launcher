import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_info.dart';
import 'window_info.dart';
import '../services/app_service.dart';
import '../services/storage_service.dart';

class DesktopState extends ChangeNotifier {
  final AppService appService = AppService();
  final StorageService storage = StorageService();

  List<AppInfo> _allApps = [];
  List<String> _recentPackages = [];
  final List<WindowInfo> _runningWindows = [];
  bool _freeformEnabled = false;
  bool _loading = true;
  int _wallpaperIndex = 0;
  bool _showDesktopIcons = true;
  double _iconSize = 48.0;
  Map<String, Offset> _desktopPositions = {};

  // Bildschirmgröße für Fenster-Positionierung
  ui.Size _screenSize = const ui.Size(1920, 1080);
  int _windowCounter = 0;

  List<AppInfo> get allApps => _allApps;
  List<AppInfo> get pinnedApps => _allApps.where((a) => a.isPinned).toList();
  List<AppInfo> get desktopApps => _allApps.where((a) => a.isOnDesktop).toList();

  /// Zuletzt benutzte Apps, sortiert nach letzter Nutzung
  List<AppInfo> get recentApps {
    final appMap = {for (final a in _allApps) a.packageName: a};
    return _recentPackages
        .where((pkg) => appMap.containsKey(pkg))
        .map((pkg) => appMap[pkg]!)
        .toList();
  }
  List<WindowInfo> get runningWindows => _runningWindows;
  bool get freeformEnabled => _freeformEnabled;
  bool get loading => _loading;
  int get wallpaperIndex => _wallpaperIndex;
  bool get showDesktopIcons => _showDesktopIcons;
  double get iconSize => _iconSize;
  Map<String, Offset> get desktopPositions => _desktopPositions;

  Future<void> init() async {
    await storage.init();
    _wallpaperIndex = storage.wallpaperIndex;
    _showDesktopIcons = storage.showDesktopIcons;
    _iconSize = storage.iconSize;
    _loadPositions();
    await loadApps();
    await loadRecentApps();
    await checkFreeformSupport();
  }

  void _loadPositions() {
    final saved = storage.getDesktopPositions();
    _desktopPositions = saved.map(
      (k, v) => MapEntry(k, Offset(v[0], v[1])),
    );
  }

  void _savePositions() {
    final map = _desktopPositions.map(
      (k, v) => MapEntry(k, [v.dx, v.dy]),
    );
    storage.saveDesktopPositions(map);
  }

  Future<void> loadApps() async {
    try {
      final apps = await appService.getInstalledApps();
      final savedPinned = storage.pinnedApps;
      final savedDesktop = storage.desktopApps;

      for (final app in apps) {
        if (savedPinned.isNotEmpty) {
          app.isPinned = savedPinned.contains(app.packageName);
        }
        if (savedDesktop.isNotEmpty) {
          app.isOnDesktop = savedDesktop.contains(app.packageName);
        }
      }

      // Erster Start: erste 6 pinnen, erste 20 auf Desktop
      if (savedPinned.isEmpty) {
        for (var i = 0; i < apps.length && i < 6; i++) {
          apps[i].isPinned = true;
        }
        _savePins();
      }
      if (savedDesktop.isEmpty) {
        for (var i = 0; i < apps.length && i < 20; i++) {
          apps[i].isOnDesktop = true;
        }
        _saveDesktopApps();
      }

      _allApps = apps;
      _loading = false;
      notifyListeners();
    } catch (_) {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentApps() async {
    try {
      _recentPackages = await appService.getRecentApps(limit: 10);
      notifyListeners();
    } catch (_) {
      // UsageStats-Permission fehlt — graceful fallback
    }
  }

  Future<void> checkFreeformSupport() async {
    try {
      _freeformEnabled = await appService.isFreeformEnabled();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> enableFreeform() async {
    try {
      final success = await appService.enableFreeform();
      if (success) {
        _freeformEnabled = true;
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  void updateScreenSize(ui.Size size) {
    _screenSize = size;
  }

  void launchApp(AppInfo app) {
    if (_freeformEnabled) {
      launchAppFreeform(app);
    } else {
      appService.launchApp(app.packageName);
    }
    // Recent-Apps-Liste aktualisieren nach kurzem Delay
    Future.delayed(const Duration(seconds: 1), loadRecentApps);
  }

  void launchAppFullscreen(AppInfo app) {
    appService.launchApp(app.packageName);
    Future.delayed(const Duration(seconds: 1), loadRecentApps);
  }

  Future<void> launchAppFreeform(AppInfo app) async {
    // Kaskadierte Positionierung: jedes neue Fenster leicht versetzt
    _windowCounter++;
    final offset = (_windowCounter % 8) * 30;
    final w = (_screenSize.width * 0.55).toInt();
    final h = (_screenSize.height * 0.65).toInt();
    final left = 80 + offset;
    final top = 40 + offset;

    final bounds = Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      w.toDouble(),
      h.toDouble(),
    );

    final success = await appService.launchAppFreeform(
      app.packageName,
      left: left,
      top: top,
      right: left + w,
      bottom: top + h,
    );

    if (success) {
      // Bestehendes Fenster aktualisieren oder neues erstellen
      final existingIndex = _runningWindows.indexWhere(
        (w) => w.packageName == app.packageName,
      );
      if (existingIndex >= 0) {
        _runningWindows[existingIndex].isMinimized = false;
      } else {
        _runningWindows.add(WindowInfo(
          packageName: app.packageName,
          appName: app.name,
          bounds: bounds,
        ));
      }
      notifyListeners();
    }
  }

  void closeWindow(String packageName) {
    _runningWindows.removeWhere((w) => w.packageName == packageName);
    notifyListeners();
  }

  void toggleMinimizeWindow(String packageName) {
    final window = _runningWindows.where(
      (w) => w.packageName == packageName,
    ).firstOrNull;
    if (window != null) {
      window.isMinimized = !window.isMinimized;
      notifyListeners();
    }
  }

  void openAppInfo(AppInfo app) {
    appService.openAppInfo(app.packageName);
  }

  void uninstallApp(AppInfo app) {
    appService.uninstallApp(app.packageName);
  }

  void togglePin(AppInfo app) {
    app.isPinned = !app.isPinned;
    _savePins();
    notifyListeners();
  }

  void toggleDesktop(AppInfo app) {
    app.isOnDesktop = !app.isOnDesktop;
    _saveDesktopApps();
    notifyListeners();
  }

  void updateDesktopPosition(String packageName, Offset position) {
    _desktopPositions[packageName] = position;
    _savePositions();
  }

  void setWallpaper(int index) {
    _wallpaperIndex = index;
    storage.wallpaperIndex = index;
    notifyListeners();
  }

  void setShowDesktopIcons(bool show) {
    _showDesktopIcons = show;
    storage.showDesktopIcons = show;
    notifyListeners();
  }

  void setIconSize(double size) {
    _iconSize = size;
    storage.iconSize = size;
    notifyListeners();
  }

  void _savePins() {
    storage.pinnedApps = _allApps
        .where((a) => a.isPinned)
        .map((a) => a.packageName)
        .toList();
  }

  void _saveDesktopApps() {
    storage.desktopApps = _allApps
        .where((a) => a.isOnDesktop)
        .map((a) => a.packageName)
        .toList();
  }
}
