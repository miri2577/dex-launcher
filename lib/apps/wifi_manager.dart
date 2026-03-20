import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WifiManagerApp extends StatefulWidget {
  const WifiManagerApp({super.key});

  @override
  State<WifiManagerApp> createState() => _WifiManagerAppState();
}

class _WifiManagerAppState extends State<WifiManagerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');

  List<Map<String, dynamic>> _networks = [];
  Map<String, dynamic>? _currentWifi;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentWifi();
    _scanNetworks();
  }

  Future<void> _loadCurrentWifi() async {
    try {
      final result = await _channel.invokeMethod('getCurrentWifiInfo');
      if (!mounted) return;
      setState(() => _currentWifi = Map<String, dynamic>.from(result as Map));
    } catch (_) {}
  }

  Future<void> _scanNetworks() async {
    setState(() => _scanning = true);
    try {
      final result = await _channel.invokeMethod('scanWifiNetworks');
      final List<dynamic> list = result as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _networks = list.map((n) => Map<String, dynamic>.from(n as Map)).toList();
        _scanning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
    }
  }

  Future<void> _connectToNetwork(String ssid, bool isSecure) async {
    String? password;
    if (isSecure) {
      password = await _showPasswordDialog(ssid);
      if (password == null) return;
    }

    try {
      await _channel.invokeMethod('connectWifi', {
        'ssid': ssid,
        'password': password,
      });
      // Warten und Status aktualisieren
      await Future.delayed(const Duration(seconds: 3));
      _loadCurrentWifi();
    } catch (_) {}
  }

  Future<String?> _showPasswordDialog(String ssid) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: Text('Verbinden mit $ssid', style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Passwort',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Verbinden'),
          ),
        ],
      ),
    );
  }

  IconData _signalIcon(int level) {
    if (level >= 4) return Icons.signal_wifi_4_bar;
    if (level >= 3) return Icons.network_wifi_3_bar;
    if (level >= 2) return Icons.network_wifi_2_bar;
    if (level >= 1) return Icons.network_wifi_1_bar;
    return Icons.signal_wifi_0_bar;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Toolbar
          Container(
            height: 36,
            color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.wifi, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                const Text('WLAN-Netzwerke', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                if (_scanning)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blueAccent),
                  )
                else
                  GestureDetector(
                    onTap: _scanNetworks,
                    child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                  ),
              ],
            ),
          ),

          // Aktuelle Verbindung
          if (_currentWifi != null && _currentWifi!['connected'] == true)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _signalIcon(_currentWifi!['signalLevel'] as int? ?? 0),
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentWifi!['ssid'] as String? ?? 'Verbunden',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'IP: ${_currentWifi!['ip'] ?? '---'}  •  ${_currentWifi!['linkSpeed'] ?? 0} Mbps',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Verbunden', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                  ),
                ],
              ),
            ),

          // Netzwerk-Liste
          Expanded(
            child: _networks.isEmpty && !_scanning
                ? Center(
                    child: Text(
                      'Keine Netzwerke gefunden',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _networks.length,
                    itemBuilder: (context, index) {
                      final network = _networks[index];
                      final ssid = network['ssid'] as String;
                      final level = network['level'] as int? ?? 0;
                      final isSecure = network['secure'] as bool? ?? false;
                      final isConnected = _currentWifi?['ssid'] == ssid && _currentWifi?['connected'] == true;

                      return _NetworkRow(
                        ssid: ssid,
                        signalIcon: _signalIcon(level),
                        isSecure: isSecure,
                        isConnected: isConnected,
                        onTap: isConnected ? null : () => _connectToNetwork(ssid, isSecure),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NetworkRow extends StatefulWidget {
  final String ssid;
  final IconData signalIcon;
  final bool isSecure;
  final bool isConnected;
  final VoidCallback? onTap;

  const _NetworkRow({
    required this.ssid,
    required this.signalIcon,
    required this.isSecure,
    required this.isConnected,
    this.onTap,
  });

  @override
  State<_NetworkRow> createState() => _NetworkRowState();
}

class _NetworkRowState extends State<_NetworkRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _hovering ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(widget.signalIcon, color: widget.isConnected ? Colors.blueAccent : Colors.white54, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.ssid,
                  style: TextStyle(
                    color: widget.isConnected ? Colors.blueAccent : Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              if (widget.isSecure)
                Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.3), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
