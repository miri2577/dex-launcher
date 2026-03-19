import 'package:flutter/material.dart';
import '../services/system_status_service.dart';

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
        // Netzwerk
        _TrayIcon(
          icon: status.networkIcon,
          tooltip: status.ethernetConnected
              ? 'Ethernet'
              : status.wifiConnected
                  ? 'WLAN: ${status.wifiName ?? "Verbunden"}'
                  : 'Kein Netzwerk',
          color: status.hasNetwork ? Colors.white : Colors.white38,
        ),
        // Batterie (nur wenn vorhanden — TV-Boxen haben oft keine)
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

  const _TrayIcon({
    required this.icon,
    required this.tooltip,
    this.color = Colors.white,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _hovering ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Icon(widget.icon, color: widget.color, size: 16),
        ),
      ),
    );
  }
}
