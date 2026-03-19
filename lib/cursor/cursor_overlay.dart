import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/system_status_service.dart';

/// Cursor-Overlay das intelligent entscheidet:
/// - Externe Maus erkannt → System-Cursor nutzen, Custom-Cursor aus
/// - Keine Maus → Custom-Cursor per D-Pad steuern
class CursorOverlay extends StatefulWidget {
  final Widget child;

  const CursorOverlay({super.key, required this.child});

  @override
  State<CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<CursorOverlay> {
  Offset _cursorPosition = Offset.zero;
  bool _customCursorVisible = false;
  static const _cursorSpeed = 8.0;

  @override
  Widget build(BuildContext context) {
    final hasExternalMouse = context.select<SystemStatusService, bool>(
      (s) => s.status.hasExternalMouse,
    );

    // Externe Maus vorhanden → System-Cursor nutzen, kein Custom-Cursor
    if (hasExternalMouse) {
      return KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (_) {}, // D-Pad ignorieren wenn Maus da
        child: widget.child,
      );
    }

    // Keine externe Maus → Custom-Cursor per D-Pad
    return Listener(
      onPointerHover: _onMouseMove,
      onPointerMove: _onMouseMove,
      onPointerDown: (_) {
        if (!_customCursorVisible) setState(() => _customCursorVisible = true);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.none,
        onExit: (_) => setState(() => _customCursorVisible = false),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: _handleKeyEvent,
          child: Stack(
            children: [
              widget.child,
              if (_customCursorVisible)
                Positioned(
                  left: _cursorPosition.dx,
                  top: _cursorPosition.dy,
                  child: const IgnorePointer(
                    child: _CursorWidget(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMouseMove(PointerEvent event) {
    setState(() {
      _cursorPosition = event.position;
      _customCursorVisible = true;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final screenSize = MediaQuery.of(context).size;
    var dx = _cursorPosition.dx;
    var dy = _cursorPosition.dy;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      dy = (dy - _cursorSpeed).clamp(0, screenSize.height);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      dy = (dy + _cursorSpeed).clamp(0, screenSize.height);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      dx = (dx - _cursorSpeed).clamp(0, screenSize.width);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      dx = (dx + _cursorSpeed).clamp(0, screenSize.width);
    } else {
      return;
    }

    setState(() {
      _cursorPosition = Offset(dx, dy);
      _customCursorVisible = true;
    });
  }
}

class _CursorWidget extends StatelessWidget {
  const _CursorWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _CursorPainter(),
    );
  }
}

class _CursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 18)
      ..lineTo(5, 14)
      ..lineTo(9, 22)
      ..lineTo(12, 20.5)
      ..lineTo(8, 12.5)
      ..lineTo(14, 12.5)
      ..close();

    // Schatten
    canvas.drawPath(
      path.shift(const Offset(1, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // Füllung
    canvas.drawPath(path, Paint()..color = Colors.white);
    // Rand
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
