import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebBrowserApp extends StatefulWidget {
  final String? initialUrl;
  final void Function(String title)? onTitleChanged;

  const WebBrowserApp({super.key, this.initialUrl, this.onTitleChanged});

  @override
  State<WebBrowserApp> createState() => _WebBrowserAppState();
}

class _WebBrowserAppState extends State<WebBrowserApp> {
  late WebViewController _controller;
  final _urlController = TextEditingController();
  bool _loading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _currentUrl = '';
  String _pageTitle = '';
  int _zoomLevel = 100; // Prozent
  bool _showBookmarks = false;
  bool _showMenu = false;
  bool _desktopMode = true;
  bool _findMode = false;
  final _findController = TextEditingController();
  List<Map<String, String>> _bookmarks = [];
  List<String> _history = [];

  // Tabs
  final List<_TabInfo> _tabs = [];
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _loadHistory();
    _addTab(widget.initialUrl ?? 'https://www.google.com');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _findController.dispose();
    super.dispose();
  }

  void _addTab(String url) {
    final controller = _createController(url);
    setState(() {
      _tabs.add(_TabInfo(url: url, title: 'Laden...', controller: controller));
      _activeTab = _tabs.length - 1;
      _controller = controller;
      _currentUrl = url;
      _urlController.text = url;
    });
  }

  void _switchTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() {
      _activeTab = index;
      _controller = _tabs[index].controller;
      _currentUrl = _tabs[index].url;
      _urlController.text = _currentUrl;
      _pageTitle = _tabs[index].title;
    });
    widget.onTitleChanged?.call(_pageTitle);
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) return; // Mindestens 1 Tab
    setState(() {
      _tabs.removeAt(index);
      if (_activeTab >= _tabs.length) _activeTab = _tabs.length - 1;
      _controller = _tabs[_activeTab].controller;
      _currentUrl = _tabs[_activeTab].url;
      _urlController.text = _currentUrl;
    });
  }

  WebViewController _createController(String url) {
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_desktopMode
          ? 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          : null)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (!mounted) return;
          setState(() {
            _loading = true;
            _currentUrl = url;
            _urlController.text = url;
            if (_activeTab < _tabs.length) _tabs[_activeTab].url = url;
          });
        },
        onPageFinished: (url) async {
          if (!mounted) return;
          setState(() => _loading = false);
          _canGoBack = await _controller.canGoBack();
          _canGoForward = await _controller.canGoForward();
          final title = await _controller.getTitle();
          if (title != null && title.isNotEmpty) {
            _pageTitle = title;
            if (_activeTab < _tabs.length) _tabs[_activeTab].title = title;
            widget.onTitleChanged?.call(title);
          }
          // Zoom anwenden
          _applyZoom();
          // History
          if (!_history.contains(url)) {
            _history.insert(0, url);
            if (_history.length > 50) _history.removeLast();
            _saveHistory();
          }
          if (mounted) setState(() {});
        },
      ))
      ..loadRequest(Uri.parse(url));
    return ctrl;
  }

  void _navigate() {
    var url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }
    _controller.loadRequest(Uri.parse(url));
  }

  void _applyZoom() {
    final scale = _zoomLevel / 100.0;
    _controller.runJavaScript(
      'document.body.style.zoom = "$scale"; document.body.style.webkitTextSizeAdjust = "${_zoomLevel}%";'
    );
  }

  void _zoomIn() { setState(() { _zoomLevel = (_zoomLevel + 10).clamp(50, 200); }); _applyZoom(); }
  void _zoomOut() { setState(() { _zoomLevel = (_zoomLevel - 10).clamp(50, 200); }); _applyZoom(); }
  void _zoomReset() { setState(() { _zoomLevel = 100; }); _applyZoom(); }

  void _findOnPage() {
    final query = _findController.text.trim();
    if (query.isEmpty) return;
    _controller.runJavaScript('window.find("$query")');
  }

  void _toggleDesktopMode() {
    setState(() => _desktopMode = !_desktopMode);
    // Seite mit neuem User-Agent neu laden
    final url = _currentUrl;
    _controller.setUserAgent(_desktopMode
        ? 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        : null);
    _controller.loadRequest(Uri.parse(url));
  }

  // Bookmarks
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('browser_bookmarks');
    if (json != null) {
      final list = jsonDecode(json) as List;
      if (mounted) setState(() { _bookmarks = list.map((e) => Map<String, String>.from(e as Map)).toList(); });
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('browser_bookmarks', jsonEncode(_bookmarks));
  }

  void _addBookmark() {
    if (_bookmarks.any((b) => b['url'] == _currentUrl)) return;
    setState(() { _bookmarks.add({'title': _pageTitle.isNotEmpty ? _pageTitle : _currentUrl, 'url': _currentUrl}); });
    _saveBookmarks();
  }

  void _removeBookmark(int index) { setState(() => _bookmarks.removeAt(index)); _saveBookmarks(); }
  bool get _isBookmarked => _bookmarks.any((b) => b['url'] == _currentUrl);

  // History
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _history = prefs.getStringList('browser_history') ?? [];
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('browser_history', _history);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Tab-Leiste
          if (_tabs.length > 1)
            Container(
              height: 28,
              color: const Color(0xFF1E1E1E),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length + 1, // +1 für "Neuer Tab"
                itemBuilder: (context, i) {
                  if (i == _tabs.length) {
                    return GestureDetector(
                      onTap: () => _addTab('https://www.google.com'),
                      child: Container(
                        width: 28, height: 28,
                        alignment: Alignment.center,
                        child: const Icon(Icons.add, color: Colors.white38, size: 14),
                      ),
                    );
                  }
                  final tab = _tabs[i];
                  final active = i == _activeTab;
                  return GestureDetector(
                    onTap: () => _switchTab(i),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF252525) : Colors.transparent,
                        border: Border(bottom: BorderSide(
                          color: active ? Colors.blueAccent : Colors.transparent, width: 2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(tab.title, style: TextStyle(
                            color: active ? Colors.white : Colors.white54, fontSize: 10),
                            overflow: TextOverflow.ellipsis)),
                          if (_tabs.length > 1) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _closeTab(i),
                              child: Icon(Icons.close, size: 12, color: active ? Colors.white54 : Colors.white24),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Navigation Bar
          Container(
            height: 34,
            color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              children: [
                _NavBtn(Icons.arrow_back, _canGoBack, () => _controller.goBack()),
                _NavBtn(Icons.arrow_forward, _canGoForward, () => _controller.goForward()),
                _NavBtn(_loading ? Icons.close : Icons.refresh, true, () { if (!_loading) _controller.reload(); }),
                const SizedBox(width: 4),
                // URL Bar
                Expanded(
                  child: Container(
                    height: 26,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _navigate(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Zoom
                _NavBtn(Icons.remove, true, _zoomOut),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: _zoomReset,
                    child: Text('$_zoomLevel%', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9)),
                  ),
                ),
                _NavBtn(Icons.add, true, _zoomIn),
                const SizedBox(width: 2),
                _NavBtn(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, true, _addBookmark),
                _NavBtn(Icons.more_vert, true, () => setState(() => _showMenu = !_showMenu)),
              ],
            ),
          ),

          // Find Bar
          if (_findMode)
            Container(
              height: 30, color: const Color(0xFF202020),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _findController, autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: 'Auf Seite suchen...', hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _findOnPage(),
                )),
                GestureDetector(onTap: _findOnPage, child: const Icon(Icons.search, color: Colors.white54, size: 16)),
                const SizedBox(width: 8),
                GestureDetector(onTap: () => setState(() { _findMode = false; _findController.clear(); }),
                  child: const Icon(Icons.close, color: Colors.white38, size: 16)),
              ]),
            ),

          // Menu
          if (_showMenu)
            Container(
              color: const Color(0xFF252525),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(spacing: 4, runSpacing: 4, children: [
                _MenuChip('Neuer Tab', Icons.add, () { _addTab('https://www.google.com'); setState(() => _showMenu = false); }),
                _MenuChip('Lesezeichen', Icons.bookmarks, () => setState(() { _showBookmarks = !_showBookmarks; _showMenu = false; })),
                _MenuChip('Verlauf', Icons.history, () { _showHistoryDialog(); setState(() => _showMenu = false); }),
                _MenuChip('Suchen', Icons.search, () => setState(() { _findMode = true; _showMenu = false; })),
                _MenuChip(_desktopMode ? 'Mobile Ansicht' : 'Desktop Ansicht',
                  _desktopMode ? Icons.phone_android : Icons.desktop_windows,
                  () { _toggleDesktopMode(); setState(() => _showMenu = false); }),
                _MenuChip('Startseite', Icons.home, () { _controller.loadRequest(Uri.parse('https://www.google.com')); setState(() => _showMenu = false); }),
              ]),
            ),

          if (_loading)
            const LinearProgressIndicator(minHeight: 2, color: Colors.blueAccent, backgroundColor: Colors.transparent),

          // Bookmarks Bar
          if (_showBookmarks && _bookmarks.isNotEmpty)
            Container(
              height: 28, color: const Color(0xFF202020),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                itemCount: _bookmarks.length,
                itemBuilder: (context, i) {
                  final bm = _bookmarks[i];
                  return GestureDetector(
                    onTap: () => _controller.loadRequest(Uri.parse(bm['url']!)),
                    onSecondaryTapUp: (_) => _removeBookmark(i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
                      alignment: Alignment.center,
                      child: Text(bm['title'] ?? bm['url']!, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10), overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
              ),
            ),

          // WebView
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: _tabs.map((tab) => WebViewWidget(controller: tab.controller)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('Verlauf', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: SizedBox(
          width: 400, height: 300,
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () { Navigator.of(ctx).pop(); _controller.loadRequest(Uri.parse(_history[i])); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_history[i], style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () { _history.clear(); _saveHistory(); Navigator.of(ctx).pop(); },
            child: const Text('Loeschen', style: TextStyle(color: Colors.redAccent))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Schliessen')),
        ],
      ),
    );
  }
}

class _TabInfo {
  String url;
  String title;
  final WebViewController controller;
  _TabInfo({required this.url, required this.title, required this.controller});
}

// Kompakter Nav-Button
Widget _NavBtn(IconData icon, bool enabled, VoidCallback onTap) {
  return _NavButton(icon: icon, enabled: enabled, onTap: onTap);
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.enabled, required this.onTap});
  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          width: 26, height: 26,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: _h && widget.enabled ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Icon(widget.icon, color: widget.enabled ? Colors.white70 : Colors.white24, size: 14),
        ),
      ),
    );
  }
}

class _MenuChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MenuChip(this.label, this.icon, this.onTap);
  @override
  State<_MenuChip> createState() => _MenuChipState();
}

class _MenuChipState extends State<_MenuChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _h ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
