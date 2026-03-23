import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/vitals_provider.dart';
import '../../models/vital_model.dart';
import '../../theme/app_theme.dart';

class PatientVitalsViewer extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const PatientVitalsViewer({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestVitalProvider(patientId));
    final historyAsync = ref.watch(vitalHistoryProvider(patientId));

    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: AppBar(
        title: Text('Vitals: $patientName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0a1520),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            latestAsync.when(
              data: (vital) => vital != null 
                ? _buildHeroStats(context, vital)
                : const _NoDataPlaceholder(),
              loading: () => const LinearProgressIndicator(color: Color(0xFF00e5ff), backgroundColor: Colors.transparent),
              error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HISTORICAL TRENDS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  historyAsync.when(
                    data: (history) => _buildVitalsChart(history),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const SizedBox(),
                  ),
                  const SizedBox(height: 30),
                  const Text('AI CLINICAL INSIGHTS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  latestAsync.when(
                    data: (vital) => vital != null 
                      ? _buildXaiCard(context, vital)
                      : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStats(BuildContext context, VitalReading vital) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF0a1520), const Color(0xFF060d14)],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatMini('PHI SCORE', '${vital.phiScore.toInt()}%', const Color(0xFF69ff47)),
              _StatMini('STRESS LEVEL', '${vital.stressLevel?.toInt() ?? 0}%', const Color(0xFFffab00)),
              _StatMini('HEART RATE VARIABILITY', '${vital.hrv?.toInt() ?? 0}ms', const Color(0xFF00e5ff)),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeroMetric(Icons.favorite, '${vital.heartRate.toInt()}', 'BPM', 'Heart Rate', const Color(0xFFff3d00)),
              _HeroMetric(Icons.bloodtype, '${vital.spo2.toInt()}', '%', 'SpO2', const Color(0xFF00e5ff)),
              _HeroMetric(Icons.thermostat, vital.temperature.toStringAsFixed(1), '°C', 'Temp', const Color(0xFFffab00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsChart(List<VitalReading> history) {
    final spots = history.reversed.toList().asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.heartRate)).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0c1824),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05))),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF00e5ff),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [const Color(0xFF00e5ff).withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXaiCard(BuildContext context, VitalReading vital) {
    final factors = (vital.xaiExplanation?['factors'] as List?) ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0c1824).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1a3040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vital.xaiExplanation?['summary'] ?? 'No automated assessment available.',
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ...factors.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF69ff47)),
                const SizedBox(width: 10),
                Expanded(child: Text(f.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label, val;
  final Color color;
  const _StatMini(this.label, this.val, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value, unit, label;
  final Color color;
  const _HeroMetric(this.icon, this.value, this.unit, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), 
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            Padding(padding: const EdgeInsets.only(bottom: 4, left: 3), child: Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
        Text(label.toUpperCase(), style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ],
    );
  }
}

class _NoDataPlaceholder extends StatelessWidget {
  const _NoDataPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: Text('Awaiting patient sync...', style: TextStyle(color: Colors.white24))),
    );
  }
}
