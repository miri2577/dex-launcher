import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemMonitorApp extends StatefulWidget {
  const SystemMonitorApp({super.key});

  @override
  State<SystemMonitorApp> createState() => _SystemMonitorAppState();
}

class _SystemMonitorAppState extends State<SystemMonitorApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');

  Map<String, dynamic>? _info;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadInfo());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    try {
      final result = await _channel.invokeMethod('getSystemInfo');
      setState(() => _info = Map<String, dynamic>.from(result as Map));
    } catch (_) {}
  }

  String _formatMB(int mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '$mb MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_info == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final usedMem = _info!['usedMemoryMB'] as int? ?? 0;
    final maxMem = _info!['maxMemoryMB'] as int? ?? 1;
    final totalStorage = _info!['totalStorageMB'] as int? ?? 1;
    final freeStorage = _info!['freeStorageMB'] as int? ?? 0;
    final usedStorage = totalStorage - freeStorage;

    return Container(
      color: const Color(0xFF1A1A1A),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Gerät
          _Section(title: 'Geraet', children: [
            _InfoRow('Modell', '${_info!['manufacturer']} ${_info!['model']}'),
            _InfoRow('Android', '${_info!['androidVersion']} (SDK ${_info!['sdkVersion']})'),
            _InfoRow('CPU-Kerne', '${_info!['cpuCores']}'),
          ]),
          const SizedBox(height: 16),

          // Arbeitsspeicher
          _Section(title: 'Arbeitsspeicher', children: [
            _UsageBar(
              used: usedMem,
              total: maxMem,
              color: Colors.blueAccent,
              label: '${_formatMB(usedMem)} / ${_formatMB(maxMem)}',
            ),
          ]),
          const SizedBox(height: 16),

          // Speicher
          _Section(title: 'Speicherplatz', children: [
            _UsageBar(
              used: usedStorage,
              total: totalStorage,
              color: Colors.amber,
              label: '${_formatMB(usedStorage)} belegt / ${_formatMB(totalStorage)} gesamt',
            ),
            const SizedBox(height: 4),
            _InfoRow('Frei', _formatMB(freeStorage)),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final int used;
  final int total;
  final Color color;
  final String label;

  const _UsageBar({
    required this.used,
    required this.total,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
        ),
      ],
    );
  }
}
