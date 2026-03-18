import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../models/desktop_state.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/context_menu.dart';

class DesktopIcons extends StatelessWidget {
  const DesktopIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DesktopState>(
      builder: (context, state, _) {
        if (!state.showDesktopIcons) return const SizedBox.shrink();

        final apps = state.desktopApps;
        final iconSize = state.iconSize;
        final itemWidth = iconSize + 32;
        final itemHeight = iconSize + 40;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Berechne Grid-Positionen spaltenweise von oben-links
            final maxRows = (constraints.maxHeight / itemHeight).floor();

            return Stack(
              children: List.generate(apps.length, (index) {
                final app = apps[index];
                final savedPos = state.desktopPositions[app.packageName];

                // Default-Position: spaltenweise von links oben
                final col = index ~/ maxRows;
                final row = index % maxRows;
                final defaultX = 16.0 + col * itemWidth;
                final defaultY = 16.0 + row * itemHeight;

                final position = savedPos ?? Offset(defaultX, defaultY);

                return _DraggableDesktopIcon(
                  app: app,
                  position: position,
                  iconSize: iconSize,
                  onPositionChanged: (pos) {
                    state.updateDesktopPosition(app.packageName, pos);
                  },
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _DraggableDesktopIcon extends StatefulWidget {
  final AppInfo app;
  final Offset position;
  final double iconSize;
  final ValueChanged<Offset> onPositionChanged;

  const _DraggableDesktopIcon({
    required this.app,
    required this.position,
    required this.iconSize,
    required this.onPositionChanged,
  });

  @override
  State<_DraggableDesktopIcon> createState() => _DraggableDesktopIconState();
}

class _DraggableDesktopIconState extends State<_DraggableDesktopIcon> {
  late Offset _position;
  bool _selected = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
  }

  @override
  void didUpdateWidget(covariant _DraggableDesktopIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) {
      _position = widget.position;
    }
  }

  void _showContextMenu(Offset globalPosition) {
    final state = context.read<DesktopState>();
    ContextMenu.show(
      context: context,
      position: globalPosition,
      items: [
        ContextMenuItem(
          icon: Icons.open_in_new,
          label: 'Oeffnen',
          onTap: () => state.launchApp(widget.app),
        ),
        ContextMenuItem(
          icon: widget.app.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          label: widget.app.isPinned ? 'Von Dock entfernen' : 'An Dock anheften',
          onTap: () => state.togglePin(widget.app),
        ),
        ContextMenuItem(
          icon: Icons.info_outline,
          label: 'App-Info',
          onTap: () => state.openAppInfo(widget.app),
        ),
        ContextMenuItem(
          icon: Icons.delete_outline,
          label: 'Vom Desktop entfernen',
          onTap: () => state.toggleDesktop(widget.app),
        ),
        if (!widget.app.isSystemApp)
          ContextMenuItem(
            icon: Icons.delete_forever,
            label: 'Deinstallieren',
            onTap: () => state.uninstallApp(widget.app),
            isDanger: true,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selected = !_selected),
        onDoubleTap: () => context.read<DesktopState>().launchApp(widget.app),
        onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox;
          final pos = box.localToGlobal(Offset(widget.iconSize / 2, widget.iconSize / 2));
          _showContextMenu(pos);
        },
        onPanStart: (_) => _dragging = true,
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0, double.infinity),
              (_position.dy + details.delta.dy).clamp(0, double.infinity),
            );
          });
        },
        onPanEnd: (_) {
          _dragging = false;
          widget.onPositionChanged(_position);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.iconSize + 32,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _selected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconWidget(app: widget.app, size: widget.iconSize),
              const SizedBox(height: 4),
              Text(
                widget.app.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 6),
                    Shadow(color: Colors.black, blurRadius: 3),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
