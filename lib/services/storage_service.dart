import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _pinnedAppsKey = 'pinned_apps';
  static const _desktopAppsKey = 'desktop_apps';
  static const _wallpaperIndexKey = 'wallpaper_index';
  static const _dockPositionKey = 'dock_position';
  static const _showDesktopIconsKey = 'show_desktop_icons';
  static const _iconSizeKey = 'icon_size';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Pinned Apps
  List<String> get pinnedApps {
    return _prefs.getStringList(_pinnedAppsKey) ?? [];
  }

  set pinnedApps(List<String> packages) {
    _prefs.setStringList(_pinnedAppsKey, packages);
  }

  // Desktop Apps (welche auf dem Desktop angezeigt werden)
  List<String> get desktopApps {
    return _prefs.getStringList(_desktopAppsKey) ?? [];
  }

  set desktopApps(List<String> packages) {
    _prefs.setStringList(_desktopAppsKey, packages);
  }

  // Desktop Icon Positionen
  Map<String, List<double>> getDesktopPositions() {
    final json = _prefs.getString('desktop_positions');
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, List<double>.from(v as List)));
  }

  void saveDesktopPositions(Map<String, List<double>> positions) {
    _prefs.setString('desktop_positions', jsonEncode(positions));
  }

  // Wallpaper
  int get wallpaperIndex => _prefs.getInt(_wallpaperIndexKey) ?? 0;
  set wallpaperIndex(int index) => _prefs.setInt(_wallpaperIndexKey, index);

  // Dock Position (bottom, top, left, right)
  String get dockPosition => _prefs.getString(_dockPositionKey) ?? 'bottom';
  set dockPosition(String pos) => _prefs.setString(_dockPositionKey, pos);

  // Show Desktop Icons
  bool get showDesktopIcons => _prefs.getBool(_showDesktopIconsKey) ?? true;
  set showDesktopIcons(bool show) => _prefs.setBool(_showDesktopIconsKey, show);

  // Icon Size
  double get iconSize => _prefs.getDouble(_iconSizeKey) ?? 48.0;
  set iconSize(double size) => _prefs.setDouble(_iconSizeKey, size);

  // Pinned Built-in Tools (IDs)
  List<String> get pinnedTools {
    return _prefs.getStringList('pinned_tools') ?? ['file_manager', 'browser'];
  }
  set pinnedTools(List<String> ids) {
    _prefs.setStringList('pinned_tools', ids);
  }

  // Custom Wallpaper Image Path
  String? get customWallpaperPath => _prefs.getString('custom_wallpaper_path');
  set customWallpaperPath(String? path) {
    if (path == null) {
      _prefs.remove('custom_wallpaper_path');
    } else {
      _prefs.setString('custom_wallpaper_path', path);
    }
  }
}
