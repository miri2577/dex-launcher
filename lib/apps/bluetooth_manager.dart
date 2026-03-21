import '../theme/cinnamon_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BluetoothManagerApp extends StatefulWidget {
  const BluetoothManagerApp({super.key});

  @override
  State<BluetoothManagerApp> createState() => _BluetoothManagerAppState();
}

class _BluetoothManagerAppState extends State<BluetoothManagerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');

  List<Map<String, dynamic>> _devices = [];
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    try {
      _enabled = await _channel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
      if (_enabled) {
        final result = await _channel.invokeMethod('getBluetoothDevices');
        final List<dynamic> list = result as List<dynamic>;
        _devices = list.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  IconData _deviceIcon(String type) {
    return switch (type) {
      'LE' => Icons.bluetooth_searching,
      'Classic' => Icons.bluetooth_connected,
      'Dual' => Icons.bluetooth,
      _ => Icons.bluetooth,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.panelBg,
      child: Column(
        children: [
          // Toolbar
          Container(
            height: 36,
            color: C.windowChromeUnfocused,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.bluetooth, color: _enabled ? const Color(0xFF86BE43) : Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text(
                  _enabled ? 'Bluetooth aktiv' : 'Bluetooth deaktiviert',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadDevices,
                  child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                ),
              ],
            ),
          ),

          if (!_enabled && !_loading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_disabled, color: Colors.white.withValues(alpha: 0.2), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Bluetooth ist deaktiviert',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aktiviere Bluetooth in den Android-Einstellungen',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            // Gepaarte Geräte
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Text(
                    'Gepaarte Geraete (${_devices.length})',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        'Keine gepaarten Geraete',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return _DeviceRow(
                          name: device['name'] as String,
                          address: device['address'] as String,
                          type: device['type'] as String,
                          icon: _deviceIcon(device['type'] as String),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceRow extends StatefulWidget {
  final String name;
  final String address;
  final String type;
  final IconData icon;

  const _DeviceRow({
    required this.name,
    required this.address,
    required this.type,
    required this.icon,
  });

  @override
  State<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<_DeviceRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: _hovering ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: const Color(0xFF86BE43), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  Text(
                    '${widget.type}  •  ${widget.address}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF86BE43).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Gepaart', style: TextStyle(color: const Color(0xFF86BE43), fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}
