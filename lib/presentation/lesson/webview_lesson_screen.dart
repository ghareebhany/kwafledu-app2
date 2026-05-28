import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/widgets/secure_screen.dart';
import '../../domain/entities/lesson.dart';
import '../providers/di_providers.dart';
import '../screens/video_progress_service.dart';

class WebViewLessonScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  final int courseId;
  final List<Lesson> allLessons;

  const WebViewLessonScreen({
    super.key,
    required this.lesson,
    required this.courseId,
    required this.allLessons,
  });

  @override
  ConsumerState<WebViewLessonScreen> createState() =>
      _WebViewLessonScreenState();
}

class _WebViewLessonScreenState extends ConsumerState<WebViewLessonScreen> {
  late Lesson _current;
  WebViewController? _ctrl;

  bool _loading          = true;
  bool _hasError         = false;
  bool _completionFired  = false;

  @override
  void initState() {
    super.initState();
    _current = widget.lesson;
    _loadLesson(_current);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // تحميل الدرس
  // الحل الصحيح: نُمرّر JWT كـ ?token=JWT في الـ URL نفسه بدل Authorization header.
  // app_player.php يقرأ التوكن من query string ويُسجّل المستخدم بـ wp_set_current_user()
  // فتعمل جميع sub-requests (CSS/JS/iframe) بنفس الجلسة بدون حاجة لـ headers.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadLesson(Lesson lesson) async {
    setState(() {
      _loading         = true;
      _hasError        = false;
      _completionFired = false;
      _ctrl            = null;
    });

    final token = await SecureStorageService.instance.getToken();
    if (token == null || token.isEmpty) {
      setState(() { _hasError = true; _loading = false; });
      return;
    }

    // بناء URL بنمط: /lesson-permalink/?app=1&token=JWT
    // app_player.php يُفعَّل بـ add_action('wp', 'app_mode_init', 1)
    // يُسجّل المستخدم ويُضيف CSS+JS bridge بدون الثيم
    final lessonUrl = _buildLessonUrl(lesson, token);

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
          // UA كامل: Android + Mobile keyword ضروري لـ YouTube يتحقق منه
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..enableZoom(false);

    // ── Android WebView settings ───────────────────────────────────────────
    // setMediaPlaybackRequiresUserGesture(false)
    //   → يرفع حظر Android الافتراضي على تشغيل media برمجياً
    //   → بدونه: Plyr يرسل play() لـ YouTube API لكن Stream لا يبدأ
    // ملاحظة: setDomStorageEnabled غير مُعرَّضة في Flutter plugin (native only)
    //   → DOM Storage مُفعَّل افتراضياً في Android WebView الحديث
    if (ctrl.platform is AndroidWebViewController) {
      (ctrl.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    ctrl
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (e) {
            // تجاهل أخطاء sub-resources (fonts/icons) — أبلّغ فقط عن الصفحة الرئيسية
            if ((e.isForMainFrame ?? false) && mounted) {
              setState(() { _hasError = true; _loading = false; });
            }
          },
          onNavigationRequest: (req) {
            final uri  = Uri.tryParse(req.url);
            final host = uri?.host ?? '';

            // السماح بكل طلبات الموقع وموفّري الفيديو والأصول
            const allowed = [
              'kwafledu.com',
              'youtube.com',
              'youtube-nocookie.com',
              'youtu.be',
              'ytimg.com',
              'googlevideo.com',
              'vimeo.com',
              'player.vimeo.com',
              'vimeocdn.com',
              'fonts.googleapis.com',
              'fonts.gstatic.com',
              'googleapis.com',
            ];

            final isAllowed = allowed.any((h) => host == h || host.endsWith('.$h'));
            return isAllowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel('AppChannel',  onMessageReceived: _onVideoEvent)
      ..addJavaScriptChannel('VideoEvents', onMessageReceived: _onVideoEvent)
      // تحميل الدرس بدون Authorization header — التوكن في الـ URL
      ..loadRequest(Uri.parse(lessonUrl));

    if (mounted) setState(() => _ctrl = ctrl);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // بناء رابط الدرس بـ ?app=1&token=JWT
  // يستخدم app-player rewrite rule أو permalink مباشرة
  // ─────────────────────────────────────────────────────────────────────────
  String _buildLessonUrl(Lesson lesson, String token) {
    final encodedToken = Uri.encodeComponent(token);

    // الأولوية: lessonUrl من API (صفحة الدرس الحقيقية على الموقع)
    // app_player.php يُفعَّل بـ ?app=1 ويُسجّل المستخدم بالـ token
    if (lesson.lessonUrl.isNotEmpty) {
      final base = lesson.lessonUrl.endsWith('/')
          ? lesson.lessonUrl
          : '${lesson.lessonUrl}/';
      return '${base}?app=1&token=$encodedToken';
    }

    // Fallback: rewrite rule /app-player/{lesson_id}/?app=1&token=
    return ApiConstants.appPlayerUrl(lesson.id, token);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // أحداث الفيديو من Plyr عبر JavaScript channel
  // ─────────────────────────────────────────────────────────────────────────
  void _onVideoEvent(JavaScriptMessage msg) {
    final data = msg.message;

    switch (data) {
      case 'ended':
        if (!_completionFired) {
          _completionFired = true;
          _handleCompletion();
        }
      case 'ready':
        if (mounted) setState(() => _loading = false);
      case 'play':
      case 'pause':
        break;
      default:
        if (data.startsWith('time:')) {
          final sec = int.tryParse(data.substring(5)) ?? 0;
          VideoProgressService.instance.savePosition(_current.id, sec);
        } else if (data.startsWith('pdf:')) {
          _openAttachment(data.substring(4));
        } else if (data.startsWith('open:')) {
          _openAttachment(data.substring(5));
        }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // إتمام الدرس والانتقال للتالي
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleCompletion() async {
    await ref
        .read(markLessonCompleteUseCaseProvider)
        .call(_current.id, widget.courseId);
    await VideoProgressService.instance.clearPosition(_current.id);
    if (!mounted) return;
    await _checkAndMoveToNextLesson();
  }

  Future<void> _checkAndMoveToNextLesson() async {
    if (!mounted) return;
    final idx  = widget.allLessons.indexWhere((l) => l.id == _current.id);
    final next = (idx >= 0 && idx + 1 < widget.allLessons.length)
        ? widget.allLessons[idx + 1]
        : null;

    if (next != null) {
      setState(() => _current = next);
      _loadLesson(next);
    } else {
      await ref.read(markCourseCompleteUseCaseProvider).call(widget.courseId);
      if (mounted) _showCourseComplete();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // مرفقات الدرس
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openAttachment(String url) async {
    final token = await SecureStorageService.instance.getToken() ?? '';
    if (!mounted) return;

    // أضف token للمرفق أيضاً لضمان المصادقة
    final attachUrl = url.contains('?')
        ? '$url&token=${Uri.encodeComponent(token)}'
        : '$url?token=${Uri.encodeComponent(token)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(attachUrl)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1a1a),
          foregroundColor: Colors.white,
          title: Text(
            _current.title,
            style: const TextStyle(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_rounded),
              onPressed: _showLessonsList,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (_ctrl != null)
                    WebViewWidget(controller: _ctrl!),

                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe52027)),
                      ),
                    ),

                  if (_hasError && !_loading)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text('فشل تحميل الدرس',
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => _loadLesson(_current),
                            icon: const Icon(Icons.refresh, color: Color(0xFFe52027)),
                            label: const Text('إعادة المحاولة',
                                style: TextStyle(color: Color(0xFFe52027))),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNavBar() {
    final lessons = widget.allLessons;
    final idx     = lessons.indexWhere((l) => l.id == _current.id);
    final hasPrev = idx > 0;
    final hasNext = idx >= 0 && idx + 1 < lessons.length;

    return Container(
      color: const Color(0xFF1a1a1a),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: hasPrev ? () => _loadLesson(lessons[idx - 1]) : null,
            style: TextButton.styleFrom(
              foregroundColor: hasPrev ? const Color(0xFFe52027) : Colors.grey,
            ),
            child: const Text('السابق'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${idx + 1} / ${lessons.length}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: hasNext ? () => _loadLesson(lessons[idx + 1]) : null,
            style: TextButton.styleFrom(
              foregroundColor: hasNext ? const Color(0xFFe52027) : Colors.grey,
            ),
            child: const Text('التالي'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  void _showCourseComplete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تهانينا 🎉'),
        content: const Text('أنهيت جميع دروس الكورس بنجاح'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('رجوع'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  void _showLessonsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView.builder(
        itemCount: widget.allLessons.length,
        itemBuilder: (_, i) {
          final l         = widget.allLessons[i];
          final isCurrent = l.id == _current.id;
          return ListTile(
            title: Text(
              l.title,
              style: TextStyle(
                color:      isCurrent ? const Color(0xFFe52027) : Colors.white,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isCurrent
                ? const Icon(Icons.play_circle, color: Color(0xFFe52027), size: 20)
                : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _current = l);
              _loadLesson(l);
            },
          );
        },
      ),
    );
  }
}
