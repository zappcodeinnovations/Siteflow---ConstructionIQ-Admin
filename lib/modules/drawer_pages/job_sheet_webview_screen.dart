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
  function scaleFormToFit() {
    // 1. Clean up any previous style overrides
    var oldStyle = document.getElementById('siteflow-form-lock-style');
    if (oldStyle) oldStyle.remove();
    var oldAutofit = document.getElementById('siteflow-autofit-style');
    if (oldAutofit) oldAutofit.remove();

    // 2. Reset inline styles on body so natural dimensions can be measured
    document.body.style.zoom = '1';
    document.body.style.transform = 'none';

    var screenWidth = window.screen.width || window.innerWidth || document.documentElement.clientWidth;
    if (!screenWidth || screenWidth <= 0) return;

    // 3. Find the main form container / tables to measure natural layout width
    var mainEl = document.querySelector('.form-container') ||
                 document.querySelector('.container') ||
                 document.querySelector('.page') ||
                 document.querySelector('form') ||
                 document.querySelector('table') ||
                 document.body;

    var detectedWidth = Math.max(
      document.body.scrollWidth || 0,
      document.documentElement.scrollWidth || 0,
      mainEl ? (mainEl.scrollWidth || mainEl.offsetWidth || 0) : 0
    );

    // Standard desktop / A4 print form width (at least 1024px for full zoom-out view)
    var targetWidth = Math.max(detectedWidth, 1024);

    // Zoom out with comfortable padding so the entire form borders fit inside the screen
    var scale = ((screenWidth - 16) / targetWidth) * 0.94;
    scale = Math.floor(scale * 10000) / 10000;

    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      document.head.appendChild(meta);
    }
    meta.setAttribute('content', 'width=' + targetWidth + ', initial-scale=' + scale + ', minimum-scale=' + (scale * 0.5) + ', maximum-scale=5.0, user-scalable=yes');

    var style = document.createElement('style');
    style.id = 'siteflow-form-lock-style';
    style.innerHTML = `
      html {
        min-width: ${targetWidth}px !important;
        background-color: transparent !important;
      }
      body {
        min-width: ${targetWidth}px !important;
        margin: 0 auto !important;
        padding: 10px !important;
        background-color: transparent !important;
      }
    `;
    document.head.appendChild(style);
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

  function applyEnhancements() {
    formatDateTimestamps();
    scaleFormToFit();
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
        backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
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
