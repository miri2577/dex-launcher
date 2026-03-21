import '../theme/cinnamon_theme.dart';
import 'package:flutter/material.dart';
import 'mdi_window.dart';
import 'window_manager.dart';

class WindowChrome extends StatefulWidget {
  final MDIWindow window;
  final WindowManager manager;
  final Widget child;

  const WindowChrome({super.key, required this.window, required this.manager, required this.child});

  @override
  State<WindowChrome> createState() => _WindowChromeState();
}

class _WindowChromeState extends State<WindowChrome> {
  late Offset _position;
  late Size _size;
  bool _maximized = false;
  Offset? _preMaxPos;
  Size? _preMaxSize;

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
    if (_maximized) _restore(); // Aus Maximize rauslösen beim Drag
    setState(() {
      _position = Offset(
        (_position.dx + delta.dx).clamp(0, double.infinity),
        (_position.dy + delta.dy).clamp(0, double.infinity),
      );
    });
    widget.manager.updatePosition(widget.window.id, _position);
  }

  void _onDragEnd() {
    final screen = MediaQuery.of(context).size;
    const snap = 15.0;
    const topBar = 0.0;
    const dockH = 40.0;

    if (_position.dx < snap) {
      setState(() { _position = Offset(0, topBar); _size = Size(screen.width / 2, screen.height - topBar - dockH); });
    } else if (_position.dx + _size.width > screen.width - snap) {
      setState(() { _position = Offset(screen.width / 2, topBar); _size = Size(screen.width / 2, screen.height - topBar - dockH); });
    } else if (_position.dy < snap + topBar) {
      _maximize();
      return;
    }
    widget.manager.updatePosition(widget.window.id, _position);
    widget.manager.updateSize(widget.window.id, _size);
  }

  void _maximize() {
    final screen = MediaQuery.of(context).size;
    const topBar = 0.0;
    const dockH = 40.0;
    setState(() {
      _preMaxPos = _position;
      _preMaxSize = _size;
      _position = Offset(0, topBar);
      _size = Size(screen.width, screen.height - topBar - dockH);
      _maximized = true;
    });
    widget.manager.updatePosition(widget.window.id, _position);
    widget.manager.updateSize(widget.window.id, _size);
  }

  void _restore() {
    if (_preMaxPos != null && _preMaxSize != null) {
      setState(() {
        _position = _preMaxPos!;
        _size = _preMaxSize!;
        _maximized = false;
      });
      widget.manager.updatePosition(widget.window.id, _position);
      widget.manager.updateSize(widget.window.id, _size);
    }
  }

  void _toggleMaximize() {
    if (_maximized) _restore(); else _maximize();
  }

  void _onResize(Offset delta, {bool left = false, bool top = false, bool right = false, bool bottom = false}) {
    if (_maximized) return;
    setState(() {
      var l = _position.dx, t = _position.dy, w = _size.width, h = _size.height;
      if (right) w += delta.dx;
      if (bottom) h += delta.dy;
      if (left) { l += delta.dx; w -= delta.dx; }
      if (top) { t += delta.dy; h -= delta.dy; }
      final minW = widget.window.minSize.width, minH = widget.window.minSize.height;
      if (w < minW) { if (left) l -= (minW - w); w = minW; }
      if (h < minH) { if (top) t -= (minH - h); h = minH; }
      _position = Offset(l.clamp(0, double.infinity), t.clamp(0, double.infinity));
      _size = Size(w, h);
    });
    widget.manager.updatePosition(widget.window.id, _position);
    widget.manager.updateSize(widget.window.id, _size);
  }

  void _showWindowMenu(Offset position) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _WindowMenu(
      position: position,
      isMaximized: _maximized,
      onDismiss: () => entry.remove(),
      onMinimize: () { entry.remove(); widget.manager.minimizeWindow(widget.window.id); },
      onMaximize: () { entry.remove(); _toggleMaximize(); },
      onClose: () { entry.remove(); widget.manager.closeWindow(widget.window.id); },
    ));
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.window.isFocused;
    return Positioned(
      left: _position.dx, top: _position.dy,
      child: GestureDetector(
        onTap: () => widget.manager.focusWindow(widget.window.id),
        child: SizedBox(
          width: _size.width, height: _size.height,
          child: Stack(children: [
            // Fenster
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: _maximized ? null : BorderRadius.circular(8),
                border: Border.all(
                  color: focused ? C.accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                  width: focused ? 1.5 : 1,
                ),
                boxShadow: _maximized ? null : [BoxShadow(
                  color: Colors.black.withValues(alpha: focused ? 0.5 : 0.2),
                  blurRadius: focused ? 16 : 6, offset: const Offset(0, 3),
                )],
              ),
              child: ClipRRect(
                borderRadius: _maximized ? BorderRadius.zero : BorderRadius.circular(7),
                child: Column(children: [
                  // Titelleiste
                  GestureDetector(
                    onPanUpdate: (d) => _onDragTitle(d.delta),
                    onPanEnd: (_) => _onDragEnd(),
                    onDoubleTap: _toggleMaximize,
                    onSecondaryTapUp: (d) => _showWindowMenu(d.globalPosition),
                    child: Container(
                      height: 32,
                      color: focused ? const Color(0xFF2D2D3D) : const Color(0xFF252525),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        Icon(widget.window.icon, color: Colors.white54, size: 13),
                        const SizedBox(width: 6),
                        Expanded(child: Text(widget.window.title,
                          style: TextStyle(color: focused ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis)),
                        _TrafficBtn(
                          icon: Icons.minimize,
                          hoverColor: const Color(0xFFF39C12),
                          onTap: () => widget.manager.minimizeWindow(widget.window.id),
                        ),
                        _TrafficBtn(
                          icon: _maximized ? Icons.filter_none : Icons.crop_square,
                          hoverColor: const Color(0xFF2ECC71),
                          onTap: _toggleMaximize,
                        ),
                        _TrafficBtn(
                          icon: Icons.close,
                          hoverColor: const Color(0xFFE74C3C),
                          onTap: () => widget.manager.closeWindow(widget.window.id),
                        ),
                      ]),
                    ),
                  ),
                  Expanded(child: widget.child),
                ]),
              ),
            )),
            // Resize (nicht wenn maximiert)
            if (!_maximized) ...[
              _Handle(Alignment.centerRight, SystemMouseCursors.resizeLeftRight, 6, null, (d) => _onResize(d, right: true)),
              _Handle(Alignment.bottomCenter, SystemMouseCursors.resizeUpDown, null, 6, (d) => _onResize(d, bottom: true)),
              _Handle(Alignment.centerLeft, SystemMouseCursors.resizeLeftRight, 6, null, (d) => _onResize(d, left: true)),
              _Handle(Alignment.bottomRight, SystemMouseCursors.resizeDownRight, 12, 12, (d) => _onResize(d, right: true, bottom: true)),
              _Handle(Alignment.bottomLeft, SystemMouseCursors.resizeDownLeft, 12, 12, (d) => _onResize(d, left: true, bottom: true)),
              _Handle(Alignment.topRight, SystemMouseCursors.resizeUpRight, 12, 12, (d) => _onResize(d, right: true, top: true)),
              _Handle(Alignment.topLeft, SystemMouseCursors.resizeUpLeft, 12, 12, (d) => _onResize(d, left: true, top: true)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Traffic-light style window button (Mint-Y / macOS style)
class _TrafficBtn extends StatefulWidget {
  final IconData icon;
  final Color hoverColor;
  final VoidCallback onTap;
  const _TrafficBtn({required this.icon, required this.hoverColor, required this.onTap});
  @override State<_TrafficBtn> createState() => _TrafficBtnState();
}

class _TrafficBtnState extends State<_TrafficBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 24, height: 24,
          margin: const EdgeInsets.only(left: 2),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: _h ? 20 : 6,
            height: _h ? 20 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _h ? widget.hoverColor : Colors.white.withValues(alpha: 0.2),
            ),
            child: _h
                ? Icon(widget.icon, color: Colors.white, size: 11)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  final Alignment align; final MouseCursor cursor; final double? w; final double? h;
  final void Function(Offset) onDrag;
  const _Handle(this.align, this.cursor, this.w, this.h, this.onDrag);
  @override
  Widget build(BuildContext context) => Align(alignment: align, child: MouseRegion(cursor: cursor,
    child: GestureDetector(onPanUpdate: (d) => onDrag(d.delta),
      child: Container(width: w ?? double.infinity, height: h ?? double.infinity, color: Colors.transparent))));
}

class _WindowMenu extends StatelessWidget {
  final Offset position; final bool isMaximized;
  final VoidCallback onDismiss, onMinimize, onMaximize, onClose;
  const _WindowMenu({required this.position, required this.isMaximized,
    required this.onDismiss, required this.onMinimize, required this.onMaximize, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    var dx = position.dx.clamp(8.0, screen.width - 168.0);
    var dy = position.dy.clamp(8.0, screen.height - 160.0);
    return Stack(children: [
      Positioned.fill(child: GestureDetector(onTap: onDismiss, child: Container(color: Colors.transparent))),
      Positioned(left: dx, top: dy, child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xF0282828), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _MenuItem(Icons.minimize, 'Minimieren', onMinimize),
          _MenuItem(isMaximized ? Icons.filter_none : Icons.crop_square,
            isMaximized ? 'Wiederherstellen' : 'Maximieren', onMaximize),
          Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            color: Colors.white.withValues(alpha: 0.08)),
          _MenuItem(Icons.close, 'Schliessen', onClose, danger: true),
        ]),
      )),
    ]);
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool danger;
  const _MenuItem(this.icon, this.label, this.onTap, {this.danger = false});
  @override State<_MenuItem> createState() => _MenuItemState();
}
class _MenuItemState extends State<_MenuItem> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: Container(
      height: 30, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
        color: _h ? Colors.white.withValues(alpha: 0.07) : Colors.transparent),
      child: Row(children: [
        Icon(widget.icon, color: widget.danger ? Colors.redAccent : Colors.white70, size: 14),
        const SizedBox(width: 8),
        Text(widget.label, style: TextStyle(color: widget.danger ? Colors.redAccent : Colors.white, fontSize: 11)),
      ]),
    )),
  );
}
