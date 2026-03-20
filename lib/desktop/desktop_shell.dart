import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/desktop_state.dart';
import '../windows/mdi_window.dart';
import '../windows/window_manager.dart';
import '../windows/window_chrome.dart';
import '../apps/file_manager.dart';
import '../apps/web_browser.dart';
import '../apps/calculator.dart';
import '../apps/wifi_manager.dart';
import '../apps/bluetooth_manager.dart';
import '../apps/system_monitor.dart';
import '../apps/terminal.dart';
import '../apps/text_editor.dart';
import '../apps/image_viewer.dart';
import '../apps/video_player.dart';
import '../apps/clipboard_manager.dart';
import '../apps/task_manager.dart';
import '../apps/network_scanner.dart';
import '../apps/music_player.dart';
import '../apps/weather_widget.dart';
import '../dock/dock.dart';
import '../cursor/cursor_overlay.dart';
import '../widgets/settings_panel.dart';
import '../widgets/app_switcher.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/top_bar.dart';
import 'desktop_background.dart';
import 'desktop_icons.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  bool _settingsOpen = false;
  bool _appSwitcherOpen = false;
  bool _dockVisible = true;
  final _appSwitcherKey = GlobalKey<AppSwitcherState2>();
  final _dockKey = GlobalKey<DockState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DesktopState>(
        builder: (context, state, _) {
          if (state.loading) {
            return Container(
              color: const Color(0xFF0D1B2A),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.desktop_windows, color: Colors.white38, size: 64),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: Colors.white38),
                    SizedBox(height: 16),
                    Text('Desktop wird geladen...',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
              ),
            );
          }

          // Bildschirmgröße für Fenster-Positionierung
          state.updateScreenSize(MediaQuery.of(context).size);

          return CursorOverlay(
            child: Shortcuts(
              shortcuts: {
                // Alt+Tab App Switcher
                LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.tab):
                    const _AppSwitcherIntent(),
                // Escape schließt offene Panels
                LogicalKeySet(LogicalKeyboardKey.escape):
                    const _DismissIntent(),
                // Super+D / Meta+D → Desktop zeigen (Dock ein/aus)
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyD):
                    const _ToggleDesktopIntent(),
                // Super+S → Einstellungen
                LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
                    const _ToggleSettingsIntent(),
                // F5 → Apps aktualisieren
                LogicalKeySet(LogicalKeyboardKey.f5):
                    const _RefreshIntent(),
                // Ctrl+1/2/3 → Desktop wechseln
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1):
                    const _SwitchDesktopIntent(0),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2):
                    const _SwitchDesktopIntent(1),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3):
                    const _SwitchDesktopIntent(2),
              },
              child: Actions(
                actions: {
                  _AppSwitcherIntent: CallbackAction<_AppSwitcherIntent>(
                    onInvoke: (_) {
                      if (_appSwitcherOpen) {
                        _appSwitcherKey.currentState?.selectNext();
                      } else {
                        setState(() => _appSwitcherOpen = true);
                      }
                      return null;
                    },
                  ),
                  _DismissIntent: CallbackAction<_DismissIntent>(
                    onInvoke: (_) {
                      setState(() {
                        if (_appSwitcherOpen) {
                          _appSwitcherKey.currentState?.confirmSelection();
                          _appSwitcherOpen = false;
                        } else if (_settingsOpen) {
                          _settingsOpen = false;
                        }
                      });
                      return null;
                    },
                  ),
                  _ToggleDesktopIntent: CallbackAction<_ToggleDesktopIntent>(
                    onInvoke: (_) {
                      setState(() {
                        _dockVisible = !_dockVisible;
                        _settingsOpen = false;
                      });
                      return null;
                    },
                  ),
                  _ToggleSettingsIntent: CallbackAction<_ToggleSettingsIntent>(
                    onInvoke: (_) {
                      setState(() => _settingsOpen = !_settingsOpen);
                      return null;
                    },
                  ),
                  _RefreshIntent: CallbackAction<_RefreshIntent>(
                    onInvoke: (_) {
                      state.loadApps();
                      return null;
                    },
                  ),
                  _SwitchDesktopIntent: CallbackAction<_SwitchDesktopIntent>(
                    onInvoke: (intent) {
                      context.read<WindowManager>().switchDesktop(intent.desktop);
                      return null;
                    },
                  ),
                },
                child: Focus(
                  autofocus: true,
                  child: Stack(
                    children: [
                      // Background
                      DesktopBackground(
                        wallpaperIndex: state.wallpaperIndex,
                        customImagePath: state.customWallpaperPath,
                      ),

                      // Top Bar
                      const Positioned(
                        left: 0, right: 0, top: 0,
                        child: TopBar(),
                      ),

                      // Desktop Icons (zwischen Top-Bar und Dock)
                      Positioned.fill(
                        top: 28,
                        bottom: _dockVisible ? 56 : 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _settingsOpen = false);
                            _dockKey.currentState?.closeStartMenu();
                          },
                          onSecondaryTapUp: (details) {
                            _showDesktopContextMenu(details.globalPosition, state);
                          },
                          behavior: HitTestBehavior.translucent,
                          child: const DesktopIcons(),
                        ),
                      ),

                      // Desktop-Widgets (optional, oben rechts unter Top-Bar)
                      if (state.activeWidgets.isNotEmpty)
                        Positioned(
                          right: 16,
                          top: 36,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (state.isWidgetActive('clock'))
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: ClockWidget(),
                                ),
                              if (state.isWidgetActive('calendar'))
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: CalendarWidget(),
                                ),
                              if (state.isWidgetActive('system'))
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: SystemWidget(),
                                ),
                            ],
                          ),
                        ),

                      // In-App Fenster (MDI)
                      Consumer<WindowManager>(
                        builder: (context, wm, _) {
                          return Stack(
                            children: wm.sortedWindows
                                .where((w) => !w.isMinimized)
                                .map((window) => WindowChrome(
                                      key: ValueKey(window.id),
                                      window: window,
                                      manager: wm,
                                      child: _buildWindowContent(window, wm),
                                    ))
                                .toList(),
                          );
                        },
                      ),

                      // Dock
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        left: 0,
                        right: 0,
                        bottom: _dockVisible ? 0 : -60,
                        child: Dock(
                          key: _dockKey,
                          onSettingsOpen: () =>
                              setState(() => _settingsOpen = !_settingsOpen),
                        ),
                      ),

                      // Settings Panel
                      if (_settingsOpen)
                        Positioned(
                          right: 0,
                          top: 28,
                          bottom: 56,
                          child: SettingsPanel(
                            onClose: () => setState(() => _settingsOpen = false),
                          ),
                        ),

                      // App Switcher (Alt+Tab)
                      if (_appSwitcherOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              _appSwitcherKey.currentState?.confirmSelection();
                              setState(() => _appSwitcherOpen = false);
                            },
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.4),
                              child: AppSwitcher(
                                key: _appSwitcherKey,
                                apps: state.recentApps.isNotEmpty
                                    ? state.recentApps
                                    : state.pinnedApps,
                                onSelect: (app) {
                                  setState(() => _appSwitcherOpen = false);
                                  state.launchApp(app);
                                },
                                onDismiss: () =>
                                    setState(() => _appSwitcherOpen = false),
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
        },
      ),
    );
  }

  Widget _buildWindowContent(MDIWindow window, WindowManager wm) {
    return switch (window.appType) {
      'file_manager' => FileManagerApp(initialPath: window.initialData?['path'] as String?),
      'browser' => WebBrowserApp(
          initialUrl: window.initialData?['url'] as String?,
          onTitleChanged: (title) => wm.updateWindowTitle(window.id, title),
        ),
      'calculator' => const CalculatorApp(),
      'wifi_manager' => const WifiManagerApp(),
      'bluetooth_manager' => const BluetoothManagerApp(),
      'system_monitor' => const SystemMonitorApp(),
      'terminal' => const TerminalApp(),
      'text_editor' => TextEditorApp(
          filePath: window.initialData?['path'] as String?,
          onTitleChanged: (title) => wm.updateWindowTitle(window.id, title),
        ),
      'image_viewer' => ImageViewerApp(
          initialPath: window.initialData?['path'] as String?,
          onTitleChanged: (title) => wm.updateWindowTitle(window.id, title),
        ),
      'clipboard' => const ClipboardManagerApp(),
      'task_manager' => const TaskManagerApp(),
      'network_scanner' => const NetworkScannerApp(),
      'music_player' => const MusicPlayerApp(),
      'weather' => const WeatherApp(),
      'video_player' => VideoPlayerApp(
          onTitleChanged: (title) => wm.updateWindowTitle(window.id, title),
        ),
      _ => Center(
          child: Text(window.appType, style: const TextStyle(color: Colors.white)),
        ),
    };
  }

  void _showDesktopContextMenu(Offset position, DesktopState state) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) {
        return _DesktopContextMenu(
          position: position,
          onDismiss: () => entry.remove(),
          onSettings: () {
            entry.remove();
            setState(() => _settingsOpen = true);
          },
          onRefresh: () {
            entry.remove();
            state.loadApps();
          },
          onToggleIcons: () {
            entry.remove();
            state.setShowDesktopIcons(!state.showDesktopIcons);
          },
          showIcons: state.showDesktopIcons,
        );
      },
    );
    overlay.insert(entry);
  }
}

class _DesktopContextMenu extends StatelessWidget {
  final Offset position;
  final VoidCallback onDismiss;
  final VoidCallback onSettings;
  final VoidCallback onRefresh;
  final VoidCallback onToggleIcons;
  final bool showIcons;

  const _DesktopContextMenu({
    required this.position,
    required this.onDismiss,
    required this.onSettings,
    required this.onRefresh,
    required this.onToggleIcons,
    required this.showIcons,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const menuWidth = 220.0;
    const menuHeight = 200.0;

    var dx = position.dx;
    var dy = position.dy;
    if (dx + menuWidth > screenSize.width) dx = screenSize.width - menuWidth - 8;
    if (dy + menuHeight > screenSize.height) dy = screenSize.height - menuHeight - 8;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            onSecondaryTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: dx,
          top: dy,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            builder: (context, value, child) => Transform.scale(
              scale: 0.9 + 0.1 * value,
              alignment: Alignment.topLeft,
              child: Opacity(opacity: value, child: child),
            ),
            child: Container(
              width: menuWidth,
              decoration: BoxDecoration(
                color: const Color(0xF0282828),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuItem(Icons.refresh, 'Apps aktualisieren', onRefresh),
                  _menuItem(
                    showIcons ? Icons.visibility_off : Icons.visibility,
                    showIcons ? 'Icons ausblenden' : 'Icons anzeigen',
                    onToggleIcons,
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  _menuItem(Icons.settings, 'Einstellungen', onSettings),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return _HoverMenuItem(icon: icon, label: label, onTap: onTap);
  }
}

class _HoverMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HoverMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  State<_HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<_HoverMenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _hovering ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppSwitcherIntent extends Intent {
  const _AppSwitcherIntent();
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}

class _ToggleDesktopIntent extends Intent {
  const _ToggleDesktopIntent();
}

class _ToggleSettingsIntent extends Intent {
  const _ToggleSettingsIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _SwitchDesktopIntent extends Intent {
  final int desktop;
  const _SwitchDesktopIntent(this.desktop);
}
