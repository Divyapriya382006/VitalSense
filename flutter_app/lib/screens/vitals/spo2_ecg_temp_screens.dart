import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/vital_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/hardware_provider.dart';
import '../../widgets/mode_banner_widget.dart';

// ─────────────── SpO2 ───────────────
class SpO2Screen extends ConsumerWidget {
  const SpO2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final latestAsync = ref.watch(latestVitalProvider(user?.uid ?? ''));
    final historyAsync = ref.watch(vitalHistoryProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Oxygen (SpO₂)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ModeBannerWidget(),
            const SizedBox(height: 12),
            latestAsync.when(
              data: (v) => v != null ? _SpO2Card(vital: v) : const SizedBox(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),
            _SpO2RangeGuide(),
            const SizedBox(height: 20),
            Text('SpO₂ Trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (readings) => readings.isNotEmpty ? _SpO2Chart(readings: readings) : const SizedBox(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpO2Card extends StatelessWidget {
  final VitalReading vital;
  const _SpO2Card({required this.vital});

  @override
  Widget build(BuildContext context) {
    final color = VitalSenseTheme.getStatusColor(vital.spo2Status.name);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Blood Oxygen', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${vital.spo2.toInt()}', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: color)),
                    const Padding(padding: EdgeInsets.only(bottom: 8, left: 4), child: Text('%', style: TextStyle(color: Colors.grey, fontSize: 20))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(vital.spo2Status.name.toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: VitalSenseTheme.primaryBlue.withOpacity(0.12)),
              child: const Icon(Icons.air_rounded, color: VitalSenseTheme.primaryBlue, size: 40),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms),
          ],
        ),
      ),
    );
  }
}

class _SpO2RangeGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SpO₂ Reference Ranges', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
            const SizedBox(height: 12),
            _RangeRow('Critical', '< 90%', VitalSenseTheme.alertRed, 'Seek emergency help immediately'),
            _RangeRow('Low', '90–94%', VitalSenseTheme.alertAmber, 'Get fresh air, monitor closely'),
            _RangeRow('Normal', '95–100%', VitalSenseTheme.primaryGreen, 'Healthy oxygen levels'),
          ],
        ),
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  final String label, value, note;
  final Color color;
  const _RangeRow(this.label, this.value, this.color, this.note);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12))),
          SizedBox(width: 60, child: Text(value, style: const TextStyle(fontSize: 12))),
          Expanded(child: Text(note, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11))),
        ],
      ),
    );
  }
}

class _SpO2Chart extends StatelessWidget {
  final List<VitalReading> readings;
  const _SpO2Chart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings.reversed.toList().asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.spo2)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            minY: 85, maxY: 101,
            gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots, isCurved: true,
                color: VitalSenseTheme.primaryBlue, barWidth: 2.5,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [VitalSenseTheme.primaryBlue.withOpacity(0.25), Colors.transparent],
                )),
              ),
            ],
          )),
        ),
      ),
    );
  }
}



// ─────────────── Temperature ───────────────
class TemperatureScreen extends ConsumerWidget {
  const TemperatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final latestAsync = ref.watch(latestVitalProvider(user?.uid ?? ''));
    final historyAsync = ref.watch(vitalHistoryProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Body Temperature')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ModeBannerWidget(),
            const SizedBox(height: 12),
            latestAsync.when(
              data: (v) {
                if (v == null) return const SizedBox();
                final color = VitalSenseTheme.getStatusColor(v.temperatureStatus.name);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Body Temperature', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(v.temperature.toStringAsFixed(1),
                                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: color)),
                                const Padding(padding: EdgeInsets.only(bottom: 8, left: 4), child: Text('°C', style: TextStyle(color: Colors.grey, fontSize: 20))),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(v.temperatureStatus.name.toUpperCase(),
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
                          child: Icon(Icons.thermostat_rounded, color: color, size: 40),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temperature Ranges', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                    const SizedBox(height: 12),
                    _RangeRow('Hypothermia', '< 36°C', VitalSenseTheme.accentPurple, 'Seek medical help immediately'),
                    _RangeRow('Low', '36–36.1°C', VitalSenseTheme.alertAmber, 'Slightly below normal'),
                    _RangeRow('Normal', '36.1–37.5°C', VitalSenseTheme.primaryGreen, 'Healthy temperature'),
                    _RangeRow('Low Fever', '37.5–38.5°C', VitalSenseTheme.alertAmber, 'Rest and stay hydrated'),
                    _RangeRow('High Fever', '> 38.5°C', VitalSenseTheme.alertRed, 'Seek medical attention'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Temperature Trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (readings) {
                if (readings.isEmpty) return const SizedBox();
                final spots = readings.reversed.toList().asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 180,
                      child: LineChart(LineChartData(
                        minY: 35, maxY: 40,
                        gridData: FlGridData(show: true, drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                              getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots, isCurved: true,
                            color: VitalSenseTheme.alertAmber, barWidth: 2.5,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [VitalSenseTheme.alertAmber.withOpacity(0.2), Colors.transparent],
                            )),
                          ),
                        ],
                      )),
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
