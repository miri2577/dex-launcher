import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AboutApp extends StatefulWidget {
  const AboutApp({super.key});
  @override
  State<AboutApp> createState() => _AboutAppState();
}

class _AboutAppState extends State<AboutApp> {
  String? _latestVersion;
  bool _checking = false;

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    try {
      final response = await http.get(Uri.parse(
        'https://api.github.com/repos/miri2577/dex-launcher/releases/latest'));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _latestVersion = data['tag_name'] as String?;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const Row(children: [
            Icon(Icons.desktop_windows, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DeX Launcher', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300)),
              Text('v2.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 20),

          _InfoLine('Beschreibung', 'Samsung DeX-inspirierte Desktop-Umgebung fuer Android TV'),
          _InfoLine('Framework', 'Flutter / Dart'),
          _InfoLine('Mini-Apps', '25 eingebaute Anwendungen'),
          _InfoLine('Spiele', '4 native + 9 Browser-Spiele'),
          _InfoLine('Design', 'Linux Mint Cinnamon (Mint-Y-Dark)'),
          _InfoLine('Repository', 'github.com/miri2577/dex-launcher'),
          _InfoLine('Lizenz', 'MIT'),

          const SizedBox(height: 20),

          // Update Check
          Row(children: [
            GestureDetector(
              onTap: _checking ? null : _checkUpdate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF86BE43).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_checking)
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: const Color(0xFF86BE43)))
                  else
                    const Icon(Icons.update, color: const Color(0xFF86BE43), size: 14),
                  const SizedBox(width: 6),
                  const Text('Update pruefen', style: TextStyle(color: const Color(0xFF86BE43), fontSize: 11)),
                ]),
              ),
            ),
            if (_latestVersion != null) ...[
              const SizedBox(width: 12),
              Text(
                _latestVersion == 'v2.0.0' ? 'Aktuell!' : 'Neu: $_latestVersion',
                style: TextStyle(
                  color: _latestVersion == 'v2.0.0' ? Colors.greenAccent : Colors.amber,
                  fontSize: 11,
                ),
              ),
            ],
          ]),

          const Spacer(),

          // Credits
          Text('Entwickelt mit Claude Code',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10)),
          const SizedBox(height: 4),
          Text('2026 Mirko Richter',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label, value;
  const _InfoLine(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 11))),
    ]),
  );
}
