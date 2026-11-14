import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/design_tokens.dart';

/// LearnTZ Animated Brand Emblem
/// Executes the 7-step choreographed sequence:
/// 1. Logo fades in & scales up (0 - 700 ms)
/// 2. Graduation cap drops gently (700 - 1300 ms)
/// 3. Golden rays illuminate (1300 - 2100 ms)
/// 4. Book opens subtly (2100 - 2800 ms)
/// 5. Sparkles appear & twinkle (2800 - 3700 ms)
/// 6. LearnTZ typography reveals (3700 - 4400 ms)
/// 7. Tagline "Learn Anywhere, Anytime" slides in (4400 - 5000 ms)
class AnimatedWelcomeEmblem extends StatefulWidget {
  const AnimatedWelcomeEmblem({
    super.key,
    this.size = 280.0,
    this.onSequenceCompleted,
    this.autoPlay = true,
  });

  final double size;
  final VoidCallback? onSequenceCompleted;
  final bool autoPlay;

  @override
  State<AnimatedWelcomeEmblem> createState() => AnimatedWelcomeEmblemState();
}

class AnimatedWelcomeEmblemState extends State<AnimatedWelcomeEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Step 1: Logo fade & scale (0 - 700ms -> 0.0 to 0.14)
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Step 2: Graduation cap drop (700 - 1300ms -> 0.14 to 0.26)
  late final Animation<double> _capDrop;
  late final Animation<double> _capTilt;

  // Step 3: Golden rays illuminate (1300 - 2100ms -> 0.26 to 0.42)
  late final Animation<double> _raysOpacity;
  late final Animation<double> _raysScale;
  late final Animation<double> _raysRotation;

  // Step 4: Book opens subtly (2100 - 2800ms -> 0.42 to 0.56)
  late final Animation<double> _bookOpen;
  late final Animation<double> _bookGlow;

  // Step 5: Sparkles appear & animate (2800 - 3700ms -> 0.56 to 0.74)
  late final Animation<double> _sparklesProgress;

  // Step 6: LearnTZ Wordmark (3700 - 4400ms -> 0.74 to 0.88)
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;

  // Step 7: Tagline "Learn Anywhere, Anytime" (4400 - 5000ms -> 0.88 to 1.0)
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // 1. Logo fade & scale: 0.0 - 0.14 (700ms)
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.14, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.12, curve: Curves.easeIn),
      ),
    );

    // 2. Graduation cap drop: 0.14 - 0.26 (600ms)
    _capDrop = Tween<double>(begin: -45.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.26, curve: Curves.bounceOut),
      ),
    );
    _capTilt = Tween<double>(begin: -0.18, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.26, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Golden rays illuminate: 0.26 - 0.42 (800ms)
    _raysOpacity = Tween<double>(begin: 0.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.26, 0.42, curve: Curves.easeInOut),
      ),
    );
    _raysScale = Tween<double>(begin: 0.75, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.26, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _raysRotation = Tween<double>(begin: 0.0, end: math.pi / 6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.26, 1.0, curve: Curves.linear),
      ),
    );

    // 4. Book opens subtly: 0.42 - 0.56 (700ms)
    _bookOpen = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.56, curve: Curves.easeOutBack),
      ),
    );
    _bookGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.56, curve: Curves.easeIn),
      ),
    );

    // 5. Sparkles appear & animate: 0.56 - 0.74 (900ms)
    _sparklesProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.74, curve: Curves.easeOutCubic),
      ),
    );

    // 6. LearnTZ Wordmark: 0.74 - 0.88 (700ms)
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.74, 0.88, curve: Curves.easeIn),
      ),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.74, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 7. Tagline: 0.88 - 1.0 (600ms)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSequenceCompleted?.call();
      }
    });

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void restart() {
    _controller.reset();
    _controller.forward();
  }

  void skipToEnd() {
    _controller.animateTo(1.0, duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double emblemSize = widget.size;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Center Stage: Animated Emblem with Golden Rays, Open Book, Cap & Sparkles
            SizedBox(
              width: emblemSize,
              height: emblemSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Step 3: Golden Illuminating Rays (Backdrop)
                  if (_raysOpacity.value > 0.01)
                    Transform.rotate(
                      angle: _raysRotation.value,
                      child: Transform.scale(
                        scale: _raysScale.value,
                        child: Opacity(
                          opacity: _raysOpacity.value,
                          child: CustomPaint(
                            size: Size(emblemSize * 1.25, emblemSize * 1.25),
                            painter: const GoldenRaysPainter(),
                          ),
                        ),
                      ),
                    ),

                  // Step 1: Base Crest / Shield with gradient & drop shadow
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: emblemSize * 0.72,
                        height: emblemSize * 0.72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.2, -0.3),
                            radius: 0.9,
                            colors: [
                              LearnTzColors.primary400,
                              LearnTzColors.primary,
                              LearnTzColors.primary900,
                            ],
                          ),
                          border: Border.all(
                            color: LearnTzColors.accent.withValues(alpha: 0.8),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: LearnTzColors.primary.withValues(alpha: 0.4),
                              blurRadius: 28,
                              spreadRadius: 4,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: LearnTzColors.accent.withValues(alpha: 0.25 * _raysOpacity.value),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          // Step 4: Subtle Opening Book
                          child: Transform.scale(
                            scale: _bookOpen.value,
                            child: CustomPaint(
                              size: Size(emblemSize * 0.38, emblemSize * 0.28),
                              painter: OpenBookPainter(glowProgress: _bookGlow.value),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Step 2: Graduation Cap (Drops from top into position)
                  if (_logoOpacity.value > 0.1)
                    Positioned(
                      top: emblemSize * 0.08 + _capDrop.value,
                      child: Transform.rotate(
                        angle: _capTilt.value,
                        child: CustomPaint(
                          size: Size(emblemSize * 0.42, emblemSize * 0.22),
                          painter: const GraduationCapPainter(),
                        ),
                      ),
                    ),

                  // Step 5: Twinkling Learning Sparkles
                  if (_sparklesProgress.value > 0.05)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SparklesPainter(progress: _sparklesProgress.value),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step 6: LearnTZ Wordmark Typography Reveal
            SlideTransition(
              position: _wordmarkSlide,
              child: Opacity(
                opacity: _wordmarkOpacity.value,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Learn',
                        style: LearnTzTypography.h1.copyWith(
                          color: LearnTzColors.primary,
                          fontSize: (emblemSize * 0.15).clamp(32.0, 48.0),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'TZ',
                        style: LearnTzTypography.h1.copyWith(
                          color: LearnTzColors.secondary,
                          fontSize: (emblemSize * 0.15).clamp(32.0, 48.0),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: LearnTzColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Step 7: Tagline "Learn Anywhere, Anytime"
            SlideTransition(
              position: _taglineSlide,
              child: Opacity(
                opacity: _taglineOpacity.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              LearnTzColors.primary.withValues(alpha: 0.08),
                              LearnTzColors.secondary.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: LearnTzRadii.borderFull,
                          border: Border.all(
                            color: LearnTzColors.accent.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: LearnTzColors.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Learn Anywhere, Anytime',
                              style: LearnTzTypography.bodyLarge.copyWith(
                                color: LearnTzColors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Tanzania National Curriculum • TIE Standard',
                        style: LearnTzTypography.caption.copyWith(
                          color: LearnTzColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom Painter for Step 3: Golden Illuminating Rays
class GoldenRaysPainter extends CustomPainter {
  const GoldenRaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    const rayCount = 16;
    const rayAngle = (2 * math.pi) / rayCount;

    for (int i = 0; i < rayCount; i++) {
      final angle = i * rayAngle;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + maxRadius * math.cos(angle - rayAngle * 0.28),
          center.dy + maxRadius * math.sin(angle - rayAngle * 0.28),
        )
        ..lineTo(
          center.dx + maxRadius * math.cos(angle + rayAngle * 0.28),
          center.dy + maxRadius * math.sin(angle + rayAngle * 0.28),
        )
        ..close();

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            LearnTzColors.accent.withValues(alpha: 0.75),
            LearnTzColors.accent300.withValues(alpha: 0.35),
            Colors.transparent,
          ],
          stops: const [0.15, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for Step 2: Graduation Cap (Mortarboard & Tassel)
class GraduationCapPainter extends CustomPainter {
  const GraduationCapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Skullcap (Base)
    final skullcapPath = Path()
      ..moveTo(w * 0.28, h * 0.55)
      ..quadraticBezierTo(w * 0.5, h * 0.85, w * 0.72, h * 0.55)
      ..lineTo(w * 0.65, h * 0.40)
      ..quadraticBezierTo(w * 0.5, h * 0.55, w * 0.35, h * 0.40)
      ..close();

    final skullcapPaint = Paint()
      ..color = LearnTzColors.primary900
      ..style = PaintingStyle.fill;
    canvas.drawPath(skullcapPath, skullcapPaint);

    // 2. Diamond Cap Top (Mortarboard)
    final boardPath = Path()
      ..moveTo(w * 0.5, h * 0.05) // Top
      ..lineTo(w * 0.95, h * 0.40) // Right
      ..lineTo(w * 0.5, h * 0.72) // Bottom
      ..lineTo(w * 0.05, h * 0.40) // Left
      ..close();

    final boardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        LearnTzColors.primary600,
        LearnTzColors.primary,
        LearnTzColors.primary900,
      ],
    );

    final boardPaint = Paint()
      ..shader = boardGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Draw shadow underneath mortarboard
    canvas.drawShadow(boardPath, LearnTzColors.primary900, 6.0, true);
    canvas.drawPath(boardPath, boardPaint);

    // Gold rim border on the mortarboard
    final rimPaint = Paint()
      ..color = LearnTzColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(boardPath, rimPaint);

    // 3. Center Gold Button
    final buttonPaint = Paint()
      ..color = LearnTzColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.40), 4.5, buttonPaint);

    // 4. Golden Tassel draping down to the side
    final tasselPath = Path()
      ..moveTo(w * 0.5, h * 0.40)
      ..quadraticBezierTo(w * 0.75, h * 0.45, w * 0.88, h * 0.75);

    final tasselPaint = Paint()
      ..color = LearnTzColors.accent400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tasselPath, tasselPaint);

    // Tassel Fringe
    final fringePaint = Paint()
      ..color = LearnTzColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.88, h * 0.78), 4.0, fringePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for Step 4: Open Book with Knowledge Lines & Bookmark
class OpenBookPainter extends CustomPainter {
  const OpenBookPainter({required this.glowProgress});

  final double glowProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Left Page
    final leftPagePath = Path()
      ..moveTo(w * 0.5, h * 0.85) // Spine bottom
      ..quadraticBezierTo(w * 0.25, h * 0.95, w * 0.05, h * 0.82)
      ..lineTo(w * 0.05, h * 0.22)
      ..quadraticBezierTo(w * 0.25, h * 0.35, w * 0.5, h * 0.25) // Spine top
      ..close();

    // Right Page
    final rightPagePath = Path()
      ..moveTo(w * 0.5, h * 0.85) // Spine bottom
      ..quadraticBezierTo(w * 0.75, h * 0.95, w * 0.95, h * 0.82)
      ..lineTo(w * 0.95, h * 0.22)
      ..quadraticBezierTo(w * 0.75, h * 0.35, w * 0.5, h * 0.25) // Spine top
      ..close();

    final pagePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw Pages with soft shadow
    canvas.drawShadow(leftPagePath, Colors.black, 4.0, true);
    canvas.drawShadow(rightPagePath, Colors.black, 4.0, true);
    canvas.drawPath(leftPagePath, pagePaint);
    canvas.drawPath(rightPagePath, pagePaint);

    // Page Page Borders
    final pageBorderPaint = Paint()
      ..color = LearnTzColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(leftPagePath, pageBorderPaint);
    canvas.drawPath(rightPagePath, pageBorderPaint);

    // Knowledge lines inside left page
    final linePaint = Paint()
      ..color = LearnTzColors.secondary.withValues(alpha: 0.65 * glowProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.14, h * 0.40), Offset(w * 0.42, h * 0.44), linePaint);
    canvas.drawLine(Offset(w * 0.14, h * 0.54), Offset(w * 0.42, h * 0.58), linePaint);
    canvas.drawLine(Offset(w * 0.14, h * 0.68), Offset(w * 0.36, h * 0.71), linePaint);

    // Knowledge lines inside right page
    canvas.drawLine(Offset(w * 0.58, h * 0.44), Offset(w * 0.86, h * 0.40), linePaint);
    canvas.drawLine(Offset(w * 0.58, h * 0.58), Offset(w * 0.86, h * 0.54), linePaint);
    canvas.drawLine(Offset(w * 0.58, h * 0.71), Offset(w * 0.80, h * 0.68), linePaint);

    // Center Gold Ribbon Bookmark
    final ribbonPath = Path()
      ..moveTo(w * 0.48, h * 0.25)
      ..lineTo(w * 0.52, h * 0.25)
      ..lineTo(w * 0.52, h * 0.95)
      ..lineTo(w * 0.50, h * 0.90)
      ..lineTo(w * 0.48, h * 0.95)
      ..close();

    final ribbonPaint = Paint()
      ..color = LearnTzColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant OpenBookPainter oldDelegate) =>
      oldDelegate.glowProgress != glowProgress;
}

/// Custom Painter for Step 5: Magic Sparkles (Twinkling 4-Point Stars)
class SparklesPainter extends CustomPainter {
  const SparklesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 6 Star coordinates around the emblem with individualized phases
    final stars = [
      _StarData(Offset(w * 0.12, h * 0.25), 10.0, 0.0),
      _StarData(Offset(w * 0.88, h * 0.22), 12.0, 0.2),
      _StarData(Offset(w * 0.94, h * 0.60), 8.0, 0.4),
      _StarData(Offset(w * 0.08, h * 0.68), 9.0, 0.6),
      _StarData(Offset(w * 0.30, h * 0.05), 11.0, 0.3),
      _StarData(Offset(w * 0.70, h * 0.95), 8.5, 0.5),
    ];

    for (final star in stars) {
      final localPhase = ((progress - star.phaseOffset).clamp(0.0, 1.0) / (1.0 - star.phaseOffset)).clamp(0.0, 1.0);
      if (localPhase <= 0.0) continue;

      // Pulsing scale: grows, peaks, and gently settles
      final scale = math.sin(localPhase * math.pi) * 1.35;
      final opacity = (math.sin(localPhase * math.pi)).clamp(0.0, 1.0);

      _draw4PointStar(
        canvas,
        star.center,
        star.baseRadius * scale,
        opacity,
        localPhase * math.pi / 2,
      );
    }
  }

  void _draw4PointStar(
    Canvas canvas,
    Offset center,
    double radius,
    double opacity,
    double rotation,
  ) {
    if (radius <= 0.5 || opacity <= 0.05) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    const innerRadiusRatio = 0.28;
    final innerR = radius * innerRadiusRatio;

    path.moveTo(0, -radius);
    path.lineTo(innerR, -innerR);
    path.lineTo(radius, 0);
    path.lineTo(innerR, innerR);
    path.lineTo(0, radius);
    path.lineTo(-innerR, innerR);
    path.lineTo(-radius, 0);
    path.lineTo(-innerR, -innerR);
    path.close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity),
          LearnTzColors.accent.withValues(alpha: opacity * 0.9),
          LearnTzColors.accent400.withValues(alpha: 0.0),
        ],
        stops: const [0.2, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SparklesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StarData {
  const _StarData(this.center, this.baseRadius, this.phaseOffset);
  final Offset center;
  final double baseRadius;
  final double phaseOffset;
}
