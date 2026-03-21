import '../theme/cinnamon_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class TrashApp extends StatefulWidget {
  const TrashApp({super.key});
  @override
  State<TrashApp> createState() => _TrashAppState();
}

class _TrashAppState extends State<TrashApp> {
  static const _trashDir = '/storage/emulated/0/.trash';
  List<FileSystemEntity> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dir = Directory(_trashDir);
      if (!await dir.exists()) { await dir.create(recursive: true); }
      final items = await dir.list().toList();
      items.sort((a, b) => b.path.compareTo(a.path));
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore(FileSystemEntity item) async {
    try {
      final name = item.path.split('/').last;
      // Entferne Timestamp-Prefix
      final origName = name.contains('_') ? name.substring(name.indexOf('_') + 1) : name;
      final dest = '/storage/emulated/0/Download/$origName';
      await File(item.path).rename(dest);
      _load();
    } catch (_) {}
  }

  Future<void> _deletePermanently(FileSystemEntity item) async {
    try {
      if (item is Directory) { await item.delete(recursive: true); }
      else { await item.delete(); }
      _load();
    } catch (_) {}
  }

  Future<void> _emptyTrash() async {
    try {
      final dir = Directory(_trashDir);
      if (await dir.exists()) {
        await for (final item in dir.list()) {
          if (item is Directory) { await item.delete(recursive: true); }
          else { await item.delete(); }
        }
      }
      _load();
    } catch (_) {}
  }

  String _formatSize(FileSystemEntity item) {
    try {
      final bytes = item.statSync().size;
      if (bytes > 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
      if (bytes > 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
      return '$bytes B';
    } catch (_) { return ''; }
  }

  String _displayName(String path) {
    final name = path.split('/').last;
    if (name.contains('_')) return name.substring(name.indexOf('_') + 1);
    return name;
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
              const Icon(Icons.delete_outline, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text('${_items.length} Elemente', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              if (_items.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                      backgroundColor: C.windowChromeUnfocused,
                      title: const Text('Papierkorb leeren?', style: TextStyle(color: Colors.white, fontSize: 14)),
                      content: Text('${_items.length} Elemente endgueltig loeschen?',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Abbrechen')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Leeren', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ));
                    if (confirm == true) _emptyTrash();
                  },
                  child: const Text('Leeren', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              const SizedBox(width: 8),
              GestureDetector(onTap: _load, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _items.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.delete_outline, color: Colors.white.withValues(alpha: 0.15), size: 48),
                        const SizedBox(height: 8),
                        Text('Papierkorb ist leer', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          final name = _displayName(item.path);
                          final isDir = item is Directory;
                          return _TrashRow(
                            name: name, isDir: isDir, size: _formatSize(item),
                            onRestore: () => _restore(item),
                            onDelete: () => _deletePermanently(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TrashRow extends StatefulWidget {
  final String name; final bool isDir; final String size;
  final VoidCallback onRestore, onDelete;
  const _TrashRow({required this.name, required this.isDir, required this.size,
    required this.onRestore, required this.onDelete});
  @override State<_TrashRow> createState() => _TrashRowState();
}

class _TrashRowState extends State<_TrashRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: Container(
      height: 34, margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
        color: _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
      child: Row(children: [
        Icon(widget.isDir ? Icons.folder : Icons.insert_drive_file, color: Colors.white38, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(widget.name, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
        Text(widget.size, style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10)),
        if (_h) ...[
          const SizedBox(width: 8),
          GestureDetector(onTap: widget.onRestore,
            child: const Tooltip(message: 'Wiederherstellen', child: Icon(Icons.restore, color: Colors.greenAccent, size: 16))),
          const SizedBox(width: 6),
          GestureDetector(onTap: widget.onDelete,
            child: const Tooltip(message: 'Endgueltig loeschen', child: Icon(Icons.delete_forever, color: Colors.redAccent, size: 16))),
        ],
      ]),
    ),
  );
}
