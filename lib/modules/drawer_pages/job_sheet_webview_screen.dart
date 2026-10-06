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
  function fitToViewport() {
    // 1. Inject or update viewport meta tag
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      document.head.appendChild(meta);
    }
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';

    // 2. Add base style overrides
    if (!document.getElementById('siteflow-autofit-style')) {
      var style = document.createElement('style');
      style.id = 'siteflow-autofit-style';
      style.innerHTML = `
        html, body {
          margin: 0 !important;
          padding: 0 !important;
          box-sizing: border-box !important;
          overflow-x: hidden !important;
        }
        * {
          box-sizing: border-box !important;
        }
      `;
      document.head.appendChild(style);
    }

    // 3. Measure content width and auto-scale if wider than screen
    var screenWidth = window.innerWidth || document.documentElement.clientWidth || screen.width;
    if (!screenWidth || screenWidth <= 0) return;

    document.body.style.zoom = '1';
    document.body.style.transform = 'none';
    document.body.style.width = 'auto';

    var rootEl = document.querySelector('.form-container') || 
                 document.querySelector('.container') || 
                 document.querySelector('.page') || 
                 document.querySelector('form') || 
                 document.body.firstElementChild || 
                 document.body;

    var contentWidth = Math.max(
      document.body.scrollWidth,
      document.documentElement.scrollWidth,
      rootEl ? (rootEl.scrollWidth || rootEl.offsetWidth) : 0
    );

    if (contentWidth > screenWidth) {
      var padding = 6;
      var availableWidth = screenWidth - (padding * 2);
      var scale = availableWidth / contentWidth;

      if ('zoom' in document.body.style) {
        document.body.style.zoom = scale;
        document.body.style.padding = (padding / scale) + 'px';
      } else {
        document.body.style.transformOrigin = 'top left';
        document.body.style.transform = 'scale(' + scale + ')';
        document.body.style.width = (100 / scale) + '%';
        document.body.style.padding = padding + 'px';
      }
    }
  }

  fitToViewport();
  setTimeout(fitToViewport, 100);
  setTimeout(fitToViewport, 300);
  setTimeout(fitToViewport, 700);
  setTimeout(fitToViewport, 1500);
  window.addEventListener('resize', fitToViewport);
})();
""";
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint("Error injecting autofit script: $e");
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
