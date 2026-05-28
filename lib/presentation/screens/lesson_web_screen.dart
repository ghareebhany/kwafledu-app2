import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';

/// عرض الدروس النصية / PDF / واجبات في WebView
/// يستخدم نفس endpoint /lesson-view/{id}
class LessonWebScreen extends StatefulWidget {
  final int lessonId;
  final String title;
  const LessonWebScreen({super.key, required this.lessonId, required this.title});

  @override
  State<LessonWebScreen> createState() => _LessonWebScreenState();
}

class _LessonWebScreenState extends State<LessonWebScreen> {
  WebViewController? _ctrl;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await SecureStorageService.instance.getToken() ?? '';
    final url   = ApiConstants.lessonViewUrl(widget.lessonId);

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) {
            setState(() { _hasError = true; _loading = false; });
          }
        },
      ))
      ..addJavaScriptChannel('VideoEvents', onMessageReceived: (_) {})
      ..loadRequest(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});

    setState(() => _ctrl = ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: Stack(children: [
        if (_ctrl != null) WebViewWidget(controller: _ctrl!),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        if (_hasError)
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('تعذّر تحميل المحتوى'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ]),
          ),
      ]),
    );
  }
}
