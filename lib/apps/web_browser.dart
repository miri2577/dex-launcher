import '../theme/cinnamon_theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _zoomLevel = 50; // Standard 50% für TV
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
    late final WebViewController ctrl;
    ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('DeXBridge', onMessageReceived: (message) {
        _handleBridgeMessage(message.message);
      })
      ..setUserAgent(_desktopMode
          ? 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          : null)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (!mounted) return;
          // Find the tab that owns this controller
          final tabIndex = _tabs.indexWhere((t) => t.controller == ctrl);
          setState(() {
            if (tabIndex >= 0) _tabs[tabIndex].url = url;
            // Only update URL bar if this is the active tab
            if (tabIndex == _activeTab) {
              _loading = true;
              _currentUrl = url;
              _urlController.text = url;
            }
          });
        },
        onPageFinished: (url) async {
          if (!mounted) return;
          // Find the tab that owns this controller
          final tabIndex = _tabs.indexWhere((t) => t.controller == ctrl);
          final isActiveTab = tabIndex == _activeTab;
          if (isActiveTab) {
            setState(() => _loading = false);
          }
          _canGoBack = await ctrl.canGoBack();
          _canGoForward = await ctrl.canGoForward();
          final title = await ctrl.getTitle();
          if (title != null && title.isNotEmpty) {
            if (tabIndex >= 0) _tabs[tabIndex].title = title;
            if (isActiveTab) {
              _pageTitle = title;
              widget.onTitleChanged?.call(title);
            }
          }
          // Zoom anwenden
          if (isActiveTab) _applyZoom();
          // Soft-Keyboard unterdrücken + Rechtsklick auf Bilder
          ctrl.runJavaScript('''
            document.addEventListener('focusin', function(e) {
              if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) {
                e.target.setAttribute('inputmode', 'none');
              }
            });
            document.addEventListener('contextmenu', function(e) {
              var el = e.target;
              if (el.tagName === 'IMG' && el.src) {
                e.preventDefault();
                window.DeXBridge.postMessage(JSON.stringify({type: 'image_context', url: el.src}));
              } else if (el.tagName === 'A' && el.href) {
                e.preventDefault();
                window.DeXBridge.postMessage(JSON.stringify({type: 'link_context', url: el.href, text: el.textContent}));
              }
            });
          ''');
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

  static const _channel = MethodChannel('com.dexlauncher/apps');

  void _handleBridgeMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;
      final url = data['url'] as String?;
      if (url == null) return;

      if (type == 'image_context') {
        _showImageContextMenu(url);
      } else if (type == 'link_context') {
        _showLinkContextMenu(url, data['text'] as String? ?? url);
      }
    } catch (_) {}
  }

  void _showImageContextMenu(String imageUrl) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    // Menü in der Mitte des Fensters
    final box = context.findRenderObject() as RenderBox;
    final center = box.localToGlobal(Offset(box.size.width / 2 - 80, box.size.height / 2 - 40));

    entry = OverlayEntry(builder: (_) => Stack(children: [
      Positioned.fill(child: GestureDetector(
        onTap: () => entry.remove(),
        child: Container(color: Colors.transparent),
      )),
      Positioned(left: center.dx, top: center.dy, child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xF0282828), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _ctxItem(Icons.download, 'Bild speichern', () {
            entry.remove();
            _downloadFile(imageUrl);
          }),
          _ctxItem(Icons.open_in_new, 'Bild in neuem Tab', () {
            entry.remove();
            _addTab(imageUrl);
          }),
          _ctxItem(Icons.copy, 'URL kopieren', () {
            entry.remove();
            Clipboard.setData(ClipboardData(text: imageUrl));
          }),
        ]),
      )),
    ]));
    overlay.insert(entry);
  }

  void _showLinkContextMenu(String linkUrl, String text) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final box = context.findRenderObject() as RenderBox;
    final center = box.localToGlobal(Offset(box.size.width / 2 - 80, box.size.height / 2 - 40));

    entry = OverlayEntry(builder: (_) => Stack(children: [
      Positioned.fill(child: GestureDetector(onTap: () => entry.remove(), child: Container(color: Colors.transparent))),
      Positioned(left: center.dx, top: center.dy, child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xF0282828), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _ctxItem(Icons.open_in_new, 'In neuem Tab oeffnen', () { entry.remove(); _addTab(linkUrl); }),
          _ctxItem(Icons.copy, 'Link kopieren', () { entry.remove(); Clipboard.setData(ClipboardData(text: linkUrl)); }),
          _ctxItem(Icons.download, 'Link herunterladen', () { entry.remove(); _downloadFile(linkUrl); }),
        ]),
      )),
    ]));
    overlay.insert(entry);
  }

  Widget _ctxItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32, padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(children: [
          Icon(icon, color: Colors.white70, size: 14), const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      ),
    );
  }

  Future<void> _downloadFile(String url) async {
    try {
      var filename = url.split('/').last.split('?').first;
      if (filename.isEmpty || !filename.contains('.')) {
        filename = 'download_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }
      final savePath = '/storage/emulated/0/Download/$filename';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Download gestartet...', style: TextStyle(fontSize: 12)),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF2D2D2D),
        ));
      }

      final result = await _channel.invokeMethod('downloadFile', {
        'url': url,
        'savePath': savePath,
      });

      if (!mounted) return;
      final m = Map<String, dynamic>.from(result as Map);
      if (m['success'] == true) {
        final size = m['size'] as int? ?? 0;
        final sizeStr = size > 1048576 ? '${(size / 1048576).toStringAsFixed(1)} MB' : '${(size / 1024).toStringAsFixed(0)} KB';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gespeichert: $filename ($sizeStr)', style: const TextStyle(fontSize: 12)),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF2D2D2D),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: ${m['error'] ?? 'Unbekannt'}', style: const TextStyle(fontSize: 12)),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.shade900,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download fehlgeschlagen: $e', style: const TextStyle(fontSize: 12)),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.shade900,
        ));
      }
    }
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
      color: C.panelBg,
      child: Column(
        children: [
          // Tab-Leiste
          if (_tabs.length > 1)
            Container(
              height: 34,
              color: C.windowBg,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length + 1, // +1 für "Neuer Tab"
                itemBuilder: (context, i) {
                  if (i == _tabs.length) {
                    return GestureDetector(
                      onTap: () => _addTab('https://www.google.com'),
                      child: Container(
                        width: 34, height: 34,
                        alignment: Alignment.center,
                        child: const Icon(Icons.add, color: Colors.white38, size: 15),
                      ),
                    );
                  }
                  final tab = _tabs[i];
                  final active = i == _activeTab;
                  return GestureDetector(
                    onTap: () => _switchTab(i),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: active ? C.windowChromeUnfocused : Colors.transparent,
                        border: Border(bottom: BorderSide(
                          color: active ? const Color(0xFF86BE43) : Colors.transparent, width: 2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(tab.title, style: TextStyle(
                            color: active ? Colors.white : Colors.white54, fontSize: 11),
                            overflow: TextOverflow.ellipsis)),
                          if (_tabs.length > 1) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _closeTab(i),
                              child: Icon(Icons.close, size: 13, color: active ? Colors.white54 : Colors.white24),
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
            height: 40,
            color: C.windowChromeUnfocused,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                _NavBtn(Icons.arrow_back, _canGoBack, () => _controller.goBack()),
                _NavBtn(Icons.arrow_forward, _canGoForward, () => _controller.goForward()),
                _NavBtn(_loading ? Icons.close : Icons.refresh, true, () { if (!_loading) _controller.reload(); }),
                const SizedBox(width: 4),
                // URL Bar
                Expanded(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                    child: TextField(keyboardType: TextInputType.none,
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                Expanded(child: TextField(keyboardType: TextInputType.none, 
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
              color: C.windowChromeUnfocused,
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
            const LinearProgressIndicator(minHeight: 4, color: Color(0xFF86BE43), backgroundColor: Colors.transparent),

          // Bookmarks Bar
          if (_showBookmarks && _bookmarks.isNotEmpty)
            Container(
              height: 30, color: const Color(0xFF202020),
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
        backgroundColor: C.windowChromeUnfocused,
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
          width: 32, height: 32,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: _h && widget.enabled ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Icon(widget.icon, color: widget.enabled ? Colors.white70 : Colors.white24, size: 15),
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
