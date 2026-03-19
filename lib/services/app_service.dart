import 'package:flutter/services.dart';
import '../models/app_info.dart';

class AppService {
  static const _channel = MethodChannel('com.dexlauncher/apps');

  Future<List<AppInfo>> getInstalledApps() async {
    final List<dynamic> result = await _channel.invokeMethod('getInstalledApps');
    return result.map((app) {
      final map = Map<String, dynamic>.from(app as Map);
      return AppInfo(
        name: map['name'] as String,
        packageName: map['packageName'] as String,
        icon: map['icon'] != null ? Uint8List.fromList(List<int>.from(map['icon'])) : null,
        isSystemApp: map['isSystemApp'] as bool? ?? false,
        category: AppCategory.fromAndroidCategory(map['category'] as int?),
      );
    }).toList();
  }

  Future<void> launchApp(String packageName) async {
    await _channel.invokeMethod('launchApp', {'packageName': packageName});
  }

  Future<void> openAppInfo(String packageName) async {
    await _channel.invokeMethod('openAppInfo', {'packageName': packageName});
  }

  Future<void> uninstallApp(String packageName) async {
    await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
  }

  Future<List<String>> getRecentApps({int limit = 10}) async {
    final List<dynamic> result = await _channel.invokeMethod(
      'getRecentApps',
      {'limit': limit},
    );
    return result.cast<String>();
  }

  Future<List<String>> getWallpaperImages() async {
    final List<dynamic> result = await _channel.invokeMethod('getWallpaperImages');
    return result.cast<String>();
  }

  Future<void> setVolume(int percent) async {
    await _channel.invokeMethod('setVolume', {'percent': percent});
  }

  Future<bool> isFreeformEnabled() async {
    return await _channel.invokeMethod<bool>('isFreeformEnabled') ?? false;
  }

  Future<bool> enableFreeform() async {
    return await _channel.invokeMethod<bool>('enableFreeform') ?? false;
  }

  /// Startet App in Freeform-Fenster mit gegebenen Bounds (Pixel)
  Future<bool> launchAppFreeform(
    String packageName, {
    required int left,
    required int top,
    required int right,
    required int bottom,
  }) async {
    return await _channel.invokeMethod<bool>('launchAppFreeform', {
      'packageName': packageName,
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    }) ?? false;
  }
}
