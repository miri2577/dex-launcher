import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClipboardManagerApp extends StatefulWidget {
  const ClipboardManagerApp({super.key});

  @override
  State<ClipboardManagerApp> createState() => _ClipboardManagerAppState();
}

class _ClipboardManagerAppState extends State<ClipboardManagerApp> {
  final List<String> _history = [];
  String? _current;

  @override
  void initState() {
    super.initState();
    _readClipboard();
  }

  Future<void> _readClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _current = data.text;
        if (!_history.contains(data.text)) {
          _history.insert(0, data.text!);
          if (_history.length > 20) _history.removeLast();
        }
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _current = text);
  }

  void _removeEntry(int index) {
    setState(() => _history.removeAt(index));
  }

  void _clearAll() {
    setState(() {
      _history.clear();
      _current = null;
    });
    Clipboard.setData(const ClipboardData(text: ''));
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
                const Icon(Icons.content_paste, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                const Text('Zwischenablage', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: _readClipboard,
                  child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearAll,
                  child: const Icon(Icons.delete_sweep, color: Colors.white38, size: 16),
                ),
              ],
            ),
          ),
          // Aktuell
          if (_current != null)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.content_copy, color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _current!,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Verlauf
          Expanded(
            child: _history.isEmpty
                ? Center(child: Text('Leer', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final text = _history[index];
                      final isCurrent = text == _current;
                      return _ClipRow(
                        text: text,
                        isCurrent: isCurrent,
                        onTap: () => _copyToClipboard(text),
                        onDelete: () => _removeEntry(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClipRow extends StatefulWidget {
  final String text;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ClipRow({required this.text, required this.isCurrent, required this.onTap, required this.onDelete});

  @override
  State<_ClipRow> createState() => _ClipRowState();
}

class _ClipRowState extends State<_ClipRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.isCurrent ? Colors.blueAccent : Colors.white,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_h)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.3), size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
