import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerApp extends StatefulWidget {
  final String? initialPath;
  final void Function(String title)? onTitleChanged;

  const ImageViewerApp({super.key, this.initialPath, this.onTitleChanged});

  @override
  State<ImageViewerApp> createState() => _ImageViewerAppState();
}

class _ImageViewerAppState extends State<ImageViewerApp> {
  List<String> _images = [];
  int _currentIndex = 0;
  double _scale = 1.0;
  String _scanPath = '/storage/emulated/0/Pictures';

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null) {
      _scanPath = File(widget.initialPath!).parent.path;
    }
    _loadImages();
  }

  Future<void> _loadImages() async {
    final dir = Directory(_scanPath);
    if (!await dir.exists()) return;

    final extensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'};
    final files = <String>[];

    await for (final entity in dir.list()) {
      if (entity is File) {
        final ext = entity.path.split('.').last.toLowerCase();
        if (extensions.contains('.$ext')) {
          files.add(entity.path);
        }
      }
    }

    files.sort();
    setState(() {
      _images = files;
      if (widget.initialPath != null) {
        _currentIndex = files.indexOf(widget.initialPath!).clamp(0, files.length - 1);
      }
      _updateTitle();
    });
  }

  void _updateTitle() {
    if (_images.isNotEmpty) {
      widget.onTitleChanged?.call(_images[_currentIndex].split('/').last);
    }
  }

  void _next() {
    if (_images.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _images.length;
      _scale = 1.0;
      _updateTitle();
    });
  }

  void _prev() {
    if (_images.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _images.length) % _images.length;
      _scale = 1.0;
      _updateTitle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0C0C),
      child: _images.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported, color: Colors.white.withValues(alpha: 0.2), size: 48),
                  const SizedBox(height: 8),
                  Text('Keine Bilder in $_scanPath',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                ],
              ),
            )
          : Stack(
              children: [
                // Bild
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.file(
                      File(_images[_currentIndex]),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white24, size: 48),
                      ),
                    ),
                  ),
                ),
                // Navigation
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 36,
                    color: Colors.black.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _prev,
                          child: const Icon(Icons.chevron_left, color: Colors.white70, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1} / ${_images.length}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _next,
                          child: const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
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
