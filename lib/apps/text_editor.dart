import 'dart:io';
import 'package:flutter/material.dart';

class TextEditorApp extends StatefulWidget {
  final String? filePath;
  final void Function(String title)? onTitleChanged;

  const TextEditorApp({super.key, this.filePath, this.onTitleChanged});

  @override
  State<TextEditorApp> createState() => _TextEditorAppState();
}

class _TextEditorAppState extends State<TextEditorApp> {
  final _controller = TextEditingController();
  String? _filePath;
  bool _modified = false;

  @override
  void initState() {
    super.initState();
    if (widget.filePath != null) _loadFile(widget.filePath!);
    _controller.addListener(() {
      if (!_modified) setState(() => _modified = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFile(String path) async {
    try {
      final content = await File(path).readAsString();
      if (!mounted) return;
      _controller.text = content;
      setState(() {
        _filePath = path;
        _modified = false;
      });
      widget.onTitleChanged?.call(path.split('/').last);
    } catch (e) {
      if (!mounted) return;
      setState(() => _modified = false);
    }
  }

  Future<void> _saveFile() async {
    if (_filePath == null) {
      _filePath = '/storage/emulated/0/Download/notiz_${DateTime.now().millisecondsSinceEpoch}.txt';
    }
    try {
      await File(_filePath!).writeAsString(_controller.text);
      if (!mounted) return;
      setState(() => _modified = false);
      widget.onTitleChanged?.call(_filePath!.split('/').last);
    } catch (_) {}
  }

  Future<void> _newFile() async {
    _controller.clear();
    setState(() {
      _filePath = null;
      _modified = false;
    });
    widget.onTitleChanged?.call('Neue Notiz');
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
                _ToolBtn(icon: Icons.note_add, tooltip: 'Neu', onTap: _newFile),
                _ToolBtn(icon: Icons.save, tooltip: 'Speichern', onTap: _saveFile),
                const SizedBox(width: 8),
                if (_filePath != null)
                  Expanded(
                    child: Text(
                      '${_filePath!.split('/').last}${_modified ? ' •' : ''}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'Neue Notiz${_modified ? ' •' : ''}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  ),
                Text(
                  '${_controller.text.split('\n').length} Zeilen',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                ),
              ],
            ),
          ),
          // Editor
          Expanded(
            child: TextField(keyboardType: TextInputType.none, 
              controller: _controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_ToolBtn> createState() => _ToolBtnState();
}

class _ToolBtnState extends State<_ToolBtn> {
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
