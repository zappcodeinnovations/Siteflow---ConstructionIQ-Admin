import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class JobSheetWebviewScreen extends StatefulWidget {
  final String url;
  final String title;

  const JobSheetWebviewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<JobSheetWebviewScreen> createState() => _JobSheetWebviewScreenState();
}

class _JobSheetWebviewScreenState extends State<JobSheetWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _injectAutoFitScript();
          },
          onProgress: (int progress) {
            if (progress > 60) {
              _injectAutoFitScript();
            }
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            await _injectAutoFitScript();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
        ),
      );
      
    _loadUrlWithAuth();
  }

  Future<void> _injectAutoFitScript() async {
    const script = r"""
(function() {
  function fitFormToScreen() {
    // 1. Set standard responsive viewport meta
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      document.head.appendChild(meta);
    }
    meta.setAttribute('content', 'width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=3.0, user-scalable=yes');

    // 2. Remove old conflicting styles
    var oldStyle = document.getElementById('siteflow-form-fit-style');
    if (oldStyle) oldStyle.remove();
    var oldLock = document.getElementById('siteflow-form-lock-style');
    if (oldLock) oldLock.remove();
    var oldAutofit = document.getElementById('siteflow-autofit-style');
    if (oldAutofit) oldAutofit.remove();

    // 3. Inject responsive styles so the form card fits the mobile screen edge-to-edge
    var style = document.createElement('style');
    style.id = 'siteflow-form-fit-style';
    style.innerHTML = `
      * {
        box-sizing: border-box !important;
      }
      html {
        width: 100% !important;
        max-width: 100% !important;
        min-width: 0 !important;
        margin: 0 !important;
        padding: 0 !important;
        background-color: #f8fafc !important;
        overflow-x: hidden !important;
      }
      body {
        width: 100% !important;
        max-width: 100% !important;
        min-width: 0 !important;
        margin: 0 auto !important;
        padding: 12px !important;
        background-color: #f8fafc !important;
        overflow-x: hidden !important;
        -webkit-text-size-adjust: 100% !important;
      }
      .form-container, .container, .page, .card, form, table, .sheet-container, .sheet-card, .wrapper, main, [class*="container"], [class*="card"] {
        max-width: 100% !important;
        width: 100% !important;
        min-width: 0 !important;
        box-sizing: border-box !important;
        margin-left: auto !important;
        margin-right: auto !important;
        box-shadow: 0 1px 3px rgba(0,0,0,0.08) !important;
        border-radius: 12px !important;
      }
      table {
        width: 100% !important;
        max-width: 100% !important;
        min-width: 0 !important;
        table-layout: auto !important;
        word-break: break-word !important;
      }
      td, th {
        word-break: break-word !important;
      }
      img {
        max-width: 100% !important;
        height: auto !important;
      }
    `;
    document.head.appendChild(style);

    // 4. Clean up any inline min-widths or fixed widths on DOM elements
    var screenW = window.innerWidth || document.documentElement.clientWidth || 360;
    var allElements = document.querySelectorAll('*');
    for (var i = 0; i < allElements.length; i++) {
      var el = allElements[i];
      if (el.style) {
        if (el.style.minWidth && parseInt(el.style.minWidth) > screenW) {
          el.style.minWidth = '100%';
        }
        if (el.style.width && parseInt(el.style.width) > screenW) {
          el.style.width = '100%';
        }
      }
    }
  }

  function formatDateTimestamps() {
    var isoRegex = /^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?$/;
    var isoDateOnlyRegex = /^(\d{4})-(\d{2})-(\d{2})$/;

    function formatValue(val) {
      if (!val || typeof val !== 'string') return null;
      var trimmed = val.trim();
      var m = trimmed.match(isoRegex);
      if (m) {
        return m[3] + '/' + m[2] + '/' + m[1] + ' ' + m[4] + ':' + m[5];
      }
      var mDate = trimmed.match(isoDateOnlyRegex);
      if (mDate) {
        return mDate[3] + '/' + mDate[2] + '/' + mDate[1];
      }
      return null;
    }

    // Format all leaf DOM elements (table cells, divs, spans, p, labels)
    var nodes = document.querySelectorAll('td, th, span, div, p, li, label, strong, em, b, i');
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node.children.length === 0 && node.textContent) {
        var formatted = formatValue(node.textContent);
        if (formatted) {
          node.textContent = formatted;
        }
      }
    }

    // Format input and textarea values
    var inputs = document.querySelectorAll('input, textarea');
    for (var j = 0; j < inputs.length; j++) {
      var inp = inputs[j];
      if (inp.value) {
        var formattedVal = formatValue(inp.value);
        if (formattedVal) {
          inp.value = formattedVal;
        }
      }
    }

    // Format embedded timestamps within text nodes
    var walk = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT, null, false);
    var textNode;
    while ((textNode = walk.nextNode())) {
      if (textNode.nodeValue && textNode.nodeValue.indexOf('202') !== -1) {
        textNode.nodeValue = textNode.nodeValue.replace(
          /\b(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?\b/g,
          function(match, y, m, d, hh, mm) {
            return d + '/' + m + '/' + y + ' ' + hh + ':' + mm;
          }
        );
      }
    }
  }

  // Desktop templates contain wide tables. Scale only the table that
  // overflows, rather than shrinking its cells or the entire page. This
  // retains the normal readable mobile form size and prevents left/right
  // scrolling without causing fields to overlap.
  function fitWideTablesToViewport() {
    var availableWidth = (window.innerWidth || document.documentElement.clientWidth || 360) - 24;
    if (availableWidth <= 0) return;

    var candidates = document.querySelectorAll('table, .worksheet, .form-page, .page, .sheet-container');
    var target = null;
    var targetWidth = availableWidth;
    for (var i = 0; i < candidates.length; i++) {
      var element = candidates[i];
      element.style.setProperty('zoom', '1', 'important');
      var naturalWidth = Math.max(
        element.scrollWidth || 0,
        element.offsetWidth || 0,
        Math.ceil(element.getBoundingClientRect().width || 0)
      );
      if (naturalWidth > targetWidth + 2) {
        target = element;
        targetWidth = naturalWidth;
      }
    }
    if (target) {
      var scale = availableWidth / targetWidth;
      // Give the element its natural layout width first; Chromium's CSS zoom
      // then reserves exactly the scaled width in the parent flow.
      target.style.setProperty('width', targetWidth + 'px', 'important');
      target.style.setProperty('max-width', 'none', 'important');
      target.style.setProperty('zoom', String(scale), 'important');
    }
  }

  function applyEnhancements() {
    fitFormToScreen();
    formatDateTimestamps();
    fitWideTablesToViewport();
  }

  applyEnhancements();
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applyEnhancements);
  }
  window.addEventListener('load', applyEnhancements);
  setTimeout(applyEnhancements, 100);
  setTimeout(applyEnhancements, 300);
  setTimeout(applyEnhancements, 600);
  setTimeout(applyEnhancements, 1200);
  window.addEventListener('resize', applyEnhancements);
})();
""";
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint("Error injecting scale form script: $e");
    }
  }

  Future<void> _loadUrlWithAuth() async {
    final token = await AuthService.getAccessToken();
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    await _controller.loadRequest(Uri.parse(widget.url), headers: headers);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A192F) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
