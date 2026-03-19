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

  @override
  void initState() {
    super.initState();
    _position = widget.window.position;
    _size = widget.window.size;
  }

  @override
  void didUpdateWidget(covariant WindowChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    _position = widget.window.position;
    _size = widget.window.size;
  }

  void _onDragTitle(Offset delta) {
    setState(() {
      _position = Offset(
        (_position.dx + delta.dx).clamp(0, double.infinity),
        (_position.dy + delta.dy).clamp(0, double.infinity),
      );
    });
    widget.manager.updatePosition(widget.window.id, _position);
  }

  void _onResize(Offset delta, {bool left = false, bool top = false, bool right = false, bool bottom = false}) {
    setState(() {
      var newLeft = _position.dx;
      var newTop = _position.dy;
      var newWidth = _size.width;
      var newHeight = _size.height;

      if (right) newWidth += delta.dx;
      if (bottom) newHeight += delta.dy;
      if (left) {
        newLeft += delta.dx;
        newWidth -= delta.dx;
      }
      if (top) {
        newTop += delta.dy;
        newHeight -= delta.dy;
      }

      // Min-Size enforcing
      final minW = widget.window.minSize.width;
      final minH = widget.window.minSize.height;

      if (newWidth < minW) {
        if (left) newLeft -= (minW - newWidth);
        newWidth = minW;
      }
      if (newHeight < minH) {
        if (top) newTop -= (minH - newHeight);
        newHeight = minH;
      }

      _position = Offset(newLeft.clamp(0, double.infinity), newTop.clamp(0, double.infinity));
      _size = Size(newWidth, newHeight);
    });
    widget.manager.updatePosition(widget.window.id, _position);
    widget.manager.updateSize(widget.window.id, _size);
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.window.isFocused;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () => widget.manager.focusWindow(widget.window.id),
        child: SizedBox(
          width: _size.width,
          height: _size.height,
          child: Stack(
            children: [
              // Fenster-Inhalt
              Positioned.fill(
                child: Container(
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
                        _TitleBar(
                          title: widget.window.title,
                          icon: widget.window.icon,
                          isFocused: isFocused,
                          onDragUpdate: _onDragTitle,
                          onMinimize: () => widget.manager.minimizeWindow(widget.window.id),
                          onClose: () => widget.manager.closeWindow(widget.window.id),
                        ),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ),
              ),

              // Resize Handles (8 Bereiche: 4 Ecken + 4 Kanten)
              // Rechts
              _ResizeHandle(
                alignment: Alignment.centerRight,
                cursor: SystemMouseCursors.resizeLeftRight,
                width: 6,
                onDrag: (d) => _onResize(d, right: true),
              ),
              // Unten
              _ResizeHandle(
                alignment: Alignment.bottomCenter,
                cursor: SystemMouseCursors.resizeUpDown,
                height: 6,
                onDrag: (d) => _onResize(d, bottom: true),
              ),
              // Links
              _ResizeHandle(
                alignment: Alignment.centerLeft,
                cursor: SystemMouseCursors.resizeLeftRight,
                width: 6,
                onDrag: (d) => _onResize(d, left: true),
              ),
              // Oben (nur unterhalb Titelleiste nutzbar, daher schmaler)
              // Unten-Rechts (Ecke)
              _ResizeHandle(
                alignment: Alignment.bottomRight,
                cursor: SystemMouseCursors.resizeDownRight,
                width: 12,
                height: 12,
                onDrag: (d) => _onResize(d, right: true, bottom: true),
              ),
              // Unten-Links
              _ResizeHandle(
                alignment: Alignment.bottomLeft,
                cursor: SystemMouseCursors.resizeDownLeft,
                width: 12,
                height: 12,
                onDrag: (d) => _onResize(d, left: true, bottom: true),
              ),
              // Oben-Rechts
              _ResizeHandle(
                alignment: Alignment.topRight,
                cursor: SystemMouseCursors.resizeUpRight,
                width: 12,
                height: 12,
                onDrag: (d) => _onResize(d, right: true, top: true),
              ),
              // Oben-Links
              _ResizeHandle(
                alignment: Alignment.topLeft,
                cursor: SystemMouseCursors.resizeUpLeft,
                width: 12,
                height: 12,
                onDrag: (d) => _onResize(d, left: true, top: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final Alignment alignment;
  final MouseCursor cursor;
  final double? width;
  final double? height;
  final void Function(Offset delta) onDrag;

  const _ResizeHandle({
    required this.alignment,
    required this.cursor,
    this.width,
    this.height,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanUpdate: (details) => onDrag(details.delta),
          child: Container(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            color: Colors.transparent,
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
            _WindowButton(icon: Icons.minimize, onTap: onMinimize),
            _WindowButton(icon: Icons.close, onTap: onClose, isClose: true),
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

  const _WindowButton({required this.icon, required this.onTap, this.isClose = false});

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
