import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/vital_model.dart';

// ─────────────── Heart Pumping Animation ───────────────
class HeartPumpWidget extends StatefulWidget {
  final double heartRate;
  final VitalStatus status;
  const HeartPumpWidget({super.key, required this.heartRate, required this.status});

  @override
  State<HeartPumpWidget> createState() => _HeartPumpWidgetState();
}

class _HeartPumpWidgetState extends State<HeartPumpWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _updateRate();
  }

  void _updateRate() {
    final bps = widget.heartRate / 60;
    final duration = Duration(milliseconds: (1000 / bps).round());
    _controller = AnimationController(vsync: this, duration: duration)
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(HeartPumpWidget old) {
    super.didUpdateWidget(old);
    if (old.heartRate != widget.heartRate) {
      _controller.dispose();
      _updateRate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = VitalSenseTheme.getStatusColor(widget.status.name);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = 1.0 + (_controller.value * 0.18);
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 120, height: 120,
            child: CustomPaint(
              painter: _HeartPainter(
                color: color,
                pulseValue: _controller.value,
                heartRate: widget.heartRate,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeartPainter extends CustomPainter {
  final Color color;
  final double pulseValue;
  final double heartRate;

  _HeartPainter({required this.color, required this.pulseValue, required this.heartRate});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15 + pulseValue * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(cx, cy), r * 1.4, glowPaint);

    // Heart shape using bezier curves
    final heartPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final scale = r / 45;

    path.moveTo(cx, cy + 25 * scale);

    // Left curve
    path.cubicTo(
      cx - 45 * scale, cy,
      cx - 45 * scale, cy - 30 * scale,
      cx, cy - 15 * scale,
    );

    // Right curve
    path.cubicTo(
      cx + 45 * scale, cy - 30 * scale,
      cx + 45 * scale, cy,
      cx, cy + 25 * scale,
    );

    path.close();

    // Draw shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, shadowPaint);

    // Draw heart
    canvas.drawPath(path, heartPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final highlightPath = Path();
    highlightPath.moveTo(cx - 5 * scale, cy - 10 * scale);
    highlightPath.cubicTo(
      cx - 20 * scale, cy - 20 * scale,
      cx - 25 * scale, cy - 5 * scale,
      cx - 5 * scale, cy,
    );
    highlightPath.cubicTo(
      cx - 5 * scale, cy - 5 * scale,
      cx - 5 * scale, cy - 10 * scale,
      cx - 5 * scale, cy - 10 * scale,
    );
    canvas.drawPath(highlightPath, highlightPaint);

    // BPM text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${heartRate.toInt()}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18 * scale,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black26)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2 + 2 * scale));
  }

  @override
  bool shouldRepaint(_HeartPainter old) =>
      old.pulseValue != pulseValue || old.color != color;
}

// ─────────────── Lungs Breathing Animation ───────────────
class LungBreathWidget extends StatefulWidget {
  final double spo2;
  final VitalStatus status;
  const LungBreathWidget({super.key, required this.spo2, required this.status});

  @override
  State<LungBreathWidget> createState() => _LungBreathWidgetState();
}

class _LungBreathWidgetState extends State<LungBreathWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Normal breathing: ~15 breaths/min = 4 second cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = VitalSenseTheme.getStatusColor(widget.status.name);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return SizedBox(
          width: 120, height: 120,
          child: CustomPaint(
            painter: _LungPainter(
              color: color,
              breathValue: _controller.value,
              spo2: widget.spo2,
            ),
          ),
        );
      },
    );
  }
}

class _LungPainter extends CustomPainter {
  final Color color;
  final double breathValue;
  final double spo2;

  _LungPainter({required this.color, required this.breathValue, required this.spo2});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.1 + breathValue * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.4, glowPaint);

    // Draw trachea (center tube)
    final tracheaPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, cy - 40),
      Offset(cx, cy - 20),
      tracheaPaint,
    );

    // Left bronchus
    canvas.drawLine(Offset(cx, cy - 20), Offset(cx - 18, cy - 10), tracheaPaint);
    // Right bronchus
    canvas.drawLine(Offset(cx, cy - 20), Offset(cx + 18, cy - 10), tracheaPaint);

    // Left lung
    _drawLung(canvas, Offset(cx - 20, cy + 5), true, color, breathValue, size);
    // Right lung
    _drawLung(canvas, Offset(cx + 20, cy + 5), false, color, breathValue, size);

    // SpO2 text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${spo2.toInt()}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 30));
  }

  void _drawLung(Canvas canvas, Offset center, bool isLeft, Color color,
      double breath, Size size) {
    final expansion = breath * 6;
    final w = 22.0 + expansion;
    final h = 35.0 + expansion;

    final lungPaint = Paint()
      ..color = color.withOpacity(0.7 + breath * 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      path.addOval(Rect.fromCenter(
          center: center, width: w, height: h));
    } else {
      path.addOval(Rect.fromCenter(
          center: center, width: w, height: h));
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, lungPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx - (isLeft ? 5 : -5), center.dy - 8),
          width: w * 0.4,
          height: h * 0.35),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_LungPainter old) => old.breathValue != breathValue;
}

// ─────────────── Dashboard Stats Widget ───────────────
class DashboardStatsWidget extends StatelessWidget {
  final VitalReading vital;
  final List<VitalReading> history;

  const DashboardStatsWidget({
    super.key,
    required this.vital,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heart + Lungs VR animation row
        _VRAnimationRow(vital: vital),
        const SizedBox(height: 20),

        // Stats grid
        Text('Health Statistics', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            _MiniStatCard('Heart Rate', '${vital.heartRate.toInt()}', 'BPM',
                Icons.favorite_rounded, VitalSenseTheme.alertRed),
            _MiniStatCard('SpO₂', '${vital.spo2.toInt()}', '%',
                Icons.air_rounded, VitalSenseTheme.primaryBlue),
            _MiniStatCard('Temp', vital.temperature.toStringAsFixed(1), '°C',
                Icons.thermostat_rounded, VitalSenseTheme.alertAmber),
            _MiniStatCard('PHI Score', '${vital.phiScore.toInt()}', '/100',
                Icons.analytics_rounded, VitalSenseTheme.primaryGreen),
            _MiniStatCard('HRV', '${vital.hrv?.toInt() ?? '--'}', 'ms',
                Icons.timeline_rounded, VitalSenseTheme.accentPurple),
            _MiniStatCard('Stress', '${vital.stressLevel?.toInt() ?? '--'}', '%',
                Icons.psychology_rounded, VitalSenseTheme.alertAmber),
          ],
        ),
        const SizedBox(height: 20),

        // Multi-vital trend chart
        if (history.length > 2) ...[
          Text('Vital Trends', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _MultiTrendChart(history: history),
          const SizedBox(height: 16),

          // PHI trend
          Text('PHI Score Trend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _PHITrendChart(history: history),
          const SizedBox(height: 16),

          // Stats summary
          _StatsSummaryCard(history: history, latest: vital),
        ],
      ],
    );
  }
}

class _VRAnimationRow extends StatelessWidget {
  final VitalReading vital;
  const _VRAnimationRow({required this.vital});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  HeartPumpWidget(
                    heartRate: vital.heartRate,
                    status: vital.heartRateStatus,
                  ),
                  const SizedBox(height: 8),
                  Text('Heart', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text('${vital.heartRate.toInt()} BPM',
                      style: TextStyle(color: VitalSenseTheme.getStatusColor(vital.heartRateStatus.name), fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
                Column(children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 1, height: 100,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ]),
                Column(children: [
                  LungBreathWidget(
                    spo2: vital.spo2,
                    status: vital.spo2Status,
                  ),
                  const SizedBox(height: 8),
                  Text('Lungs', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text('${vital.spo2.toInt()}% SpO₂',
                      style: TextStyle(color: VitalSenseTheme.getStatusColor(vital.spo2Status.name), fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '🫀 Live organ visualization based on your real-time vitals',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _MiniStatCard(this.label, this.value, this.unit, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(unit, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultiTrendChart extends StatelessWidget {
  final List<VitalReading> history;
  const _MultiTrendChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.reversed.take(20).toList();
    final hrSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.heartRate)).toList();
    final spo2Spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.spo2)).toList();
    final tempSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature * 2)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend
            Row(children: [
              _LegendDot(VitalSenseTheme.alertRed), const SizedBox(width: 4),
              const Text('HR', style: TextStyle(fontSize: 10)), const SizedBox(width: 12),
              _LegendDot(VitalSenseTheme.primaryBlue), const SizedBox(width: 4),
              const Text('SpO₂', style: TextStyle(fontSize: 10)), const SizedBox(width: 12),
              _LegendDot(VitalSenseTheme.alertAmber), const SizedBox(width: 4),
              const Text('Temp×2', style: TextStyle(fontSize: 10)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(LineChartData(
                minY: 60, maxY: 110,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _lineBar(hrSpots, VitalSenseTheme.alertRed),
                  _lineBar(spo2Spots, VitalSenseTheme.primaryBlue),
                  _lineBar(tempSpots, VitalSenseTheme.alertAmber),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.15), Colors.transparent],
        ),
      ),
    );
  }
}

class _PHITrendChart extends StatelessWidget {
  final List<VitalReading> history;
  const _PHITrendChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.reversed.take(20).toList();
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.phiScore)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 140,
          child: LineChart(LineChartData(
            minY: 0, maxY: 100,
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (v) {
                if (v == 40 || v == 70) return FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1, dashArray: [4, 4]);
                return FlLine(color: Colors.transparent);
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(colors: [VitalSenseTheme.alertRed, VitalSenseTheme.alertAmber, VitalSenseTheme.primaryGreen]),
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [VitalSenseTheme.primaryGreen.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  final List<VitalReading> history;
  final VitalReading latest;
  const _StatsSummaryCard({required this.history, required this.latest});

  @override
  Widget build(BuildContext context) {
    final hrs = history.map((r) => r.heartRate).toList();
    final spo2s = history.map((r) => r.spo2).toList();
    final avgHR = hrs.reduce((a, b) => a + b) / hrs.length;
    final maxHR = hrs.reduce(max);
    final minHR = hrs.reduce(min);
    final avgSpO2 = spo2s.reduce((a, b) => a + b) / spo2s.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
            Row(children: [
              _SummaryItem('Avg HR', '${avgHR.toInt()} BPM', VitalSenseTheme.alertRed),
              _SummaryItem('Max HR', '${maxHR.toInt()} BPM', VitalSenseTheme.alertAmber),
              _SummaryItem('Min HR', '${minHR.toInt()} BPM', VitalSenseTheme.primaryBlue),
              _SummaryItem('Avg SpO₂', '${avgSpO2.toInt()}%', VitalSenseTheme.primaryGreen),
            ]),
            const SizedBox(height: 12),
            // Health zone bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heart Rate Zones', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(children: [
                    _ZoneBar('Rest', 0.3, VitalSenseTheme.primaryBlue),
                    _ZoneBar('Fat Burn', 0.25, VitalSenseTheme.primaryGreen),
                    _ZoneBar('Cardio', 0.25, VitalSenseTheme.alertAmber),
                    _ZoneBar('Peak', 0.2, VitalSenseTheme.alertRed),
                  ]),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('<60', style: TextStyle(fontSize: 9, color: VitalSenseTheme.primaryBlue)),
                    Text('60–80', style: TextStyle(fontSize: 9, color: VitalSenseTheme.primaryGreen)),
                    Text('80–100', style: TextStyle(fontSize: 9, color: VitalSenseTheme.alertAmber)),
                    Text('>100', style: TextStyle(fontSize: 9, color: VitalSenseTheme.alertRed)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ]),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  final String label;
  final double flex;
  final Color color;
  const _ZoneBar(this.label, this.flex, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Container(
        height: 16,
        color: color.withOpacity(0.7),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700))),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot(this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
