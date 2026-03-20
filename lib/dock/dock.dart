import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../models/builtin_apps.dart';
import '../models/desktop_state.dart';
import '../windows/mdi_window.dart';
import '../windows/window_manager.dart';
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
          // Dock Bar — passt sich der Größe an
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.15),
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
          width: 40, height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.isActive || _h ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          ),
          child: Icon(widget.isActive ? Icons.close : Icons.apps_rounded, color: Colors.white, size: 20),
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
            width: 40, height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _h ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            ),
            child: Icon(widget.tool.icon, color: Colors.white, size: 20),
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
            width: 40, height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _h ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            ),
            padding: const EdgeInsets.all(5),
            child: AppIconWidget(app: widget.app, size: 30),
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
            width: 40, height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _h ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: min ? 0.4 : 1.0,
                  child: Icon(widget.window.icon, color: Colors.white, size: 20)),
                Positioned(bottom: 3, child: Container(
                  width: 6, height: 2,
                  decoration: BoxDecoration(
                    color: widget.window.isFocused ? Colors.blueAccent : Colors.white38,
                    borderRadius: BorderRadius.circular(1),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
