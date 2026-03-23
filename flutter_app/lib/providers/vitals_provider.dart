import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vital_model.dart';
import '../services/database_service.dart';


// Demo vitals that update every 3 seconds to simulate real sensor data

VitalReading _generateDemoVital() {
  final rng = Random();
  final hr = 68.0 + rng.nextInt(20);
  final spo2 = 96.0 + rng.nextInt(4);
  final temp = 36.4 + rng.nextDouble() * 0.8;
  final hrv = 45.0 + rng.nextInt(30);
  final stress = 20.0 + rng.nextInt(30);

  // PHI score calculation
  double phi = 100;
  if (hr < 60 || hr > 100) phi -= 20;
  if (spo2 < 95) phi -= 25;
  if (temp < 36 || temp > 37.5) phi -= 15;
  phi = phi.clamp(0, 100);

  return VitalReading(
    id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
    userId: 'demo_user_123',
    timestamp: DateTime.now(),
    heartRate: hr,
    spo2: spo2,
    temperature: temp,
    ecgValue: 0.3 + rng.nextDouble() * 0.4,
    systolicBP: 118 + rng.nextInt(10).toDouble(),
    diastolicBP: 76 + rng.nextInt(8).toDouble(),
    phiScore: phi,
    stressLevel: stress,
    hrv: hrv,
    source: 'demo',
    xaiExplanation: {
      'summary': phi >= 80
          ? 'All vitals are within normal range. Your health looks excellent today!'
          : 'Some vitals need monitoring. Stay hydrated and rest well.',
      'factors': [
        'Heart rate: ${hr.toInt()} BPM — ${hr >= 60 && hr <= 100 ? "Normal ✅" : "Slightly elevated ⚠️"}',
        'SpO₂: ${spo2.toInt()}% — ${spo2 >= 95 ? "Healthy ✅" : "Below normal ⚠️"}',
        'Temperature: ${temp.toStringAsFixed(1)}°C — Normal ✅',
      ],
      'recommendations': [
        'Stay hydrated — drink water every 2 hours',
        'Take a short walk to improve circulation',
      ],
    },
    isSynced: false,
  );
}

// Streams a new demo vital every 3 seconds
final latestVitalProvider = StreamProvider.family<VitalReading?, String>((ref, userId) {
  return Stream.periodic(const Duration(seconds: 3), (_) => _generateDemoVital())
      .asBroadcastStream();
});

// Returns last 20 demo readings for charts
final vitalHistoryProvider = StreamProvider.family<List<VitalReading>, String>((ref, userId) {
  final history = List.generate(20, (i) {
    final rng = Random(i);
    return VitalReading(
      id: 'history_$i',
      userId: userId,
      timestamp: DateTime.now().subtract(Duration(minutes: i * 5)),
      heartRate: 65.0 + rng.nextInt(25),
      spo2: 95.0 + rng.nextInt(5),
      temperature: 36.3 + rng.nextDouble() * 0.9,
      ecgValue: 0.3 + rng.nextDouble() * 0.4,
      phiScore: 70.0 + rng.nextInt(25),
      stressLevel: 15.0 + rng.nextInt(40),
      hrv: 40.0 + rng.nextInt(40),
      source: 'demo',
      isSynced: false,
    );
  });
  return Stream.value(history);
});

// Empty alerts for demo
final alertsProvider = StreamProvider.family<List<HealthAlert>, String>((ref, userId) {
  final alerts = [
    HealthAlert(
      id: 'alert_1',
      userId: userId,
      title: 'Heart Rate Elevated',
      message: 'Your heart rate reached 112 BPM at 2:30 PM. Consider resting.',
      severity: VitalStatus.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      vitalSnapshot: {'xaiSummary': 'Heart rate spiked above normal range. Likely due to physical activity.'},
    ),
    HealthAlert(
      id: 'alert_2',
      userId: userId,
      title: 'SpO₂ Check',
      message: 'Oxygen saturation was at 93% briefly. Now back to normal.',
      severity: VitalStatus.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      vitalSnapshot: {'xaiSummary': 'Brief dip in oxygen saturation. Resolved after deep breathing.'},
    ),
  ];
  return Stream.value(alerts);
});

final unreadAlertsCountProvider = Provider.family<AsyncValue<int>, String>((ref, userId) {
  return ref.watch(alertsProvider(userId)).whenData(
    (alerts) => alerts.where((a) => !a.isRead).length,
  );
});

// Doctor patients demo data
class PatientSummary {
  final String userId;
  final String name;
  final double heartRate;
  final double spo2;
  final double temperature;
  final double phiScore;
  final VitalStatus status;
  final VitalReading? vital;

  PatientSummary({
    required this.userId,
    required this.name,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.phiScore,
    required this.status,
    this.vital,
  });
}

final doctorPatientsProvider = StreamProvider<List<PatientSummary>>((ref) {
  final patients = [
    PatientSummary(userId: 'p1', name: 'Arjun Kumar', heartRate: 142, spo2: 89,
        temperature: 39.2, phiScore: 28, status: VitalStatus.critical),
    PatientSummary(userId: 'p2', name: 'Priya Sharma', heartRate: 108, spo2: 93,
        temperature: 38.1, phiScore: 52, status: VitalStatus.warning),
    PatientSummary(userId: 'p3', name: 'Rahul Singh', heartRate: 78, spo2: 98,
        temperature: 36.8, phiScore: 88, status: VitalStatus.normal),
    PatientSummary(userId: 'p4', name: 'Ananya Reddy', heartRate: 72, spo2: 97,
        temperature: 36.6, phiScore: 91, status: VitalStatus.normal),
    PatientSummary(userId: 'p5', name: 'Vikram Nair', heartRate: 55, spo2: 96,
        temperature: 37.1, phiScore: 74, status: VitalStatus.low),
  ];
  return Stream.value(patients);
});

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

Future<void> saveVitalReading(WidgetRef ref, VitalReading reading) async {
  await ref.read(databaseServiceProvider).insertVital(reading);
}

Future<void> saveAlert(WidgetRef ref, HealthAlert alert) async {
  await ref.read(databaseServiceProvider).insertAlert(alert);
}

Future<void> markAlertRead(WidgetRef ref, String alertId) async {
  // Logic to mark as read in local DB would go here
  // For now we'll just implement the interface
}