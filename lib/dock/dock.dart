import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/cinnamon_theme.dart';
import '../models/app_info.dart';
import '../models/builtin_apps.dart';
import '../models/desktop_state.dart';
import '../windows/mdi_window.dart';
import '../windows/window_manager.dart';
import 'dart:async';
import '../services/system_status_service.dart';
import '../widgets/context_menu.dart';
import '../widgets/app_icon_widget.dart';
import 'start_menu.dart';

class Dock extends StatefulWidget {
  final VoidCallback onSettingsOpen;

  const Dock({super.key, required this.onSettingsOpen});

  @override
  State<Dock> createState() => DockState();
}

class DockState extends State<Dock> {
  bool _startMenuOpen = false;

  void closeStartMenu() {
    if (_startMenuOpen) setState(() => _startMenuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DesktopState>(
      builder: (context, state, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Start Menu
          if (_startMenuOpen)
            StartMenu(
              apps: state.allApps,
              onAppTap: (app) {
                setState(() => _startMenuOpen = false);
                state.launchApp(app);
              },
              onClose: () => setState(() => _startMenuOpen = false),
            ),
          // Dock Bar — full-width solid taskbar panel
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Start Button
                _PowerStartButton(
                  isActive: _startMenuOpen,
                  onTap: () => setState(() => _startMenuOpen = !_startMenuOpen),
                ),
                _divider(),
                // Gepinnte Tools
                ...state.pinnedToolIds.map((toolId) {
                  final tool = getBuiltinApp(toolId);
                  if (tool == null) return const SizedBox.shrink();
                  return _DockToolButton(tool: tool);
                }),
                _divider(),
                // Gepinnte Android-Apps
                ...state.pinnedApps.map((app) => _DockAppItem(app: app)),
                // Laufende Fenster
                Consumer<WindowManager>(
                  builder: (context, wm, _) {
                    if (wm.windows.isEmpty) return const SizedBox.shrink();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _divider(),
                        ...wm.windows.map((w) => _DockMDIItem(window: w, manager: wm)),
                      ],
                    );
                  },
                ),
                const Spacer(),
                // System Tray (rechts)
                _divider(),
                Consumer<SystemStatusService>(
                  builder: (context, service, _) {
                    final s = service.status;
                    return Row(mainAxisSize: MainAxisSize.min, children: [
                      // Volume
                      GestureDetector(
                        onTap: () => context.read<WindowManager>().openWindow(
                          appType: 'quick_settings', title: 'Schnelleinstellungen',
                          icon: Icons.tune, size: const Size(350, 350)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(s.volumeIcon, color: Colors.white54, size: 14),
                          const SizedBox(width: 2),
                          Text('${s.volumePercent}%', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      // WiFi
                      GestureDetector(
                        onTap: () => context.read<WindowManager>().openWindow(
                          appType: 'wifi_manager', title: 'WLAN', icon: Icons.wifi, size: const Size(400, 420)),
                        child: Icon(s.networkIcon, color: s.hasNetwork ? Colors.white : Colors.white38, size: 14),
                      ),
                      const SizedBox(width: 6),
                      // BT
                      GestureDetector(
                        onTap: () => context.read<WindowManager>().openWindow(
                          appType: 'bluetooth_manager', title: 'Bluetooth', icon: Icons.bluetooth, size: const Size(400, 400)),
                        child: const Icon(Icons.bluetooth, color: Colors.white38, size: 14),
                      ),
                      // Batterie
                      if (s.hasBattery) ...[
                        const SizedBox(width: 6),
                        Icon(s.batteryIcon, color: s.batteryColor, size: 14),
                      ],
                    ]);
                  },
                ),
                _divider(),
                // Uhr
                _DockClock(),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1, height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: C.borderLight,
    );
  }
}

// --- Start Button mit Power-Menü ---
class _PowerStartButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _PowerStartButton({required this.isActive, required this.onTap});

  @override
  State<_PowerStartButton> createState() => _PowerStartButtonState();
}

class _PowerStartButtonState extends State<_PowerStartButton> {
  bool _h = false;
  static const _channel = MethodChannel('com.dexlauncher/apps');

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) {
          ContextMenu.show(
            context: context,
            position: details.globalPosition,
            items: [
              ContextMenuItem(icon: Icons.bedtime, label: 'Standby',
                onTap: () => _channel.invokeMethod('goToSleep')),
              ContextMenuItem(icon: Icons.exit_to_app, label: 'Launcher beenden',
                onTap: () => _channel.invokeMethod('exitApp')),
            ],
          );
        },
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(

            color: widget.isActive || _h ? C.hover : Colors.transparent,
          ),
          child: Icon(widget.isActive ? Icons.close : Icons.apps_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// --- Gepinntes Tool ---
class _DockToolButton extends StatefulWidget {
  final BuiltinApp tool;
  const _DockToolButton({required this.tool});

  @override
  State<_DockToolButton> createState() => _DockToolButtonState();
}

class _DockToolButtonState extends State<_DockToolButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final wm = context.watch<WindowManager>();
    final isRunning = wm.allWindows.any((w) => w.appType == widget.tool.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Tooltip(
        message: widget.tool.name,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () => context.read<WindowManager>().openWindow(
            appType: widget.tool.id, title: widget.tool.name,
            icon: widget.tool.icon, size: widget.tool.defaultSize,
          ),
          onSecondaryTapUp: (details) {
            ContextMenu.show(
              context: context,
              position: details.globalPosition,
              items: [
                ContextMenuItem(icon: Icons.open_in_new, label: 'Oeffnen',
                  onTap: () => context.read<WindowManager>().openWindow(
                    appType: widget.tool.id, title: widget.tool.name,
                    icon: widget.tool.icon, size: widget.tool.defaultSize,
                  )),
                ContextMenuItem(icon: Icons.push_pin, label: 'Vom Dock entfernen',
                  onTap: () => context.read<DesktopState>().toggleToolPin(widget.tool.id)),
              ],
            );
          },
          child: Container(
            width: 44, height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(

              color: _h ? C.hover : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(widget.tool.icon, color: Colors.white, size: 22),
                if (isRunning)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 4, height: 2,
                      decoration: BoxDecoration(
                        color: C.accent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Gepinnte Android-App ---
class _DockAppItem extends StatefulWidget {
  final AppInfo app;
  const _DockAppItem({required this.app});

  @override
  State<_DockAppItem> createState() => _DockAppItemState();
}

class _DockAppItemState extends State<_DockAppItem> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Tooltip(
        message: widget.app.name,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () => context.read<DesktopState>().launchApp(widget.app),
          onSecondaryTapUp: (details) {
            final state = context.read<DesktopState>();
            ContextMenu.show(
              context: context,
              position: details.globalPosition,
              items: [
                ContextMenuItem(icon: Icons.open_in_new, label: 'Oeffnen',
                  onTap: () => state.launchApp(widget.app)),
                ContextMenuItem(icon: Icons.push_pin, label: 'Vom Dock entfernen',
                  onTap: () => state.togglePin(widget.app)),
                ContextMenuItem(icon: Icons.info_outline, label: 'App-Info',
                  onTap: () => state.openAppInfo(widget.app)),
              ],
            );
          },
          child: Container(
            width: 44, height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(

              color: _h ? C.hover : Colors.transparent,
            ),
            padding: const EdgeInsets.all(4),
            child: AppIconWidget(app: widget.app, size: 34),
          ),
        ),
      ),
    );
  }
}

// --- Laufendes MDI-Fenster ---
class _DockMDIItem extends StatefulWidget {
  final MDIWindow window;
  final WindowManager manager;
  const _DockMDIItem({required this.window, required this.manager});

  @override
  State<_DockMDIItem> createState() => _DockMDIItemState();
}

class _DockMDIItemState extends State<_DockMDIItem> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final min = widget.window.isMinimized;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Tooltip(
        message: widget.window.title,
        waitDuration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () => widget.manager.focusWindow(widget.window.id),
          onSecondaryTapUp: (details) {
            ContextMenu.show(
              context: context,
              position: details.globalPosition,
              items: [
                ContextMenuItem(icon: Icons.open_in_new, label: 'Anzeigen',
                  onTap: () => widget.manager.focusWindow(widget.window.id)),
                ContextMenuItem(icon: Icons.minimize, label: min ? 'Wiederherstellen' : 'Minimieren',
                  onTap: () => widget.manager.minimizeWindow(widget.window.id)),
                ContextMenuItem(icon: Icons.close, label: 'Schliessen',
                  onTap: () => widget.manager.closeWindow(widget.window.id), isDanger: true),
              ],
            );
          },
          child: Container(
            height: 44,
            constraints: const BoxConstraints(minWidth: 44, maxWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: widget.window.isFocused
                  ? Colors.white.withValues(alpha: 0.1)
                  : _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: widget.window.isFocused ? C.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(opacity: min ? 0.4 : 1.0,
                  child: Icon(widget.window.icon, color: Colors.white, size: 16)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.window.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: min ? 0.4 : 0.8),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockClock extends StatefulWidget {
  @override
  State<_DockClock> createState() => _DockClockState();
}

class _DockClockState extends State<_DockClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return GestureDetector(
      onTap: () => context.read<WindowManager>().openWindow(
        appType: 'calendar', title: 'Kalender',
        icon: Icons.calendar_month, size: const Size(300, 340)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1),
          ),
          Text(
            '${weekdays[_now.weekday - 1]} ${_now.day}.${_now.month}.${_now.year}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8, height: 1.2),
          ),
        ],
      ),
    );
  }
}
