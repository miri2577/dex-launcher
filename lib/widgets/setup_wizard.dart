import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/desktop_state.dart';
import '../models/builtin_apps.dart';

class SetupWizard extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupWizard({super.key, required this.onComplete});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedWallpaper = 0;
  final Set<String> _selectedDockApps = {'file_manager', 'browser'};

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    final state = context.read<DesktopState>();
    // Apply wallpaper selection
    state.setWallpaper(_selectedWallpaper);
    // Apply dock pins
    for (final app in builtinApps) {
      final shouldPin = _selectedDockApps.contains(app.id);
      final isCurrentlyPinned = state.isToolPinned(app.id);
      if (shouldPin && !isCurrentlyPinned) {
        state.toggleToolPin(app.id);
      } else if (!shouldPin && isCurrentlyPinned) {
        state.toggleToolPin(app.id);
      }
    }
    // Mark setup as complete
    state.storage.setupComplete = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 48, right: 48),
            child: Row(
              children: List.generate(_totalPages, (i) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= _currentPage
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildWelcomePage(),
                _buildWallpaperPage(),
                _buildDockPage(),
                _buildDonePage(),
              ],
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 48, right: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0 && _currentPage < _totalPages - 1)
                  TextButton(
                    onPressed: _back,
                    child: const Text('Zurueck',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                  )
                else
                  const SizedBox(width: 80),
                if (_currentPage < _totalPages - 1)
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Weiter', style: TextStyle(fontSize: 15)),
                  )
                else
                  ElevatedButton(
                    onPressed: _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF448AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child:
                        const Text('Starten', style: TextStyle(fontSize: 15)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.desktop_windows, color: Colors.white54, size: 72),
          const SizedBox(height: 24),
          const Text(
            'Willkommen bei DeX Launcher',
            style: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 12),
          Text(
            'Richte deinen Desktop in wenigen Schritten ein.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperPage() {
    const wallpaperNames = [
      'Dunkel',
      'Blau',
      'Gradient',
      'Abstrakt',
      'Natur',
    ];
    const wallpaperColors = [
      Color(0xFF0D1B2A),
      Color(0xFF1A237E),
      Color(0xFF1B5E20),
      Color(0xFF4A148C),
      Color(0xFF004D40),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Hintergrund waehlen',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(wallpaperColors.length, (i) {
              final selected = _selectedWallpaper == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedWallpaper = i),
                child: Container(
                  width: 120,
                  height: 75,
                  decoration: BoxDecoration(
                    color: wallpaperColors[i],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          const Icon(Icons.check, color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          wallpaperNames[i],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDockPage() {
    // Show a subset of popular built-in apps to pin
    const popularIds = [
      'file_manager',
      'browser',
      'terminal',
      'calculator',
      'system_monitor',
      'music_player',
      'text_editor',
      'image_viewer',
      'weather',
      'games',
    ];

    final popularApps =
        builtinApps.where((a) => popularIds.contains(a.id)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Apps fuer das Dock auswaehlen',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 8),
          Text(
            'Diese Apps erscheinen in der Taskleiste.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: popularApps.map((app) {
              final selected = _selectedDockApps.contains(app.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedDockApps.remove(app.id);
                    } else {
                      _selectedDockApps.add(app.id);
                    }
                  });
                },
                child: Container(
                  width: 100,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? Colors.white54 : Colors.white12,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(app.icon,
                          color: selected ? Colors.white : Colors.white38,
                          size: 28),
                      const SizedBox(height: 6),
                      Text(
                        app.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white38,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonePage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.greenAccent, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Alles bereit!',
            style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 12),
          Text(
            'Dein Desktop ist eingerichtet. Du kannst alles spaeter in den Einstellungen aendern.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
