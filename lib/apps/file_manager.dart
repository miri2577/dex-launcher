import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({super.key});

  @override
  State<FileManagerApp> createState() => _FileManagerAppState();
}

class _FileManagerAppState extends State<FileManagerApp> {
  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _entries = [];
  bool _loading = true;
  bool _showHidden = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory([String? path]) async {
    final targetPath = path ?? _currentPath;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dir = Directory(targetPath);
      if (!await dir.exists()) {
        // Fallback
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          _currentPath = extDir.path;
          _loadDirectory();
          return;
        }
      }

      final entries = await dir.list().toList();
      entries.sort((a, b) {
        // Ordner zuerst, dann alphabetisch
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
        return a.path.split('/').last.toLowerCase().compareTo(
              b.path.split('/').last.toLowerCase(),
            );
      });

      setState(() {
        _currentPath = targetPath;
        _entries = entries.where((e) {
          if (_showHidden) return true;
          final name = e.path.split('/').last;
          return !name.startsWith('.');
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Zugriff verweigert: $targetPath';
        _loading = false;
      });
    }
  }

  void _navigateUp() {
    final parent = Directory(_currentPath).parent.path;
    if (parent != _currentPath) {
      _loadDirectory(parent);
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _ToolButton(
                  icon: Icons.arrow_upward,
                  tooltip: 'Ordner hoch',
                  onTap: _navigateUp,
                ),
                _ToolButton(
                  icon: Icons.refresh,
                  tooltip: 'Aktualisieren',
                  onTap: () => _loadDirectory(),
                ),
                _ToolButton(
                  icon: _showHidden ? Icons.visibility : Icons.visibility_off,
                  tooltip: _showHidden ? 'Versteckte ausblenden' : 'Versteckte anzeigen',
                  onTap: () {
                    _showHidden = !_showHidden;
                    _loadDirectory();
                  },
                ),
                const SizedBox(width: 8),
                // Pfad-Anzeige
                Expanded(
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _currentPath,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    ? Center(
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      )
                    : _entries.isEmpty
                        ? Center(
                            child: Text(
                              'Ordner ist leer',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final name = entry.path.split('/').last;
                              final isDir = entry is Directory;

                              return _FileRow(
                                name: name,
                                icon: isDir ? Icons.folder : _iconForFile(name),
                                iconColor: isDir ? Colors.amber : Colors.white54,
                                subtitle: isDir ? null : _getFileSize(entry),
                                onTap: () {
                                  if (isDir) {
                                    _loadDirectory(entry.path);
                                  }
                                },
                              );
                            },
                          ),
          ),
          // Statusleiste
          Container(
            height: 24,
            color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  '${_entries.length} Elemente',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getFileSize(FileSystemEntity entry) {
    try {
      final stat = entry.statSync();
      return _formatSize(stat.size);
    } catch (_) {
      return null;
    }
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _hovering ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
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
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final VoidCallback onTap;

  const _FileRow({
    required this.name,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    required this.onTap,
  });

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: _hovering ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
