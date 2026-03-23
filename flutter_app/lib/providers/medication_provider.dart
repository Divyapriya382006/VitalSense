import 'package:flutter_riverpod/flutter_riverpod.dart';

class Medication {
  final String id;
  final String name;
  final String purpose;
  final String instructions;
  final String time;
  final bool isTaken;

  Medication({
    required this.id,
    required this.name,
    required this.purpose,
    required this.instructions,
    required this.time,
    this.isTaken = false,
  });

  Medication copyWith({bool? isTaken}) {
    return Medication(
      id: id,
      name: name,
      purpose: purpose,
      instructions: instructions,
      time: time,
      isTaken: isTaken ?? this.isTaken,
    );
  }
}

class MedicationNotifier extends StateNotifier<List<Medication>> {
  MedicationNotifier() : super([
    Medication(id: '1', name: 'Atorvastatin', purpose: 'Cholesterol', instructions: 'Take with water after dinner', time: '09:00 PM'),
    Medication(id: '2', name: 'Lisinopril', purpose: 'Blood Pressure', instructions: 'Take on empty stomach', time: '08:00 AM'),
  ]);

  void addMedication(Medication med) {
    state = [...state, med];
  }

  void toggleMedication(String id) {
    state = [
      for (final med in state)
        if (med.id == id) med.copyWith(isTaken: !med.isTaken) else med,
    ];
  }
}

final medicationProvider = StateNotifierProvider<MedicationNotifier, List<Medication>>((ref) {
  return MedicationNotifier();
});
