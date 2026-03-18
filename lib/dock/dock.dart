import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../models/desktop_state.dart';
import '../widgets/context_menu.dart';
import '../widgets/app_icon_widget.dart';
import 'start_menu.dart';

class Dock extends StatefulWidget {
  final VoidCallback onSettingsOpen;

  const Dock({super.key, required this.onSettingsOpen});

  @override
  State<Dock> createState() => _DockState();
}

class _DockState extends State<Dock> {
  bool _startMenuOpen = false;

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
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                // Start Button
                _DockButton(
                  icon: _startMenuOpen ? Icons.close : Icons.apps_rounded,
                  isActive: _startMenuOpen,
                  onTap: () => setState(() => _startMenuOpen = !_startMenuOpen),
                  tooltip: 'Startmenue',
                ),
                _divider(),
                // Pinned Apps
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.pinnedApps.length,
                    itemBuilder: (context, index) {
                      final app = state.pinnedApps[index];
                      return _DockAppItem(app: app);
                    },
                  ),
                ),
                _divider(),
                // System Tray
                _DockButton(
                  icon: Icons.settings,
                  onTap: widget.onSettingsOpen,
                  tooltip: 'Einstellungen',
                ),
                const SizedBox(width: 4),
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
            child: AppIconWidget(app: widget.app, size: 32),
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
