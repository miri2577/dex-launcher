import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../models/builtin_apps.dart';
import '../models/desktop_state.dart';
import '../windows/window_manager.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/context_menu.dart';

class StartMenu extends StatefulWidget {
  final List<AppInfo> apps;
  final void Function(AppInfo app) onAppTap;
  final VoidCallback onClose;

  const StartMenu({super.key, required this.apps, required this.onAppTap, required this.onClose});

  @override
  State<StartMenu> createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSystemApps = false;

  List<AppInfo> get _filteredApps {
    var apps = widget.apps;
    if (!_showSystemApps) apps = apps.where((a) => !a.isSystemApp).toList();
    if (_searchQuery.isEmpty) return apps;
    final q = _searchQuery.toLowerCase();
    return apps.where((a) => a.name.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTool(BuildContext context, BuiltinApp tool) {
    widget.onClose();
    context.read<WindowManager>().openWindow(
      appType: tool.id, title: tool.name, icon: tool.icon, size: tool.defaultSize,
    );
  }

  void _openWebApp(BuildContext context, String title, String url) {
    widget.onClose();
    context.read<WindowManager>().openWindow(
      appType: 'browser', title: title, icon: Icons.language,
      size: const Size(700, 450), initialData: {'url': url},
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      width: 320,
      height: screenH * 0.85,
      margin: const EdgeInsets.only(left: 8, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xF0181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24)],
      ),
      child: Column(
        children: [
          // Suche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Suchen...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.3), size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _showSystemApps = !_showSystemApps),
                  child: Icon(Icons.android, size: 18,
                    color: _showSystemApps ? Colors.blueAccent : Colors.white24),
                ),
              ],
            ),
          ),

          // Inhalt — eine einzige scrollbare Liste
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              children: [
                // Tools
                if (_searchQuery.isEmpty) ...[
                  _SectionHeader('Tools'),
                  ...builtinApps.map((tool) => _ListItem(
                    icon: tool.icon, label: tool.name,
                    onTap: () => _openTool(context, tool),
                    onSecondaryTap: (pos) {
                      final state = context.read<DesktopState>();
                      final pinned = state.isToolPinned(tool.id);
                      ContextMenu.show(context: context, position: pos, items: [
                        ContextMenuItem(icon: Icons.open_in_new, label: 'Oeffnen', onTap: () => _openTool(context, tool)),
                        ContextMenuItem(
                          icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
                          label: pinned ? 'Vom Dock entfernen' : 'An Dock anheften',
                          onTap: () => state.toggleToolPin(tool.id),
                        ),
                      ]);
                    },
                  )),

                  _SectionHeader('Google'),
                  _ListItem(icon: Icons.search, label: 'Google Suche',
                    onTap: () { widget.onClose(); context.read<WindowManager>().openWindow(
                      appType: 'browser', title: 'Google', icon: Icons.language, size: const Size(700, 450)); }),
                  _ListItem(icon: Icons.cloud, label: 'Google Drive',
                    onTap: () => _openWebApp(context, 'Drive', 'https://drive.google.com')),
                  _ListItem(icon: Icons.description, label: 'Google Docs',
                    onTap: () => _openWebApp(context, 'Docs', 'https://docs.google.com')),
                  _ListItem(icon: Icons.table_chart, label: 'Google Sheets',
                    onTap: () => _openWebApp(context, 'Sheets', 'https://sheets.google.com')),
                  _ListItem(icon: Icons.mail, label: 'Gmail',
                    onTap: () => _openWebApp(context, 'Gmail', 'https://mail.google.com')),
                  _ListItem(icon: Icons.play_circle, label: 'YouTube',
                    onTap: () => _openWebApp(context, 'YouTube', 'https://www.youtube.com')),
                  _ListItem(icon: Icons.map, label: 'Google Maps',
                    onTap: () => _openWebApp(context, 'Maps', 'https://maps.google.com')),
                ],

                // Android Apps
                _SectionHeader('${_filteredApps.length} Apps'),
                ..._filteredApps.map((app) => _AppListItem(
                  app: app,
                  onTap: () => widget.onAppTap(app),
                )),
              ],
            ),
          ),

          // Power-Bereich unten
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('DeX Launcher', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    widget.onClose();
                    context.read<WindowManager>().openWindow(
                      appType: 'system_monitor', title: 'System',
                      icon: Icons.monitor_heart, size: const Size(450, 350),
                    );
                  },
                  child: Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.3), size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sektion Header ---
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Text(title,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

// --- Listen-Item (Tool/Google) ---
class _ListItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final void Function(Offset)? onSecondaryTap;

  const _ListItem({required this.icon, required this.label, required this.onTap, this.onSecondaryTap});

  @override
  State<_ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: widget.onSecondaryTap != null ? (d) => widget.onSecondaryTap!(d.globalPosition) : null,
        child: Container(
          height: 32,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _h ? Colors.white.withValues(alpha: 0.07) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white70, size: 16),
              const SizedBox(width: 10),
              Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- App Listen-Item ---
class _AppListItem extends StatefulWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const _AppListItem({required this.app, required this.onTap});

  @override
  State<_AppListItem> createState() => _AppListItemState();
}

class _AppListItemState extends State<_AppListItem> {
  bool _h = false;

  void _showContextMenu(Offset pos) {
    final state = context.read<DesktopState>();
    ContextMenu.show(context: context, position: pos, items: [
      ContextMenuItem(icon: Icons.open_in_new, label: 'Oeffnen', onTap: widget.onTap),
      ContextMenuItem(
        icon: widget.app.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        label: widget.app.isPinned ? 'Vom Dock entfernen' : 'An Dock anheften',
        onTap: () => state.togglePin(widget.app),
      ),
      ContextMenuItem(
        icon: widget.app.isOnDesktop ? Icons.desktop_access_disabled : Icons.desktop_windows,
        label: widget.app.isOnDesktop ? 'Vom Desktop entfernen' : 'Auf Desktop',
        onTap: () => state.toggleDesktop(widget.app),
      ),
      ContextMenuItem(icon: Icons.info_outline, label: 'App-Info', onTap: () => state.openAppInfo(widget.app)),
      if (!widget.app.isSystemApp)
        ContextMenuItem(icon: Icons.delete_forever, label: 'Deinstallieren',
          onTap: () => state.uninstallApp(widget.app), isDanger: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (d) => _showContextMenu(d.globalPosition),
        onLongPressStart: (d) => _showContextMenu(d.globalPosition),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _h ? Colors.white.withValues(alpha: 0.07) : Colors.transparent,
          ),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: AppIconWidget(app: widget.app, size: 24)),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.app.name, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
              if (widget.app.isPinned)
                Icon(Icons.push_pin, color: Colors.white.withValues(alpha: 0.15), size: 12),
            ],
          ),
        ),
      ),
    );
  }
}
