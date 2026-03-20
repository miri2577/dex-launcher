import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VpnManagerApp extends StatefulWidget {
  const VpnManagerApp({super.key});
  @override
  State<VpnManagerApp> createState() => _VpnManagerAppState();
}

class _VpnManagerAppState extends State<VpnManagerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  String? _vpnStatus;
  List<String> _profiles = [];

  @override
  void initState() { super.initState(); _loadStatus(); }

  Future<void> _loadStatus() async {
    try {
      final r = await _channel.invokeMethod('executeCommand', {'command': 'settings get global vpn_tethering'});
      final m = Map<String, dynamic>.from(r as Map);
      // VPN-Profile auslesen
      final r2 = await _channel.invokeMethod('executeCommand', {'command': 'settings get secure vpn_configuration 2>/dev/null || echo "none"'});
      final m2 = Map<String, dynamic>.from(r2 as Map);
      if (!mounted) return;
      setState(() {
        _vpnStatus = (m['stdout'] as String? ?? '').trim();
        final cfg = (m2['stdout'] as String? ?? '').trim();
        _profiles = cfg.isNotEmpty && cfg != 'none' && cfg != 'null' ? [cfg] : [];
      });
    } catch (_) {}
  }

  void _openSystemVpnSettings() {
    _channel.invokeMethod('executeCommand', {'command': 'am start -a android.net.vpn.SETTINGS 2>/dev/null || am start -a android.settings.VPN_SETTINGS 2>/dev/null'});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Container(height: 32, color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Icon(Icons.vpn_lock, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              const Text('VPN', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              GestureDetector(onTap: _loadStatus, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
            ])),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.vpn_lock, color: _profiles.isNotEmpty ? Colors.greenAccent : Colors.white38, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_profiles.isNotEmpty ? 'VPN konfiguriert' : 'Kein VPN',
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Text(_vpnStatus ?? 'Unbekannt',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                        ],
                      )),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Profiles
                  if (_profiles.isNotEmpty)
                    ..._profiles.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                    )),
                  const Spacer(),
                  // System VPN Settings öffnen
                  GestureDetector(
                    onTap: _openSystemVpnSettings,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text('System VPN-Einstellungen oeffnen',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
