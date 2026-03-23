import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/vitals_provider.dart';
import '../../models/vital_model.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestVitalProvider(patientId));
    final historyAsync = ref.watch(vitalHistoryProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current vitals
            latestAsync.when(
              data: (vital) {
                if (vital == null) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No recent data')));
                final color = VitalSenseTheme.getStatusColor(vital.overallStatus.name);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Current Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(vital.overallStatus.name.toUpperCase(),
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          _VitalMini('HR', '${vital.heartRate.toInt()} BPM', VitalSenseTheme.getStatusColor(vital.heartRateStatus.name)),
                          _VitalMini('SpO₂', '${vital.spo2.toInt()}%', VitalSenseTheme.getStatusColor(vital.spo2Status.name)),
                          _VitalMini('Temp', '${vital.temperature.toStringAsFixed(1)}°C', VitalSenseTheme.getStatusColor(vital.temperatureStatus.name)),
                          _VitalMini('PHI', '${vital.phiScore.toInt()}', VitalSenseTheme.getPHIColor(vital.phiScore)),
                        ]),
                        if (vital.xaiExplanation != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: VitalSenseTheme.primaryBlue.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Icon(Icons.analytics_outlined, size: 14, color: VitalSenseTheme.primaryBlue),
                                  SizedBox(width: 6),
                                  Text('AI Analysis', style: TextStyle(fontSize: 11, color: VitalSenseTheme.primaryBlue, fontWeight: FontWeight.w700)),
                                ]),
                                const SizedBox(height: 6),
                                Text(vital.xaiExplanation!['summary'] ?? '', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // Trend chart
            Text('Vital Trends', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (readings) {
                if (readings.isEmpty) return const Text('No trend data available');
                final hrSpots = readings.reversed.toList().asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.heartRate)).toList();
                final spo2Spots = readings.reversed.toList().asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.spo2)).toList();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _LegendDot(VitalSenseTheme.alertRed), const SizedBox(width: 4), const Text('HR', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 12),
                          _LegendDot(VitalSenseTheme.primaryBlue), const SizedBox(width: 4), const Text('SpO₂', style: TextStyle(fontSize: 11)),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: LineChart(LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(spots: hrSpots, isCurved: true, color: VitalSenseTheme.alertRed, barWidth: 2, dotData: FlDotData(show: false)),
                              LineChartBarData(spots: spo2Spots, isCurved: true, color: VitalSenseTheme.primaryBlue, barWidth: 2, dotData: FlDotData(show: false)),
                            ],
                          )),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalMini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _VitalMini(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot(this.color);
  @override
  Widget build(BuildContext context) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
