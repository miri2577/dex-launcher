import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../models/desktop_state.dart';
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
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  List<AppInfo> get _filteredApps {
    var apps = widget.apps;
    if (!_showSystemApps) {
      apps = apps.where((a) => !a.isSystemApp).toList();
    }
    if (_searchQuery.isEmpty) return apps;
    final query = _searchQuery.toLowerCase();
    return apps.where((app) =>
      app.name.toLowerCase().contains(query) ||
      app.packageName.toLowerCase().contains(query)
    ).toList();
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
          width: 480,
          height: 520,
          margin: const EdgeInsets.only(left: 16, bottom: 4),
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
