import 'package:flutter/material.dart';
import '../models/app_info.dart';

class AppIconWidget extends StatelessWidget {
  final AppInfo app;
  final double size;

  const AppIconWidget({super.key, required this.app, this.size = 48});

  @override
  Widget build(BuildContext context) {
    if (app.icon != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.memory(
          app.icon!,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colorFromName(app.name),
            _colorFromName(app.name).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    final hash = name.hashCode;
    return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.5, 0.4).toColor();
  }
}
