import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _mainCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _pulse;

  // FIX: سبب الشاشة البيضاء — الـ listener كان يُطلق go() قبل اكتمال
  // animation frame. نُضيف timeout أقصى 4 ثوان لضمان الانتقال دائماً.
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );
    _titleSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.35, 0.7, curve: Curves.easeIn),
    );
    _subtitleFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _mainCtrl.forward();

    // FIX: Timeout كـ safety net — إذا بقي AuthInitial أكثر من 4 ثوان
    // نُوجّه للـ login مباشرة بدلاً من إبقاء الشاشة البيضاء.
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || _hasNavigated) return;
      final s = ref.read(authProvider);
      if (s is AuthInitial || s is AuthLoading) {
        _navigate(const AuthUnauthenticated());
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  void _navigate(AuthState next) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    if (next is AuthAuthenticated) {
      context.go('/home');
    } else if (next is AuthUnauthenticated || next is AuthError) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: استخدام ref.listen بدل الاستجابة المباشرة — يضمن عدم
    // استدعاء context.go أثناء build مما يُسبب شاشة بيضاء.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthAuthenticated || next is AuthUnauthenticated || next is AuthError) {
        // تأخير صغير لضمان اكتمال أول frame
        Future.microtask(() => _navigate(next));
      }
    });

    // FIX: إذا كانت الحالة جاهزة عند أول build (مثلاً app restart سريع)
    // نستجيب مباشرة بعد أول frame
    final currentState = ref.read(authProvider);
    if (currentState is AuthAuthenticated ||
        currentState is AuthUnauthenticated ||
        currentState is AuthError) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigate(currentState));
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE52027),
                  Color(0xFFBF1219),
                  Color(0xFF8B0D12),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Decorative circles ──────────────────────────────────────────
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.35, left: -40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // ── Animated wave ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => CustomPaint(
                painter: _WavePainter(_waveCtrl.value),
                size: Size(size.width, 120),
              ),
            ),
          ),

          // ── Golden line ─────────────────────────────────────────────────
          Positioned(
            bottom: 110,
            left: size.width * 0.25,
            right: size.width * 0.25,
            child: AnimatedBuilder(
              animation: _subtitleFade,
              builder: (_, __) => Opacity(
                opacity: _subtitleFade.value,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Colors.transparent,
                      AppTheme.brandGold,
                      Colors.transparent,
                    ]),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoScale, _logoFade, _pulse]),
                    builder: (_, __) => FadeTransition(
                      opacity: _logoFade,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 165 + (_pulse.value * 12),
                              height: 165 + (_pulse.value * 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                                    .withValues(alpha: 0.08 * (1 - _pulse.value * 0.5)),
                              ),
                            ),
                            Container(
                              width: 148, height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 145, height: 145,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(18),
                              child: const AppLogo(size: 108),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Title
                  AnimatedBuilder(
                    animation: Listenable.merge([_titleSlide, _titleFade]),
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Column(
                          children: [
                            const Text(
                              'القوافل التعليمية',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 50, height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.brandGold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'نطوّر لنبني مستقبلاً مستداماً',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Loading dots
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: _LoadingDots(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wave Painter ──────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double progress;
  const _WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    _drawWave(canvas, size, paint1, progress, 1.0);
    _drawWave(canvas, size, paint2, progress + 0.5, 0.7);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint,
      double offset, double amplitude) {
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y =
          math.sin((x / size.width * 2 * math.pi) + (offset * 2 * math.pi)) *
              (size.height * 0.35 * amplitude) +
          size.height * 0.55;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

// ── Loading Dots ──────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final v = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * math.sin(v * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.5 + 0.5 * scale),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
