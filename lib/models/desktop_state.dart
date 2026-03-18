import 'package:flutter/material.dart';
import 'app_info.dart';
import '../services/app_service.dart';
import '../services/storage_service.dart';

class DesktopState extends ChangeNotifier {
  final AppService appService = AppService();
  final StorageService storage = StorageService();

  List<AppInfo> _allApps = [];
  List<String> _recentPackages = [];
  bool _loading = true;
  int _wallpaperIndex = 0;
  bool _showDesktopIcons = true;
  double _iconSize = 48.0;
  Map<String, Offset> _desktopPositions = {};

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

  void launchApp(AppInfo app) {
    appService.launchApp(app.packageName);
    // Recent-Apps-Liste aktualisieren nach kurzem Delay
    Future.delayed(const Duration(seconds: 1), loadRecentApps);
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
