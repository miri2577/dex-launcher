import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoPlayerApp extends StatefulWidget {
  final String? filePath;
  final void Function(String title)? onTitleChanged;

  const VideoPlayerApp({super.key, this.filePath, this.onTitleChanged});

  @override
  State<VideoPlayerApp> createState() => _VideoPlayerAppState();
}

class _VideoPlayerAppState extends State<VideoPlayerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  List<String> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final extensions = {'.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v', '.ts'};
    final dirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/DCIM',
    ];

    final files = <String>[];
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      await for (final entity in dir.list()) {
        if (entity is File) {
          final ext = '.${entity.path.split('.').last.toLowerCase()}';
          if (extensions.contains(ext)) {
            files.add(entity.path);
          }
        }
      }
    }

    files.sort((a, b) => b.compareTo(a)); // Neueste zuerst
    if (!mounted) return;
    setState(() => _videos = files);
  }

  Future<void> _playVideo(String path) async {
    // Android Intent zum Abspielen
    try {
      await _channel.invokeMethod('playVideo', {'path': path});
    } catch (_) {}
  }

  String _fileName(String path) => path.split('/').last;
  String _fileSize(String path) {
    try {
      final bytes = File(path).lengthSync();
      if (bytes > 1073741824) return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
      if (bytes > 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Container(
            height: 36,
            color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.movie, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                const Text('Videos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text('${_videos.length} Dateien',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            child: _videos.isEmpty
                ? Center(child: Text('Keine Videos gefunden',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))
                : ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final path = _videos[index];
                      return _VideoRow(
                        name: _fileName(path),
                        size: _fileSize(path),
                        onTap: () => _playVideo(path),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VideoRow extends StatefulWidget {
  final String name;
  final String size;
  final VoidCallback onTap;
  const _VideoRow({required this.name, required this.size, required this.onTap});

  @override
  State<_VideoRow> createState() => _VideoRowState();
}

class _VideoRowState extends State<_VideoRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, color: Colors.white54, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
              Text(widget.size, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
