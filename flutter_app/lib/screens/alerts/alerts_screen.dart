import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/vital_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final alertsAsync = ref.watch(alertsProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            onPressed: () => _showMeshSOS(context),
            icon: const Icon(Icons.emergency_share, color: Colors.redAccent),
            tooltip: 'Simulate Offline SOS',
          ),
          TextButton(
            onPressed: () {/* mark all read */},
            child: const Text('Mark all read', style: TextStyle(color: VitalSenseTheme.primaryBlue)),
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No alerts', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text("You're all clear! We'll notify you if anything needs attention.",
                      style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (_, i) => _AlertCard(alert: alerts[i], index: i),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showMeshSOS(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MeshSOSSimulation(),
    );
  }
}

class _MeshSOSSimulation extends StatefulWidget {
  @override
  State<_MeshSOSSimulation> createState() => _MeshSOSSimulationState();
}

class _MeshSOSSimulationState extends State<_MeshSOSSimulation> {
  int _step = 0;
  final List<String> _logs = [
    '⚠️ Network Failure: cellular link lost',
    '🔌 Initializing P2P Mesh Protocol...',
    '🛰️ Broadcasting SOS Packet to local nodes...',
    '✅ Node #102 (Nearby) received packet',
    '🔗 Hopping packet to Node #105 (Hospital Sector)',
    '🩺 SOS Received by Doctor Sarah Jenkins via Mesh',
    '💬 Doctor: "Help is on the way!"',
  ];

  @override
  void initState() {
    super.initState();
    _nextStep();
  }

  void _nextStep() {
    if (_step < _logs.length - 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _step++);
          _nextStep();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF060d14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent, width: 2)),
      title: Row(
        children: const [
          Icon(Icons.hub, color: Colors.redAccent),
          SizedBox(width: 12),
          Text('MESH SOS ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 2, width: double.infinity, decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.3))),
            const SizedBox(height: 16),
            ...List.generate(_step + 1, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(_logs[i], style: TextStyle(color: i == _step ? Colors.white : Colors.white54, fontSize: 13, fontWeight: i == _step ? FontWeight.bold : FontWeight.normal)),
            ).animate().fadeIn().slideX(begin: -0.1)),
            const SizedBox(height: 16),
            if (_step < _logs.length - 1)
              const Center(child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2))
            else
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  child: const Text('DISMISS'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final HealthAlert alert;
  final int index;
  const _AlertCard({required this.alert, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = VitalSenseTheme.getStatusColor(alert.severity.name);
    final fmt = DateFormat('MMM dd, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? VitalSenseTheme.darkCard : VitalSenseTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alert.isRead ? VitalSenseTheme.darkBorder : color.withOpacity(0.5)),
        boxShadow: !alert.isRead ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)] : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(
                alert.severity == VitalStatus.critical ? Icons.warning_rounded : Icons.info_rounded,
                color: color, size: 20,
              ),
            ),
            title: Text(alert.title,
                style: TextStyle(fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w700, fontSize: 14)),
            subtitle: Text(alert.message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(alert.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (!alert.isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
          // XAI snapshot
          if (alert.vitalSnapshot != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.analytics_outlined, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text('AI Explanation', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      alert.vitalSnapshot?['xaiSummary'] ?? 'Vitals deviated from your normal range.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.1);
  }
}
