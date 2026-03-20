import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/cinnamon_theme.dart';
import '../services/system_status_service.dart';
import '../windows/window_manager.dart';

/// Schmale obere Leiste wie in Linux/macOS
class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: C.panelBg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Desktop Switcher
          Consumer<WindowManager>(
            builder: (context, wm, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(WindowManager.maxDesktops, (i) {
                final active = wm.currentDesktop == i;
                final hasWin = wm.allWindows.any((w) => w.desktop == i);
                return GestureDetector(
                  onTap: () => wm.switchDesktop(i),
                  child: Container(
                    width: 22, height: 18,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? Colors.white.withValues(alpha: 0.4)
                            : hasWin
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white38,
                        fontSize: 9, fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 8),

          // Fokussiertes Fenster Titel
          Consumer<WindowManager>(
            builder: (context, wm, _) {
              final focused = wm.focusedWindow;
              if (focused == null) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(focused.icon, color: Colors.white54, size: 12),
                  const SizedBox(width: 4),
                  Text('${focused.title}${wm.windows.length > 1 ? ' (+${wm.windows.length - 1})' : ''}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),

          const Spacer(),

          // System Tray
          Consumer<SystemStatusService>(
            builder: (context, service, _) {
              final s = service.status;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // WiFi
                  _TrayItem(
                    icon: s.networkIcon,
                    label: s.wifiConnected ? (s.wifiName ?? 'WLAN') : s.ethernetConnected ? 'LAN' : '',
                    color: s.hasNetwork ? Colors.white : Colors.white38,
                    onTap: () => context.read<WindowManager>().openWindow(
                      appType: 'wifi_manager', title: 'WLAN', icon: Icons.wifi, size: const Size(400, 420),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Volume (klickbar → Quick Settings)
                  GestureDetector(
                    onTap: () => context.read<WindowManager>().openWindow(
                      appType: 'quick_settings', title: 'Schnelleinstellungen',
                      icon: Icons.tune, size: const Size(350, 350),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(s.volumeIcon, color: Colors.white54, size: 13),
                      const SizedBox(width: 2),
                      Text('${s.volumePercent}%',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Bluetooth
                  GestureDetector(
                    onTap: () => context.read<WindowManager>().openWindow(
                      appType: 'bluetooth_manager', title: 'Bluetooth', icon: Icons.bluetooth, size: const Size(400, 400),
                    ),
                    child: const Icon(Icons.bluetooth, color: Colors.white38, size: 13),
                  ),
                  // Batterie
                  if (s.hasBattery) ...[
                    const SizedBox(width: 8),
                    Icon(s.batteryIcon, color: s.batteryColor, size: 13),
                    const SizedBox(width: 2),
                    Text('${s.batteryLevel}%',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                  ],
                ],
              );
            },
          ),

          const SizedBox(width: 12),

          // Uhr (klickbar → Benachrichtigungen)
          GestureDetector(
            onTap: () => context.read<WindowManager>().openWindow(
              appType: 'notifications', title: 'Benachrichtigungen',
              icon: Icons.notifications, size: const Size(420, 400),
            ),
            child: Builder(
              builder: (context) {
                final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
                final months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500, height: 1),
                    ),
                    Text(
                      '${weekdays[_now.weekday - 1]} ${_now.day}. ${months[_now.month - 1]}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8, height: 1.2),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrayItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _TrayItem({required this.icon, required this.label, this.color = Colors.white, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 3),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
