import 'package:flutter/material.dart';

const List<List<Color>> wallpaperGradients = [
  // 0: Deep Ocean
  [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF162447), Color(0xFF1F4068)],
  // 1: Aurora
  [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  // 2: Sunset
  [Color(0xFF2C1654), Color(0xFF6B2FA0), Color(0xFFE94560)],
  // 3: Forest
  [Color(0xFF0B3D0B), Color(0xFF145A32), Color(0xFF1E8449)],
  // 4: Midnight
  [Color(0xFF0C0C1E), Color(0xFF1A1A3E), Color(0xFF2D2D6B)],
  // 5: Ember
  [Color(0xFF1A0000), Color(0xFF4A0E0E), Color(0xFF8B1A1A)],
  // 6: Arctic
  [Color(0xFF0A1628), Color(0xFF1B3A5C), Color(0xFF3A7BD5)],
  // 7: Charcoal
  [Color(0xFF1A1A1A), Color(0xFF2D2D2D), Color(0xFF383838)],
];

class DesktopBackground extends StatelessWidget {
  final int wallpaperIndex;

  const DesktopBackground({super.key, this.wallpaperIndex = 0});

  @override
  Widget build(BuildContext context) {
    final colors = wallpaperGradients[wallpaperIndex.clamp(0, wallpaperGradients.length - 1)];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 60.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
