import '../theme/cinnamon_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../windows/window_manager.dart';

class FileManagerApp extends StatefulWidget {
  final String? initialPath;
  const FileManagerApp({super.key, this.initialPath});

  @override
  State<FileManagerApp> createState() => _FileManagerAppState();
}

class _FileManagerAppState extends State<FileManagerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');

  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _entries = [];
  bool _loading = true;
  bool _showHidden = false;
  bool _multiSelect = false;
  String? _error;
  String _sortBy = 'name'; // name, size, date, type

  // Clipboard für Kopieren/Verschieben
  String? _clipboardPath;
  bool _clipboardIsCut = false;

  // Selektion
  final Set<String> _selected = {};
  bool get _hasSelection => _selected.isNotEmpty;

  // Schnellzugriff
  static const _quickAccess = [
    ('/storage/emulated/0', 'Intern', Icons.phone_android),
    ('/storage/emulated/0/Download', 'Downloads', Icons.download),
    ('/storage/emulated/0/Pictures', 'Bilder', Icons.image),
    ('/storage/emulated/0/Music', 'Musik', Icons.music_note),
    ('/storage/emulated/0/Movies', 'Videos', Icons.movie),
    ('/storage/emulated/0/DCIM', 'Kamera', Icons.camera),
    ('/storage/emulated/0/Documents', 'Dokumente', Icons.description),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null) _currentPath = widget.initialPath!;
    _loadDirectory();
  }

  Future<void> _loadDirectory([String? path, bool isRetry = false]) async {
    final targetPath = path ?? _currentPath;
    setState(() { _loading = true; _error = null; _selected.clear(); });

    try {
      final dir = Directory(targetPath);
      if (!await dir.exists()) {
        if (!isRetry) {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) { _currentPath = extDir.path; _loadDirectory(null, true); return; }
        }
      }

      final entries = await dir.list().toList();
      entries.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
        switch (_sortBy) {
          case 'size':
            try { return b.statSync().size.compareTo(a.statSync().size); } catch (_) {}
            return 0;
          case 'date':
            try { return b.statSync().modified.compareTo(a.statSync().modified); } catch (_) {}
            return 0;
          case 'type':
            return a.path.split('.').last.compareTo(b.path.split('.').last);
          default:
            return a.path.split('/').last.toLowerCase().compareTo(
                  b.path.split('/').last.toLowerCase());
        }
      });

      setState(() {
        _currentPath = targetPath;
        _entries = entries.where((e) {
          if (_showHidden) return true;
          return !e.path.split('/').last.startsWith('.');
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Zugriff verweigert'; _loading = false; });
    }
  }

  Widget _buildBreadcrumb() {
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        // Root
        GestureDetector(
          onTap: () => _loadDirectory('/'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            child: Icon(Icons.computer, color: Colors.white.withValues(alpha: 0.4), size: 12),
          ),
        ),
        ...parts.asMap().entries.map((entry) {
          final i = entry.key;
          final part = entry.value;
          final path = '/${parts.sublist(0, i + 1).join('/')}';
          final isLast = i == parts.length - 1;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 14),
            GestureDetector(
              onTap: isLast ? null : () => _loadDirectory(path),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                child: Text(part,
                  style: TextStyle(
                    color: isLast ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ]);
        }),
      ],
    );
  }

  void _navigateUp() {
    final parent = Directory(_currentPath).parent.path;
    if (parent != _currentPath) _loadDirectory(parent);
  }

  static const _trashDir = '/storage/emulated/0/.trash';

  // Datei-Operationen — verschiebt in Papierkorb statt direkt löschen
  Future<void> _deleteSelected() async {
    final trashDir = Directory(_trashDir);
    if (!await trashDir.exists()) await trashDir.create(recursive: true);

    for (final path in _selected) {
      try {
        final name = path.split('/').last;
        final dest = '$_trashDir/${DateTime.now().millisecondsSinceEpoch}_$name';
        await File(path).rename(dest);
      } catch (_) {
        // Fallback: direkt löschen wenn Verschieben fehlschlägt
        try {
          final entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
              ? Directory(path) : File(path);
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }
    _selected.clear();
    _loadDirectory();
  }

  Future<void> _renameEntry(String oldPath) async {
    final name = oldPath.split('/').last;
    final controller = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.windowChromeUnfocused,
        title: const Text('Umbenennen', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: controller, autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true, fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text), child: const Text('OK')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != name) {
      try {
        final dir = Directory(_currentPath).path;
        await File(oldPath).rename('$dir/$newName');
      } catch (_) {}
      _loadDirectory();
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.windowChromeUnfocused,
        title: const Text('Neuer Ordner', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: controller, autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Name', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true, fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text), child: const Text('Erstellen')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try { await Directory('$_currentPath/$name').create(); } catch (_) {}
      _loadDirectory();
    }
  }

  void _copyToClipboard(String path, {bool cut = false}) {
    setState(() { _clipboardPath = path; _clipboardIsCut = cut; });
  }

  Future<void> _paste() async {
    if (_clipboardPath == null) return;
    final source = _clipboardPath!;
    final name = source.split('/').last;
    final dest = '$_currentPath/$name';

    try {
      if (_clipboardIsCut) {
        await File(source).rename(dest);
        _clipboardPath = null;
      } else {
        await File(source).copy(dest);
      }
    } catch (_) {}
    _loadDirectory();
  }

  void _openFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    final wm = context.read<WindowManager>();

    if (ext == 'apk') {
      _channel.invokeMethod('installApk', {'path': path});
    } else if ({'mp4', 'mkv', 'avi', 'mov', 'webm', 'ts', 'm4v'}.contains(ext)) {
      _channel.invokeMethod('playVideo', {'path': path});
    } else if ({'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'}.contains(ext)) {
      wm.openWindow(
        appType: 'image_viewer', title: path.split('/').last,
        icon: Icons.image, size: const Size(600, 450),
        initialData: {'path': path},
      );
    } else if ({'txt', 'log', 'md', 'json', 'xml', 'yaml', 'yml', 'sh', 'dart', 'kt', 'java', 'py', 'js', 'css', 'html', 'csv', 'cfg', 'conf', 'ini', 'properties'}.contains(ext)) {
      wm.openWindow(
        appType: 'text_editor', title: path.split('/').last,
        icon: Icons.edit_note, size: const Size(550, 400),
        initialData: {'path': path},
      );
    }
  }

  void _showFileContextMenu(Offset position, FileSystemEntity entry) {
    final name = entry.path.split('/').last;
    final isDir = entry is Directory;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    final items = <Widget>[
      if (!isDir) _ctxItem(Icons.open_in_new, 'Oeffnen', () { overlayEntry.remove(); _openFile(entry.path); }),
      _ctxItem(Icons.copy, 'Kopieren', () { overlayEntry.remove(); _copyToClipboard(entry.path); }),
      _ctxItem(Icons.content_cut, 'Ausschneiden', () { overlayEntry.remove(); _copyToClipboard(entry.path, cut: true); }),
      _ctxItem(Icons.edit, 'Umbenennen', () { overlayEntry.remove(); _renameEntry(entry.path); }),
      _ctxItem(Icons.delete, 'Loeschen', () {
        overlayEntry.remove();
        _selected.add(entry.path);
        _deleteSelected();
      }, danger: true),
    ];

    overlayEntry = OverlayEntry(
      builder: (_) => _ContextOverlay(
        position: position,
        items: items,
        onDismiss: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }

  Widget _ctxItem(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return _CtxMenuItem(icon: icon, label: label, onTap: onTap, danger: danger);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  IconData _iconForFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'bmp' || 'gif' => Icons.image,
      'mp4' || 'mkv' || 'avi' || 'mov' || 'webm' => Icons.movie,
      'mp3' || 'flac' || 'wav' || 'ogg' || 'aac' => Icons.music_note,
      'pdf' => Icons.picture_as_pdf,
      'apk' => Icons.android,
      'zip' || 'tar' || 'gz' || '7z' || 'rar' => Icons.archive,
      'txt' || 'log' || 'md' => Icons.description,
      'json' || 'xml' || 'yaml' || 'yml' => Icons.code,
      _ => Icons.insert_drive_file,
    };
  }

  String? _getFileSize(FileSystemEntity entry) {
    try { return _formatSize(entry.statSync().size); } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.panelBg,
      child: Column(
        children: [
          // Schnellzugriff
          Container(
            height: 28,
            color: const Color(0xFF202020),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: _quickAccess.map((q) {
                final (path, label, icon) = q;
                final active = _currentPath == path;
                return GestureDetector(
                  onTap: () => _loadDirectory(path),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, color: active ? Colors.white : Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 10)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          // Toolbar
          Container(
            height: 32,
            color: C.windowChromeUnfocused,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _ToolButton(icon: Icons.arrow_upward, tooltip: 'Hoch', onTap: _navigateUp),
                _ToolButton(icon: Icons.refresh, tooltip: 'Aktualisieren', onTap: () => _loadDirectory()),
                _ToolButton(
                  icon: _showHidden ? Icons.visibility : Icons.visibility_off,
                  tooltip: _showHidden ? 'Versteckte ausblenden' : 'Versteckte anzeigen',
                  onTap: () { _showHidden = !_showHidden; _loadDirectory(); },
                ),
                _ToolButton(icon: Icons.create_new_folder, tooltip: 'Neuer Ordner', onTap: _createFolder),
                _ToolButton(
                  icon: Icons.checklist,
                  tooltip: _multiSelect ? 'Einzelauswahl' : 'Mehrfachauswahl',
                  onTap: () => setState(() { _multiSelect = !_multiSelect; if (!_multiSelect) _selected.clear(); }),
                ),
                // Sortierung
                PopupMenuButton<String>(
                  onSelected: (v) { _sortBy = v; _loadDirectory(); },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'name', child: Text('Name')),
                    const PopupMenuItem(value: 'size', child: Text('Groesse')),
                    const PopupMenuItem(value: 'date', child: Text('Datum')),
                    const PopupMenuItem(value: 'type', child: Text('Typ')),
                  ],
                  child: Container(
                    width: 28, height: 28,
                    alignment: Alignment.center,
                    child: const Icon(Icons.sort, color: Colors.white70, size: 14),
                  ),
                ),
                if (_clipboardPath != null)
                  _ToolButton(icon: Icons.paste, tooltip: 'Einfuegen', onTap: _paste),
                if (_hasSelection) ...[
                  _ToolButton(icon: Icons.copy, tooltip: 'Kopieren', onTap: () {
                    _copyToClipboard(_selected.first);
                  }),
                  _ToolButton(icon: Icons.delete, tooltip: 'Loeschen', onTap: _deleteSelected),
                  Text('${_selected.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                ],
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _buildBreadcrumb(),
                  ),
                ),
              ],
            ),
          ),
          // Inhalt
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)))
                    : _entries.isEmpty
                        ? Center(child: Text('Ordner ist leer', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))
                        : ListView.builder(
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final name = entry.path.split('/').last;
                              final isDir = entry is Directory;
                              final ext = name.split('.').last.toLowerCase();
                              final isImage = {'jpg','jpeg','png','webp','bmp','gif'}.contains(ext);
                              return _FileRow(
                                name: name,
                                path: entry.path,
                                icon: isDir ? Icons.folder : _iconForFile(name),
                                iconColor: isDir ? Colors.amber : Colors.white54,
                                subtitle: isDir ? null : _getFileSize(entry),
                                selected: _selected.contains(entry.path),
                                isImage: isImage,
                                onTap: () {
                                  if (_multiSelect) {
                                    setState(() {
                                      if (_selected.contains(entry.path)) _selected.remove(entry.path);
                                      else _selected.add(entry.path);
                                    });
                                  } else if (isDir) { _loadDirectory(entry.path); }
                                  else { _openFile(entry.path); }
                                },
                                onSecondaryTap: (pos) => _showFileContextMenu(pos, entry),
                              );
                            },
                          ),
          ),
          // Statusleiste
          Container(
            height: 24,
            color: C.windowChromeUnfocused,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('${_entries.length} Elemente', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                if (_hasSelection) ...[
                  const SizedBox(width: 8),
                  Text('${_selected.length} ausgewaehlt', style: TextStyle(color: const Color(0xFF86BE43).withValues(alpha: 0.6), fontSize: 10)),
                ],
                const Spacer(),
                if (_clipboardPath != null)
                  Text(
                    '${_clipboardIsCut ? "Ausschneiden" : "Kopieren"}: ${_clipboardPath!.split('/').last}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                  ),
                if (_multiSelect)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('MULTI', style: TextStyle(color: const Color(0xFF86BE43).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Kontext-Menü Overlay
class _ContextOverlay extends StatelessWidget {
  final Offset position;
  final List<Widget> items;
  final VoidCallback onDismiss;
  const _ContextOverlay({required this.position, required this.items, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    var dx = position.dx;
    var dy = position.dy;
    if (dx + 180 > screen.width) dx = screen.width - 188;
    if (dy + items.length * 36 > screen.height) dy = screen.height - items.length * 36 - 8;

    return Stack(
      children: [
        Positioned.fill(child: GestureDetector(onTap: onDismiss, onSecondaryTap: onDismiss, child: Container(color: Colors.transparent))),
        Positioned(
          left: dx, top: dy,
          child: Container(
            width: 180,
            decoration: BoxDecoration(
              color: const Color(0xF0282828),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16)],
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),
      ],
    );
  }
}

class _CtxMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _CtxMenuItem({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  State<_CtxMenuItem> createState() => _CtxMenuItemState();
}

class _CtxMenuItemState extends State<_CtxMenuItem> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _h ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.danger ? Colors.redAccent : Colors.white70, size: 15),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(color: widget.danger ? Colors.redAccent : Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ToolButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 30, height: 30,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _h ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Icon(widget.icon, color: Colors.white70, size: 16),
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatefulWidget {
  final String name;
  final String path;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final bool selected;
  final bool isImage;
  final VoidCallback onTap;
  final void Function(Offset)? onSecondaryTap;

  const _FileRow({
    required this.name, required this.path, required this.icon, required this.iconColor,
    this.subtitle, this.selected = false, this.isImage = false,
    required this.onTap, this.onSecondaryTap,
  });

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: widget.onSecondaryTap != null
            ? (d) => widget.onSecondaryTap!(d.globalPosition) : null,
        onLongPressStart: widget.onSecondaryTap != null
            ? (d) => widget.onSecondaryTap!(d.globalPosition) : null,
        child: Container(
          height: widget.isImage ? 40 : 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: widget.selected
              ? const Color(0xFF86BE43).withValues(alpha: 0.15)
              : _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          child: Row(
            children: [
              // Thumbnail für Bilder
              if (widget.isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    width: 32, height: 32,
                    child: Image.file(File(widget.path), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(widget.icon, color: widget.iconColor, size: 18)),
                  ),
                )
              else
                Icon(widget.icon, color: widget.iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
              if (widget.subtitle != null)
                Text(widget.subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
