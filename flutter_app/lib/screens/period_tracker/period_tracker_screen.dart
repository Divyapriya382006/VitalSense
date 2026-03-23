import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class PeriodTrackerScreen extends ConsumerWidget {
  const PeriodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🌸 Period Tracker')),
      body: userAsync.when(
        data: (user) {
          if (user == null || !user.isFemale) {
            return const Center(child: Text('This feature is for female users'));
          }

          final nextPeriod = user.nextPeriodDate;
          final daysUntil = user.daysUntilNextPeriod;
          final isOverdue = daysUntil != null && daysUntil < 0;
          final isToday = daysUntil == 0;
          final isSoon = daysUntil != null && daysUntil <= 3 && daysUntil >= 0;

          final accentColor = const Color(0xFFFF6B9D);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor.withOpacity(0.8), const Color(0xFFC084FC).withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isToday ? "Today!" : isOverdue ? "Overdue" : isSoon ? "Coming Soon" : "Days Until",
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        daysUntil == null ? '—' : isOverdue ? '${daysUntil.abs()}d late' : isToday ? '🌸' : '$daysUntil',
                        style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
                      ),
                      if (nextPeriod != null)
                        Text(
                          'Expected: ${DateFormat('MMMM dd, yyyy').format(nextPeriod)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 24),

                // Cycle info
                Row(
                  children: [
                    _InfoCard(
                      title: 'Last Period',
                      value: user.lastPeriodDate != null
                          ? DateFormat('MMM dd').format(user.lastPeriodDate!)
                          : 'Not set',
                      icon: Icons.calendar_today_rounded,
                      color: accentColor,
                    ),
                    const SizedBox(width: 12),
                    _InfoCard(
                      title: 'Cycle Length',
                      value: '${user.periodCycleDays ?? 28} days',
                      icon: Icons.loop_rounded,
                      color: const Color(0xFFC084FC),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cycle visualization
                _CycleVisualization(
                  cycleDays: user.periodCycleDays ?? 28,
                  dayOfCycle: user.lastPeriodDate != null
                      ? DateTime.now().difference(user.lastPeriodDate!).inDays % (user.periodCycleDays ?? 28)
                      : 0,
                  color: accentColor,
                ),
                const SizedBox(height: 20),

                // Symptoms & tips
                Text('Health Tips During Your Cycle',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                ..._getTips(daysUntil ?? 15).map((tip) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(tip['emoji']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(tip['desc']!, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<Map<String, String>> _getTips(int daysUntil) {
    if (daysUntil <= 0) {
      return [
        {'emoji': '💊', 'title': 'Pain relief', 'desc': 'Ibuprofen or paracetamol can help with cramps'},
        {'emoji': '🌡️', 'title': 'Monitor closely', 'desc': 'Your vitals may fluctuate during menstruation'},
        {'emoji': '💧', 'title': 'Stay hydrated', 'desc': 'Drink extra water to help with bloating'},
        {'emoji': '🛌', 'title': 'Rest well', 'desc': 'Get extra sleep if needed — your body is working hard'},
      ];
    } else if (daysUntil <= 5) {
      return [
        {'emoji': '😤', 'title': 'PMS watch', 'desc': 'You may experience mood changes and bloating soon'},
        {'emoji': '🥗', 'title': 'Eat healthy', 'desc': 'Reduce salt and sugar intake to minimize bloating'},
        {'emoji': '🧘', 'title': 'Stress management', 'desc': 'Light yoga can ease PMS symptoms'},
        {'emoji': '🩺', 'title': 'Vital monitoring', 'desc': 'Watch for HR spikes during this phase'},
      ];
    } else {
      return [
        {'emoji': '💪', 'title': 'Fertile window', 'desc': 'Great time for intense workouts and high energy'},
        {'emoji': '😊', 'title': 'Mood boost', 'desc': 'Estrogen is rising — you may feel more energetic'},
        {'emoji': '🏃', 'title': 'Stay active', 'desc': 'Regular exercise helps regulate your cycle'},
        {'emoji': '📱', 'title': 'Track symptoms', 'desc': 'Log any unusual symptoms in your health records'},
      ];
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _InfoCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CycleVisualization extends StatelessWidget {
  final int cycleDays;
  final int dayOfCycle;
  final Color color;

  const _CycleVisualization({required this.cycleDays, required this.dayOfCycle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cycle Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (dayOfCycle % cycleDays) / cycleDays,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Day ${dayOfCycle % cycleDays}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                Text('of $cycleDays days', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            // Phase labels
            Row(
              children: [
                _PhaseLabel('Menstrual\n1–5', color),
                _PhaseLabel('Follicular\n6–13', const Color(0xFFFCD34D)),
                _PhaseLabel('Ovulation\n14', const Color(0xFF34D399)),
                _PhaseLabel('Luteal\n15–28', const Color(0xFFC084FC)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _PhaseLabel(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
