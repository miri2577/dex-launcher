import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CursorOverlay extends StatefulWidget {
  final Widget child;

  const CursorOverlay({super.key, required this.child});

  @override
  State<CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<CursorOverlay> {
  Offset _cursorPosition = Offset.zero;
  bool _visible = false;
  static const _cursorSpeed = 5.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onHover: (event) {
        setState(() {
          _cursorPosition = event.position;
          _visible = true;
        });
      },
      onExit: (_) => setState(() => _visible = false),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            widget.child,
            if (_visible)
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
    );
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
    }

    if (dx != _cursorPosition.dx || dy != _cursorPosition.dy) {
      setState(() {
        _cursorPosition = Offset(dx, dy);
        _visible = true;
      });
    }
  }
}

class _CursorWidget extends StatelessWidget {
  const _CursorWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _CursorPainter(),
    );
  }
}

class _CursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 16)
      ..lineTo(4.5, 12.5)
      ..lineTo(8, 19)
      ..lineTo(10.5, 18)
      ..lineTo(7, 11)
      ..lineTo(12, 11)
      ..close();

    // Schatten
    canvas.drawPath(
      path.shift(const Offset(0.5, 0.5)),
      Paint()..color = Colors.black54,
    );
    // Cursor
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
