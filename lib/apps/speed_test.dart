import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpeedTestApp extends StatefulWidget {
  const SpeedTestApp({super.key});
  @override
  State<SpeedTestApp> createState() => _SpeedTestAppState();
}

class _SpeedTestAppState extends State<SpeedTestApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  bool _testing = false;
  String? _result;
  String? _details;
  List<String> _history = [];

  Future<void> _runTest() async {
    setState(() { _testing = true; _result = null; _details = null; });
    try {
      final r = await _channel.invokeMethod('runSpeedTest');
      if (!mounted) return;
      final m = Map<String, dynamic>.from(r as Map);
      final mbps = m['mbps'] as String? ?? '0';
      final ms = m['ms'] as int? ?? 0;
      final bytes = m['bytes'] as int? ?? 0;
      final error = m['error'] as String?;
      setState(() {
        _testing = false;
        if (error != null) {
          _result = 'Fehler';
          _details = error;
        } else {
          _result = '$mbps Mbps';
          _details = '${(bytes / 1024).toStringAsFixed(0)} KB in ${ms}ms';
          _history.insert(0, '$mbps Mbps (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})');
          if (_history.length > 10) _history.removeLast();
        }
      });
    } catch (e) {
      if (mounted) setState(() { _testing = false; _result = 'Fehler'; _details = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Spacer(),
          // Ergebnis
          if (_result != null) ...[
            Text(_result!, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w200)),
            const SizedBox(height: 4),
            Text(_details ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          ] else if (!_testing)
            Text('Download-Geschwindigkeit testen', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 24),
          // Button
          GestureDetector(
            onTap: _testing ? null : _runTest,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _testing ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF86BE43).withValues(alpha: 0.3),
                border: Border.all(color: _testing ? Colors.white12 : const Color(0xFF86BE43).withValues(alpha: 0.5), width: 2),
              ),
              child: _testing
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF86BE43)))
                  : const Icon(Icons.speed, color: Colors.white, size: 32),
            ),
          ),
          const Spacer(),
          // History
          if (_history.isNotEmpty) ...[
            Text('Verlauf', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
            const SizedBox(height: 4),
            ..._history.take(5).map((h) => Text(h, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10))),
          ],
        ],
      ),
    );
  }
}
