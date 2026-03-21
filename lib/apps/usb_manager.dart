import '../theme/cinnamon_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsbManagerApp extends StatefulWidget {
  const UsbManagerApp({super.key});
  @override
  State<UsbManagerApp> createState() => _UsbManagerAppState();
}

class _UsbManagerAppState extends State<UsbManagerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await _channel.invokeMethod('getUsbDevices');
      if (!mounted) return;
      setState(() => _devices = (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.panelBg,
      child: Column(
        children: [
          Container(height: 32, color: C.windowChromeUnfocused,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Icon(Icons.usb, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text('${_devices.length} USB-Geraete', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              GestureDetector(onTap: _load, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
            ])),
          Expanded(
            child: _devices.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.usb_off, color: Colors.white.withValues(alpha: 0.2), size: 40),
                    const SizedBox(height: 8),
                    Text('Keine USB-Geraete', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _devices.length,
                    itemBuilder: (context, i) {
                      final d = _devices[i];
                      return Container(
                        height: 48, margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: [
                          const Icon(Icons.usb, color: Colors.white54, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Text('${d['vendor']}  •  ${d['class']}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                            ],
                          )),
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
