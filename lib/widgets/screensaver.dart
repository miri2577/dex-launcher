import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Screensaver extends StatefulWidget {
  final VoidCallback onDismiss;
  const Screensaver({super.key, required this.onDismiss});

  @override
  State<Screensaver> createState() => _ScreensaverState();
}

class _ScreensaverState extends State<Screensaver> with SingleTickerProviderStateMixin {
  late Timer _timer;
  double _x = 100, _y = 100;
  double _dx = 1.5, _dy = 1.0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _move());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _move() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    setState(() {
      _x += _dx;
      _y += _dy;
      if (_x <= 0 || _x >= size.width - 200) {
        _dx = -_dx * (0.9 + _random.nextDouble() * 0.2);
        _x = _x.clamp(0, size.width - 200);
      }
      if (_y <= 0 || _y >= size.height - 60) {
        _dy = -_dy * (0.9 + _random.nextDouble() * 0.2);
        _y = _y.clamp(0, size.height - 60);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      onPanDown: (_) => widget.onDismiss(),
      child: MouseRegion(
        onHover: (_) => widget.onDismiss(),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned(
                left: _x, top: _y,
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, _) {
                    final now = DateTime.now();
                    return Text(
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: HSLColor.fromAHSL(1, (now.second * 6.0) % 360, 0.7, 0.6).toColor(),
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
