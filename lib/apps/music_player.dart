import '../theme/cinnamon_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MusicPlayerApp extends StatefulWidget {
  const MusicPlayerApp({super.key});
  @override
  State<MusicPlayerApp> createState() => _MusicPlayerAppState();
}

class _MusicPlayerAppState extends State<MusicPlayerApp> {
  static const _channel = MethodChannel('com.dexlauncher/apps');
  List<Map<String, dynamic>> _tracks = [];
  int? _playingIndex;

  @override
  void initState() { super.initState(); _loadTracks(); }

  Future<void> _loadTracks() async {
    try {
      final r = await _channel.invokeMethod('getAudioFiles');
      if (!mounted) return;
      setState(() => _tracks = (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {}
  }

  Future<void> _play(int index) async {
    final path = _tracks[index]['path'] as String;
    try {
      // Öffne mit System-Player
      final intent = {'path': path};
      await _channel.invokeMethod('playVideo', intent); // playVideo funktioniert auch für Audio
      setState(() => _playingIndex = index);
    } catch (_) {}
  }

  String _formatSize(int bytes) {
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
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
              const Icon(Icons.music_note, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text('${_tracks.length} Titel', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              GestureDetector(onTap: _loadTracks, child: const Icon(Icons.refresh, color: Colors.white38, size: 14)),
            ]),
          ),
          Expanded(
            child: _tracks.isEmpty
                ? Center(child: Text('Keine Musik gefunden\n(Music / Download)', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))
                : ListView.builder(
                    itemCount: _tracks.length,
                    itemBuilder: (context, i) {
                      final t = _tracks[i];
                      final playing = _playingIndex == i;
                      return _TrackRow(
                        name: t['name'] as String,
                        size: _formatSize(t['size'] as int? ?? 0),
                        playing: playing,
                        onTap: () => _play(i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatefulWidget {
  final String name, size;
  final bool playing;
  final VoidCallback onTap;
  const _TrackRow({required this.name, required this.size, required this.playing, required this.onTap});
  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
          color: _h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          child: Row(children: [
            Icon(widget.playing ? Icons.play_arrow : Icons.music_note,
              color: widget.playing ? Colors.blueAccent : Colors.white54, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.name,
              style: TextStyle(color: widget.playing ? Colors.blueAccent : Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
            Text(widget.size, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
