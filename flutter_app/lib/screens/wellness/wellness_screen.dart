import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/medication_provider.dart';

class WellnessScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const WellnessScreen({super.key, this.showAppBar = true});
  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> {
  int _waterGlasses = 0;
  static const int _waterGoal = 8;
  DateTime? _lastWaterTime;
  Timer? _reminderTimer;
  bool _showReminder = false;

  final List<Map<String, dynamic>> _rituals = [
    {'icon': '🌬️', 'title': 'Get Fresh Air', 'desc': 'Step outside for 5 minutes and breathe deeply. Oxygen boosts brain function and reduces stress.', 'done': false, 'color': const Color(0xFF40c4ff)},
    {'icon': '🏃', 'title': 'Go for a Jog', 'desc': '15–20 minutes of jogging improves cardiovascular health and mood.', 'done': false, 'color': const Color(0xFF69ff47)},
    {'icon': '🚶', 'title': 'Take a Walk', 'desc': 'A gentle 10-minute walk helps digestion and clears your mind.', 'done': false, 'color': const Color(0xFFce93d8)},
    {'icon': '🚿', 'title': 'Cold Shower', 'desc': 'A 2-minute cold shower improves circulation and boosts alertness.', 'done': false, 'color': const Color(0xFF00e5ff)},
    {'icon': '🧘', 'title': 'Meditate', 'desc': 'Just 5 minutes of focused breathing reduces cortisol levels.', 'done': false, 'color': const Color(0xFFffcc02)},
    {'icon': '🧊', 'title': 'Stretch Break', 'desc': 'Stand up and stretch for 3 minutes. Relieves muscle tension.', 'done': false, 'color': const Color(0xFFef9a9a)},
    {'icon': '😴', 'title': 'Power Nap', 'desc': 'A 20-minute nap can restore alertness without grogginess.', 'done': false, 'color': const Color(0xFF4dd0e1)},
    {'icon': '🍎', 'title': 'Eat a Fruit', 'desc': 'Natural sugars and vitamins give a healthy energy boost.', 'done': false, 'color': const Color(0xFFff5252)},
  ];

  @override
  void initState() {
    super.initState();
    _startWaterReminder();
  }

  void _startWaterReminder() {
    _reminderTimer = Timer.periodic(const Duration(hours: 5), (_) {
      if (mounted) setState(() => _showReminder = true);
    });
    // Show initial reminder after 10 seconds for demo
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _waterGlasses == 0) setState(() => _showReminder = true);
    });
    // Simulate a Medication Alert after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _checkMedicationAlerts();
    });
  }

  void _checkMedicationAlerts() {
    final meds = ref.read(medicationProvider);
    if (meds.isNotEmpty) {
      final nextMed = meds.firstWhere((m) => !m.isTaken, orElse: () => meds.first);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0a1520),
          title: const Text('MEDICATION ALERT 🕒', style: TextStyle(color: Color(0xFFffab00), fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time to take: ${nextMed.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(nextMed.instructions, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('LATER', style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              onPressed: () {
                ref.read(medicationProvider.notifier).toggleMedication(nextMed.id);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF69ff47), foregroundColor: Colors.black),
              child: const Text('TAKE NOW'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _addWater() {
    setState(() {
      if (_waterGlasses < 12) _waterGlasses++;
      _lastWaterTime = DateTime.now();
      _showReminder = false;
    });
  }

  void _toggleRitual(int index) {
    setState(() {
      _rituals[index]['done'] = !(_rituals[index]['done'] as bool);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: const Color(0xFF0a1520),
        title: const Text('Wellness & Rituals',
            style: TextStyle(
                color: Color(0xFF00e5ff),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFF00e5ff)),
      ) : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Periods & Cycle Tracker ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFf48fb1).withOpacity(0.15), const Color(0xFF0c1824)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFf48fb1).withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_drop, color: Color(0xFFf48fb1)),
                      SizedBox(width: 10),
                      Text('MENSTRUAL HEALTH', style: TextStyle(color: Color(0xFFf48fb1), fontFamily: 'monospace', fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120, width: 120,
                        child: CircularProgressIndicator(
                          value: 18 / 28, // Day 18 of 28
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFF1a3040),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFf48fb1)),
                        ),
                      ),
                      Column(
                        children: [
                          const Text('Day', style: TextStyle(color: Color(0xFF4a6478), fontSize: 12)),
                          const Text('18', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          Text('of 28', style: TextStyle(color: const Color(0xFF4a6478).withOpacity(0.6), fontSize: 10)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Follicular Phase\nNext period in 10 days', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 12)),
                      ElevatedButton(
                        onPressed: (){
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF0c1824),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (_) {
                              final List<String> symptoms = ['Cramps', 'Headache', 'Acne', 'Fatigue', 'Bloating', 'Mood Swings'];
                              final Set<String> _selected = {};
                              return StatefulBuilder(
                                builder: (ctx, setModalState) => Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Log Menstrual Symptoms', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: symptoms.map((s) {
                                          final isSel = _selected.contains(s);
                                          return FilterChip(
                                            label: Text(s),
                                            selected: isSel,
                                            onSelected: (val) {
                                              setModalState(() {
                                                if (val) _selected.add(s);
                                                else _selected.remove(s);
                                              });
                                            },
                                            backgroundColor: const Color(0xFF1a3040),
                                            selectedColor: const Color(0xFFf48fb1).withOpacity(0.3),
                                            labelStyle: TextStyle(color: isSel ? const Color(0xFFf48fb1) : const Color(0xFFc8dae8)),
                                            side: BorderSide(color: isSel ? const Color(0xFFf48fb1) : Colors.transparent),
                                            showCheckmark: false,
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                              content: Text('Logged ${_selected.length} symptoms successfully!', style: const TextStyle(color: Color(0xFFf48fb1))),
                                              backgroundColor: const Color(0xFF0c1824),
                                              duration: const Duration(seconds: 2),
                                            ));
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFf48fb1), foregroundColor: const Color(0xFF060d14)),
                                          child: const Text('Save Symptoms', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                    ]
                                  )
                                )
                              );
                            }
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFf48fb1).withOpacity(0.2), foregroundColor: const Color(0xFFf48fb1)),
                        child: const Text('Log Symptoms', style: TextStyle(fontSize: 12)),
                      )
                    ],
                  )
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),

            // ── Water Reminder Banner ──────────────────────────────
            if (_showReminder)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF40c4ff).withOpacity(0.2),
                      const Color(0xFF00e5ff).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF40c4ff).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time to Hydrate!',
                              style: TextStyle(
                                  color: Color(0xFF40c4ff),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          Text("It's been a while — drink a glass of water",
                              style: TextStyle(
                                  color: Color(0xFF4a6478), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _showReminder = false),
                      icon: const Icon(Icons.close, color: Color(0xFF4a6478), size: 18),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

            if (_showReminder) const SizedBox(height: 16),

            // ── Water Intake Tracker ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0c1824),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1a3040)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('💧',
                          style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('WATER INTAKE',
                            style: TextStyle(
                                color: Color(0xFF00e5ff),
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5)),
                      ),
                      Text(
                        '${_waterGlasses * 250} ml',
                        style: const TextStyle(
                            color: Color(0xFF40c4ff),
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Glass indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_waterGoal, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _waterGlasses = i + 1;
                          _lastWaterTime = DateTime.now();
                          _showReminder = false;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 30,
                          height: 45,
                          decoration: BoxDecoration(
                            color: i < _waterGlasses
                                ? const Color(0xFF40c4ff).withOpacity(0.3)
                                : const Color(0xFF1a3040),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: i < _waterGlasses
                                  ? const Color(0xFF40c4ff)
                                  : const Color(0xFF1a3040),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: i < _waterGlasses ? 35 : 0,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF40c4ff).withOpacity(0.6),
                                      const Color(0xFF00e5ff),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 12),
                  // Progress text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_waterGlasses/$_waterGoal glasses',
                        style: const TextStyle(
                            color: Color(0xFF4a6478),
                            fontFamily: 'monospace',
                            fontSize: 11),
                      ),
                      Text(
                        '${((_waterGlasses / _waterGoal) * 100).toInt()}%',
                        style: TextStyle(
                            color: _waterGlasses >= _waterGoal
                                ? const Color(0xFF69ff47)
                                : const Color(0xFF40c4ff),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _waterGlasses / _waterGoal,
                      backgroundColor: const Color(0xFF1a3040),
                      valueColor: AlwaysStoppedAnimation(
                        _waterGlasses >= _waterGoal
                            ? const Color(0xFF69ff47)
                            : const Color(0xFF40c4ff),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addWater,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40c4ff).withOpacity(0.15),
                        foregroundColor: const Color(0xFF40c4ff),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Glass (250ml)',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),

            // ── Medication TODO List ──────────────────────────────
            const Text('MEDICATION REMINDERS', style: TextStyle(color: Color(0xFF69ff47), fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('Scheduled treatment from your physician', style: TextStyle(color: const Color(0xFF4a6478), fontSize: 11)),
            const SizedBox(height: 14),
            Consumer(
              builder: (context, ref, child) {
                final meds = ref.watch(medicationProvider);
                return Column(
                  children: meds.map((med) => _buildMedTile(med)).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Wellness Rituals ───────────────────────────────────
            const Text('DAILY WELLNESS RITUALS',
                style: TextStyle(
                    color: Color(0xFF00e5ff),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(
              'Complete these healthy habits to boost your wellness score',
              style: TextStyle(color: const Color(0xFF4a6478), fontSize: 12),
            ),
            const SizedBox(height: 14),

            // Ritual progress
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _rituals.where((r) => r['done'] == true).length / _rituals.length,
                      backgroundColor: const Color(0xFF1a3040),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF69ff47)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_rituals.where((r) => r['done'] == true).length}/${_rituals.length}',
                  style: const TextStyle(
                      color: Color(0xFF69ff47),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ...List.generate(_rituals.length, (i) {
              final r = _rituals[i];
              final done = r['done'] as bool;
              final color = r['color'] as Color;
              return GestureDetector(
                onTap: () => _toggleRitual(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: done
                        ? color.withOpacity(0.08)
                        : const Color(0xFF0c1824),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: done ? color.withOpacity(0.4) : const Color(0xFF1a3040),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(r['icon']!, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title']!,
                                style: TextStyle(
                                    color: done ? color : const Color(0xFFc8dae8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    decoration: done ? TextDecoration.lineThrough : null)),
                            const SizedBox(height: 2),
                            Text(r['desc']!,
                                style: TextStyle(
                                    color: const Color(0xFF4a6478),
                                    fontSize: 11,
                                    decoration: done ? TextDecoration.lineThrough : null)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: done ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: done ? color : const Color(0xFF1a3040),
                            width: 2,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: 0.05);
            }),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMedTile(Medication med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: med.isTaken ? const Color(0xFF69ff47).withOpacity(0.05) : const Color(0xFF0c1824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: med.isTaken ? const Color(0xFF69ff47).withOpacity(0.3) : const Color(0xFF1a3040)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: med.isTaken ? const Color(0xFF69ff47).withOpacity(0.1) : Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.medication, color: med.isTaken ? const Color(0xFF69ff47) : const Color(0xFF00e5ff), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: TextStyle(color: med.isTaken ? Colors.white70 : Colors.white, fontWeight: FontWeight.bold, fontSize: 15, decoration: med.isTaken ? TextDecoration.lineThrough : null)),
                Text('${med.purpose} • ${med.time}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                if (!med.isTaken) Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(med.instructions, style: const TextStyle(color: Color(0xFF69ff47), fontSize: 10)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(medicationProvider.notifier).toggleMedication(med.id),
            icon: Icon(med.isTaken ? Icons.check_circle : Icons.circle_outlined, color: med.isTaken ? const Color(0xFF69ff47) : Colors.white24),
          ),
        ],
      ),
    );
  }
}
