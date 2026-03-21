import 'dart:async';
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
import '../apps/developer_options.dart';
import '../apps/global_search.dart';
import '../apps/quick_settings.dart';
import '../apps/usb_manager.dart';
import '../apps/speed_test.dart';
import '../apps/vpn_manager.dart';
import '../apps/notification_center.dart';
import '../apps/games.dart';
import '../apps/about_app.dart';
import '../widgets/screensaver.dart';
import '../widgets/splash_screen.dart';
import '../widgets/setup_wizard.dart';
import '../models/builtin_apps.dart';
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
  bool _showSplash = true;
  bool _showWizard = false;
  // Settings ist jetzt ein MDI-Fenster
  bool _appSwitcherOpen = false;
  bool _dockVisible = true;
  bool _screensaverActive = false;
  bool _autoStartDone = false;
  Timer? _screensaverTimer;
  final _appSwitcherKey = GlobalKey<AppSwitcherState2>();
  final _dockKey = GlobalKey<DockState>();

  @override
  void dispose() {
    _screensaverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onDone: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }

    return Scaffold(
      body: Consumer<DesktopState>(
        builder: (context, state, _) {
          // Show wizard after splash if first run
          if (!state.loading && !state.storage.setupComplete && !_showWizard && !_autoStartDone) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showWizard = true);
            });
          }

          if (_showWizard) {
            return SetupWizard(
              onComplete: () {
                if (mounted) setState(() => _showWizard = false);
              },
            );
          }

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

          state.updateScreenSize(MediaQuery.of(context).size);

          // Auto-Start
          if (!_autoStartDone && state.autoStartTools.isNotEmpty) {
            _autoStartDone = true;
            final wm = context.read<WindowManager>();
            for (final toolId in state.autoStartTools) {
              final tool = getBuiltinApp(toolId);
              if (tool != null) {
                wm.openWindow(appType: tool.id, title: tool.name, icon: tool.icon, size: tool.defaultSize);
              }
            }
          }

          // Screensaver Timer
          _screensaverTimer?.cancel();
          if (state.screensaverTimeout > 0 && !_screensaverActive) {
            _screensaverTimer = Timer(Duration(minutes: state.screensaverTimeout), () {
              if (mounted) setState(() => _screensaverActive = true);
            });
          }

          if (_screensaverActive) {
            return Screensaver(onDismiss: () => setState(() {
              _screensaverActive = false;
            }));
          }

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
                // Alt+F4 → Fokussiertes Fenster schließen
                LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.f4):
                    const _CloseWindowIntent(),
                // Ctrl+W → Fokussiertes Fenster schließen
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW):
                    const _CloseWindowIntent(),
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
                        } else {
                          // Escape schließt nichts mehr
                        }
                      });
                      return null;
                    },
                  ),
                  _ToggleDesktopIntent: CallbackAction<_ToggleDesktopIntent>(
                    onInvoke: (_) {
                      setState(() => _dockVisible = !_dockVisible);
                      return null;
                    },
                  ),
                  _ToggleSettingsIntent: CallbackAction<_ToggleSettingsIntent>(
                    onInvoke: (_) {
                      context.read<WindowManager>().openWindow(
                        appType: 'settings', title: 'Einstellungen',
                        icon: Icons.settings, size: const Size(420, 480),
                      );
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
                  _CloseWindowIntent: CallbackAction<_CloseWindowIntent>(
                    onInvoke: (_) {
                      final wm = context.read<WindowManager>();
                      final focused = wm.focusedWindow;
                      if (focused != null) wm.closeWindow(focused.id);
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
                        top: 32,
                        bottom: _dockVisible ? 40 : 0,
                        child: GestureDetector(
                          onTap: () {
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
                          top: 40,
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
                        bottom: _dockVisible ? 0 : -44,
                        child: Dock(
                          key: _dockKey,
                          onSettingsOpen: () {
                            context.read<WindowManager>().openWindow(
                              appType: 'settings', title: 'Einstellungen',
                              icon: Icons.settings, size: const Size(420, 480),
                            );
                          },
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
      'developer' => const DeveloperOptionsApp(),
      'search' => const GlobalSearchApp(),
      'quick_settings' => const QuickSettingsApp(),
      'usb_manager' => const UsbManagerApp(),
      'speed_test' => const SpeedTestApp(),
      'vpn_manager' => const VpnManagerApp(),
      'notifications' => const NotificationCenterApp(),
      'games' => const GamesHubApp(),
      'snake' => const SnakeGame(),
      'tetris' => const TetrisGame(),
      'minesweeper' => const MinesweeperGame(),
      'game_2048' => const Game2048(),
      'browser_game' => BrowserGameApp(
          url: window.initialData?['url'] as String? ?? 'https://dos.zone/',
          title: window.title,
        ),
      'about' => const AboutApp(),
      'settings' => const SettingsPanel(),
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
    final wm = context.read<WindowManager>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) {
        return _DesktopContextMenu(
          position: position,
          windowManager: wm,
          onDismiss: () => entry.remove(),
          onSettings: () {
            entry.remove();
            context.read<WindowManager>().openWindow(
              appType: 'settings', title: 'Einstellungen',
              icon: Icons.settings, size: const Size(420, 480),
            );
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
  final WindowManager windowManager;
  final VoidCallback onDismiss;
  final VoidCallback onSettings;
  final VoidCallback onRefresh;
  final VoidCallback onToggleIcons;
  final bool showIcons;

  const _DesktopContextMenu({
    required this.position,
    required this.windowManager,
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
                  _menuItem(Icons.terminal, 'Terminal hier oeffnen', () {
                    onDismiss();
                    windowManager.openWindow(
                      appType: 'terminal', title: 'Terminal',
                      icon: Icons.terminal, size: const Size(650, 400),
                    );
                  }),
                  _menuItem(Icons.folder, 'Dateimanager', () {
                    onDismiss();
                    windowManager.openWindow(
                      appType: 'file_manager', title: 'Dateimanager',
                      icon: Icons.folder, size: const Size(550, 380),
                    );
                  }),
                  _sep(),
                  _menuItem(Icons.image, 'Hintergrund aendern', onSettings),
                  _menuItem(
                    showIcons ? Icons.visibility_off : Icons.visibility,
                    showIcons ? 'Icons ausblenden' : 'Icons anzeigen',
                    onToggleIcons,
                  ),
                  _menuItem(Icons.refresh, 'Apps aktualisieren', onRefresh),
                  _sep(),
                  _menuItem(Icons.minimize, 'Alle Fenster minimieren', () {
                    onDismiss();
                    for (final w in windowManager.windows) {
                      windowManager.minimizeWindow(w.id);
                    }
                  }),
                  _menuItem(Icons.close, 'Alle Fenster schliessen', () {
                    onDismiss();
                    windowManager.closeAll();
                  }),
                  _sep(),
                  _menuItem(Icons.settings, 'Einstellungen', onSettings),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sep() => Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
    color: Colors.white.withValues(alpha: 0.08));

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

class _CloseWindowIntent extends Intent {
  const _CloseWindowIntent();
}
