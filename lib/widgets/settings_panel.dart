import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/desktop_state.dart';
import '../desktop/desktop_background.dart';

class SettingsPanel extends StatelessWidget {
  final VoidCallback onClose;

  const SettingsPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      margin: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xF0202020),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                const Text(
                  'Einstellungen',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Consumer<DesktopState>(
              builder: (context, state, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionTitle('Hintergrund'),
                  const SizedBox(height: 8),
                  _WallpaperSelector(
                    currentIndex: state.wallpaperIndex,
                    onSelect: state.setWallpaper,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Desktop'),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.grid_view,
                    label: 'Desktop-Icons anzeigen',
                    value: state.showDesktopIcons,
                    onChanged: state.setShowDesktopIcons,
                  ),
                  const SizedBox(height: 12),
                  _SliderTile(
                    icon: Icons.photo_size_select_large,
                    label: 'Icon-Groesse',
                    value: state.iconSize,
                    min: 32,
                    max: 72,
                    onChanged: state.setIconSize,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Fenstermodus'),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.picture_in_picture_alt,
                    label: 'Freeform-Fenster',
                    value: state.freeformEnabled,
                    onChanged: (value) async {
                      if (value && !state.freeformEnabled) {
                        final success = await state.enableFreeform();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Freeform konnte nicht aktiviert werden.\n'
                                'Bitte per ADB: adb shell settings put global enable_freeform_support 1',
                              ),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  if (state.freeformEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        'Apps werden in verschiebbaren Fenstern gestartet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (!state.freeformEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        'ADB: adb shell settings put global enable_freeform_support 1',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  if (state.runningWindows.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.window,
                      label: 'Offene Fenster',
                      value: '${state.runningWindows.length}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionTitle('Info'),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.info_outline,
                    label: 'DeX Launcher',
                    value: 'v1.0.0',
                  ),
                  _InfoTile(
                    icon: Icons.apps,
                    label: 'Installierte Apps',
                    value: '${state.allApps.length}',
                  ),
                  _InfoTile(
                    icon: Icons.push_pin,
                    label: 'Gepinnte Apps',
                    value: '${state.pinnedApps.length}',
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _WallpaperSelector extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _WallpaperSelector({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: wallpaperGradients.length,
        itemBuilder: (context, index) {
          final isSelected = index == currentIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: wallpaperGradients[index],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              Text(
                '${value.round()}px',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.blueAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        ],
      ),
    );
  }
}
