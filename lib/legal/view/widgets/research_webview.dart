import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Reaches the native WebView to register a download listener — the high-level
// API exposes no download hook. Guarded at the call site so a package change
// degrades to the navigation-delegate fallback rather than crashing.
// ignore: implementation_imports
import 'package:webview_flutter_android/src/android_webkit.g.dart'
    as android_webkit;
import '../legal_theme.dart';
import '../../bloc/blocs.dart';
import '../../../services/download_service.dart';
import 'research_view.dart';
import 'legal_modals.dart';

/// Shares a single "are the chrome bars visible?" signal between the in-app
/// browser (which drives it from page scrolling) and the bottom nav bar.
class BarVisibilityScope extends InheritedWidget {
  final ValueNotifier<bool> visible;

  const BarVisibilityScope({
    super.key,
    required this.visible,
    required super.child,
  });

  static ValueNotifier<bool> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BarVisibilityScope>();
    assert(scope != null, 'No BarVisibilityScope found in context');
    return scope!.visible;
  }

  @override
  bool updateShouldNotify(BarVisibilityScope oldWidget) =>
      visible != oldWidget.visible;
}

/// Collapses [child] to zero height when [visible] turns false (and [enabled]),
/// retracting toward [alignment]. Reclaims the space so neighbours can grow.
class CollapsibleBar extends StatelessWidget {
  final ValueListenable<bool> visible;
  final bool enabled;
  final Alignment alignment;
  final Widget child;

  const CollapsibleBar({
    super.key,
    required this.visible,
    required this.child,
    this.enabled = true,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, isVisible, _) {
        final show = !enabled || isVisible;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: show ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, t, c) => ClipRect(
            child: Align(
              alignment: alignment,
              heightFactor: t,
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: c),
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// The in-app browser that renders a [ResearchSource]. Its header retracts as
/// the page is scrolled down and returns on scroll up, in concert with the
/// bottom nav, to give the document maximum room.
class ResearchWebView extends StatefulWidget {
  final ResearchSource source;
  const ResearchWebView({super.key, required this.source});

  @override
  State<ResearchWebView> createState() => _ResearchWebViewState();
}

class _ResearchWebViewState extends State<ResearchWebView> {
  late final WebViewController _controller;
  final ValueNotifier<double> _progress = ValueNotifier(0);

  ValueNotifier<bool>? _bars;
  double _lastY = 0;

  /// Upward distance accumulated since the last downward scroll. The bars only
  /// reappear once this passes [_showThreshold], so a stray flick up won't pull
  /// them back; a downward scroll hides them right away.
  double _upAccum = 0;
  static const _hideThreshold = 4.0;
  static const _showThreshold = 90.0;

  /// When the bars last retracted. They cannot expand again until
  /// [_expandCooldown] has elapsed, so they don't flicker straight back open.
  DateTime? _hiddenAt;
  static const _expandCooldown = Duration(seconds: 1);

  /// Posted by the page on every scroll frame so we can react to direction.
  static const _scrollHook = '''
(function(){
  if (window.__barsHook) return;
  window.__barsHook = true;
  var ticking = false;
  function report(){
    var y = window.pageYOffset || document.documentElement.scrollTop || 0;
    BarsBridge.postMessage(String(y));
    ticking = false;
  }
  window.addEventListener('scroll', function(){
    if(!ticking){ window.requestAnimationFrame(report); ticking = true; }
  }, {passive:true});
})();
''';

  /// Reroutes new-window navigations (`target="_blank"`, `window.open`) back into
  /// this WebView. The controller advertises multi-window support but never
  /// handles the new-window request, so without this an "open/download in a new
  /// tab" link — common on legal databases — silently does nothing.
  static const _linkHook = '''
(function(){
  if (window.__linkHook) return;
  window.__linkHook = true;
  var nativeOpen = window.open;
  window.open = function(u){
    if (u) { window.location.href = u; return window; }
    return nativeOpen.apply(this, arguments);
  };
  document.addEventListener('click', function(e){
    var a = e.target && e.target.closest ? e.target.closest('a[target]') : null;
    if (a && a.target && a.target !== '_self') a.target = '_self';
  }, true);
})();
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'BarsBridge',
        onMessageReceived: (message) =>
            _onScroll(double.tryParse(message.message) ?? 0),
      );

    _controller
        .setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              // Direct file URLs surface here; downloads without a tell-tale
              // extension (generated PDFs, Content-Disposition responses) are
              // caught by the native download listener attached below.
              if (DownloadService.looksDownloadable(request.url)) {
                _interceptDownload(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onProgress: (p) => _progress.value = p / 100,
            onPageStarted: (_) {
              _progress.value = 0;
              _lastY = 0;
              _upAccum = 0;
              _hiddenAt = null;
              _setBars(true);
            },
            onPageFinished: (_) {
              _progress.value = 1;
              _controller.runJavaScript(_scrollHook);
              _controller.runJavaScript(_linkHook);
            },
          ),
        )
        // Attach after the delegate is applied so our listener replaces the
        // package's (which only routes downloads back through navigation).
        .then((_) => _attachDownloadListener());

    _controller.loadRequest(Uri.parse(widget.source.url));

    // Desktop-width pages should zoom out to fit rather than scroll sideways.
    // A wide viewport plus the controller's default overview mode does exactly
    // that on Android.
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setUseWideViewPort(true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bars = BarVisibilityScope.of(context);
    _setBars(true);
  }

  void _setBars(bool value) {
    if (_bars != null && _bars!.value != value) _bars!.value = value;
  }

  /// Hide the bars as soon as the user scrolls down; only reveal them after a
  /// sustained upward scroll (or when back at the very top), and never within
  /// [_expandCooldown] of the last retract.
  void _onScroll(double y) {
    final dy = y - _lastY;
    _lastY = y;

    if (dy > _hideThreshold) {
      _upAccum = 0;
      // Arm the cooldown only on the visible -> hidden transition, so holding a
      // downward scroll can't keep re-locking. It re-arms after the next expand.
      if (_bars?.value ?? true) _hiddenAt = DateTime.now();
      _setBars(false);
      return;
    }

    // Stay retracted until the cooldown after the last retract has passed.
    if (_hiddenAt != null &&
        DateTime.now().difference(_hiddenAt!) < _expandCooldown) {
      return;
    }

    if (y <= 4) {
      _upAccum = 0;
      _setBars(true);
    } else if (dy < 0) {
      _upAccum += -dy;
      if (_upAccum > _showThreshold) _setBars(true);
    }
  }

  void _close() {
    _setBars(true);
    context.read<NavigationBloc>().add(const SourceSelected(null));
  }

  /// Registers a native Android download listener so any file the page tries to
  /// download — including generated PDFs whose URL carries no extension — is
  /// caught and offered to the case-folder save flow, with the server's
  /// filename/MIME hints. Replaces the package's own listener (which merely
  /// re-routes downloads through the navigation delegate). Failure is swallowed:
  /// the extension check in the delegate remains as a fallback.
  Future<void> _attachDownloadListener() async {
    final platform = _controller.platform;
    if (platform is! AndroidWebViewController) return;
    try {
      final webView = android_webkit.PigeonInstanceManager.instance
          .getInstanceWithWeakReference<android_webkit.WebView>(
              platform.webViewIdentifier);
      if (webView == null) return;
      // Cache the WebView's User-Agent so the fetch presents the same client as
      // the browser even on the extension-only navigation-delegate path.
      _userAgent = await webView.settings.getUserAgentString();
      await webView.setDownloadListener(
        android_webkit.DownloadListener(
          onDownloadStart:
              (_, url, userAgent, contentDisposition, mimetype, ___) =>
                  _interceptDownload(url,
                      contentDisposition: contentDisposition,
                      mimetype: mimetype,
                      userAgent: userAgent),
        ),
      );
    } catch (_) {
      // Platform internals changed under us — fall back to the navigation
      // delegate's URL-extension interception.
    }
  }

  /// Reads the WebView's cookies for [url] so a session-gated file downloads the
  /// same way it would in the browser. Returns null if unavailable.
  Future<String?> _cookieFor(String url) async {
    try {
      return await android_webkit.CookieManager.instance.getCookies(url);
    } catch (_) {
      return null;
    }
  }

  String? _userAgent;
  String? _lastDownloadUrl;
  DateTime? _lastDownloadAt;

  /// Offers to file an intercepted download into a case folder, forwarding the
  /// WebView's cookies and User-Agent so the fetch is authenticated like the
  /// page. The navigation delegate and the download listener can both surface
  /// the same URL, so a short window dedupes them. Bars are brought back first
  /// so the sheet doesn't open behind a retracted header.
  Future<void> _interceptDownload(String url,
      {String? contentDisposition, String? mimetype, String? userAgent}) async {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastDownloadUrl == url &&
        _lastDownloadAt != null &&
        now.difference(_lastDownloadAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastDownloadUrl = url;
    _lastDownloadAt = now;

    final headers = <String, String>{};
    final ua = userAgent ?? _userAgent;
    if (ua != null && ua.isNotEmpty) headers['User-Agent'] = ua;
    final cookie = await _cookieFor(url);
    if (cookie != null && cookie.isNotEmpty) headers['Cookie'] = cookie;

    if (!mounted) return;
    _setBars(true);
    LegalModals.showSaveDownloadSheet(
      context,
      PendingDownload(
        url: url,
        suggestedName: DownloadService.suggestFileName(url,
            contentDisposition: contentDisposition, mimetype: mimetype),
        sourceHost: widget.source.host,
        headers: headers,
      ),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          _close();
        }
      },
      child: Column(
        key: const ValueKey('research_web'),
        children: [
          CollapsibleBar(
            visible: _bars!,
            alignment: Alignment.topCenter,
            child: _BrowserHeader(
              source: widget.source,
              progress: _progress,
              onBack: _close,
              onRefresh: () => _controller.reload(),
            ),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

class _BrowserHeader extends StatelessWidget {
  final ResearchSource source;
  final ValueListenable<double> progress;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _BrowserHeader({
    required this.source,
    required this.progress,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: source.color,
                      borderRadius: BorderRadius.circular(9)),
                  child: Text(source.monogram,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(source.name,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 10, color: LegalTheme.muted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(source.host,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: LegalTheme.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRefresh,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.refresh_rounded,
                        size: 17, color: LegalTheme.ink),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => SizedBox(
              height: 2.5,
              child: value >= 1
                  ? const SizedBox.shrink()
                  : LinearProgressIndicator(
                      value: value == 0 ? null : value,
                      minHeight: 2.5,
                      backgroundColor: const Color(0xFFEDF0F4),
                      valueColor:
                          const AlwaysStoppedAnimation(LegalTheme.blue),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
