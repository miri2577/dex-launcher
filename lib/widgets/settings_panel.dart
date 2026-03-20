import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/desktop_state.dart';
import '../services/system_status_service.dart';
import '../desktop/desktop_background.dart';

class SettingsPanel extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsPanel({super.key, required this.onClose});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  List<String>? _wallpaperImages;

  @override
  void initState() {
    super.initState();
    _loadWallpaperImages();
  }

  Future<void> _loadWallpaperImages() async {
    try {
      final state = context.read<DesktopState>();
      final images = await state.appService.getWallpaperImages();
      if (mounted) setState(() => _wallpaperImages = images);
    } catch (_) {}
  }

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
                  onPressed: widget.onClose,
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
                  // Quick Settings
                  _SectionTitle('Schnelleinstellungen'),
                  const SizedBox(height: 8),
                  Consumer<SystemStatusService>(
                    builder: (context, service, _) => _QuickSettings(status: service.status),
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle('Hintergrund'),
                  const SizedBox(height: 8),
                  // Gradient Wallpapers
                  _WallpaperSelector(
                    currentIndex: state.customWallpaperPath == null ? state.wallpaperIndex : -1,
                    onSelect: state.setWallpaper,
                  ),
                  const SizedBox(height: 8),
                  // Eigene Bilder
                  if (_wallpaperImages != null && _wallpaperImages!.isNotEmpty) ...[
                    Text('Eigene Bilder', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                    const SizedBox(height: 6),
                    _ImageWallpaperSelector(
                      images: _wallpaperImages!,
                      selectedPath: state.customWallpaperPath,
                      onSelect: state.setCustomWallpaper,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Bild-Pfad manuell eingeben
                  GestureDetector(
                    onTap: () async {
                      final controller = TextEditingController(
                        text: state.customWallpaperPath ?? '/storage/emulated/0/Pictures/',
                      );
                      final path = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF252525),
                          title: const Text('Bild-Pfad eingeben', style: TextStyle(color: Colors.white, fontSize: 14)),
                          content: TextField(
                            controller: controller, autofocus: true,
                            keyboardType: TextInputType.none,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              hintText: '/storage/emulated/0/Pictures/bild.jpg',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                              filled: true, fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (v) => Navigator.of(ctx).pop(v),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text), child: const Text('Setzen')),
                          ],
                        ),
                      );
                      if (path != null && path.isNotEmpty) {
                        state.setCustomWallpaper(path);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.image_search, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        const Text('Bild-Pfad eingeben...', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const Spacer(),
                        if (state.customWallpaperPath != null)
                          GestureDetector(
                            onTap: () => state.setWallpaper(state.wallpaperIndex), // Reset
                            child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.3), size: 14),
                          ),
                      ]),
                    ),
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
                  const SizedBox(height: 12),
                  Consumer<SystemStatusService>(
                    builder: (context, service, _) => _InfoTile(
                      icon: service.status.hasExternalMouse ? Icons.mouse : Icons.gamepad,
                      label: 'Cursor',
                      value: service.status.hasExternalMouse ? 'System-Maus' : 'D-Pad Cursor',
                    ),
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle('Desktop-Widgets'),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.access_time,
                    label: 'Uhr',
                    value: state.isWidgetActive('clock'),
                    onChanged: (_) => state.toggleWidget('clock'),
                  ),
                  const SizedBox(height: 6),
                  _ToggleTile(
                    icon: Icons.calendar_month,
                    label: 'Kalender',
                    value: state.isWidgetActive('calendar'),
                    onChanged: (_) => state.toggleWidget('calendar'),
                  ),
                  const SizedBox(height: 6),
                  _ToggleTile(
                    icon: Icons.monitor_heart,
                    label: 'System-Status',
                    value: state.isWidgetActive('system'),
                    onChanged: (_) => state.toggleWidget('system'),
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle('Bildschirmschoner'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.nightlight, color: Colors.white70, size: 20),
                        const SizedBox(width: 12),
                        const Text('Nach', style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: state.screensaverTimeout,
                          dropdownColor: const Color(0xFF303030),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem(value: 0, child: Text('Aus')),
                            const DropdownMenuItem(value: 1, child: Text('1 Min')),
                            const DropdownMenuItem(value: 5, child: Text('5 Min')),
                            const DropdownMenuItem(value: 10, child: Text('10 Min')),
                            const DropdownMenuItem(value: 30, child: Text('30 Min')),
                          ],
                          onChanged: (v) => state.setScreensaverTimeout(v ?? 0),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle('Erscheinungsbild'),
                  const SizedBox(height: 8),
                  _AccentColorPicker(
                    currentColor: state.accentColor,
                    onSelect: state.setAccentColor,
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle('Tastenkuerzel'),
                  const SizedBox(height: 8),
                  _InfoTile(icon: Icons.keyboard, label: 'Alt + Tab', value: 'App wechseln'),
                  _InfoTile(icon: Icons.keyboard, label: 'Escape', value: 'Panel schliessen'),

                  const SizedBox(height: 24),
                  _SectionTitle('Info'),
                  const SizedBox(height: 8),
                  _InfoTile(icon: Icons.info_outline, label: 'DeX Launcher', value: 'v1.1.0'),
                  _InfoTile(icon: Icons.apps, label: 'Installierte Apps', value: '${state.allApps.length}'),
                  _InfoTile(icon: Icons.push_pin, label: 'Gepinnte Apps', value: '${state.pinnedApps.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSettings extends StatelessWidget {
  final SystemStatus status;
  const _QuickSettings({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Volume Slider
          Row(
            children: [
              Icon(status.volumeIcon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.blueAccent,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: status.volumePercent.toDouble().clamp(0, 100),
                    min: 0,
                    max: 100,
                    onChanged: (v) {
                      context.read<DesktopState>().appService.setVolume(v.toInt());
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${status.volumePercent}%',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickTile(
                icon: status.networkIcon,
                label: status.ethernetConnected
                    ? 'Ethernet'
                    : status.wifiConnected
                        ? status.wifiName ?? 'WLAN'
                        : 'Kein Netz',
                active: status.hasNetwork,
              ),
              if (status.hasBattery)
                _QuickTile(
                  icon: status.batteryIcon,
                  label: '${status.batteryLevel}%',
                  active: true,
                  color: status.batteryColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;

  const _QuickTile({
    required this.icon,
    required this.label,
    this.active = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? (active ? Colors.blueAccent : Colors.white38), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: wallpaperGradients.length,
      itemBuilder: (context, index) {
        final isSelected = index == currentIndex;
        return GestureDetector(
          onTap: () => onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: wallpaperGradients[index],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          );
        },
      );
  }
}

class _ImageWallpaperSelector extends StatelessWidget {
  final List<String> images;
  final String? selectedPath;
  final ValueChanged<String> onSelect;

  const _ImageWallpaperSelector({
    required this.images,
    this.selectedPath,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final path = images[index];
        final isSelected = path == selectedPath;
        return GestureDetector(
          onTap: () => onSelect(path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade900,
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
            ),
          );
        },
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

class _AccentColorPicker extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onSelect;

  const _AccentColorPicker({required this.currentColor, required this.onSelect});

  static const _colors = [
    Color(0xFF448AFF), Color(0xFF2196F3), Color(0xFF00BCD4),
    Color(0xFF009688), Color(0xFF4CAF50), Color(0xFF8BC34A),
    Color(0xFFFF9800), Color(0xFFFF5722), Color(0xFFF44336),
    Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF607D8B),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _colors.map((color) {
        final isSelected = color.toARGB32() == currentColor.toARGB32();
        return GestureDetector(
          onTap: () => onSelect(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
