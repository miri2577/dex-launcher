import '../theme/cinnamon_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NetworkScannerApp extends StatefulWidget {
  const NetworkScannerApp({super.key});
  @override
  State<NetworkScannerApp> createState() => _NetworkScannerAppState();
}

class _NetworkScannerAppState extends State<NetworkScannerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  List<Map<String, dynamic>> _devices = [];
  bool _scanning = false;

  @override
  void initState() { super.initState(); _scan(); }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final r = await _channel.invokeMethod('scanNetwork');
      if (!mounted) return;
      setState(() {
        _devices = (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _scanning = false;
      });
    } catch (_) {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.panelBg,
      child: Column(
        children: [
          Container(
            height: 32, color: C.windowChromeUnfocused,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Icon(Icons.lan, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text('${_devices.length} Geraete', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              if (_scanning)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blueAccent))
              else
                GestureDetector(onTap: _scan, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
            ]),
          ),
          Expanded(
            child: _devices.isEmpty && !_scanning
                ? Center(child: Text('Keine Geraete gefunden', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _devices.length,
                    itemBuilder: (context, i) {
                      final d = _devices[i];
                      return Container(
                        height: 40, margin: const EdgeInsets.symmetric(vertical: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(children: [
                          const Icon(Icons.devices, color: Colors.white54, size: 16),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['ip'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Text(d['mac'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9)),
                            ],
                          )),
                          Text(d['device'] as String? ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
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
