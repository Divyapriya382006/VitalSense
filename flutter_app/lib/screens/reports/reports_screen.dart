import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../services/pdf_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const ReportsScreen({super.key, this.showAppBar = true});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _generating = false;

  Future<void> _generateAndShare() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final latestVital = ref.read(latestVitalProvider(user?.uid ?? '')).valueOrNull;
    final history = ref.read(vitalHistoryProvider(user?.uid ?? '')).valueOrNull ?? [];

    if (user == null || latestVital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vitals data available to generate report')),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final file = await PDFReportService.generateReport(
        user: user, readings: history, latest: latestVital,
      );
      await PDFReportService.shareReport(file, user.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final historyAsync = ref.watch(vitalHistoryProvider(
        userAsync.valueOrNull?.uid ?? ''));

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Health Reports')) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filter By Date ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('REPORT DASHBOARD', style: TextStyle(color: Color(0xFF00e5ff), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'monospace')),
                GestureDetector(
                  onTap: () async {
                    await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF1a3040), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        Icon(Icons.calendar_month, color: Color(0xFF00e5ff), size: 14),
                        SizedBox(width: 8),
                        Text('Oct 2026', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 12)),
                        Icon(Icons.keyboard_arrow_down, color: Color(0xFFc8dae8), size: 16),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // ── Yearly Critical Heatmap (GitHub Style) ───────────
            const Text('CRITICAL EVENTS HEATMAP', style: TextStyle(color: Color(0xFF4a6478), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0c1824), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1a3040))),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 20, crossAxisSpacing: 3, mainAxisSpacing: 3),
                itemCount: 80, // Simulate a few months
                itemBuilder: (context, index) {
                  // Simulate heatmap data
                  final int intensity = (index % 7 == 0) ? 3 : (index % 11 == 0) ? 2 : (index % 3 == 0) ? 1 : 0;
                  Color color;
                  if (intensity == 0) color = const Color(0xFF1a3040);
                  else if (intensity == 1) color = const Color(0xFFffab00).withOpacity(0.4);
                  else if (intensity == 2) color = const Color(0xFFff3d00).withOpacity(0.7);
                  else color = const Color(0xFFff3d00);

                  return Tooltip(
                    message: "Day ${index + 1} Oct\nEvents: ${intensity == 0 ? 'None' : intensity == 1 ? 'Minor' : 'Critical'}",
                    child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Generate report card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: VitalSenseTheme.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: VitalSenseTheme.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Health Report PDF', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                          Text('Share your vitals with doctors or family', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Includes:\n• Personal Health Index (PHI) score\n• All vital signs with status\n• Historical trend data\n• AI analysis & recommendations\n• XAI explanation of alerts'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _generating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.share_rounded),
                        label: Text(_generating ? 'Generating...' : 'Generate & Share PDF'),
                        onPressed: _generating ? null : _generateAndShare,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 20),

            // Reading history summary
            Text('Recent Readings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (readings) {
                if (readings.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No readings recorded yet')),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: readings.take(20).length,
                  itemBuilder: (_, i) {
                    final r = readings[i];
                    final color = VitalSenseTheme.getStatusColor(r.overallStatus.name);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? VitalSenseTheme.darkCard : VitalSenseTheme.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VitalSenseTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                            Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.heartRate.toInt()} BPM  ·  ${r.spo2.toInt()}%  ·  ${r.temperature.toStringAsFixed(1)}°C',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Row(
                                children: [
                                  Text(_fmt(r.timestamp), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                                  if (r.periodPhase != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: const Color(0xFFf48fb1).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Text('${r.periodPhase} · ${r.daysUntilPeriod}d', style: const TextStyle(color: Color(0xFFf48fb1), fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text('PHI ${r.phiScore.toInt()}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ).animate(delay: (i * 40).ms).fadeIn();
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
