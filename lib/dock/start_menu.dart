import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/cinnamon_theme.dart';
import '../models/app_info.dart';
import '../models/builtin_apps.dart';
import '../models/desktop_state.dart';
import '../windows/window_manager.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/context_menu.dart';

/// Cinnamon-Style Startmenü: Kategorien links, Inhalt rechts
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
  String _activeCategory = 'favoriten';
  bool _showSystemApps = false;

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<AppInfo> get _filteredApps {
    var apps = widget.apps;
    if (!_showSystemApps) apps = apps.where((a) => !a.isSystemApp).toList();
    if (_searchQuery.isEmpty) return apps;
    final q = _searchQuery.toLowerCase();
    return apps.where((a) => a.name.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q)).toList();
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

  void _launchOrWeb(BuildContext context, String pkg, String title, String url) {
    widget.onClose();
    final state = context.read<DesktopState>();
    final app = state.allApps.where((a) => a.packageName == pkg).firstOrNull;
    if (app != null) { state.launchApp(app); }
    else { _openWebApp(context, title, url); }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      width: 480,
      height: screenH * 0.82,
      margin: const EdgeInsets.only(left: 8, bottom: 4),
      decoration: BoxDecoration(
        color: C.menuBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Suche oben
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(children: [
              Expanded(child: Container(
                height: 30,
                decoration: BoxDecoration(color: C.inputBg, borderRadius: BorderRadius.circular(4)),
                child: TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.none,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Suchen...', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.25), size: 16),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 9), isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              )),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _showSystemApps = !_showSystemApps),
                child: Icon(Icons.android, size: 16, color: _showSystemApps ? Colors.greenAccent : Colors.white24),
              ),
            ]),
          ),

          // Hauptbereich: Kategorien links, Inhalt rechts
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : Row(
                    children: [
                      // Kategorien-Sidebar
                      Container(
                        width: 140,
                        color: C.sidebarBg,
                        child: Column(
                          children: [
                            Expanded(child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: [
                                _CatButton(label: 'Favoriten', icon: Icons.star, active: _activeCategory == 'favoriten', onTap: () => setState(() => _activeCategory = 'favoriten')),
                                _CatButton(label: 'System-Tools', icon: Icons.build, active: _activeCategory == 'tools', onTap: () => setState(() => _activeCategory = 'tools')),
                                _CatButton(label: 'Internet', icon: Icons.language, active: _activeCategory == 'internet', onTap: () => setState(() => _activeCategory = 'internet')),
                                _CatButton(label: 'Multimedia', icon: Icons.movie, active: _activeCategory == 'multimedia', onTap: () => setState(() => _activeCategory = 'multimedia')),
                                _CatButton(label: 'Spiele', icon: Icons.sports_esports, active: _activeCategory == 'spiele', onTap: () => setState(() => _activeCategory = 'spiele')),
                                _CatButton(label: 'Google', icon: Icons.cloud, active: _activeCategory == 'google', onTap: () => setState(() => _activeCategory = 'google')),
                                _CatButton(label: 'Streaming', icon: Icons.live_tv, active: _activeCategory == 'streaming', onTap: () => setState(() => _activeCategory = 'streaming')),
                                _CatButton(label: 'Alle Apps', icon: Icons.apps, active: _activeCategory == 'alle', onTap: () => setState(() => _activeCategory = 'alle')),
                              ],
                            )),
                            // Power-Buttons unten with labels
                            Container(
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                _PowerBtn(Icons.bedtime, 'Standby', () {
                                  widget.onClose();
                                  const MethodChannel('com.dexlauncher/apps').invokeMethod('goToSleep');
                                }),
                                _PowerBtn(Icons.settings, 'Settings', () {
                                  widget.onClose();
                                  context.read<WindowManager>().openWindow(
                                    appType: 'settings', title: 'Einstellungen',
                                    icon: Icons.settings, size: const Size(600, 450),
                                  );
                                }),
                                _PowerBtn(Icons.exit_to_app, 'Beenden', () {
                                  widget.onClose();
                                  const MethodChannel('com.dexlauncher/apps').invokeMethod('exitApp');
                                }),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      // Inhalt rechts
                      Expanded(child: _buildCategoryContent()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchResults() {
    final apps = _filteredApps;
    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        // Matching tools
        ...builtinApps.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .map((t) => _AppRow(icon: Icon(t.icon, color: Colors.white, size: 18), name: t.name,
                onTap: () => _openTool(context, t))),
        // Matching apps
        ...apps.map((app) => _AppRow(
          icon: SizedBox(width: 20, height: 20, child: AppIconWidget(app: app, size: 20)),
          name: app.name, onTap: () => widget.onAppTap(app),
          onSecondary: (pos) => _showAppMenu(pos, app),
        )),
      ],
    );
  }

  Widget _buildCategoryContent() {
    return switch (_activeCategory) {
      'favoriten' => _buildFavorites(),
      'tools' => _buildTools(),
      'internet' => _buildInternet(),
      'multimedia' => _buildMultimedia(),
      'spiele' => _buildSpiele(),
      'google' => _buildGoogle(),
      'streaming' => _buildStreaming(),
      'alle' => _buildAllApps(),
      _ => _buildAllApps(),
    };
  }

  Widget _buildFavorites() {
    final state = context.watch<DesktopState>();
    final recent = state.recentApps.take(8).toList();
    return ListView(padding: const EdgeInsets.all(4), children: [
      _SectionLabel('Zuletzt verwendet'),
      ...recent.map((app) => _AppRow(
        icon: SizedBox(width: 20, height: 20, child: AppIconWidget(app: app, size: 20)),
        name: app.name, onTap: () => widget.onAppTap(app),
      )),
      _SectionLabel('Schnellzugriff'),
      _AppRow(icon: const Icon(Icons.folder, color: Colors.white, size: 18), name: 'Dateimanager',
        onTap: () => _openTool(context, builtinApps.firstWhere((t) => t.id == 'file_manager'))),
      _AppRow(icon: const Icon(Icons.language, color: Colors.white, size: 18), name: 'Browser',
        onTap: () => _openTool(context, builtinApps.firstWhere((t) => t.id == 'browser'))),
      _AppRow(icon: const Icon(Icons.terminal, color: Colors.white, size: 18), name: 'Terminal',
        onTap: () => _openTool(context, builtinApps.firstWhere((t) => t.id == 'terminal'))),
    ]);
  }

  Widget _buildTools() => ListView(padding: const EdgeInsets.all(4), children: [
    ...builtinApps.where((t) => ['file_manager', 'terminal', 'calculator', 'text_editor', 'system_monitor',
        'task_manager', 'developer', 'clipboard', 'search', 'quick_settings', 'about'].contains(t.id))
        .map((t) => _ToolRow(tool: t, onTap: () => _openTool(context, t),
            onSecondary: (pos) => _showToolMenu(pos, t))),
  ]);

  Widget _buildInternet() => ListView(padding: const EdgeInsets.all(4), children: [
    ...builtinApps.where((t) => ['browser', 'wifi_manager', 'bluetooth_manager', 'speed_test',
        'vpn_manager', 'network_scanner'].contains(t.id))
        .map((t) => _ToolRow(tool: t, onTap: () => _openTool(context, t),
            onSecondary: (pos) => _showToolMenu(pos, t))),
  ]);

  Widget _buildMultimedia() => ListView(padding: const EdgeInsets.all(4), children: [
    ...builtinApps.where((t) => ['image_viewer', 'video_player', 'music_player', 'weather'].contains(t.id))
        .map((t) => _ToolRow(tool: t, onTap: () => _openTool(context, t),
            onSecondary: (pos) => _showToolMenu(pos, t))),
  ]);

  Widget _buildSpiele() => ListView(padding: const EdgeInsets.all(4), children: [
    _AppRow(icon: const Icon(Icons.sports_esports, color: Colors.white, size: 18), name: 'Spiele-Hub',
      onTap: () { widget.onClose(); context.read<WindowManager>().openWindow(
        appType: 'games', title: 'Spiele', icon: Icons.sports_esports, size: const Size(400, 450)); }),
  ]);

  Widget _buildGoogle() => ListView(padding: const EdgeInsets.all(4), children: [
    _AppRow(icon: const Icon(Icons.search, color: Colors.white, size: 18), name: 'Google Suche',
      onTap: () { widget.onClose(); context.read<WindowManager>().openWindow(
        appType: 'browser', title: 'Google', icon: Icons.language, size: const Size(700, 450)); }),
    _AppRow(icon: const Icon(Icons.cloud, color: Colors.white, size: 18), name: 'Google Drive',
      onTap: () => _openWebApp(context, 'Drive', 'https://drive.google.com')),
    _AppRow(icon: const Icon(Icons.description, color: Colors.white, size: 18), name: 'Google Docs',
      onTap: () => _openWebApp(context, 'Docs', 'https://docs.google.com')),
    _AppRow(icon: const Icon(Icons.table_chart, color: Colors.white, size: 18), name: 'Google Sheets',
      onTap: () => _openWebApp(context, 'Sheets', 'https://sheets.google.com')),
    _AppRow(icon: const Icon(Icons.mail, color: Colors.white, size: 18), name: 'Gmail',
      onTap: () => _openWebApp(context, 'Gmail', 'https://mail.google.com')),
    _AppRow(icon: const Icon(Icons.play_circle, color: Colors.white, size: 18), name: 'YouTube',
      onTap: () => _openWebApp(context, 'YouTube', 'https://www.youtube.com')),
    _AppRow(icon: const Icon(Icons.map, color: Colors.white, size: 18), name: 'Maps',
      onTap: () => _openWebApp(context, 'Maps', 'https://maps.google.com')),
  ]);

  Widget _buildStreaming() => ListView(padding: const EdgeInsets.all(4), children: [
    _AppRow(icon: const Icon(Icons.play_circle, color: Colors.white, size: 18), name: 'YouTube',
      onTap: () => _openWebApp(context, 'YouTube', 'https://www.youtube.com')),
    _AppRow(icon: const Icon(Icons.movie, color: Colors.white, size: 18), name: 'Netflix',
      onTap: () => _launchOrWeb(context, 'com.netflix.ninja', 'Netflix', 'https://www.netflix.com')),
    _AppRow(icon: const Icon(Icons.movie, color: Colors.white, size: 18), name: 'Disney+',
      onTap: () => _launchOrWeb(context, 'com.disney.disneyplus', 'Disney+', 'https://www.disneyplus.com')),
    _AppRow(icon: const Icon(Icons.movie, color: Colors.white, size: 18), name: 'Amazon Prime',
      onTap: () => _launchOrWeb(context, 'com.amazon.amazonvideo.livingroom', 'Prime', 'https://www.amazon.de/gp/video')),
    _AppRow(icon: const Icon(Icons.music_note, color: Colors.white, size: 18), name: 'Spotify',
      onTap: () => _launchOrWeb(context, 'com.spotify.tv.android', 'Spotify', 'https://open.spotify.com')),
  ]);

  Widget _buildAllApps() {
    final apps = _filteredApps;
    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final app = apps[i];
        return _AppRow(
          icon: SizedBox(width: 20, height: 20, child: AppIconWidget(app: app, size: 20)),
          name: app.name, onTap: () => widget.onAppTap(app),
          onSecondary: (pos) => _showAppMenu(pos, app),
        );
      },
    );
  }

  void _showAppMenu(Offset pos, AppInfo app) {
    final state = context.read<DesktopState>();
    ContextMenu.show(context: context, position: pos, items: [
      ContextMenuItem(icon: Icons.open_in_new, label: 'Oeffnen', onTap: () => widget.onAppTap(app)),
      ContextMenuItem(
        icon: app.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        label: app.isPinned ? 'Vom Dock entfernen' : 'An Dock anheften',
        onTap: () => state.togglePin(app)),
      ContextMenuItem(icon: Icons.info_outline, label: 'App-Info', onTap: () => state.openAppInfo(app)),
      if (!app.isSystemApp)
        ContextMenuItem(icon: Icons.delete_forever, label: 'Deinstallieren',
          onTap: () => state.uninstallApp(app), isDanger: true),
    ]);
  }

  void _showToolMenu(Offset pos, BuiltinApp tool) {
    final state = context.read<DesktopState>();
    final pinned = state.isToolPinned(tool.id);
    final autoStart = state.isAutoStart(tool.id);
    ContextMenu.show(context: context, position: pos, items: [
      ContextMenuItem(icon: Icons.open_in_new, label: 'Oeffnen', onTap: () => _openTool(context, tool)),
      ContextMenuItem(icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
        label: pinned ? 'Vom Dock entfernen' : 'An Dock anheften',
        onTap: () => state.toggleToolPin(tool.id)),
      ContextMenuItem(icon: autoStart ? Icons.play_disabled : Icons.play_arrow,
        label: autoStart ? 'Nicht bei Start' : 'Bei Start oeffnen',
        onTap: () => state.toggleAutoStart(tool.id)),
    ]);
  }
}

// --- Widgets ---

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _AppRow extends StatefulWidget {
  final Widget icon;
  final String name;
  final VoidCallback onTap;
  final void Function(Offset)? onSecondary;
  const _AppRow({required this.icon, required this.name, required this.onTap, this.onSecondary});
  @override State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      onSecondaryTapUp: widget.onSecondary != null ? (d) => widget.onSecondary!(d.globalPosition) : null,
      child: Container(
        height: 30, margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
          color: _h ? Colors.white.withValues(alpha: 0.07) : Colors.transparent),
        child: Row(children: [
          widget.icon, const SizedBox(width: 8),
          Expanded(child: Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    ),
  );
}

class _ToolRow extends StatefulWidget {
  final BuiltinApp tool;
  final VoidCallback onTap;
  final void Function(Offset)? onSecondary;
  const _ToolRow({required this.tool, required this.onTap, this.onSecondary});
  @override State<_ToolRow> createState() => _ToolRowState();
}

class _ToolRowState extends State<_ToolRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      onSecondaryTapUp: widget.onSecondary != null ? (d) => widget.onSecondary!(d.globalPosition) : null,
      child: Container(
        height: 30, margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
          color: _h ? Colors.white.withValues(alpha: 0.07) : Colors.transparent),
        child: Row(children: [
          Icon(widget.tool.icon, color: Colors.white, size: 16), const SizedBox(width: 8),
          Expanded(child: Text(widget.tool.name, style: const TextStyle(color: Colors.white, fontSize: 11))),
        ]),
      ),
    ),
  );
}

class _CatButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _CatButton({required this.label, required this.icon, required this.active, required this.onTap});
  @override State<_CatButton> createState() => _CatButtonState();
}

class _CatButtonState extends State<_CatButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.active ? C.accentDim : _h ? C.hover : Colors.transparent,
            border: widget.active ? const Border(left: BorderSide(color: C.accent, width: 2)) : null,
          ),
          child: Row(children: [
            Icon(widget.icon, color: widget.active ? Colors.white : Colors.white54, size: 14),
            const SizedBox(width: 8),
            Text(widget.label, style: TextStyle(color: widget.active ? Colors.white : Colors.white70, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _PowerBtn extends StatefulWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _PowerBtn(this.icon, this.label, this.onTap);
  @override State<_PowerBtn> createState() => _PowerBtnState();
}

class _PowerBtnState extends State<_PowerBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6),
            color: _h ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
          child: Icon(widget.icon, color: Colors.white54, size: 16),
        ),
        const SizedBox(height: 2),
        Text(widget.label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8)),
      ],
    )),
  );
}
