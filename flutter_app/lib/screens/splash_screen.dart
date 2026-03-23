import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ecgController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 3000), _navigate);
  }

  void _navigate() {
  if (!mounted) return;
  context.go('/onboarding'); // always go to onboarding for now
}

  @override
  void dispose() {
    _pulseController.dispose();
    _ecgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VitalSenseTheme.darkBg,
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8 + (_pulseController.value * 0.2),
                    colors: [
                      VitalSenseTheme.primaryBlue.withOpacity(0.15),
                      VitalSenseTheme.darkBg,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ECG Line Animation
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _ecgController,
                builder: (_, __) => CustomPaint(
                  painter: ECGLinePainter(_ecgController.value),
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing heart icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VitalSenseTheme.primaryBlue.withOpacity(0.15),
                        border: Border.all(
                          color: VitalSenseTheme.primaryBlue.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: VitalSenseTheme.primaryBlue
                                .withOpacity(0.3 * _pulseController.value),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 50,
                        color: VitalSenseTheme.primaryBlue,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.5, 0.5)),
                const SizedBox(height: 24),

                // App name
                Text(
                  'VitalSense',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                Text(
                  'AI-Powered Health Intelligence',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: VitalSenseTheme.primaryBlue,
                        letterSpacing: 1.5,
                      ),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 48),

                // PHI tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: VitalSenseTheme.primaryGreen.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(20),
                    color: VitalSenseTheme.primaryGreen.withOpacity(0.1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: VitalSenseTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .fadeIn(duration: 600.ms)
                          .then()
                          .fadeOut(duration: 600.ms),
                      const SizedBox(width: 8),
                      Text(
                        'Monitoring Active',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: VitalSenseTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ).animate(delay: 700.ms).fadeIn(duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ECGLinePainter extends CustomPainter {
  final double progress;
  ECGLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VitalSenseTheme.primaryBlue.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    final offset = progress * w;

    path.moveTo(0, mid);
    // ECG pattern repeating
    for (double x = 0; x < w; x += 100) {
      final ox = (x - offset) % w;
      path.lineTo(ox, mid);
      path.lineTo(ox + 5, mid);
      path.lineTo(ox + 10, mid - h * 0.3);
      path.lineTo(ox + 15, mid + h * 0.4);
      path.lineTo(ox + 20, mid - h * 0.8);
      path.lineTo(ox + 25, mid + h * 0.2);
      path.lineTo(ox + 30, mid);
      path.lineTo(ox + 50, mid);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ECGLinePainter oldDelegate) => oldDelegate.progress != progress;
}
