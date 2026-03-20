import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeveloperOptionsApp extends StatefulWidget {
  const DeveloperOptionsApp({super.key});
  @override
  State<DeveloperOptionsApp> createState() => _DeveloperOptionsAppState();
}

class _DeveloperOptionsAppState extends State<DeveloperOptionsApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  Map<String, dynamic>? _sysInfo;
  Map<String, String> _settings = {};
  Map<String, String> _props = {};
  String _cmdOutput = '';
  final _cmdController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _cmdController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadSysInfo(), _loadSettings(), _loadProps()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSysInfo() async {
    try {
      final r = await _channel.invokeMethod('getSystemInfo');
      _sysInfo = Map<String, dynamic>.from(r as Map);
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    try {
      final r = await _channel.invokeMethod('executeCommand', {'command': 'settings list global 2>/dev/null | head -80'});
      final out = (Map<String, dynamic>.from(r as Map))['stdout'] as String? ?? '';
      final map = <String, String>{};
      for (final line in out.split('\n')) {
        final idx = line.indexOf('=');
        if (idx > 0) map[line.substring(0, idx)] = line.substring(idx + 1);
      }
      _settings = map;
    } catch (_) {}
  }

  Future<void> _loadProps() async {
    try {
      final r = await _channel.invokeMethod('executeCommand', {'command': 'getprop 2>/dev/null | head -80'});
      final out = (Map<String, dynamic>.from(r as Map))['stdout'] as String? ?? '';
      final map = <String, String>{};
      for (final line in out.split('\n')) {
        final match = RegExp(r'\[(.+?)\]: \[(.+?)\]').firstMatch(line);
        if (match != null) map[match.group(1)!] = match.group(2)!;
      }
      _props = map;
    } catch (_) {}
  }

  Future<String> _exec(String cmd) async {
    try {
      final r = await _channel.invokeMethod('executeCommand', {'command': cmd});
      final m = Map<String, dynamic>.from(r as Map);
      final stdout = m['stdout'] as String? ?? '';
      final stderr = m['stderr'] as String? ?? '';
      return stdout.isNotEmpty ? stdout : stderr;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> _runCommand() async {
    final cmd = _cmdController.text.trim();
    if (cmd.isEmpty) return;
    final result = await _exec(cmd);
    if (mounted) setState(() => _cmdOutput = '\$ $cmd\n$result');
  }

  // Quick-Actions
  Future<void> _toggleSetting(String key, String onVal, String offVal) async {
    final current = _settings[key];
    final newVal = current == onVal ? offVal : onVal;
    await _exec('settings put global $key $newVal');
    await _loadSettings();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Toolbar
          Container(
            height: 32, color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Icon(Icons.developer_mode, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              const Text('Entwickleroptionen', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              GestureDetector(onTap: _loadAll, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
            ]),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // Quick Command
                _Section('Befehl ausfuehren', [
                  Row(children: [
                    Expanded(child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(keyboardType: TextInputType.none, 
                        controller: _cmdController,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: 'Shell-Befehl...',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _runCommand(),
                      ),
                    )),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _runCommand,
                      child: Container(
                        height: 28, width: 28,
                        decoration: BoxDecoration(color: const Color(0xFF86BE43).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                      ),
                    ),
                  ]),
                  if (_cmdOutput.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        child: Text(_cmdOutput, style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace')),
                      ),
                    ),
                ]),

                // Geräte-Info
                _Section('Geraet', [
                  _InfoRow('Modell', '${_sysInfo?['manufacturer'] ?? '?'} ${_sysInfo?['model'] ?? '?'}'),
                  _InfoRow('Android', '${_sysInfo?['androidVersion'] ?? '?'} (SDK ${_sysInfo?['sdkVersion'] ?? '?'})'),
                  _InfoRow('CPU-Kerne', '${_sysInfo?['cpuCores'] ?? '?'}'),
                  _InfoRow('RAM App', '${_sysInfo?['usedMemoryMB'] ?? '?'} / ${_sysInfo?['maxMemoryMB'] ?? '?'} MB'),
                  _InfoRow('Speicher frei', '${_sysInfo?['freeStorageMB'] ?? '?'} / ${_sysInfo?['totalStorageMB'] ?? '?'} MB'),
                  _InfoRow('Build', _props['ro.build.display.id'] ?? '?'),
                  _InfoRow('Fingerprint', _props['ro.build.fingerprint'] ?? '?'),
                  _InfoRow('Kernel', _props['ro.build.kernel.id'] ?? _props.entries.where((e) => e.key.contains('kernel')).map((e) => e.value).firstOrNull ?? '?'),
                  _InfoRow('Serial', _props['ro.serialno'] ?? '?'),
                ]),

                // ADB Quick Actions
                _Section('ADB Schnellbefehle', [
                  _ActionBtn('Freeform aktivieren', Icons.window,
                    () async { await _exec('settings put global enable_freeform_support 1'); _loadSettings(); }),
                  _ActionBtn('Pointer-Speed auf 5', Icons.mouse,
                    () async { await _exec('settings put system pointer_speed 5'); }),
                  _ActionBtn('USB-Debugging Status', Icons.usb,
                    () async { final r = await _exec('settings get global adb_enabled'); setState(() => _cmdOutput = 'ADB enabled: $r'); }),
                  _ActionBtn('Display-Info', Icons.tv,
                    () async { final r = await _exec('wm size && wm density'); setState(() => _cmdOutput = r); }),
                  _ActionBtn('IP-Adresse', Icons.lan,
                    () async { final r = await _exec('ip addr show wlan0 | grep "inet "'); setState(() => _cmdOutput = r); }),
                  _ActionBtn('Laufende Services', Icons.miscellaneous_services,
                    () async { final r = await _exec('dumpsys activity services | head -30'); setState(() => _cmdOutput = r); }),
                  _ActionBtn('Battery-Info', Icons.battery_full,
                    () async { final r = await _exec('dumpsys battery'); setState(() => _cmdOutput = r); }),
                  _ActionBtn('WiFi-Info', Icons.wifi,
                    () async { final r = await _exec('dumpsys wifi | grep -E "mWifiInfo|SSID" | head -5'); setState(() => _cmdOutput = r); }),
                  _ActionBtn('Speicher aufraeumen', Icons.cleaning_services,
                    () async { final r = await _exec('pm trim-caches 500M 2>&1; echo "Cache getrimmt"'); setState(() => _cmdOutput = r); }),
                  _ActionBtn('Installierte Pakete', Icons.apps,
                    () async { final r = await _exec('pm list packages -3 | wc -l'); setState(() => _cmdOutput = 'Drittanbieter-Apps: $r'); }),
                ]),

                // Toggle-Settings
                _Section('System-Settings (Global)', [
                  _ToggleRow('enable_freeform_support', 'Freeform-Fenster', _settings['enable_freeform_support'] ?? '0',
                    () => _toggleSetting('enable_freeform_support', '1', '0')),
                  _ToggleRow('development_settings_enabled', 'Entwickleroptionen', _settings['development_settings_enabled'] ?? '0',
                    () => _toggleSetting('development_settings_enabled', '1', '0')),
                  _ToggleRow('stay_on_while_plugged_in', 'Bildschirm an (Laden)', _settings['stay_on_while_plugged_in'] ?? '0',
                    () => _toggleSetting('stay_on_while_plugged_in', '3', '0')),
                  _ToggleRow('animator_duration_scale', 'Animationen', _settings['animator_duration_scale'] ?? '1.0',
                    () => _toggleSetting('animator_duration_scale', '1.0', '0.0')),
                  _ToggleRow('transition_animation_scale', 'Uebergangs-Animationen', _settings['transition_animation_scale'] ?? '1.0',
                    () => _toggleSetting('transition_animation_scale', '1.0', '0.0')),
                  _ToggleRow('window_animation_scale', 'Fenster-Animationen', _settings['window_animation_scale'] ?? '1.0',
                    () => _toggleSetting('window_animation_scale', '1.0', '0.0')),
                ]),

                // System Properties (read-only)
                _Section('System Properties (${_props.length})', [
                  ..._props.entries.take(40).map((e) => _InfoRow(e.key, e.value)),
                  if (_props.length > 40)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('... und ${_props.length - 40} weitere',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                    ),
                ]),

                // Global Settings (read-only)
                _Section('Global Settings (${_settings.length})', [
                  ..._settings.entries.take(40).map((e) => _InfoRow(e.key, e.value)),
                  if (_settings.length > 40)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('... und ${_settings.length - 40} weitere',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                    ),
                ]),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widgets ---

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 160,
          child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis),
        ),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
          overflow: TextOverflow.ellipsis, maxLines: 2)),
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String settingKey, label, value;
  final VoidCallback onToggle;
  const _ToggleRow(this.settingKey, this.label, this.value, this.onToggle);
  @override
  Widget build(BuildContext context) {
    final isOn = value == '1' || value == '1.0' || value == '3';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))),
        Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontFamily: 'monospace')),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 36, height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isOn ? const Color(0xFF86BE43).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            ),
            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: isOn ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;
  const _ActionBtn(this.label, this.icon, this.onTap);
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _h = false;
  bool _running = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: _running ? null : () async {
          setState(() => _running = true);
          await widget.onTap();
          if (mounted) setState(() => _running = false);
        },
        child: Container(
          height: 30,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          ),
          child: Row(children: [
            Icon(widget.icon, color: Colors.white54, size: 14),
            const SizedBox(width: 8),
            Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            if (_running) ...[
              const Spacer(),
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: const Color(0xFF86BE43))),
            ],
          ]),
        ),
      ),
    );
  }
}
