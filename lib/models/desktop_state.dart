import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_info.dart';
import '../services/app_service.dart';
import '../services/storage_service.dart';

class DesktopState extends ChangeNotifier {
  final AppService appService = AppService();
  final StorageService storage = StorageService();

  List<AppInfo> _allApps = [];
  List<String> _recentPackages = [];
  bool _freeformEnabled = false;
  bool _loading = true;
  int _wallpaperIndex = 0;
  String? _customWallpaperPath;
  bool _showDesktopIcons = true;
  double _iconSize = 48.0;
  List<String> _pinnedToolIds = [];
  List<String> _activeWidgets = [];
  String _themeMode = 'dark';
  Color _accentColor = const Color(0xFF86BE43); // Mint Green default
  int _screensaverTimeout = 0;
  List<String> _autoStartTools = [];
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
  bool get freeformEnabled => _freeformEnabled;
  bool get loading => _loading;
  int get wallpaperIndex => _wallpaperIndex;
  String? get customWallpaperPath => _customWallpaperPath;
  bool get showDesktopIcons => _showDesktopIcons;
  double get iconSize => _iconSize;
  List<String> get pinnedToolIds => _pinnedToolIds;
  List<String> get activeWidgets => _activeWidgets;
  String get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  int get screensaverTimeout => _screensaverTimeout;
  List<String> get autoStartTools => _autoStartTools;
  Map<String, Offset> get desktopPositions => _desktopPositions;

  Future<void> init() async {
    await storage.init();
    _wallpaperIndex = storage.wallpaperIndex;
    _customWallpaperPath = storage.customWallpaperPath;
    _showDesktopIcons = storage.showDesktopIcons;
    _pinnedToolIds = storage.pinnedTools;
    _activeWidgets = storage.activeWidgets;
    _themeMode = storage.themeMode;
    _accentColor = Color(storage.accentColorValue);
    _screensaverTimeout = storage.screensaverTimeout;
    _autoStartTools = storage.autoStartTools;
    _iconSize = storage.iconSize;
    _loadPositions();
    await loadApps();
    await loadRecentApps();
    await checkFreeformSupport();
    _tryStartOverlay();
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

      // Erster Start: alle Apps auf Desktop legen
      if (savedDesktop.isEmpty) {
        for (var i = 0; i < apps.length && i < 20; i++) {
          apps[i].isOnDesktop = true;
        }
        _saveDesktopApps();
      }

      _allApps = apps;
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('DesktopState error: $e');
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentApps() async {
    try {
      _recentPackages = await appService.getRecentApps(limit: 10);
      notifyListeners();
    } catch (e) {
      debugPrint('DesktopState error: $e');
      // UsageStats-Permission fehlt — graceful fallback
    }
  }

  Future<void> _tryStartOverlay() async {
    try {
      final canDraw = await appService.canDrawOverlays();
      if (canDraw) {
        await appService.startOverlay();
      }
    } catch (e) { debugPrint('DesktopState error: $e'); }
  }

  Future<void> checkFreeformSupport() async {
    try {
      _freeformEnabled = await appService.isFreeformEnabled();
      notifyListeners();
    } catch (e) { debugPrint('DesktopState error: $e'); }
  }

  Future<bool> enableFreeform() async {
    try {
      final success = await appService.enableFreeform();
      if (success) {
        _freeformEnabled = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('DesktopState error: $e');
      return false;
    }
  }

  void updateScreenSize(ui.Size size) {
    _screenSize = size;
  }

  void launchApp(AppInfo app) {
    appService.launchApp(app.packageName);
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

    final success = await appService.launchAppFreeform(
      app.packageName,
      left: left,
      top: top,
      right: left + w,
      bottom: top + h,
    );

    if (success) {
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
    _customWallpaperPath = null;
    storage.wallpaperIndex = index;
    storage.customWallpaperPath = null;
    notifyListeners();
  }

  void setCustomWallpaper(String path) {
    _customWallpaperPath = path;
    storage.customWallpaperPath = path;
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

  bool isToolPinned(String toolId) => _pinnedToolIds.contains(toolId);

  bool isWidgetActive(String id) => _activeWidgets.contains(id);

  void toggleWidget(String id) {
    if (_activeWidgets.contains(id)) {
      _activeWidgets.remove(id);
    } else {
      _activeWidgets.add(id);
    }
    storage.activeWidgets = _activeWidgets;
    notifyListeners();
  }

  void setThemeMode(String mode) {
    _themeMode = mode;
    storage.themeMode = mode;
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    storage.accentColorValue = color.toARGB32();
    notifyListeners();
  }

  void setScreensaverTimeout(int minutes) {
    _screensaverTimeout = minutes;
    storage.screensaverTimeout = minutes;
    notifyListeners();
  }

  bool isAutoStart(String toolId) => _autoStartTools.contains(toolId);

  void toggleAutoStart(String toolId) {
    if (_autoStartTools.contains(toolId)) {
      _autoStartTools.remove(toolId);
    } else {
      _autoStartTools.add(toolId);
    }
    storage.autoStartTools = _autoStartTools;
    notifyListeners();
  }

  void toggleToolPin(String toolId) {
    if (_pinnedToolIds.contains(toolId)) {
      _pinnedToolIds.remove(toolId);
    } else {
      _pinnedToolIds.add(toolId);
    }
    storage.pinnedTools = _pinnedToolIds;
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
