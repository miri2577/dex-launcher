import 'package:flutter/material.dart';
import '../theme/cinnamon_theme.dart';

/// Einheitliche Toolbar für alle Mini-Apps
class AppToolbar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AppToolbar({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: C.windowChromeUnfocused,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
          ],
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// Einheitlicher Toolbar-Button
class ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;
  final bool active;

  const ToolbarButton({
    super.key,
    required this.icon,
    this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: widget.active || _h ? C.hover : Colors.transparent,
          ),
          child: Icon(widget.icon, color: widget.active ? Colors.white : Colors.white70, size: 14),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}

/// Einheitliche Status-Leiste
class AppStatusBar extends StatelessWidget {
  final List<Widget> children;

  const AppStatusBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      color: C.windowChromeUnfocused,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: children),
    );
  }
}
