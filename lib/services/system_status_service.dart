import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemStatus {
  final int batteryLevel;
  final bool isCharging;
  final bool wifiConnected;
  final String? wifiName;
  final int wifiStrength;
  final bool ethernetConnected;
  final int volumePercent;
  final bool isMuted;

  const SystemStatus({
    this.batteryLevel = -1,
    this.isCharging = false,
    this.wifiConnected = false,
    this.wifiName,
    this.wifiStrength = -1,
    this.ethernetConnected = false,
    this.volumePercent = 0,
    this.isMuted = false,
  });

  bool get hasBattery => batteryLevel >= 0;
  bool get hasNetwork => wifiConnected || ethernetConnected;

  IconData get batteryIcon {
    if (isCharging) return Icons.battery_charging_full;
    if (batteryLevel > 80) return Icons.battery_full;
    if (batteryLevel > 60) return Icons.battery_5_bar;
    if (batteryLevel > 40) return Icons.battery_4_bar;
    if (batteryLevel > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color get batteryColor {
    if (isCharging) return Colors.greenAccent;
    if (batteryLevel > 20) return Colors.white;
    return Colors.redAccent;
  }

  IconData get networkIcon {
    if (ethernetConnected) return Icons.settings_ethernet;
    if (!wifiConnected) return Icons.wifi_off;
    if (wifiStrength >= 3) return Icons.wifi;
    if (wifiStrength >= 1) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  IconData get volumeIcon {
    if (isMuted || volumePercent == 0) return Icons.volume_off;
    if (volumePercent < 50) return Icons.volume_down;
    return Icons.volume_up;
  }
}

class SystemStatusService extends ChangeNotifier {
  static const _channel = MethodChannel('com.dexlauncher/apps');

  SystemStatus _status = const SystemStatus();
  Timer? _timer;

  SystemStatus get status => _status;

  void startPolling() {
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchStatus());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchStatus() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('getSystemStatus');
      _status = SystemStatus(
        batteryLevel: result['batteryLevel'] as int? ?? -1,
        isCharging: result['isCharging'] as bool? ?? false,
        wifiConnected: result['wifiConnected'] as bool? ?? false,
        wifiName: result['wifiName'] as String?,
        wifiStrength: result['wifiStrength'] as int? ?? -1,
        ethernetConnected: result['ethernetConnected'] as bool? ?? false,
        volumePercent: result['volumePercent'] as int? ?? 0,
        isMuted: result['isMuted'] as bool? ?? false,
      );
      notifyListeners();
    } catch (_) {
      // Platform channel nicht verfügbar (z.B. im Emulator)
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
