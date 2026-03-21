import 'dart:async';
import 'package:flutter/material.dart';

/// Globaler Benachrichtigungs-Service für Desktop-Toasts
class NotificationToast {
  static final List<_ToastEntry> _queue = [];
  static OverlayEntry? _overlayEntry;
  static final _controller = StreamController<void>.broadcast();

  static void show(BuildContext context, String message, {IconData icon = Icons.info_outline, Duration duration = const Duration(seconds: 3)}) {
    _queue.add(_ToastEntry(message: message, icon: icon, duration: duration));
    _updateOverlay(context);
  }

  static void _updateOverlay(BuildContext context) {
    _overlayEntry?.remove();
    if (_queue.isEmpty) { _overlayEntry = null; return; }

    _overlayEntry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        entries: List.from(_queue),
        onDismiss: (index) {
          if (index < _queue.length) _queue.removeAt(index);
          _updateOverlay(context);
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-remove nach Duration
    final entry = _queue.first;
    Timer(entry.duration, () {
      _queue.remove(entry);
      _updateOverlay(context);
    });
  }
}

class _ToastEntry {
  final String message;
  final IconData icon;
  final Duration duration;
  _ToastEntry({required this.message, required this.icon, required this.duration});
}

class _ToastOverlay extends StatelessWidget {
  final List<_ToastEntry> entries;
  final void Function(int) onDismiss;
  const _ToastOverlay({required this.entries, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: const Color(0xF0282828),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(entry.icon, color: const Color(0xFF86BE43), size: 16),
                  const SizedBox(width: 10),
                  Flexible(child: Text(entry.message,
                    style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 3)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onDismiss(i),
                    child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.3), size: 14),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
