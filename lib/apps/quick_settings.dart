import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/system_status_service.dart';
import '../models/desktop_state.dart';

class QuickSettingsApp extends StatelessWidget {
  const QuickSettingsApp({super.key});
  static const _channel = MethodChannel('com.dexlauncher/apps');

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(12),
      child: Consumer<SystemStatusService>(
        builder: (context, service, _) {
          final s = service.status;
          return Column(
            children: [
              // WiFi
              _QSTile(
                icon: s.networkIcon,
                label: s.wifiConnected ? (s.wifiName ?? 'WLAN') : s.ethernetConnected ? 'Ethernet' : 'Nicht verbunden',
                active: s.hasNetwork,
                onTap: () => _channel.invokeMethod('executeCommand', {'command': 'svc wifi enable'}),
                onLongPress: () => _channel.invokeMethod('executeCommand', {'command': 'svc wifi disable'}),
              ),
              const SizedBox(height: 8),
              // Bluetooth
              _QSTile(
                icon: Icons.bluetooth,
                label: 'Bluetooth',
                active: true,
                onTap: () => _channel.invokeMethod('executeCommand', {'command': 'svc bluetooth enable'}),
                onLongPress: () => _channel.invokeMethod('executeCommand', {'command': 'svc bluetooth disable'}),
              ),
              const SizedBox(height: 12),
              // Volume
              Row(children: [
                Icon(s.volumeIcon, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: const Color(0xFF86BE43),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.12), thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: s.volumePercent.toDouble().clamp(0, 100),
                      min: 0, max: 100,
                      onChanged: (v) => context.read<DesktopState>().appService.setVolume(v.toInt()),
                    ),
                  ),
                ),
                Text('${s.volumePercent}%', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
              ]),
              const SizedBox(height: 12),
              // Brightness (über Settings)
              Row(children: [
                const Icon(Icons.brightness_6, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: Colors.amber, inactiveTrackColor: Colors.white.withValues(alpha: 0.12), thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: 128,
                      min: 0, max: 255,
                      onChanged: (v) => _channel.invokeMethod('executeCommand', {'command': 'settings put system screen_brightness ${v.toInt()}'}),
                    ),
                  ),
                ),
              ]),
              const Spacer(),
              // Info
              if (s.hasBattery)
                Row(children: [
                  Icon(s.batteryIcon, color: s.batteryColor, size: 16),
                  const SizedBox(width: 6),
                  Text('${s.batteryLevel}%', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                ]),
            ],
          );
        },
      ),
    );
  }
}

class _QSTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _QSTile({required this.icon, required this.label, required this.active, required this.onTap, this.onLongPress});
  @override
  State<_QSTile> createState() => _QSTileState();
}

class _QSTileState extends State<_QSTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.active
                ? (_h ? const Color(0xFF86BE43).withValues(alpha: 0.25) : const Color(0xFF86BE43).withValues(alpha: 0.15))
                : (_h ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(children: [
            Icon(widget.icon, color: widget.active ? const Color(0xFF86BE43) : Colors.white54, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.label, style: TextStyle(
              color: widget.active ? Colors.white : Colors.white70, fontSize: 12))),
            Text(widget.active ? 'An' : 'Aus',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
