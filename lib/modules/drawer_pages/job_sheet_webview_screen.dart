import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:image_picker/image_picker.dart';
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
      ..setBackgroundColor(const Color(0x00000000));

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController).setOnShowFileSelector(
        (FileSelectorParams params) async {
          try {
            final ImagePicker picker = ImagePicker();
            final choice = await showModalBottomSheet<String>(
              context: context,
              builder: (context) {
                return SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Take Photo (Camera)'),
                        onTap: () => Navigator.pop(context, 'camera'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Choose from Gallery'),
                        onTap: () => Navigator.pop(context, 'gallery'),
                      ),
                    ],
                  ),
                );
              },
            );

            if (choice == 'camera') {
              final XFile? photo = await picker.pickImage(source: ImageSource.camera);
              if (photo != null) {
                return [Uri.file(photo.path).toString()];
              }
            } else if (choice == 'gallery') {
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                return [Uri.file(image.path).toString()];
              }
            }
          } catch (e) {
            debugPrint("File/Camera picker error: $e");
          }
          return [];
        },
      );
    }

    _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          if (request.url.contains('api/userform') || request.url.contains('submitted=1')) {
            final token = await AuthService.getAccessToken();
            if (token != null) {
              _controller.loadRequest(Uri.parse(request.url), headers: {'Authorization': 'Bearer $token'});
              return NavigationDecision.prevent;
            }
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
        },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });

            final token = await AuthService.getAccessToken();
            if (token != null) {
              await _controller.runJavaScript('''
                try {
                  localStorage.setItem('access_token', '$token');
                  localStorage.setItem('token', '$token');
                  localStorage.setItem('auth_token', '$token');

                  const originalFetch = window.fetch;
                  window.fetch = function(...args) {
                    let [resource, config] = args;
                    config = config || {};
                    config.headers = config.headers || {};
                    if (config.headers instanceof Headers) {
                      config.headers.set('Authorization', 'Bearer $token');
                    } else {
                      config.headers['Authorization'] = 'Bearer $token';
                    }
                    return originalFetch(resource, config);
                  };

                  const originalOpen = XMLHttpRequest.prototype.open;
                  XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
                    this._url = url;
                    return originalOpen.apply(this, arguments);
                  };
                  const originalSend = XMLHttpRequest.prototype.send;
                  XMLHttpRequest.prototype.send = function(body) {
                    try {
                      this.setRequestHeader('Authorization', 'Bearer $token');
                    } catch(e) {}
                    return originalSend.apply(this, arguments);
                  };
                } catch(e) {}
              ''');
            }

            // Inject dynamic responsive auto-fit script
            await _controller.runJavaScript('''
              (function() {
                var meta = document.querySelector('meta[name="viewport"]');
                if (!meta) {
                  meta = document.createElement('meta');
                  meta.name = 'viewport';
                  document.head.appendChild(meta);
                }
                meta.content = 'width=device-width, initial-scale=1.0, minimum-scale=0.2, maximum-scale=5.0, user-scalable=yes';

                function autoFitToScreen() {
                  try {
                    document.body.style.zoom = '100%';
                    document.documentElement.style.overflowX = 'hidden';

                    var body = document.body;
                    var html = document.documentElement;
                    if (!body) return;

                    var naturalWidth = Math.max(
                      body.scrollWidth,
                      body.offsetWidth,
                      html.scrollWidth,
                      html.offsetWidth
                    );

                    var elements = document.querySelectorAll('table, .container, .form-container, #form-container, .main-content, form');
                    for (var i = 0; i < elements.length; i++) {
                      var el = elements[i];
                      var w = Math.max(el.scrollWidth || 0, el.offsetWidth || 0);
                      if (w > naturalWidth) {
                        naturalWidth = w;
                      }
                    }

                    var clientWidth = window.innerWidth || html.clientWidth || screen.width;

                    if (naturalWidth > clientWidth && clientWidth > 0) {
                      var availableWidth = clientWidth - 8;
                      var scale = availableWidth / naturalWidth;
                      
                      document.body.style.zoom = (scale * 100).toFixed(2) + '%';
                      document.body.style.margin = '0 auto';
                      document.body.style.paddingBottom = '100px';
                      document.body.style.boxSizing = 'border-box';
                    } else {
                      document.body.style.zoom = '100%';
                      document.body.style.paddingBottom = '100px';
                    }
                  } catch(e) {
                    console.error('AutoFit error:', e);
                  }
                }

                autoFitToScreen();
                setTimeout(autoFitToScreen, 100);
                setTimeout(autoFitToScreen, 300);
                setTimeout(autoFitToScreen, 700);
                setTimeout(autoFitToScreen, 1500);

                window.removeEventListener('resize', autoFitToScreen);
                window.addEventListener('resize', autoFitToScreen);
                window.addEventListener('orientationchange', function() {
                  setTimeout(autoFitToScreen, 200);
                });
              })();
            ''');
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
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
