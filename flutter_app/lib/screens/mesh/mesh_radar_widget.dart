import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MeshRadarWidget extends StatefulWidget {
  final bool isSearching;
  const MeshRadarWidget({super.key, this.isSearching = true});

  @override
  State<MeshRadarWidget> createState() => _MeshRadarWidgetState();
}

class _MeshRadarWidgetState extends State<MeshRadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  final List<Offset> _nodes = [
    const Offset(0.3, 0.4),
    const Offset(0.7, 0.2),
    const Offset(0.5, 0.8),
    const Offset(0.2, 0.7),
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          // Background Rings
          Center(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _RadarPainter(_radarController.value, widget.isSearching),
            ),
          ),
          // Center Node
          const Center(
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFF00e5ff),
              child: Icon(Icons.person, size: 14, color: Colors.black),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.5)),
          
          // Floating Nodes
          ...List.generate(_nodes.length, (index) {
            final node = _nodes[index];
            return AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                // Only show if the radar sweep has "passed" the node (mock)
                return Positioned(
                  left: MediaQuery.of(context).size.width * 0.45 * (1 + node.dx * 0.8),
                  top: MediaQuery.of(context).size.width * 0.45 * (1 + node.dy * 0.8),
                  child: Opacity(
                    opacity: widget.isSearching ? 1 : 0.2,
                    child: Column(
                      children: [
                        const Icon(Icons.hub, color: Color(0xFF69ff47), size: 16),
                        Text('NODE #${100 + index}', style: const TextStyle(color: Color(0xFF69ff47), fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepProgress;
  final bool isActive;
  _RadarPainter(this.sweepProgress, this.isActive);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..color = const Color(0xFF00e5ff).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw rings
    canvas.drawCircle(center, radius * 0.3, paint);
    canvas.drawCircle(center, radius * 0.6, paint);
    canvas.drawCircle(center, radius * 0.9, paint);

    if (isActive) {
      // Draw Sweep
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          colors: [Colors.transparent, const Color(0xFF00e5ff).withOpacity(0.4)],
          stops: const [0.8, 1.0],
          transform: GradientRotation(sweepProgress * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius * 0.9, sweepPaint..style = PaintingStyle.fill);
      
      // Lines
      canvas.drawLine(center, Offset(center.dx + radius * 0.9 * math.cos(sweepProgress * 2 * math.pi), center.dy + radius * 0.9 * math.sin(sweepProgress * 2 * math.pi)), Paint()..color = const Color(0xFF00e5ff)..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
