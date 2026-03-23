import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/vital_model.dart';
import '../../providers/vitals_provider.dart';

class DoctorWarroomScreen extends ConsumerWidget {
  const DoctorWarroomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: VitalSenseTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
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
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
                  const SizedBox(width: 6),
                  const Text('War Room', style: TextStyle(color: VitalSenseTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('Patient Monitor', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const _EmptyWarroom();
          }

          final critical = patients.where((p) => p.status == VitalStatus.critical).toList();
          final warning = patients.where((p) => p.status == VitalStatus.warning).toList();
          final normal = patients.where((p) => p.status == VitalStatus.normal || p.status == VitalStatus.low).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(doctorPatientsProvider),
            child: CustomScrollView(
              slivers: [
                // Summary stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _SummaryRow(
                      total: patients.length,
                      critical: critical.length,
                      warning: warning.length,
                      normal: normal.length,
                    ),
                  ),
                ),

                // Critical patients
                if (critical.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader('🚨 Critical', VitalSenseTheme.alertRed, critical.length),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PatientCard(patient: critical[i], index: i).animate(delay: (i * 50).ms).fadeIn().slideX(begin: -0.1),
                      childCount: critical.length,
                    ),
                  ),
                ],

                // Warning patients
                if (warning.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader('⚠️ Warning', VitalSenseTheme.alertAmber, warning.length),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PatientCard(patient: warning[i], index: i).animate(delay: (i * 50).ms).fadeIn(),
                      childCount: warning.length,
                    ),
                  ),
                ],

                // Normal patients
                if (normal.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader('✅ Stable', VitalSenseTheme.primaryGreen, normal.length),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PatientCard(patient: normal[i], index: i).animate(delay: (i * 50).ms).fadeIn(),
                      childCount: normal.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total, critical, warning, normal;
  const _SummaryRow({required this.total, required this.critical, required this.warning, required this.normal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip('Total', '$total', Colors.grey),
        const SizedBox(width: 8),
        _StatChip('Critical', '$critical', VitalSenseTheme.alertRed),
        const SizedBox(width: 8),
        _StatChip('Warning', '$warning', VitalSenseTheme.alertAmber),
        const SizedBox(width: 8),
        _StatChip('Stable', '$normal', VitalSenseTheme.primaryGreen),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final int count;
  const _SectionHeader(this.title, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientSummary patient;
  final int index;
  const _PatientCard({required this.patient, required this.index});

  @override
  Widget build(BuildContext context) {
    final statusColor = VitalSenseTheme.getStatusColor(patient.status.name);

    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/home/patient/${patient.userId}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? VitalSenseTheme.darkCard
              : VitalSenseTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: patient.status == VitalStatus.critical
                ? statusColor.withOpacity(0.6)
                : statusColor.withOpacity(0.2),
            width: patient.status == VitalStatus.critical ? 2 : 1,
          ),
          boxShadow: patient.status == VitalStatus.critical
              ? [BoxShadow(color: statusColor.withOpacity(0.15), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _VitalPill(Icons.favorite_rounded, '${patient.heartRate.toInt()} BPM',
                          patient.vital?.heartRateStatus ?? VitalStatus.normal),
                      const SizedBox(width: 6),
                      _VitalPill(Icons.air_rounded, '${patient.spo2.toInt()}%',
                          patient.vital?.spo2Status ?? VitalStatus.normal),
                      const SizedBox(width: 6),
                      _VitalPill(Icons.thermostat_rounded, '${patient.temperature.toStringAsFixed(1)}°',
                          patient.vital?.temperatureStatus ?? VitalStatus.normal),
                    ],
                  ),
                ],
              ),
            ),

            // PHI Score
            Column(
              children: [
                Text(
                  '${patient.phiScore.toInt()}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: VitalSenseTheme.getPHIColor(patient.phiScore),
                  ),
                ),
                const Text('PHI', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final VitalStatus status;
  const _VitalPill(this.icon, this.value, this.status);

  @override
  Widget build(BuildContext context) {
    final color = VitalSenseTheme.getStatusColor(status.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyWarroom extends StatelessWidget {
  const _EmptyWarroom();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No patients assigned yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Patients will appear here once they add you as their doctor',
              style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
