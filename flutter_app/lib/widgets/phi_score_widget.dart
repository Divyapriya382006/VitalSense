import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class PHIScoreWidget extends StatefulWidget {
  final double score;
  const PHIScoreWidget({super.key, required this.score});

  @override
  State<PHIScoreWidget> createState() => _PHIScoreWidgetState();
}

class _PHIScoreWidgetState extends State<PHIScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: 1500.ms);
    _animation = Tween<double>(begin: 0, end: widget.score)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(PHIScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: oldWidget.score, end: widget.score)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Fair';
    if (score >= 40) return 'Poor';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    final color = VitalSenseTheme.getPHIColor(widget.score);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Gauge
            AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: _animation.value / 100,
                    color: VitalSenseTheme.getPHIColor(_animation.value),
                    isDark: isDark,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_animation.value.toInt()}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: VitalSenseTheme.getPHIColor(_animation.value),
                          ),
                        ),
                        Text(
                          'PHI',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Health Index',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (_, __) => Text(
                      _getLabel(_animation.value),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: VitalSenseTheme.getPHIColor(_animation.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculated from HR, SpO₂, Temp & HRV using ML analysis',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),

                  // Score zones
                  Row(
                    children: [
                      _Zone('0', color: VitalSenseTheme.alertRed),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (_, __) => LinearProgressIndicator(
                              value: _animation.value / 100,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation(
                                  VitalSenseTheme.getPHIColor(_animation.value)),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ),
                      _Zone('100', color: VitalSenseTheme.primaryGreen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Zone extends StatelessWidget {
  final String label;
  final Color color;
  const _Zone(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color color;
  final bool isDark;

  _GaugePainter({required this.value, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withOpacity(0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.8,
      pi * 1.6,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.8,
      pi * 1.6 * value,
      false,
      valuePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.8,
      pi * 1.6 * value,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}
