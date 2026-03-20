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
  late final WebViewController _controller;
  final _urlController = TextEditingController();
  bool _loading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _currentUrl = '';
  bool _showBookmarks = false;
  List<Map<String, String>> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    final url = widget.initialUrl ?? 'https://www.google.com';
    _currentUrl = url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (!mounted) return;
          setState(() {
            _loading = true;
            _currentUrl = url;
            _urlController.text = url;
          });
        },
        onPageFinished: (url) async {
          if (!mounted) return;
          setState(() => _loading = false);
          _canGoBack = await _controller.canGoBack();
          _canGoForward = await _controller.canGoForward();
          final title = await _controller.getTitle();
          if (title != null && title.isNotEmpty) {
            widget.onTitleChanged?.call(title);
          }
          if (mounted) setState(() {});
        },
      ))
      ..loadRequest(Uri.parse(url));
    _urlController.text = url;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _navigate() {
    var url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }
    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('browser_bookmarks');
    if (json != null) {
      final list = jsonDecode(json) as List;
      setState(() {
        _bookmarks = list.map((e) => Map<String, String>.from(e as Map)).toList();
      });
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('browser_bookmarks', jsonEncode(_bookmarks));
  }

  void _addBookmark() {
    final title = _urlController.text.split('/').last;
    if (_bookmarks.any((b) => b['url'] == _currentUrl)) return;
    setState(() {
      _bookmarks.add({'title': title, 'url': _currentUrl});
    });
    _saveBookmarks();
  }

  void _removeBookmark(int index) {
    setState(() => _bookmarks.removeAt(index));
    _saveBookmarks();
  }

  bool get _isBookmarked => _bookmarks.any((b) => b['url'] == _currentUrl);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Navigation Bar
          Container(
            height: 38,
            color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                _NavButton(icon: Icons.arrow_back, enabled: _canGoBack, onTap: () => _controller.goBack()),
                _NavButton(icon: Icons.arrow_forward, enabled: _canGoForward, onTap: () => _controller.goForward()),
                _NavButton(
                  icon: _loading ? Icons.close : Icons.refresh, enabled: true,
                  onTap: () { if (!_loading) _controller.reload(); },
                ),
                const SizedBox(width: 6),
                // URL Bar
                Expanded(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          _loading ? Icons.hourglass_top : Icons.language,
                          color: Colors.white30, size: 14,
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 30),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _navigate(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Bookmark toggle
                _NavButton(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  enabled: true,
                  onTap: _addBookmark,
                ),
                // Bookmarks list
                _NavButton(
                  icon: Icons.bookmarks,
                  enabled: true,
                  onTap: () => setState(() => _showBookmarks = !_showBookmarks),
                ),
                _NavButton(icon: Icons.home, enabled: true, onTap: () => _controller.loadRequest(Uri.parse('https://www.google.com'))),
              ],
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2, color: Colors.blueAccent, backgroundColor: Colors.transparent),
          // Bookmarks Bar
          if (_showBookmarks && _bookmarks.isNotEmpty)
            Container(
              height: 32,
              color: const Color(0xFF202020),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: _bookmarks.length,
                itemBuilder: (context, index) {
                  final bm = _bookmarks[index];
                  return GestureDetector(
                    onTap: () => _controller.loadRequest(Uri.parse(bm['url']!)),
                    onSecondaryTapUp: (_) => _removeBookmark(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        bm['title'] ?? bm['url']!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          // WebView
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
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
          width: 28, height: 28,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _h && widget.enabled ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Icon(widget.icon, color: widget.enabled ? Colors.white70 : Colors.white24, size: 16),
        ),
      ),
    );
  }
}
