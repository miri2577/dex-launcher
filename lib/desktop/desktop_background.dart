import 'dart:io';
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
  // 8: Nebula
  [Color(0xFF1A0533), Color(0xFF3D1266), Color(0xFF6B21A8), Color(0xFF9333EA)],
  // 9: Teal Dream
  [Color(0xFF042F2E), Color(0xFF0D4F4F), Color(0xFF0F766E), Color(0xFF14B8A6)],
  // 10: Golden Hour
  [Color(0xFF1C1208), Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
  // 11: Slate
  [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
];

class DesktopBackground extends StatelessWidget {
  final int wallpaperIndex;
  final String? customImagePath;

  const DesktopBackground({
    super.key,
    this.wallpaperIndex = 0,
    this.customImagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Custom Bild als Hintergrund
    if (customImagePath != null && customImagePath!.isNotEmpty) {
      final file = File(customImagePath!);
      if (file.existsSync()) {
        return SizedBox.expand(
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _GradientBackground(wallpaperIndex: wallpaperIndex),
          ),
        );
      }
    }

    return _GradientBackground(wallpaperIndex: wallpaperIndex);
  }
}

class _GradientBackground extends StatelessWidget {
  final int wallpaperIndex;
  const _GradientBackground({required this.wallpaperIndex});

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
    );
  }
}
