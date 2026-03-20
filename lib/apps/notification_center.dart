import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationCenterApp extends StatefulWidget {
  const NotificationCenterApp({super.key});
  @override
  State<NotificationCenterApp> createState() => _NotificationCenterAppState();
}

class _NotificationCenterAppState extends State<NotificationCenterApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  final List<_Notification> _notifications = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _addInfo('Benachrichtigungs-Center gestartet');
    _addInfo('System-Benachrichtigungen erfordern NotificationListenerService');
    _addInfo('ADB: adb shell cmd notification allow_listener com.dexlauncher.dex_launcher/.NotificationService');
    _pollNotifications();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _pollNotifications());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _addInfo(String text) {
    _notifications.add(_Notification(text: text, time: DateTime.now(), type: 'info'));
  }

  Future<void> _pollNotifications() async {
    try {
      // Dumpsys für aktive Benachrichtigungen
      final r = await _channel.invokeMethod('executeCommand', {
        'command': 'dumpsys notification --noredact 2>/dev/null | grep -E "pkg=|android.title=|android.text=" | head -30'
      });
      final m = Map<String, dynamic>.from(r as Map);
      final out = (m['stdout'] as String? ?? '').trim();
      if (out.isEmpty || !mounted) return;

      final lines = out.split('\n');
      String? currentPkg;
      String? currentTitle;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.contains('pkg=')) {
          currentPkg = RegExp(r'pkg=(\S+)').firstMatch(trimmed)?.group(1);
        } else if (trimmed.contains('android.title=')) {
          currentTitle = trimmed.split('android.title=').last.trim();
        } else if (trimmed.contains('android.text=') && currentPkg != null) {
          final text = trimmed.split('android.text=').last.trim();
          final full = '${currentTitle ?? currentPkg}: $text';
          // Duplikate vermeiden
          if (!_notifications.any((n) => n.text == full)) {
            setState(() {
              _notifications.insert(0, _Notification(
                text: full, time: DateTime.now(), type: 'notification', pkg: currentPkg,
              ));
              if (_notifications.length > 50) _notifications.removeLast();
            });
          }
          currentPkg = null;
          currentTitle = null;
        }
      }
    } catch (_) {}
  }

  void _clear() => setState(() => _notifications.clear());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Container(height: 32, color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Icon(Icons.notifications, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text('${_notifications.length} Benachrichtigungen', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              GestureDetector(onTap: _pollNotifications, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
              const SizedBox(width: 8),
              GestureDetector(onTap: _clear, child: const Icon(Icons.delete_sweep, color: Colors.white38, size: 14)),
            ])),
          Expanded(
            child: _notifications.isEmpty
                ? Center(child: Text('Keine Benachrichtigungen', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))
                : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      final time = '${n.time.hour.toString().padLeft(2, '0')}:${n.time.minute.toString().padLeft(2, '0')}';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: n.type == 'info' ? const Color(0xFF86BE43).withValues(alpha: 0.06) : Colors.transparent,
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(n.type == 'info' ? Icons.info_outline : Icons.notifications_none,
                            color: n.type == 'info' ? const Color(0xFF86BE43).withValues(alpha: 0.5) : Colors.white38, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(n.text, style: TextStyle(
                            color: n.type == 'info' ? Colors.white54 : Colors.white, fontSize: 11))),
                          Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 9)),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Notification {
  final String text;
  final DateTime time;
  final String type;
  final String? pkg;
  _Notification({required this.text, required this.time, required this.type, this.pkg});
}
