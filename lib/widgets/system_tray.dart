import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_status_service.dart';
import '../windows/window_manager.dart';

class SystemTray extends StatelessWidget {
  final SystemStatus status;

  const SystemTray({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lautstärke
        _TrayIcon(
          icon: status.volumeIcon,
          tooltip: status.isMuted
              ? 'Stumm'
              : 'Lautstaerke: ${status.volumePercent}%',
        ),
        const SizedBox(width: 2),
        // WLAN — klickbar, öffnet WiFi Manager
        _TrayIcon(
          icon: status.networkIcon,
          tooltip: status.ethernetConnected
              ? 'Ethernet'
              : status.wifiConnected
                  ? 'WLAN: ${status.wifiName ?? "Verbunden"}'
                  : 'Kein Netzwerk',
          color: status.hasNetwork ? Colors.white : Colors.white38,
          onTap: () => context.read<WindowManager>().openWindow(
            appType: 'wifi_manager',
            title: 'WLAN',
            icon: Icons.wifi,
            size: const Size(400, 420),
          ),
        ),
        const SizedBox(width: 2),
        // Bluetooth — klickbar, öffnet BT Manager
        _TrayIcon(
          icon: Icons.bluetooth,
          tooltip: 'Bluetooth',
          color: Colors.white70,
          onTap: () => context.read<WindowManager>().openWindow(
            appType: 'bluetooth_manager',
            title: 'Bluetooth',
            icon: Icons.bluetooth,
            size: const Size(400, 400),
          ),
        ),
        // Batterie (nur wenn vorhanden)
        if (status.hasBattery) ...[
          const SizedBox(width: 2),
          _TrayIcon(
            icon: status.batteryIcon,
            tooltip: status.isCharging
                ? 'Laden: ${status.batteryLevel}%'
                : 'Akku: ${status.batteryLevel}%',
            color: status.batteryColor,
          ),
        ],
      ],
    );
  }
}

class _TrayIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _TrayIcon({
    required this.icon,
    required this.tooltip,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  State<_TrayIcon> createState() => _TrayIconState();
}

class _TrayIconState extends State<_TrayIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _hovering ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Icon(widget.icon, color: widget.color, size: 16),
          ),
        ),
      ),
    );
  }
}
