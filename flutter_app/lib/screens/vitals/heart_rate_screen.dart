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

class HeartRateScreen extends ConsumerWidget {
  const HeartRateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final latestAsync = ref.watch(latestVitalProvider(user?.uid ?? ''));
    final historyAsync = ref.watch(vitalHistoryProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate'),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline_rounded), onPressed: () => _showInfo(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode banner
            const ModeBannerWidget(),
            const SizedBox(height: 12),
            // Current reading
            latestAsync.when(
              data: (vital) => vital != null ? _CurrentHRCard(vital: vital) : const _NoData(),
              loading: () => const _LoadingCard(),
              error: (_, __) => const _NoData(),
            ),
            const SizedBox(height: 20),

            // Normal range guide
            _RangeGuide(),
            const SizedBox(height: 20),

            // Trend chart
            Text('Heart Rate Trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (readings) => readings.isNotEmpty
                  ? _HRTrendChart(readings: readings)
                  : const Center(child: Text('No historical data yet')),
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // HRV & Stress
            latestAsync.when(
              data: (vital) => vital != null ? _HRVCard(vital: vital) : const SizedBox(),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About Heart Rate', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Heart rate (HR) is the number of times your heart beats per minute (BPM). A normal resting heart rate for adults is 60–100 BPM. Athletes may have lower resting rates (40–60 BPM).'),
            const SizedBox(height: 12),
            const Text('• Below 40 BPM: Critical bradycardia\n• 40–59 BPM: Low (may be normal for athletes)\n• 60–100 BPM: Normal\n• 101–110 BPM: Slightly elevated\n• Above 110 BPM: Tachycardia — seek attention'),
          ],
        ),
      ),
    );
  }
}

class _CurrentHRCard extends StatelessWidget {
  final VitalReading vital;
  const _CurrentHRCard({required this.vital});

  @override
  Widget build(BuildContext context) {
    final color = VitalSenseTheme.getStatusColor(vital.heartRateStatus.name);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Heart Rate', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${vital.heartRate.toInt()}',
                        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: color)),
                    const Padding(padding: EdgeInsets.only(bottom: 8, left: 4), child: Text('BPM', style: TextStyle(color: Colors.grey))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(vital.heartRateStatus.name.toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                ),
              ],
            ),
            const Spacer(),
            // Pulse animation
            _PulseIcon(color: color)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.85, end: 1.15, duration: 600.ms, curve: Curves.easeInOut),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class _PulseIcon extends StatelessWidget {
  final Color color;
  const _PulseIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
      child: Icon(Icons.favorite_rounded, color: color, size: 40),
    );
  }
}

class _HRTrendChart extends StatelessWidget {
  final List<VitalReading> readings;
  const _HRTrendChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings.reversed.toList().asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.heartRate)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 40, maxY: 160,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: VitalSenseTheme.alertRed,
                  barWidth: 2.5,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [VitalSenseTheme.alertRed.withOpacity(0.3), VitalSenseTheme.alertRed.withOpacity(0)],
                    ),
                  ),
                ),
                // Normal range band
                LineChartBarData(
                  spots: spots.map((s) => FlSpot(s.x, 100)).toList(),
                  isCurved: false, color: Colors.transparent, barWidth: 0,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: VitalSenseTheme.primaryGreen.withOpacity(0.05),
                    cutOffY: 60, applyCutOffY: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Normal Ranges', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
            const SizedBox(height: 12),
            _RangeBar('Critical Low', '< 40', 0, VitalSenseTheme.alertRed),
            _RangeBar('Low', '40–59', 0.25, VitalSenseTheme.accentPurple),
            _RangeBar('Normal', '60–100', 0.6, VitalSenseTheme.primaryGreen),
            _RangeBar('Warning', '101–110', 0.8, VitalSenseTheme.alertAmber),
            _RangeBar('Critical High', '> 110', 1.0, VitalSenseTheme.alertRed),
          ],
        ),
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final String label, range;
  final double fill;
  final Color color;
  const _RangeBar(this.label, this.range, this.fill, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11))),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: fill, backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
          )),
          const SizedBox(width: 8),
          SizedBox(width: 55, child: Text(range, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _HRVCard extends StatelessWidget {
  final VitalReading vital;
  const _HRVCard({required this.vital});

  @override
  Widget build(BuildContext context) {
    if (vital.hrv == null) return const SizedBox();
    final stressColor = vital.stressLevel != null && vital.stressLevel! > 60
        ? VitalSenseTheme.alertRed
        : vital.stressLevel != null && vital.stressLevel! > 40
            ? VitalSenseTheme.alertAmber
            : VitalSenseTheme.primaryGreen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.psychology_rounded, size: 18),
              const SizedBox(width: 8),
              Text('HRV & Stress Analysis', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _HRVStat('HRV', '${vital.hrv!.toInt()} ms', VitalSenseTheme.primaryBlue),
              const SizedBox(width: 16),
              if (vital.stressLevel != null)
                _HRVStat('Stress', '${vital.stressLevel!.toInt()}%', stressColor),
            ]),
            const SizedBox(height: 10),
            Text(
              vital.hrv! > 60
                  ? '✅ Good HRV — low stress, well recovered'
                  : vital.hrv! > 30
                      ? '⚠️ Moderate HRV — some stress detected'
                      : '🔴 Low HRV — high stress or fatigue',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _HRVStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HRVStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: Text('No data available. Connect sensors or use face scan.')),
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
  );
}
