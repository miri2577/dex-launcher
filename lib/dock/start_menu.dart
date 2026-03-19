import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../models/desktop_state.dart';
import '../windows/window_manager.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/context_menu.dart';

class StartMenu extends StatefulWidget {
  final List<AppInfo> apps;
  final void Function(AppInfo app) onAppTap;
  final VoidCallback onClose;

  const StartMenu({
    super.key,
    required this.apps,
    required this.onAppTap,
    required this.onClose,
  });

  @override
  State<StartMenu> createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSystemApps = false;
  AppCategory? _selectedCategory;
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  List<AppInfo> get _filteredApps {
    var apps = widget.apps;
    if (!_showSystemApps) {
      apps = apps.where((a) => !a.isSystemApp).toList();
    }
    if (_selectedCategory != null) {
      apps = apps.where((a) => a.category == _selectedCategory).toList();
    }
    if (_searchQuery.isEmpty) return apps;
    final query = _searchQuery.toLowerCase();
    return apps.where((app) =>
      app.name.toLowerCase().contains(query) ||
      app.packageName.toLowerCase().contains(query)
    ).toList();
  }

  /// Kategorien die tatsächlich Apps enthalten
  List<AppCategory> get _availableCategories {
    var apps = widget.apps;
    if (!_showSystemApps) {
      apps = apps.where((a) => !a.isSystemApp).toList();
    }
    final cats = apps.map((a) => a.category).toSet().toList();
    cats.sort((a, b) => a.index.compareTo(b.index));
    return cats;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_slideAnim),
      child: FadeTransition(
        opacity: _slideAnim,
        child: Container(
          width: 420,
          height: MediaQuery.of(context).size.height * 0.82,
          margin: const EdgeInsets.only(left: 12, bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0xF0202020),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search + Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Apps suchen...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.4), size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: _showSystemApps ? 'System-Apps ausblenden' : 'System-Apps anzeigen',
                      child: GestureDetector(
                        onTap: () => setState(() => _showSystemApps = !_showSystemApps),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _showSystemApps
                                ? Colors.blueAccent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            Icons.android,
                            color: _showSystemApps ? Colors.blueAccent : Colors.white.withValues(alpha: 0.4),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Eingebaute Tools
              if (_searchQuery.isEmpty)
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _MiniAppButton(
                        icon: Icons.folder, label: 'Dateien', color: Colors.amber,
                        onTap: () {
                          widget.onClose();
                          context.read<WindowManager>().openWindow(
                            appType: 'file_manager', title: 'Dateimanager',
                            icon: Icons.folder, size: const Size(550, 380),
                          );
                        },
                      ),
                      _MiniAppButton(
                        icon: Icons.language, label: 'Browser', color: Colors.blueAccent,
                        onTap: () {
                          widget.onClose();
                          context.read<WindowManager>().openWindow(
                            appType: 'browser', title: 'Browser',
                            icon: Icons.language, size: const Size(700, 450),
                          );
                        },
                      ),
                      _MiniAppButton(
                        icon: Icons.calculate, label: 'Rechner', color: Colors.tealAccent,
                        onTap: () {
                          widget.onClose();
                          context.read<WindowManager>().openWindow(
                            appType: 'calculator', title: 'Rechner',
                            icon: Icons.calculate, size: const Size(280, 380),
                          );
                        },
                      ),
                      _MiniAppButton(
                        icon: Icons.wifi, label: 'WLAN', color: Colors.lightBlueAccent,
                        onTap: () {
                          widget.onClose();
                          context.read<WindowManager>().openWindow(
                            appType: 'wifi_manager', title: 'WLAN',
                            icon: Icons.wifi, size: const Size(400, 420),
                          );
                        },
                      ),
                      _MiniAppButton(
                        icon: Icons.bluetooth, label: 'Bluetooth', color: Colors.blue,
                        onTap: () {
                          widget.onClose();
                          context.read<WindowManager>().openWindow(
                            appType: 'bluetooth_manager', title: 'Bluetooth',
                            icon: Icons.bluetooth, size: const Size(400, 400),
                          );
                        },
                      ),
                      _MiniAppButton(
                        icon: Icons.monitor_heart, label: 'System', color: Colors.greenAccent,
                        onTap: () {
                          widget.onClose();
                          context.read<WindowManager>().openWindow(
                            appType: 'system_monitor', title: 'Systemmonitor',
                            icon: Icons.monitor_heart, size: const Size(450, 350),
                          );
                        },
                      ),
                      _MiniAppButton(
                        icon: Icons.terminal, label: 'Terminal', color: Colors.green,
                        onTap: () {
                          widget.onClose();
                          context.read<WindowManager>().openWindow(
                            appType: 'terminal', title: 'Terminal',
                            icon: Icons.terminal, size: const Size(650, 400),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if (_searchQuery.isEmpty)
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              // Zuletzt verwendet
              if (_searchQuery.isEmpty && _selectedCategory == null)
                Consumer<DesktopState>(
                  builder: (context, state, _) {
                    final recent = state.recentApps.take(5).toList();
                    if (recent.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Text(
                            'Zuletzt verwendet',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                          ),
                        ),
                        SizedBox(
                          height: 62,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: recent.length,
                            itemBuilder: (context, index) {
                              final app = recent[index];
                              return GestureDetector(
                                onTap: () {
                                  widget.onAppTap(app);
                                },
                                child: Container(
                                  width: 56,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppIconWidget(app: app, size: 36),
                                      const SizedBox(height: 3),
                                      Text(
                                        app.name,
                                        style: const TextStyle(color: Colors.white60, fontSize: 9),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                      ],
                    );
                  },
                ),
              // Kategorie-Chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CategoryChip(
                      label: 'Alle',
                      icon: Icons.apps,
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    for (final cat in _availableCategories)
                      _CategoryChip(
                        label: cat.label,
                        icon: cat.icon,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() =>
                          _selectedCategory = _selectedCategory == cat ? null : cat,
                        ),
                      ),
                  ],
                ),
              ),
              // App count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filteredApps.length} Apps',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                    ),
                  ],
                ),
              ),
              // App Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = _filteredApps[index];
                    return _StartMenuItem(
                      app: app,
                      onTap: () => widget.onAppTap(app),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.isSelected
                  ? Colors.blueAccent.withValues(alpha: 0.3)
                  : _hovering
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
              border: widget.isSelected
                  ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isSelected ? Colors.blueAccent : Colors.white54,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isSelected ? Colors.blueAccent : Colors.white70,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAppButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniAppButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MiniAppButton> createState() => _MiniAppButtonState();
}

class _MiniAppButtonState extends State<_MiniAppButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _hovering ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 18),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartMenuItem extends StatefulWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const _StartMenuItem({required this.app, required this.onTap});

  @override
  State<_StartMenuItem> createState() => _StartMenuItemState();
}

class _StartMenuItemState extends State<_StartMenuItem> {
  bool _hovering = false;

  void _showContextMenu(Offset position) {
    final state = context.read<DesktopState>();
    ContextMenu.show(
      context: context,
      position: position,
      items: [
        ContextMenuItem(
          icon: Icons.open_in_new,
          label: 'Oeffnen',
          onTap: widget.onTap,
        ),
        if (state.freeformEnabled)
          ContextMenuItem(
            icon: Icons.picture_in_picture,
            label: 'Im Fenster oeffnen',
            onTap: () => state.launchAppFreeform(widget.app),
          ),
        if (state.freeformEnabled)
          ContextMenuItem(
            icon: Icons.fullscreen,
            label: 'Vollbild oeffnen',
            onTap: () => state.launchAppFullscreen(widget.app),
          ),
        ContextMenuItem(
          icon: widget.app.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          label: widget.app.isPinned ? 'Vom Dock entfernen' : 'An Dock anheften',
          onTap: () => state.togglePin(widget.app),
        ),
        ContextMenuItem(
          icon: widget.app.isOnDesktop ? Icons.desktop_access_disabled : Icons.desktop_windows,
          label: widget.app.isOnDesktop ? 'Vom Desktop entfernen' : 'Auf Desktop legen',
          onTap: () => state.toggleDesktop(widget.app),
        ),
        ContextMenuItem(
          icon: Icons.info_outline,
          label: 'App-Info',
          onTap: () => state.openAppInfo(widget.app),
        ),
        if (!widget.app.isSystemApp)
          ContextMenuItem(
            icon: Icons.delete_forever,
            label: 'Deinstallieren',
            onTap: () => state.uninstallApp(widget.app),
            isDanger: true,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox;
          _showContextMenu(box.localToGlobal(const Offset(40, 40)));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hovering ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconWidget(app: widget.app, size: 42),
              const SizedBox(height: 4),
              Text(
                widget.app.name,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
