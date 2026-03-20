import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../models/builtin_apps.dart';
import '../models/desktop_state.dart';
import '../models/window_info.dart';
import '../windows/mdi_window.dart';
import '../windows/window_manager.dart';
import '../services/system_status_service.dart';
import '../widgets/context_menu.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/system_tray.dart';
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
          // Dock Bar
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, -2),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                // Start Button (Rechtsklick = Power-Menü)
                _PowerStartButton(
                  isActive: _startMenuOpen,
                  onTap: () => setState(() => _startMenuOpen = !_startMenuOpen),
                ),
                _divider(),
                // Gepinnte Built-in Tools
                ...state.pinnedToolIds.map((toolId) {
                  final tool = getBuiltinApp(toolId);
                  if (tool == null) return const SizedBox.shrink();
                  return _DockToolButton(tool: tool);
                }),
                if (state.pinnedToolIds.isNotEmpty) _divider(),
                // Pinned Apps
                Expanded(
                  child: Row(
                    children: [
                      // Gepinnte Android-Apps (nur wenn der User welche angepinnt hat)
                      if (state.pinnedApps.isNotEmpty)
                        Flexible(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: state.pinnedApps.length,
                            itemBuilder: (context, index) {
                              final app = state.pinnedApps[index];
                              return _DockAppItem(app: app);
                            },
                          ),
                        ),
                      // Offene MDI-Fenster
                      Consumer<WindowManager>(
                        builder: (context, wm, _) {
                          if (wm.windows.isEmpty) return const SizedBox.shrink();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 1, height: 24,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              ...wm.windows.map((window) => _DockMDIItem(
                                window: window,
                                manager: wm,
                              )),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _divider(),
                // Settings
                _DockButton(
                  icon: Icons.settings,
                  onTap: widget.onSettingsOpen,
                  tooltip: 'Einstellungen',
                ),
                const SizedBox(width: 2),
                // System Tray
                Consumer<SystemStatusService>(
                  builder: (context, service, _) =>
                      SystemTray(status: service.status),
                ),
                _divider(),
                // Clock
                const _Clock(),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _DockButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final String? tooltip;

  const _DockButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.tooltip,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isActive || _hovering
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: child,
      );
    }
    return child;
  }
}

class _DockAppItem extends StatefulWidget {
  final AppInfo app;

  const _DockAppItem({required this.app});

  @override
  State<_DockAppItem> createState() => _DockAppItemState();
}

class _DockAppItemState extends State<_DockAppItem> {
  bool _hovering = false;

  void _showContextMenu(Offset position) {
    final state = context.read<DesktopState>();
    ContextMenu.show(
      context: context,
      position: position,
      items: [
        ContextMenuItem(
          icon: Icons.open_in_new,
          label: 'Oeffnen',
          onTap: () => state.launchApp(widget.app),
        ),
        ContextMenuItem(
          icon: Icons.push_pin,
          label: 'Vom Dock entfernen',
          onTap: () => state.togglePin(widget.app),
        ),
        ContextMenuItem(
          icon: Icons.info_outline,
          label: 'App-Info',
          onTap: () => state.openAppInfo(widget.app),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.app.name,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () => context.read<DesktopState>().launchApp(widget.app),
          onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
          onLongPress: () {
            final box = context.findRenderObject() as RenderBox;
            _showContextMenu(box.localToGlobal(const Offset(20, -50)));
          },
          child: AnimatedScale(
            scale: _hovering ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _hovering ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              ),
              padding: const EdgeInsets.all(6),
              child: AppIconWidget(app: widget.app, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockRunningItem extends StatefulWidget {
  final AppInfo app;
  final WindowInfo window;

  const _DockRunningItem({required this.app, required this.window});

  @override
  State<_DockRunningItem> createState() => _DockRunningItemState();
}

class _DockRunningItemState extends State<_DockRunningItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isMinimized = widget.window.isMinimized;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: '${widget.app.name} (Fenster)',
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () {
            final state = context.read<DesktopState>();
            if (isMinimized) {
              state.toggleMinimizeWindow(widget.app.packageName);
              state.launchAppFreeform(widget.app);
            } else {
              state.launchAppFreeform(widget.app);
            }
          },
          onSecondaryTapUp: (details) {
            final state = context.read<DesktopState>();
            ContextMenu.show(
              context: context,
              position: details.globalPosition,
              items: [
                ContextMenuItem(
                  icon: Icons.open_in_new,
                  label: 'Fenster anzeigen',
                  onTap: () => state.launchAppFreeform(widget.app),
                ),
                ContextMenuItem(
                  icon: Icons.fullscreen,
                  label: 'Vollbild',
                  onTap: () {
                    state.closeWindow(widget.app.packageName);
                    state.launchAppFullscreen(widget.app);
                  },
                ),
                ContextMenuItem(
                  icon: Icons.close,
                  label: 'Fenster schliessen',
                  onTap: () => state.closeWindow(widget.app.packageName),
                  isDanger: true,
                ),
              ],
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _hovering ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            ),
            padding: const EdgeInsets.all(6),
            child: Stack(
              children: [
                Opacity(
                  opacity: isMinimized ? 0.5 : 1.0,
                  child: AppIconWidget(app: widget.app, size: 32),
                ),
                // Running-Indicator: kleiner Punkt unten
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isMinimized
                            ? Colors.white38
                            : Colors.blueAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
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

class _PowerStartButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _PowerStartButton({required this.isActive, required this.onTap});

  @override
  State<_PowerStartButton> createState() => _PowerStartButtonState();
}

class _PowerStartButtonState extends State<_PowerStartButton> {
  bool _hovering = false;
  static const _channel = MethodChannel('com.dexlauncher/apps');

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) {
          ContextMenu.show(
            context: context,
            position: details.globalPosition,
            items: [
              ContextMenuItem(
                icon: Icons.bedtime,
                label: 'Standby',
                onTap: () => _channel.invokeMethod('goToSleep'),
              ),
              ContextMenuItem(
                icon: Icons.exit_to_app,
                label: 'Launcher beenden',
                onTap: () => _channel.invokeMethod('exitApp'),
              ),
            ],
          );
        },
        child: Tooltip(
          message: 'Startmenue (Rechtsklick: Power)',
          waitDuration: const Duration(milliseconds: 500),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.isActive || _hovering
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.isActive ? Icons.close : Icons.apps_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockToolButton extends StatefulWidget {
  final BuiltinApp tool;
  const _DockToolButton({required this.tool});

  @override
  State<_DockToolButton> createState() => _DockToolButtonState();
}

class _DockToolButtonState extends State<_DockToolButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.tool.name,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () => context.read<WindowManager>().openWindow(
            appType: widget.tool.id,
            title: widget.tool.name,
            icon: widget.tool.icon,
            size: widget.tool.defaultSize,
          ),
          onSecondaryTapUp: (details) {
            ContextMenu.show(
              context: context,
              position: details.globalPosition,
              items: [
                ContextMenuItem(
                  icon: Icons.open_in_new,
                  label: 'Oeffnen',
                  onTap: () => context.read<WindowManager>().openWindow(
                    appType: widget.tool.id,
                    title: widget.tool.name,
                    icon: widget.tool.icon,
                    size: widget.tool.defaultSize,
                  ),
                ),
                ContextMenuItem(
                  icon: Icons.push_pin,
                  label: 'Vom Dock entfernen',
                  onTap: () => context.read<DesktopState>().toggleToolPin(widget.tool.id),
                ),
              ],
            );
          },
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _hovering ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            ),
            child: Icon(widget.tool.icon, color: widget.tool.iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}

class _DockMDIItem extends StatefulWidget {
  final MDIWindow window;
  final WindowManager manager;

  const _DockMDIItem({required this.window, required this.manager});

  @override
  State<_DockMDIItem> createState() => _DockMDIItemState();
}

class _DockMDIItemState extends State<_DockMDIItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isMinimized = widget.window.isMinimized;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
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
                ContextMenuItem(
                  icon: Icons.open_in_new,
                  label: 'Fenster anzeigen',
                  onTap: () => widget.manager.focusWindow(widget.window.id),
                ),
                ContextMenuItem(
                  icon: Icons.minimize,
                  label: isMinimized ? 'Wiederherstellen' : 'Minimieren',
                  onTap: () => widget.manager.minimizeWindow(widget.window.id),
                ),
                ContextMenuItem(
                  icon: Icons.close,
                  label: 'Schliessen',
                  onTap: () => widget.manager.closeWindow(widget.window.id),
                  isDanger: true,
                ),
              ],
            );
          },
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _hovering ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isMinimized ? 0.4 : 1.0,
                  child: Icon(widget.window.icon, color: Colors.white, size: 22),
                ),
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6, height: 3,
                    decoration: BoxDecoration(
                      color: widget.window.isFocused ? Colors.blueAccent : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
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

class _Clock extends StatelessWidget {
  const _Clock();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final date = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(date, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}
