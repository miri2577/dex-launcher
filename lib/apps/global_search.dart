import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/desktop_state.dart';
import '../windows/window_manager.dart';
import '../widgets/app_icon_widget.dart';

class GlobalSearchApp extends StatefulWidget {
  const GlobalSearchApp({super.key});
  @override
  State<GlobalSearchApp> createState() => _GlobalSearchAppState();
}

class _GlobalSearchAppState extends State<GlobalSearchApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _fileResults = [];
  bool _searching = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _search(String query) async {
    if (query.length < 2) { setState(() => _fileResults = []); return; }
    setState(() => _searching = true);
    try {
      final r = await _channel.invokeMethod('searchFiles', {'query': query});
      if (!mounted) return;
      setState(() {
        _fileResults = (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _searching = false;
      });
    } catch (_) { if (mounted) setState(() => _searching = false); }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DesktopState>();
    final query = _controller.text.toLowerCase();
    final appResults = query.length >= 2
        ? state.allApps.where((a) => a.name.toLowerCase().contains(query)).take(10).toList()
        : [];

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Suchfeld
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF252525),
            child: TextField(keyboardType: TextInputType.none, 
              controller: _controller, autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Apps, Dateien, alles durchsuchen...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                filled: true, fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (v) { setState(() {}); _search(v); },
            ),
          ),
          // Ergebnisse
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(6),
              children: [
                if (appResults.isNotEmpty) ...[
                  _Header('Apps (${appResults.length})'),
                  ...appResults.map((app) => _ResultRow(
                    icon: SizedBox(width: 20, height: 20, child: AppIconWidget(app: app, size: 20)),
                    label: app.name,
                    subtitle: app.packageName,
                    onTap: () { state.launchApp(app); },
                  )),
                ],
                if (_fileResults.isNotEmpty) ...[
                  _Header('Dateien (${_fileResults.length})'),
                  ..._fileResults.map((f) => _ResultRow(
                    icon: Icon(f['isDir'] == 'true' ? Icons.folder : Icons.insert_drive_file, color: Colors.white54, size: 16),
                    label: f['name'] as String,
                    subtitle: f['path'] as String,
                    onTap: () {
                      if (f['isDir'] == 'true') {
                        context.read<WindowManager>().openWindow(
                          appType: 'file_manager', title: f['name'] as String,
                          icon: Icons.folder, size: const Size(550, 380),
                          initialData: {'path': f['path']},
                        );
                      }
                    },
                  )),
                ],
                if (_searching)
                  const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                if (!_searching && query.length >= 2 && appResults.isEmpty && _fileResults.isEmpty)
                  Padding(padding: const EdgeInsets.all(20),
                    child: Center(child: Text('Keine Ergebnisse', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _ResultRow extends StatefulWidget {
  final Widget icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _ResultRow({required this.icon, required this.label, required this.subtitle, required this.onTap});
  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36, margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
            color: _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
          child: Row(children: [
            widget.icon, const SizedBox(width: 8),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis),
                Text(widget.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 9), overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}
