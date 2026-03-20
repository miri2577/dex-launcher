import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TerminalApp extends StatefulWidget {
  const TerminalApp({super.key});

  @override
  State<TerminalApp> createState() => _TerminalAppState();
}

class _TerminalAppState extends State<TerminalApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_TerminalLine> _lines = [];
  final List<String> _history = [];
  int _historyIndex = -1;
  String _cwd = '/storage/emulated/0';
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _addLine('DeX Terminal v1.0', _LineType.info);
    _addLine('Shell bereit. Tippe Befehle ein.', _LineType.info);
    _addLine('', _LineType.info);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addLine(String text, _LineType type) {
    _lines.add(_TerminalLine(text, type));
  }

  Future<void> _executeCommand(String input) async {
    if (input.trim().isEmpty) return;

    final command = input.trim();
    _history.add(command);
    _historyIndex = _history.length;

    setState(() {
      _addLine('\$ $command', _LineType.command);
      _running = true;
    });
    _inputController.clear();

    // Eingebaute Befehle
    if (command == 'clear') {
      setState(() {
        _lines.clear();
        _running = false;
      });
      return;
    }

    if (command.startsWith('cd ')) {
      final dir = command.substring(3).trim();
      final newDir = dir.startsWith('/')
          ? dir
          : '$_cwd/$dir';
      // Prüfen ob Verzeichnis existiert
      final result = await _channel.invokeMethod('executeCommand', {
        'command': 'cd "$newDir" && pwd',
      });
      final map = Map<String, dynamic>.from(result as Map);
      final stdout = (map['stdout'] as String? ?? '').trim();
      if (map['exitCode'] == 0 && stdout.isNotEmpty) {
        _cwd = stdout;
        setState(() {
          _addLine(stdout, _LineType.output);
          _running = false;
        });
      } else {
        setState(() {
          _addLine('cd: Verzeichnis nicht gefunden: $dir', _LineType.error);
          _running = false;
        });
      }
      _scrollToBottom();
      return;
    }

    // Normaler Befehl — im aktuellen Verzeichnis ausführen
    try {
      final result = await _channel.invokeMethod('executeCommand', {
        'command': 'cd "$_cwd" 2>/dev/null; $command',
      });
      final map = Map<String, dynamic>.from(result as Map);
      final stdout = (map['stdout'] as String? ?? '').trimRight();
      final stderr = (map['stderr'] as String? ?? '').trimRight();

      setState(() {
        if (stdout.isNotEmpty) {
          for (final line in stdout.split('\n')) {
            _addLine(line, _LineType.output);
          }
        }
        if (stderr.isNotEmpty) {
          for (final line in stderr.split('\n')) {
            _addLine(line, _LineType.error);
          }
        }
        _running = false;
      });
    } catch (e) {
      setState(() {
        _addLine('Fehler: $e', _LineType.error);
        _running = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // History zurück
      if (_history.isNotEmpty && _historyIndex > 0) {
        _historyIndex--;
        _inputController.text = _history[_historyIndex];
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // History vorwärts
      if (_historyIndex < _history.length - 1) {
        _historyIndex++;
        _inputController.text = _history[_historyIndex];
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      } else {
        _historyIndex = _history.length;
        _inputController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0C0C),
      child: Column(
        children: [
          // Output
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _lines.length,
                itemBuilder: (context, index) {
                  final line = _lines[index];
                  return Text(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                      color: switch (line.type) {
                        _LineType.command => const Color(0xFF86BE43),
                        _LineType.output => const Color(0xFFCCCCCC),
                        _LineType.error => Colors.redAccent,
                        _LineType.info => const Color(0xB386BE43),
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // Input
          Container(
            color: const Color(0xFF141414),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  '\$ ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: const Color(0xFF86BE43).withValues(alpha: 0.7),
                  ),
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: _handleKey,
                    child: TextField(keyboardType: TextInputType.none, 
                      controller: _inputController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (value) {
                        _executeCommand(value);
                        _focusNode.requestFocus();
                      },
                      enabled: !_running,
                    ),
                  ),
                ),
                if (_running)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: const Color(0xFF86BE43)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _LineType { command, output, error, info }

class _TerminalLine {
  final String text;
  final _LineType type;
  _TerminalLine(this.text, this.type);
}
