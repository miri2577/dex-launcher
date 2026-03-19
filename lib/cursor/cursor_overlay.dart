import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/system_status_service.dart';

/// Cursor-Overlay:
/// - Externe Maus erkannt → nichts tun, System-Cursor nutzen
/// - Keine Maus → Custom-Cursor per D-Pad
class CursorOverlay extends StatelessWidget {
  final Widget child;

  const CursorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final hasExternalMouse = context.select<SystemStatusService, bool>(
      (s) => s.status.hasExternalMouse,
    );

    if (hasExternalMouse) {
      return child;
    }

    return _DpadCursor(child: child);
  }
}

class _DpadCursor extends StatefulWidget {
  final Widget child;
  const _DpadCursor({required this.child});

  @override
  State<_DpadCursor> createState() => _DpadCursorState();
}

class _DpadCursorState extends State<_DpadCursor> {
  double _dx = 0;
  double _dy = 0;
  bool _visible = false;
  static const _speed = 8.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            widget.child,
            if (_visible)
              Positioned(
                left: _dx,
                top: _dy,
                child: const IgnorePointer(child: _CursorPaint()),
              ),
          ],
        ),
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final size = MediaQuery.of(context).size;
    var dx = _dx;
    var dy = _dy;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        dy = (dy - _speed).clamp(0, size.height);
      case LogicalKeyboardKey.arrowDown:
        dy = (dy + _speed).clamp(0, size.height);
      case LogicalKeyboardKey.arrowLeft:
        dx = (dx - _speed).clamp(0, size.width);
      case LogicalKeyboardKey.arrowRight:
        dx = (dx + _speed).clamp(0, size.width);
      default:
        return;
    }

    setState(() {
      _dx = dx;
      _dy = dy;
      _visible = true;
    });
  }
}

class _CursorPaint extends StatelessWidget {
  const _CursorPaint();

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

    canvas.drawPath(
      path.shift(const Offset(1, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawPath(path, Paint()..color = Colors.white);
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
