import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            _loading = true;
            _urlController.text = url;
          });
        },
        onPageFinished: (url) async {
          setState(() => _loading = false);
          _canGoBack = await _controller.canGoBack();
          _canGoForward = await _controller.canGoForward();
          final title = await _controller.getTitle();
          if (title != null && title.isNotEmpty) {
            widget.onTitleChanged?.call(title);
          }
          setState(() {});
        },
      ))
      ..loadRequest(Uri.parse(widget.initialUrl ?? 'https://www.google.com'));

    _urlController.text = widget.initialUrl ?? 'https://www.google.com';
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
                _NavButton(
                  icon: Icons.arrow_back,
                  enabled: _canGoBack,
                  onTap: () => _controller.goBack(),
                ),
                _NavButton(
                  icon: Icons.arrow_forward,
                  enabled: _canGoForward,
                  onTap: () => _controller.goForward(),
                ),
                _NavButton(
                  icon: _loading ? Icons.close : Icons.refresh,
                  enabled: true,
                  onTap: () {
                    if (_loading) {
                      // Stop not available in webview_flutter, just ignore
                    } else {
                      _controller.reload();
                    }
                  },
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
                          color: Colors.white30,
                          size: 14,
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
                const SizedBox(width: 6),
                _NavButton(
                  icon: Icons.home,
                  enabled: true,
                  onTap: () => _controller.loadRequest(Uri.parse('https://www.google.com')),
                ),
              ],
            ),
          ),
          // Loading Indicator
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Colors.blueAccent,
              backgroundColor: Colors.transparent,
            ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _hovering && widget.enabled
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            color: widget.enabled ? Colors.white70 : Colors.white24,
            size: 16,
          ),
        ),
      ),
    );
  }
}
