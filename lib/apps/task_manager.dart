import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});
  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  List<Map<String, dynamic>> _processes = [];
  Timer? _timer;

  @override
  void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load()); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final r = await _channel.invokeMethod('getRunningApps');
      if (!mounted) return;
      setState(() => _processes = (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {}
  }

  Future<void> _kill(String pkg) async {
    await _channel.invokeMethod('killApp', {'packageName': pkg});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Container(
            height: 32, color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Icon(Icons.memory, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text('${_processes.length} Prozesse', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              GestureDetector(onTap: _load, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
            ]),
          ),
          // Header
          Container(
            height: 24, color: const Color(0xFF202020),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Expanded(flex: 3, child: Text('Prozess', style: TextStyle(color: Colors.white38, fontSize: 9))),
              const SizedBox(width: 50, child: Text('RAM', style: TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.right)),
              const SizedBox(width: 40),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _processes.length,
              itemBuilder: (context, i) {
                final p = _processes[i];
                final name = (p['name'] as String).split(':').first.split('.').last;
                final mem = p['memoryMB'] as int? ?? 0;
                return _ProcRow(name: name, fullName: p['name'] as String, memMB: mem, onKill: () => _kill(p['name'] as String));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcRow extends StatefulWidget {
  final String name, fullName;
  final int memMB;
  final VoidCallback onKill;
  const _ProcRow({required this.name, required this.fullName, required this.memMB, required this.onKill});
  @override
  State<_ProcRow> createState() => _ProcRowState();
}

class _ProcRowState extends State<_ProcRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: _h ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        child: Row(children: [
          Expanded(flex: 3, child: Tooltip(message: widget.fullName,
            child: Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis))),
          SizedBox(width: 50, child: Text('${widget.memMB} MB',
            style: TextStyle(color: widget.memMB > 100 ? Colors.amber : Colors.white54, fontSize: 10), textAlign: TextAlign.right)),
          SizedBox(width: 40, child: _h ? GestureDetector(onTap: widget.onKill,
            child: const Icon(Icons.close, color: Colors.redAccent, size: 14)) : const SizedBox()),
        ]),
      ),
    );
  }
}
