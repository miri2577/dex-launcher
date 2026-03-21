import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Screensaver extends StatefulWidget {
  final VoidCallback onDismiss;
  const Screensaver({super.key, required this.onDismiss});

  @override
  State<Screensaver> createState() => _ScreensaverState();
}

class _ScreensaverState extends State<Screensaver> {
  late Timer _timer;
  final _random = Random();
  int _mode = 0; // 0=Uhr, 1=Sterne, 2=Matrix
  double _clockX = 100, _clockY = 100;
  double _dx = 1.5, _dy = 1.0;

  // Sterne
  final List<_Star> _stars = [];

  // Matrix
  final List<_MatrixColumn> _matrixCols = [];

  @override
  void initState() {
    super.initState();
    _mode = _random.nextInt(3);
    // Sterne initialisieren
    for (int i = 0; i < 120; i++) {
      _stars.add(_Star(
        x: _random.nextDouble(), y: _random.nextDouble(),
        speed: 0.001 + _random.nextDouble() * 0.003,
        size: 0.5 + _random.nextDouble() * 2,
        brightness: 0.3 + _random.nextDouble() * 0.7,
      ));
    }
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  void _tick() {
    if (!mounted) return;
    setState(() {
      if (_mode == 0) _moveClock();
      else if (_mode == 1) _moveStars();
      else _moveMatrix();
    });
  }

  void _moveClock() {
    final size = MediaQuery.of(context).size;
    _clockX += _dx; _clockY += _dy;
    if (_clockX <= 0 || _clockX >= size.width - 200) _dx = -_dx;
    if (_clockY <= 0 || _clockY >= size.height - 60) _dy = -_dy;
    _clockX = _clockX.clamp(0, size.width - 200);
    _clockY = _clockY.clamp(0, size.height - 60);
  }

  void _moveStars() {
    for (final s in _stars) {
      s.y += s.speed;
      if (s.y > 1) { s.y = 0; s.x = _random.nextDouble(); }
    }
  }

  void _moveMatrix() {
    final size = MediaQuery.of(context).size;
    final cols = (size.width / 14).floor();
    while (_matrixCols.length < cols) {
      _matrixCols.add(_MatrixColumn(
        x: _matrixCols.length * 14.0,
        y: -_random.nextDouble() * size.height,
        speed: 2 + _random.nextDouble() * 4,
        chars: List.generate(20, (_) => String.fromCharCode(0x30A0 + _random.nextInt(96))),
      ));
    }
    for (final col in _matrixCols) {
      col.y += col.speed;
      if (col.y > size.height + 300) {
        col.y = -300;
        col.speed = 2 + _random.nextDouble() * 4;
      }
      // Zeichen zufällig wechseln
      if (_random.nextDouble() < 0.05) {
        final idx = _random.nextInt(col.chars.length);
        col.chars[idx] = String.fromCharCode(0x30A0 + _random.nextInt(96));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (_) => widget.onDismiss(),
      child: GestureDetector(
        onTap: widget.onDismiss,
        onPanDown: (_) => widget.onDismiss(),
        child: MouseRegion(
          onHover: (_) => widget.onDismiss(),
          child: Container(
            color: Colors.black,
            child: switch (_mode) {
              0 => _buildClock(),
              1 => _buildStars(),
              2 => _buildMatrix(),
              _ => _buildClock(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClock() {
    return Stack(children: [
      Positioned(left: _clockX, top: _clockY, child: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, _) {
          final now = DateTime.now();
          return Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: HSLColor.fromAHSL(1, (now.second * 6.0) % 360, 0.7, 0.6).toColor(),
              fontSize: 48, fontWeight: FontWeight.w200,
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildStars() {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarPainter(_stars),
    );
  }

  Widget _buildMatrix() {
    return CustomPaint(
      size: Size.infinite,
      painter: _MatrixPainter(_matrixCols),
    );
  }
}

class _Star {
  double x, y, speed, size, brightness;
  _Star({required this.x, required this.y, required this.speed, required this.size, required this.brightness});
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  _StarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = Colors.white.withValues(alpha: s.brightness),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MatrixColumn {
  double x, y, speed;
  List<String> chars;
  _MatrixColumn({required this.x, required this.y, required this.speed, required this.chars});
}

class _MatrixPainter extends CustomPainter {
  final List<_MatrixColumn> cols;
  _MatrixPainter(this.cols);

  @override
  void paint(Canvas canvas, Size size) {
    for (final col in cols) {
      for (int i = 0; i < col.chars.length; i++) {
        final y = col.y + i * 16;
        if (y < -16 || y > size.height) continue;
        final brightness = i == 0 ? 1.0 : (1.0 - i / col.chars.length) * 0.7;
        final tp = TextPainter(
          text: TextSpan(
            text: col.chars[i],
            style: TextStyle(
              color: Color.fromRGBO(134, 190, 67, brightness), // Mint Green
              fontSize: 14, fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(col.x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
