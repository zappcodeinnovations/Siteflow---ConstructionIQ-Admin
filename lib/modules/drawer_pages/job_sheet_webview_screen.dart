import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/network/api_client.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'EurosideCamera',
        onMessageReceived: (_) => _pickNativeImages(ImageSource.camera),
      )
      ..addJavaScriptChannel(
        'EurosideGallery',
        onMessageReceived: (_) => _pickNativeImages(ImageSource.gallery),
      )
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
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            final source = Uri.tryParse(widget.url);
            // Success/reload links inside a form are normal browser
            // navigations. Re-fetch same-origin userform pages through the
            // authenticated API client so WebView never loses its JWT.
            if (request.isMainFrame &&
                target != null &&
                source != null &&
                target.host == source.host &&
                target.path.startsWith('/api/userform/')) {
              _loadUrlWithAuth(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
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
      )
      // Without this, a form's JavaScript alert() falls back to the WebView
      // engine's own raw browser-chrome dialog instead of looking native.
      ..setOnJavaScriptAlertDialog((request) async {
        if (!mounted) return;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            content: Text(
              request.message,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });

    _loadUrlWithAuth();
  }

  Future<void> _pickNativeImages(ImageSource source) async {
    try {
      final List<XFile> images;
      if (source == ImageSource.camera) {
        final image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 2048,
        );
        images = image == null ? <XFile>[] : <XFile>[image];
      } else {
        images = await _imagePicker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 2048,
        );
      }
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final extension = image.name.split('.').last.toLowerCase();
        final mimeType = extension == 'png'
            ? 'image/png'
            : extension == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
        final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
        await _controller.runJavaScript(
          'window.__eurosideReceiveNativeImage('
          '${jsonEncode(dataUrl)}, ${jsonEncode(image.name)});',
        );
      }
    } catch (error) {
      debugPrint('Native form image picker failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Unable to open the camera. Please check camera permission.'
                  : 'Unable to open the gallery. Please try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  Future<void> _injectAutoFitScript() async {
    final accessToken = await AuthService.getAccessToken();
    final isDark = mounted && Theme.of(context).brightness == Brightness.dark;
    final tokenAssignment =
        'window.__eurosideAccessToken = ${jsonEncode(accessToken ?? '')};';
    final themeAssignment =
        'window.__siteflowDarkMode = ${isDark ? 'true' : 'false'};';
    final script =
        '$tokenAssignment\n$themeAssignment\n${r"""
(function() {
  function fitFormToScreen() {
    // Keep the WebView on the physical device width. The document itself is
    // reflowed below; it is never scaled or cropped to make it fit.
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      document.head.appendChild(meta);
    }
    meta.setAttribute('content', 'width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=3.0, user-scalable=yes');

    var oldStyle = document.getElementById('siteflow-form-fit-style');
    if (oldStyle) oldStyle.remove();
    var oldLock = document.getElementById('siteflow-form-lock-style');
    if (oldLock) oldLock.remove();
    var oldAutofit = document.getElementById('siteflow-autofit-style');
    if (oldAutofit) oldAutofit.remove();

    var viewportWidth = window.innerWidth || document.documentElement.clientWidth || 360;
    if (viewportWidth > 600) return;

    // This is the common renderer for raw HTML forms (Daywork, materials,
    // plant and other library templates). It only runs on phone widths so
    // desktop and tablet templates retain their authored layout.
    var style = document.createElement('style');
    style.id = 'siteflow-form-fit-style';
    style.innerHTML = `
      @media (max-width: 600px) {
        *, *::before, *::after { box-sizing: border-box !important; }
        html, body {
          width: 100% !important;
          max-width: 100% !important;
          min-width: 0 !important;
          height: auto !important;
          min-height: 100% !important;
          margin: 0 !important;
          padding: 0 0 calc(180px + env(safe-area-inset-bottom, 0px)) !important;
          background-color: #f8fafc !important;
          -webkit-text-size-adjust: 100% !important;
          /* Some raw templates set body/page overflow:hidden or a fixed
             height. Restore document-level vertical scrolling so the assets
             appended after the Daywork sheet remain reachable. */
          overflow-y: auto !important;
        }
        #euroside-preview-form,
        #euroside-form-zoom-content,
        #euroside-form-zoom-inner,
        .form-container, .form-page, .form-wrap, .form-rendered,
        .sheet, .sheet-wrapper, .sheet-container, .sheet-card,
        .worksheet, .page, .wrapper, main,
        [class*="form-container"], [class*="sheet-container"] {
          display: block !important;
          width: 100% !important;
          max-width: 100% !important;
          min-width: 0 !important;
          height: auto !important;
          max-height: none !important;
          overflow: visible !important;
          margin-left: auto !important;
          margin-right: auto !important;
          transform: none !important;
        }
        .header, .info-row, .footer-area, .total-row, .company,
        [class*="header"], [class*="info-row"], [class*="footer"] {
          min-width: 0 !important;
          max-width: 100% !important;
          flex-wrap: wrap !important;
        }
        .header table, .company table, .sheet-header table,
        table.header, table.company, table.sheet-header {
          table-layout: fixed !important;
        }
        .header img, .company img, .sheet-header img,
        .logo img, .logo-block img {
          width: auto !important;
          max-width: min(100%, 180px) !important;
          margin-left: auto !important;
          margin-right: auto !important;
        }
        .header td, .header th, .company td, .company th,
        .sheet-header td, .sheet-header th {
          font-size: clamp(9px, 2.6vw, 12px) !important;
          line-height: 1.25 !important;
        }
        table {
          width: 100% !important;
          max-width: 100% !important;
          min-width: 0 !important;
          table-layout: fixed !important;
          border-collapse: collapse !important;
        }
        table col { width: auto !important; min-width: 0 !important; }
        table td, table th {
          width: auto !important;
          min-width: 0 !important;
          max-width: 100% !important;
          white-space: normal !important;
          overflow-wrap: anywhere !important;
          word-break: break-word !important;
          vertical-align: top !important;
        }
        table input:not([type="checkbox"]):not([type="radio"]),
        table textarea, table select {
          width: 100% !important;
          min-width: 0 !important;
          max-width: 100% !important;
          padding-left: 4px !important;
          padding-right: 4px !important;
        }
        table.euroside-mobile-dense-table {
          font-size: clamp(7px, 2.25vw, 10px) !important;
        }
        table.euroside-mobile-dense-table td,
        table.euroside-mobile-dense-table th {
          padding: 2px 1px !important;
          line-height: 1.15 !important;
        }
        table.euroside-mobile-dense-table input,
        table.euroside-mobile-dense-table select,
        table.euroside-mobile-dense-table textarea {
          min-height: 22px !important;
          padding: 1px !important;
          font-size: inherit !important;
        }
        input, textarea, select {
          max-width: 100% !important;
          min-width: 0 !important;
        }
        textarea { overflow-wrap: anywhere !important; }
        img, svg, video, picture, canvas {
          display: block;
          max-width: 100% !important;
          height: auto !important;
        }
        canvas.euroside-signature-pad { width: 100% !important; height: 180px !important; }
        .euroside-live-assets, .euroside-client-signatures {
          width: calc(100% - 24px) !important;
          max-width: 100% !important;
          min-width: 0 !important;
          margin-left: 12px !important;
          margin-right: 12px !important;
        }
        #siteflow-form-scroll-track {
          position: fixed;
          z-index: 2147483646;
          top: calc(env(safe-area-inset-top, 0px) + 10px);
          right: 3px;
          bottom: calc(env(safe-area-inset-bottom, 0px) + 10px);
          width: 14px;
          border-radius: 999px;
          background: rgba(15, 23, 42, .08);
          opacity: .72;
          touch-action: none;
        }
        #siteflow-form-scroll-indicator {
          position: absolute;
          left: 5px;
          top: 0;
          width: 4px;
          min-height: 36px;
          border-radius: 999px;
          background: rgba(13, 110, 253, .62);
          box-shadow: 0 1px 3px rgba(15, 23, 42, .24);
          pointer-events: auto;
        }
      }
    `;
    document.head.appendChild(style);

    var cameraButton = document.getElementById('euroside-live-camera-open');
    var galleryButton = document.getElementById('euroside-live-gallery-open');
    if (cameraButton && window.EurosideCamera && window.EurosideCamera.postMessage) {
      cameraButton.addEventListener('click', function (event) {
        event.preventDefault();
        event.stopImmediatePropagation();
        window.EurosideCamera.postMessage('open');
      }, true);
    }
    if (galleryButton && window.EurosideGallery && window.EurosideGallery.postMessage) {
      galleryButton.addEventListener('click', function (event) {
        event.preventDefault();
        event.stopImmediatePropagation();
        window.EurosideGallery.postMessage('open');
      }, true);
    }

    // The post-submit page comes from the backend as HTML. Respect the app's
    // selected theme even when Android WebView's system color-scheme does not
    // match the Flutter ThemeMode (for example, an in-app Dark Mode choice).
    var successCard = document.querySelector('.success-card');
    if (successCard && window.__siteflowDarkMode) {
      document.documentElement.style.setProperty('color-scheme', 'dark');
      document.documentElement.style.setProperty('background-color', '#0a192f', 'important');
      document.body.style.setProperty('background-color', '#0a192f', 'important');
      document.body.style.setProperty('color', '#f8fafc', 'important');
      successCard.style.setProperty('background-color', '#111827', 'important');
      successCard.style.setProperty('border-color', '#334155', 'important');
      successCard.style.setProperty('box-shadow', '0 18px 40px rgba(0, 0, 0, 0.35)', 'important');
      var successHeading = successCard.querySelector('h1');
      var successCopy = successCard.querySelector('p');
      if (successHeading) successHeading.style.setProperty('color', '#f8fafc', 'important');
      if (successCopy) successCopy.style.setProperty('color', '#cbd5e1', 'important');
    }

    var scrollTrack = document.getElementById('siteflow-form-scroll-track');
    if (!scrollTrack) {
      scrollTrack = document.createElement('div');
      scrollTrack.id = 'siteflow-form-scroll-track';
      scrollTrack.setAttribute('aria-label', 'Form scroll position');
      document.body.appendChild(scrollTrack);
    }
    var scrollIndicator = document.getElementById('siteflow-form-scroll-indicator');
    if (!scrollIndicator) {
      scrollIndicator = document.createElement('div');
      scrollIndicator.id = 'siteflow-form-scroll-indicator';
      scrollIndicator.setAttribute('aria-hidden', 'true');
      scrollTrack.appendChild(scrollIndicator);
    }
    function updateScrollIndicator() {
      var root = document.scrollingElement || document.documentElement;
      var visibleHeight = root.clientHeight || window.innerHeight || 1;
      var totalHeight = root.scrollHeight || visibleHeight;
      if (totalHeight <= visibleHeight + 1) {
        scrollTrack.style.display = 'none';
        return;
      }
      scrollTrack.style.display = 'block';
      var trackHeight = Math.max(scrollTrack.clientHeight, 1);
      var thumbHeight = Math.max((visibleHeight / totalHeight) * trackHeight, 36);
      var maxTop = Math.max(trackHeight - thumbHeight, 0);
      var maxScroll = Math.max(totalHeight - visibleHeight, 1);
      var top = (root.scrollTop / maxScroll) * maxTop;
      scrollIndicator.style.height = thumbHeight + 'px';
      scrollIndicator.style.transform = 'translateY(' + top + 'px)';
    }
    window.addEventListener('scroll', updateScrollIndicator, { passive: true });
    window.addEventListener('resize', updateScrollIndicator);
    function scrollFromPointer(event) {
      var root = document.scrollingElement || document.documentElement;
      var point = event.touches && event.touches.length ? event.touches[0] : event;
      var bounds = scrollTrack.getBoundingClientRect();
      var ratio = Math.max(0, Math.min(1, (point.clientY - bounds.top) / Math.max(bounds.height, 1)));
      root.scrollTop = ratio * Math.max(root.scrollHeight - root.clientHeight, 0);
      updateScrollIndicator();
    }
    scrollTrack.addEventListener('pointerdown', function (event) {
      event.preventDefault();
      scrollFromPointer(event);
      if (scrollTrack.setPointerCapture) scrollTrack.setPointerCapture(event.pointerId);
    });
    scrollTrack.addEventListener('pointermove', function (event) {
      if (event.buttons) scrollFromPointer(event);
    });
    scrollTrack.addEventListener('touchstart', function (event) {
      event.preventDefault();
      scrollFromPointer(event);
    }, { passive: false });
    scrollTrack.addEventListener('touchmove', function (event) {
      event.preventDefault();
      scrollFromPointer(event);
    }, { passive: false });
    setTimeout(updateScrollIndicator, 0);
    setTimeout(updateScrollIndicator, 500);

    // Templates often carry inline desktop widths (and width attributes),
    // which can beat their own CSS. Clear only layout widths in the reusable
    // form wrappers and tables; values, fields and table columns remain.
    var wrappers = document.querySelectorAll(
      '.form-container, .form-page, .form-wrap, .form-rendered, .sheet, ' +
      '.sheet-wrapper, .sheet-container, .sheet-card, .worksheet, .page, .wrapper, main'
    );
    for (var i = 0; i < wrappers.length; i++) {
      wrappers[i].style.setProperty('width', '100%', 'important');
      wrappers[i].style.setProperty('max-width', '100%', 'important');
      wrappers[i].style.setProperty('min-width', '0', 'important');
    }

    var tables = document.querySelectorAll('table');
    for (var j = 0; j < tables.length; j++) {
      var table = tables[j];
      table.style.setProperty('width', '100%', 'important');
      table.style.setProperty('max-width', '100%', 'important');
      table.style.setProperty('min-width', '0', 'important');
      table.style.setProperty('table-layout', 'fixed', 'important');

      var maxColumns = 0;
      for (var r = 0; r < table.rows.length; r++) {
        var columns = 0;
        for (var c = 0; c < table.rows[r].cells.length; c++) {
          columns += table.rows[r].cells[c].colSpan || 1;
        }
        maxColumns = Math.max(maxColumns, columns);
      }
      table.classList.toggle('euroside-mobile-dense-table', maxColumns >= 7);

      var cells = table.querySelectorAll('th, td');
      for (var k = 0; k < cells.length; k++) {
        cells[k].style.setProperty('min-width', '0', 'important');
        cells[k].style.setProperty('max-width', '100%', 'important');
        cells[k].style.setProperty('width', 'auto', 'important');
        cells[k].style.setProperty('white-space', 'normal', 'important');
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

  // NOTE: The previous implementation here ("fitWideTablesToViewport") shrank
  // overflowing desktop tables using CSS `zoom` to force them into the
  // viewport. That distorted text/tables and fought the backend's responsive
  // reflow. The backend form shell now reflows wide tables to the real device
  // width via its @media CSS, so no client-side scaling is needed here.

  function applyEnhancements() {
    fitFormToScreen();
    formatDateTimestamps();
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
"""}';
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint("Error injecting scale form script: $e");
    }
  }

  Future<void> _loadUrlWithAuth([String? url]) async {
    final sourceUrl = url ?? widget.url;
    try {
      // Android WebView does not consistently retain custom Authorization
      // headers for a top-level page navigation. Fetching the HTML through
      // ApiClient guarantees the same authenticated request/refresh flow the
      // rest of the app uses, then keeps the original URL as the document's
      // base so relative assets and form endpoints still resolve correctly.
      final response = await ApiClient.get(sourceUrl);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _controller.loadHtmlString(response.body, baseUrl: sourceUrl);
        return;
      }
      await _controller.loadHtmlString(
        _formLoadErrorHtml(response.statusCode),
        baseUrl: sourceUrl,
      );
    } catch (error) {
      await _controller.loadHtmlString(
        _formLoadErrorHtml(null),
        baseUrl: sourceUrl,
      );
    }
  }

  String _formLoadErrorHtml(int? statusCode) {
    final detail = statusCode == 401
        ? 'Your session has expired. Please sign in again.'
        : 'The form could not be opened. Please retry.';
    return '''<!doctype html><html><body style="font-family:Arial,sans-serif;padding:24px;color:#0f172a"><h2>Unable to open form</h2><p>$detail</p></body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A192F)
          : const Color(0xFFF8FAFC),
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
