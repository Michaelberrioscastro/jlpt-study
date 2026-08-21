import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/home_screen.dart';
import '../theme/app_colors.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;

  late final AnimationController _introController;
  late final AnimationController _loopController;
  late final AnimationController _exitController;

  late final Animation<double> _introOpacity;
  late final Animation<double> _introScale;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final introCurve = CurvedAnimation(
      parent: _introController,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );

    _introOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: introCurve,
        curve: const Interval(0, .72, curve: Curves.easeOut),
      ),
    );

    _introScale = Tween<double>(begin: .94, end: 1).animate(introCurve);

    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _introController.forward();
    _loopController.repeat();

    _timer = Timer(const Duration(milliseconds: 2900), _finishSplash);
  }

  Future<void> _finishSplash() async {
    if (!mounted) return;

    await _exitController.forward();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 460),
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: .992, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introController.dispose();
    _loopController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _fadeOut,
          child: AnimatedBuilder(
            animation: Listenable.merge([_introController, _loopController]),
            builder: (context, _) {
              final loop = _loopController.value;
              final floatY = math.sin(loop * math.pi * 2) * 4;
              final breathe = 1 + (math.sin(loop * math.pi * 2) * .006);

              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _JapaneseSplashPainter(progress: loop)),

                  SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 3),

                        FadeTransition(
                          opacity: _introOpacity,
                          child: ScaleTransition(
                            scale: _introScale,
                            child: Transform.translate(
                              offset: Offset(0, floatY),
                              child: Transform.scale(
                                scale: breathe,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 370,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                  ),
                                  child: Image.asset(
                                    'assets/branding/jlpt_study_brand.png',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),

                        FadeTransition(
                          opacity: _introOpacity,
                          child: _GoldLoader(progress: loop),
                        ),

                        const SizedBox(height: 14),

                        FadeTransition(
                          opacity: _introOpacity,
                          child: const Text(
                            '日本語を、一歩ずつ。',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .7,
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoldLoader extends StatelessWidget {
  final double progress;

  const _GoldLoader({required this.progress});

  @override
  Widget build(BuildContext context) {
    const count = 12;
    const size = 42.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var index = 0; index < count; index++)
            Transform.rotate(
              angle: (math.pi * 2 / count) * index,
              child: Align(
                alignment: Alignment.topCenter,
                child: _LoaderDash(active: _isActive(index, progress, count)),
              ),
            ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.brandGold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(int index, double progress, int count) {
    final activeIndex = (progress * count).floor() % count;
    final distance = (activeIndex - index) % count;

    return distance == 0 || distance == 1 || distance == 2;
  }
}

class _LoaderDash extends StatelessWidget {
  final bool active;

  const _LoaderDash({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      width: 3.5,
      height: 9,
      decoration: BoxDecoration(
        color: active ? AppColors.brandGold : AppColors.goldSoft,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _JapaneseSplashPainter extends CustomPainter {
  final double progress;

  _JapaneseSplashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    _paintPaper(canvas, size);
    _paintClouds(canvas, size);
    _paintWavePattern(canvas, size);
    _paintBranch(canvas, size);
    _paintFallingPetals(canvas, size);
    _paintBottomWave(canvas, size);
  }

  void _paintPaper(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, paint);

    final grain = Paint()
      ..color = AppColors.goldSoft.withValues(alpha: .12)
      ..strokeWidth = .7;

    final stepX = size.width / 18;
    final stepY = size.height / 30;

    for (var row = 0; row < 30; row++) {
      for (var column = 0; column < 18; column++) {
        if ((row + column) % 4 != 0) continue;

        final x = column * stepX + ((row % 2) * 3);
        final y = row * stepY;
        canvas.drawCircle(Offset(x, y), .45, grain);
      }
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.goldSoft.withValues(alpha: .18)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 13;

    canvas.drawLine(
      Offset(-30, size.height * .18),
      Offset(size.width * .20, size.height * .18),
      paint,
    );

    canvas.drawLine(
      Offset(-15, size.height * .205),
      Offset(size.width * .31, size.height * .205),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * .80, size.height * .67),
      Offset(size.width + 32, size.height * .67),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * .74, size.height * .695),
      Offset(size.width + 22, size.height * .695),
      paint,
    );
  }

  void _paintWavePattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;

    final baseY = size.height * .73;
    const radius = 24.0;

    for (var row = 0; row < 7; row++) {
      final y = baseY + (row * 20);

      for (var column = -1; column < 11; column++) {
        final x = column * radius * 1.6 + ((row % 2) * radius * .8);

        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: radius),
          math.pi,
          math.pi,
          false,
          paint,
        );
      }
    }
  }

  void _paintBranch(Canvas canvas, Size size) {
    final branchPaint = Paint()
      ..color = AppColors.brandGold.withValues(alpha: .72)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width * .68, size.height * .12);
    final end = Offset(size.width * 1.04, size.height * .015);

    canvas.drawLine(start, end, branchPaint);

    final twigs = [
      (
        Offset(size.width * .76, size.height * .095),
        Offset(size.width * .72, size.height * .055),
      ),
      (
        Offset(size.width * .84, size.height * .072),
        Offset(size.width * .87, size.height * .032),
      ),
      (
        Offset(size.width * .91, size.height * .048),
        Offset(size.width * .95, size.height * .075),
      ),
    ];

    for (final twig in twigs) {
      canvas.drawLine(twig.$1, twig.$2, branchPaint);
    }

    final blossomPaint = Paint()
      ..color = AppColors.brandGold.withValues(alpha: .72);

    final blossomCenters = [
      Offset(size.width * .72, size.height * .055),
      Offset(size.width * .79, size.height * .075),
      Offset(size.width * .87, size.height * .032),
      Offset(size.width * .94, size.height * .075),
      Offset(size.width * .97, size.height * .028),
    ];

    for (final center in blossomCenters) {
      _drawBlossom(canvas, center, blossomPaint, 4.2);
    }
  }

  void _paintFallingPetals(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.brandGold.withValues(alpha: .54);

    final drift = progress * 26;

    final petals = [
      Offset(size.width * .82, size.height * .18 + drift),
      Offset(size.width * .90, size.height * .23 + drift * .75),
      Offset(size.width * .78, size.height * .28 + drift * .55),
    ];

    for (var i = 0; i < petals.length; i++) {
      final p = petals[i];
      final wrappedY = p.dy > size.height * .42
          ? p.dy - size.height * .22
          : p.dy;

      canvas.save();
      canvas.translate(p.dx, wrappedY);
      canvas.rotate(progress * math.pi * 2 + i);
      canvas.drawOval(const Rect.fromLTWH(-3, -6, 6, 12), paint);
      canvas.restore();
    }
  }

  void _paintBottomWave(Canvas canvas, Size size) {
    final navy = Paint()..color = AppColors.primaryStrong;
    final gold = Paint()
      ..color = AppColors.brandGold.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final path = Path()
      ..moveTo(0, size.height * .91)
      ..cubicTo(
        size.width * .17,
        size.height * .87,
        size.width * .26,
        size.height * .96,
        size.width * .44,
        size.height * .94,
      )
      ..cubicTo(
        size.width * .61,
        size.height * .92,
        size.width * .72,
        size.height * 1.01,
        size.width,
        size.height * .97,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, navy);

    final goldLine = Path()
      ..moveTo(0, size.height * .935)
      ..cubicTo(
        size.width * .22,
        size.height * .90,
        size.width * .30,
        size.height * .98,
        size.width * .50,
        size.height * .955,
      )
      ..cubicTo(
        size.width * .67,
        size.height * .935,
        size.width * .79,
        size.height * 1.01,
        size.width,
        size.height * .985,
      );

    canvas.drawPath(goldLine, gold);
  }

  void _drawBlossom(Canvas canvas, Offset center, Paint paint, double radius) {
    for (var i = 0; i < 5; i++) {
      final angle = (math.pi * 2 / 5) * i - math.pi / 2;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      canvas.drawCircle(petalCenter, radius * .62, paint);
    }

    canvas.drawCircle(
      center,
      radius * .35,
      Paint()..color = AppColors.background,
    );
  }

  @override
  bool shouldRepaint(covariant _JapaneseSplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
