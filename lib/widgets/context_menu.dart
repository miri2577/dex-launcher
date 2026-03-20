import 'package:flutter/material.dart';

class ContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}

class ContextMenu {
  static void show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ContextMenuOverlay(
        position: position,
        items: items,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ContextMenuOverlay extends StatelessWidget {
  final Offset position;
  final List<ContextMenuItem> items;
  final VoidCallback onDismiss;

  const _ContextMenuOverlay({
    required this.position,
    required this.items,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const menuWidth = 220.0;
    final menuHeight = items.length * 44.0 + 16;

    // Position korrigieren falls Menu aus dem Screen ragt
    var dx = position.dx;
    var dy = position.dy;
    if (dx + menuWidth > screenSize.width) dx = screenSize.width - menuWidth - 8;
    if (dy + menuHeight > screenSize.height) dy = screenSize.height - menuHeight - 8;
    dx = dx.clamp(8, screenSize.width - menuWidth - 8);
    dy = dy.clamp(8, screenSize.height - menuHeight - 8);

    return Stack(
      children: [
        // Backdrop zum Schließen
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            onSecondaryTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu
        Positioned(
          left: dx,
          top: dy,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            builder: (context, value, child) => Transform.scale(
              scale: 0.9 + 0.1 * value,
              alignment: Alignment.topLeft,
              child: Opacity(opacity: value, child: child),
            ),
            child: Container(
              width: menuWidth,
              decoration: BoxDecoration(
                color: const Color(0xF0282828),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) => _MenuItem(
                  item: item,
                  onTap: () {
                    onDismiss();
                    item.onTap();
                  },
                )).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatefulWidget {
  final ContextMenuItem item;
  final VoidCallback onTap;

  const _MenuItem({required this.item, required this.onTap});

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item.isDanger ? Colors.red.shade300 : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _hovering ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, color: color, size: 18),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(color: color, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
