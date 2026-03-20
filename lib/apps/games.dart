import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../windows/window_manager.dart';

/// Games Hub — Übersicht aller Spiele
class GamesHubApp extends StatelessWidget {
  const GamesHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _GameTile('Snake', Icons.pest_control, 'snake', const Size(400, 400)),
          _GameTile('Tetris', Icons.grid_view, 'tetris', const Size(320, 480)),
          _GameTile('Minesweeper', Icons.flag, 'minesweeper', const Size(380, 420)),
          _GameTile('2048', Icons.looks_4, 'game_2048', const Size(340, 400)),
          const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text('DOS Klassiker (Browser)', style: TextStyle(color: Colors.white38, fontSize: 10))),
          _BrowserGameTile('DOOM', Icons.local_fire_department, 'https://dos.zone/doom-dec-1993/', const Size(750, 520)),
          _BrowserGameTile('Duke Nukem 3D', Icons.person, 'https://dos.zone/duke-nukem-3d-jan-29-1996/', const Size(750, 520)),
          _BrowserGameTile('Commander Keen 4', Icons.rocket_launch, 'https://dos.zone/commander-keen-4-secret-of-the-oracle-dec-15-1991/', const Size(700, 480)),
          _BrowserGameTile('Prince of Persia', Icons.shield, 'https://dos.zone/prince-of-persia-1990/', const Size(700, 480)),
          _BrowserGameTile('Wolfenstein 3D', Icons.military_tech, 'https://dos.zone/wolfenstein-3d-may-05-1992/', const Size(750, 520)),
          _BrowserGameTile('Pac-Man', Icons.circle, 'https://dos.zone/pac-man-1983/', const Size(650, 480)),
          const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text('Web Spiele', style: TextStyle(color: Colors.white38, fontSize: 10))),
          _BrowserGameTile('Wordle', Icons.abc, 'https://www.nytimes.com/games/wordle/index.html', const Size(500, 550)),
          _BrowserGameTile('Chess', Icons.grid_on, 'https://www.chess.com/play/computer', const Size(650, 550)),
          _BrowserGameTile('2048 Online', Icons.looks_4, 'https://play2048.co/', const Size(420, 550)),
        ],
      ),
    );
  }
}

class _GameTile extends StatefulWidget {
  final String name;
  final IconData icon;
  final String appType;
  final Size size;
  const _GameTile(this.name, this.icon, this.appType, this.size);
  @override
  State<_GameTile> createState() => _GameTileState();
}

class _BrowserGameTile extends StatefulWidget {
  final String name;
  final IconData icon;
  final String url;
  final Size size;
  const _BrowserGameTile(this.name, this.icon, this.url, this.size);
  @override
  State<_BrowserGameTile> createState() => _BrowserGameTileState();
}

class _BrowserGameTileState extends State<_BrowserGameTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => context.read<WindowManager>().openWindow(
          appType: 'browser_game', title: widget.name,
          icon: widget.icon, size: widget.size,
          initialData: {'url': widget.url},
        ),
        child: Container(
          height: 48, margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _h ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          ),
          child: Row(children: [
            Icon(widget.icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Spacer(),
            Icon(Icons.language, color: Colors.white.withValues(alpha: 0.2), size: 16),
          ]),
        ),
      ),
    );
  }
}

class _GameTileState extends State<_GameTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => context.read<WindowManager>().openWindow(
          appType: widget.appType, title: widget.name,
          icon: widget.icon, size: widget.size,
        ),
        child: Container(
          height: 48, margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _h ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          ),
          child: Row(children: [
            Icon(widget.icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Spacer(),
            Icon(Icons.play_arrow, color: Colors.white.withValues(alpha: 0.3), size: 18),
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// SNAKE
// ============================================================
class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});
  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const _gridSize = 20;
  static const _cellSize = 16.0;
  final _random = Random();
  List<Point<int>> _snake = [const Point(10, 10)];
  Point<int> _food = const Point(15, 15);
  Point<int> _dir = const Point(1, 0);
  Timer? _timer;
  bool _gameOver = false;
  int _score = 0;
  final _focusNode = FocusNode();

  @override
  void initState() { super.initState(); _start(); }
  @override
  void dispose() { _timer?.cancel(); _focusNode.dispose(); super.dispose(); }

  void _start() {
    _snake = [const Point(10, 10)];
    _dir = const Point(1, 0);
    _score = 0;
    _gameOver = false;
    _spawnFood();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _tick());
    _focusNode.requestFocus();
  }

  void _spawnFood() {
    _food = Point(_random.nextInt(_gridSize), _random.nextInt(_gridSize));
  }

  void _tick() {
    if (_gameOver || !mounted) return;
    final head = Point((_snake.first.x + _dir.x) % _gridSize, (_snake.first.y + _dir.y) % _gridSize);
    if (_snake.any((p) => p == head)) { setState(() => _gameOver = true); _timer?.cancel(); return; }
    setState(() {
      _snake.insert(0, head);
      if (head == _food) { _score += 10; _spawnFood(); }
      else { _snake.removeLast(); }
    });
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp: if (_dir.y != 1) _dir = const Point(0, -1);
      case LogicalKeyboardKey.arrowDown: if (_dir.y != -1) _dir = const Point(0, 1);
      case LogicalKeyboardKey.arrowLeft: if (_dir.x != 1) _dir = const Point(-1, 0);
      case LogicalKeyboardKey.arrowRight: if (_dir.x != -1) _dir = const Point(1, 0);
      case LogicalKeyboardKey.space: if (_gameOver) _start();
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode, autofocus: true, onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          color: const Color(0xFF0C0C0C),
          child: Column(children: [
            Container(height: 28, color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Text('Score: $_score', style: const TextStyle(color: Colors.white, fontSize: 12)),
                const Spacer(),
                if (_gameOver) const Text('GAME OVER — Leertaste', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
              ])),
            Expanded(child: Center(child: CustomPaint(
              size: Size(_gridSize * _cellSize, _gridSize * _cellSize),
              painter: _SnakePainter(_snake, _food, _gridSize, _cellSize),
            ))),
          ]),
        ),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final int grid;
  final double cell;
  _SnakePainter(this.snake, this.food, this.grid, this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    for (int x = 0; x < grid; x++) for (int y = 0; y < grid; y++) {
      canvas.drawRect(Rect.fromLTWH(x * cell + 0.5, y * cell + 0.5, cell - 1, cell - 1), gridPaint);
    }
    // Food
    canvas.drawRect(Rect.fromLTWH(food.x * cell, food.y * cell, cell, cell), Paint()..color = Colors.redAccent);
    // Snake
    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final brightness = 1.0 - (i / snake.length) * 0.5;
      canvas.drawRect(Rect.fromLTWH(p.x * cell, p.y * cell, cell, cell),
        Paint()..color = Colors.greenAccent.withValues(alpha: brightness));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================
// 2048
// ============================================================
class Game2048 extends StatefulWidget {
  const Game2048({super.key});
  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  List<List<int>> _grid = List.generate(4, (_) => List.filled(4, 0));
  int _score = 0;
  bool _gameOver = false;
  final _focusNode = FocusNode();
  final _random = Random();

  @override
  void initState() { super.initState(); _start(); }
  @override
  void dispose() { _focusNode.dispose(); super.dispose(); }

  void _start() {
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _score = 0; _gameOver = false;
    _addTile(); _addTile();
    _focusNode.requestFocus();
  }

  void _addTile() {
    final empty = <Point<int>>[];
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) if (_grid[r][c] == 0) empty.add(Point(r, c));
    if (empty.isEmpty) return;
    final p = empty[_random.nextInt(empty.length)];
    _grid[p.x][p.y] = _random.nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> _merge(List<int> row) {
    final filtered = row.where((v) => v != 0).toList();
    final result = <int>[];
    int i = 0;
    while (i < filtered.length) {
      if (i + 1 < filtered.length && filtered[i] == filtered[i + 1]) {
        result.add(filtered[i] * 2);
        _score += filtered[i] * 2;
        i += 2;
      } else { result.add(filtered[i]); i++; }
    }
    while (result.length < 4) result.add(0);
    return result;
  }

  void _move(int dr, int dc) {
    if (_gameOver) return;
    final old = _grid.map((r) => List<int>.from(r)).toList();

    if (dc != 0) { // Links/Rechts
      for (int r = 0; r < 4; r++) {
        var row = List<int>.from(_grid[r]);
        if (dc > 0) row = row.reversed.toList();
        row = _merge(row);
        if (dc > 0) row = row.reversed.toList();
        _grid[r] = row;
      }
    } else { // Hoch/Runter
      for (int c = 0; c < 4; c++) {
        var col = [_grid[0][c], _grid[1][c], _grid[2][c], _grid[3][c]];
        if (dr > 0) col = col.reversed.toList();
        col = _merge(col);
        if (dr > 0) col = col.reversed.toList();
        for (int r = 0; r < 4; r++) _grid[r][c] = col[r];
      }
    }

    bool changed = false;
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) if (_grid[r][c] != old[r][c]) changed = true;
    if (changed) { _addTile(); _checkGameOver(); }
    setState(() {});
  }

  void _checkGameOver() {
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) {
      if (_grid[r][c] == 0) return;
      if (c < 3 && _grid[r][c] == _grid[r][c + 1]) return;
      if (r < 3 && _grid[r][c] == _grid[r + 1][c]) return;
    }
    _gameOver = true;
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp: _move(-1, 0);
      case LogicalKeyboardKey.arrowDown: _move(1, 0);
      case LogicalKeyboardKey.arrowLeft: _move(0, -1);
      case LogicalKeyboardKey.arrowRight: _move(0, 1);
      case LogicalKeyboardKey.keyR: _start();
      default: break;
    }
  }

  Color _tileColor(int val) => switch (val) {
    2 => const Color(0xFF4A4A4A), 4 => const Color(0xFF5A5A3A),
    8 => const Color(0xFF6B5B3A), 16 => const Color(0xFF7B4B2A),
    32 => const Color(0xFF8B3B2A), 64 => const Color(0xFF9B2B1A),
    128 => const Color(0xFF6B6B1A), 256 => const Color(0xFF5B7B1A),
    512 => const Color(0xFF4B8B2A), 1024 => const Color(0xFF3B7B4A),
    2048 => const Color(0xFFDAA520), _ => const Color(0xFF3A3A3A),
  };

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode, autofocus: true, onKeyEvent: _onKey,
      child: Container(
        color: const Color(0xFF0C0C0C),
        child: Column(children: [
          Container(height: 28, color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Text('Score: $_score', style: const TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              if (_gameOver) const Text('GAME OVER — R=Restart', style: TextStyle(color: Colors.redAccent, fontSize: 11))
              else const Text('R=Restart', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
          Expanded(child: Center(child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
            child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(4, (r) =>
              Row(mainAxisSize: MainAxisSize.min, children: List.generate(4, (c) {
                final val = _grid[r][c];
                return Container(
                  width: 60, height: 60, margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: _tileColor(val), borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: val > 0 ? Text('$val', style: TextStyle(
                    color: Colors.white, fontSize: val >= 1024 ? 14 : val >= 100 ? 18 : 22, fontWeight: FontWeight.w600,
                  )) : null,
                );
              })),
            )),
          ))),
        ]),
      ),
    );
  }
}

// ============================================================
// MINESWEEPER
// ============================================================
class MinesweeperGame extends StatefulWidget {
  const MinesweeperGame({super.key});
  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  static const _rows = 10, _cols = 10, _mines = 15;
  late List<List<int>> _grid; // -1=mine, 0-8=count
  late List<List<bool>> _revealed, _flagged;
  bool _gameOver = false, _won = false;
  final _random = Random();

  @override
  void initState() { super.initState(); _start(); }

  void _start() {
    _grid = List.generate(_rows, (_) => List.filled(_cols, 0));
    _revealed = List.generate(_rows, (_) => List.filled(_cols, false));
    _flagged = List.generate(_rows, (_) => List.filled(_cols, false));
    _gameOver = false; _won = false;
    // Minen setzen
    int placed = 0;
    while (placed < _mines) {
      final r = _random.nextInt(_rows), c = _random.nextInt(_cols);
      if (_grid[r][c] != -1) { _grid[r][c] = -1; placed++; }
    }
    // Zahlen berechnen
    for (int r = 0; r < _rows; r++) for (int c = 0; c < _cols; c++) {
      if (_grid[r][c] == -1) continue;
      int count = 0;
      for (int dr = -1; dr <= 1; dr++) for (int dc = -1; dc <= 1; dc++) {
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols && _grid[nr][nc] == -1) count++;
      }
      _grid[r][c] = count;
    }
    setState(() {});
  }

  void _reveal(int r, int c) {
    if (_gameOver || _won || _revealed[r][c] || _flagged[r][c]) return;
    _revealed[r][c] = true;
    if (_grid[r][c] == -1) { _gameOver = true; setState(() {}); return; }
    if (_grid[r][c] == 0) {
      for (int dr = -1; dr <= 1; dr++) for (int dc = -1; dc <= 1; dc++) {
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols) _reveal(nr, nc);
      }
    }
    // Win check
    int unrevealed = 0;
    for (int r2 = 0; r2 < _rows; r2++) for (int c2 = 0; c2 < _cols; c2++) if (!_revealed[r2][c2]) unrevealed++;
    if (unrevealed == _mines) _won = true;
    setState(() {});
  }

  void _toggleFlag(int r, int c) {
    if (_revealed[r][c] || _gameOver || _won) return;
    setState(() => _flagged[r][c] = !_flagged[r][c]);
  }

  Color _numColor(int n) => [Colors.transparent, Colors.blue, Colors.green, Colors.red, Colors.purple,
    Colors.brown, Colors.cyan, Colors.black, Colors.grey][n.clamp(0, 8)];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0C0C),
      child: Column(children: [
        Container(height: 28, color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('Minen: $_mines', style: const TextStyle(color: Colors.white, fontSize: 12)),
            const Spacer(),
            if (_gameOver) GestureDetector(onTap: _start, child: const Text('BOOM — Nochmal', style: TextStyle(color: Colors.redAccent, fontSize: 11)))
            else if (_won) GestureDetector(onTap: _start, child: const Text('GEWONNEN! — Nochmal', style: TextStyle(color: Colors.greenAccent, fontSize: 11)))
            else GestureDetector(onTap: _start, child: const Text('Neu', style: TextStyle(color: Colors.white38, fontSize: 10))),
          ])),
        Expanded(child: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_rows, (r) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_cols, (c) {
              final revealed = _revealed[r][c];
              final flagged = _flagged[r][c];
              final val = _grid[r][c];
              return GestureDetector(
                onTap: () => _reveal(r, c),
                onSecondaryTap: () => _toggleFlag(r, c),
                onLongPress: () => _toggleFlag(r, c),
                child: Container(
                  width: 28, height: 28, margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: revealed
                        ? (val == -1 ? Colors.red.withValues(alpha: 0.5) : const Color(0xFF2A2A2A))
                        : const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.center,
                  child: revealed
                      ? (val == -1 ? const Text('💣', style: TextStyle(fontSize: 14))
                          : val > 0 ? Text('$val', style: TextStyle(color: _numColor(val), fontSize: 12, fontWeight: FontWeight.w600)) : null)
                      : flagged ? const Text('🚩', style: TextStyle(fontSize: 12)) : null,
                ),
              );
            }),
          )),
        ))),
      ]),
    );
  }
}

// ============================================================
// TETRIS
// ============================================================
class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});
  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  static const _rows = 20, _cols = 10, _cellSize = 18.0;
  late List<List<int>> _board;
  List<Point<int>> _piece = [];
  int _pieceType = 0;
  Point<int> _pos = const Point(0, 3);
  Timer? _timer;
  int _score = 0;
  bool _gameOver = false;
  final _focusNode = FocusNode();
  final _random = Random();

  static const _pieces = [
    [Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1)], // O
    [Point(0, 0), Point(0, 1), Point(0, 2), Point(0, 3)], // I
    [Point(0, 0), Point(1, 0), Point(1, 1), Point(1, 2)], // J
    [Point(0, 2), Point(1, 0), Point(1, 1), Point(1, 2)], // L
    [Point(0, 1), Point(0, 2), Point(1, 0), Point(1, 1)], // S
    [Point(0, 0), Point(0, 1), Point(1, 1), Point(1, 2)], // Z
    [Point(0, 1), Point(1, 0), Point(1, 1), Point(1, 2)], // T
  ];

  @override
  void initState() { super.initState(); _start(); }
  @override
  void dispose() { _timer?.cancel(); _focusNode.dispose(); super.dispose(); }

  void _start() {
    _board = List.generate(_rows, (_) => List.filled(_cols, 0));
    _score = 0; _gameOver = false;
    _spawnPiece();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    _focusNode.requestFocus();
  }

  void _spawnPiece() {
    _pieceType = _random.nextInt(_pieces.length);
    _piece = _pieces[_pieceType].map((p) => Point(p.x, p.y)).toList();
    _pos = const Point(0, 3);
    if (!_canPlace(_piece, _pos)) { _gameOver = true; _timer?.cancel(); }
  }

  bool _canPlace(List<Point<int>> piece, Point<int> pos) {
    for (final p in piece) {
      final r = pos.x + p.x, c = pos.y + p.y;
      if (r < 0 || r >= _rows || c < 0 || c >= _cols) return false;
      if (_board[r][c] != 0) return false;
    }
    return true;
  }

  void _lock() {
    for (final p in _piece) { _board[_pos.x + p.x][_pos.y + p.y] = _pieceType + 1; }
    // Reihen löschen
    int cleared = 0;
    for (int r = _rows - 1; r >= 0; r--) {
      if (_board[r].every((c) => c != 0)) {
        _board.removeAt(r); _board.insert(0, List.filled(_cols, 0));
        cleared++; r++;
      }
    }
    _score += cleared * 100;
    _spawnPiece();
  }

  void _tick() { if (_gameOver || !mounted) return; _moveDown(); }

  void _moveDown() {
    final newPos = Point(_pos.x + 1, _pos.y);
    if (_canPlace(_piece, newPos)) { setState(() => _pos = newPos); }
    else { _lock(); setState(() {}); }
  }

  void _moveLeft() {
    final np = Point(_pos.x, _pos.y - 1);
    if (_canPlace(_piece, np)) setState(() => _pos = np);
  }

  void _moveRight() {
    final np = Point(_pos.x, _pos.y + 1);
    if (_canPlace(_piece, np)) setState(() => _pos = np);
  }

  void _rotate() {
    final rotated = _piece.map((p) => Point(p.y, -p.x + 2)).toList();
    if (_canPlace(rotated, _pos)) setState(() => _piece = rotated);
  }

  void _drop() {
    while (_canPlace(_piece, Point(_pos.x + 1, _pos.y))) { _pos = Point(_pos.x + 1, _pos.y); }
    _lock(); setState(() {});
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_gameOver) { if (event.logicalKey == LogicalKeyboardKey.space) _start(); return; }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft: _moveLeft();
      case LogicalKeyboardKey.arrowRight: _moveRight();
      case LogicalKeyboardKey.arrowDown: _moveDown();
      case LogicalKeyboardKey.arrowUp: _rotate();
      case LogicalKeyboardKey.space: _drop();
      default: break;
    }
  }

  static const _colors = [
    Color(0xFF2A2A2A), Color(0xFFFFD700), Color(0xFF00CED1), Color(0xFF1E90FF),
    Color(0xFFFF8C00), Color(0xFF32CD32), Color(0xFFFF4500), Color(0xFF9370DB),
  ];

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode, autofocus: true, onKeyEvent: _onKey,
      child: Container(
        color: const Color(0xFF0C0C0C),
        child: Column(children: [
          Container(height: 28, color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Text('Score: $_score', style: const TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              if (_gameOver) const Text('GAME OVER — Leertaste', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
            ])),
          Expanded(child: Center(child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(_rows, (r) =>
              Row(mainAxisSize: MainAxisSize.min, children: List.generate(_cols, (c) {
                int val = _board[r][c];
                // Aktuelles Stück zeichnen
                for (final p in _piece) {
                  if (_pos.x + p.x == r && _pos.y + p.y == c) val = _pieceType + 1;
                }
                return Container(width: _cellSize, height: _cellSize,
                  decoration: BoxDecoration(
                    color: _colors[val.clamp(0, _colors.length - 1)],
                    border: val > 0 ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5) : null,
                  ),
                );
              })),
            )),
          ))),
        ]),
      ),
    );
  }
}

// ============================================================
// Browser-Spiel im Kiosk-Modus (WebView fullscreen, keine Toolbar)
// ============================================================
class BrowserGameApp extends StatefulWidget {
  final String url;
  final String title;
  const BrowserGameApp({super.key, required this.url, required this.title});
  @override
  State<BrowserGameApp> createState() => _BrowserGameAppState();
}

class _BrowserGameAppState extends State<BrowserGameApp> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() => _loading = true); },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          _controller.runJavaScript("document.addEventListener('focusin',function(e){if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA')e.target.setAttribute('inputmode','none');});");
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
        ],
      ),
    );
  }
}
