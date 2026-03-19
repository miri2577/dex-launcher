import 'package:flutter/material.dart';
import 'mdi_window.dart';
import 'window_manager.dart';

/// Fenster-Rahmen mit Titelleiste, Drag, Resize-Handles
class WindowChrome extends StatefulWidget {
  final MDIWindow window;
  final WindowManager manager;
  final Widget child;

  const WindowChrome({
    super.key,
    required this.window,
    required this.manager,
    required this.child,
  });

  @override
  State<WindowChrome> createState() => _WindowChromeState();
}

class _WindowChromeState extends State<WindowChrome> {
  late Offset _position;
  late Size _size;
  final bool _resizing = false;

  @override
  void initState() {
    super.initState();
    _position = widget.window.position;
    _size = widget.window.size;
  }

  @override
  void didUpdateWidget(covariant WindowChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_resizing) {
      _position = widget.window.position;
      _size = widget.window.size;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.window.isFocused;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () => widget.manager.focusWindow(widget.window.id),
        child: Container(
          width: _size.width,
          height: _size.height,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused
                  ? Colors.blueAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: isFocused ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isFocused ? 0.6 : 0.3),
                blurRadius: isFocused ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Column(
              children: [
                // Titelleiste
                _TitleBar(
                  title: widget.window.title,
                  icon: widget.window.icon,
                  isFocused: isFocused,
                  onDragUpdate: (delta) {
                    setState(() {
                      _position = Offset(
                        (_position.dx + delta.dx).clamp(0, double.infinity),
                        (_position.dy + delta.dy).clamp(0, double.infinity),
                      );
                    });
                    widget.manager.updatePosition(widget.window.id, _position);
                  },
                  onMinimize: () => widget.manager.minimizeWindow(widget.window.id),
                  onClose: () => widget.manager.closeWindow(widget.window.id),
                ),
                // Inhalt
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isFocused;
  final void Function(Offset delta) onDragUpdate;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const _TitleBar({
    required this.title,
    required this.icon,
    required this.isFocused,
    required this.onDragUpdate,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onDragUpdate(details.delta),
      child: Container(
        height: 32,
        color: isFocused ? const Color(0xFF2D2D3D) : const Color(0xFF252525),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isFocused ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _WindowButton(
              icon: Icons.minimize,
              onTap: onMinimize,
            ),
            _WindowButton(
              icon: Icons.close,
              onTap: onClose,
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _hovering
                ? (widget.isClose ? Colors.red.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1))
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            color: _hovering ? Colors.white : Colors.white38,
            size: 14,
          ),
        ),
      ),
    );
  }
}
