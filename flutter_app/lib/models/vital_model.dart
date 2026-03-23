enum VitalStatus { low, normal, warning, critical }

class VitalReading {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double heartRate; // BPM
  final double spo2; // %
  final double temperature; // Celsius
  final double? ecgValue; // mV
  final double? systolicBP;
  final double? diastolicBP;
  final double phiScore; // 0-100
  final Map<String, dynamic>? xaiExplanation;
  final String? periodPhase;
  final int? daysUntilPeriod;
  final bool isSynced;

  VitalReading({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    this.ecgValue,
    this.systolicBP,
    this.diastolicBP,
    required this.phiScore,
    this.stressLevel,
    this.hrv,
    this.source = 'sensor',
    this.xaiExplanation,
    this.periodPhase,
    this.daysUntilPeriod,
    this.isSynced = true,
  });

  VitalStatus get heartRateStatus {
    if (heartRate < 40 || heartRate > 150) return VitalStatus.critical;
    if (heartRate < 55 || heartRate > 110) return VitalStatus.warning;
    if (heartRate < 60 || heartRate > 100) return VitalStatus.low;
    return VitalStatus.normal;
  }

  VitalStatus get spo2Status {
    if (spo2 < 90) return VitalStatus.critical;
    if (spo2 < 94) return VitalStatus.warning;
    if (spo2 < 96) return VitalStatus.low;
    return VitalStatus.normal;
  }

  VitalStatus get temperatureStatus {
    if (temperature < 35.0 || temperature > 39.5) return VitalStatus.critical;
    if (temperature < 36.0 || temperature > 38.5) return VitalStatus.warning;
    return VitalStatus.normal;
  }

  VitalStatus get overallStatus {
    final statuses = [heartRateStatus, spo2Status, temperatureStatus];
    if (statuses.contains(VitalStatus.critical)) return VitalStatus.critical;
    if (statuses.contains(VitalStatus.warning)) return VitalStatus.warning;
    if (statuses.contains(VitalStatus.low)) return VitalStatus.low;
    return VitalStatus.normal;
  }

  bool get requiresImmediateAttention => overallStatus == VitalStatus.critical;

  // Normal ranges for display
  static const Map<String, Map<String, double>> normalRanges = {
    'heartRate': {'veryLow': 0, 'low': 40, 'normal': 60, 'high': 100, 'veryHigh': 150, 'max': 200},
    'spo2': {'veryLow': 80, 'low': 90, 'normal': 95, 'high': 100, 'max': 100},
    'temperature': {'veryLow': 34, 'low': 36, 'normal': 37, 'high': 38.5, 'veryHigh': 40, 'max': 42},
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'ecgValue': ecgValue,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'phiScore': phiScore,
      'stressLevel': stressLevel,
      'hrv': hrv,
      'source': source,
      'periodPhase': periodPhase,
      'daysUntilPeriod': daysUntilPeriod,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory VitalReading.fromMap(Map<String, dynamic> d) {
    return VitalReading(
      id: d['id'] ?? '',
      userId: d['userId'] ?? '',
      timestamp: d['timestamp'] is DateTime
          ? d['timestamp']
          : DateTime.parse(d['timestamp'].toString()),
      heartRate: (d['heartRate'] as num).toDouble(),
      spo2: (d['spo2'] as num).toDouble(),
      temperature: (d['temperature'] as num).toDouble(),
      ecgValue: d['ecgValue'] != null ? (d['ecgValue'] as num).toDouble() : null,
      systolicBP: d['systolicBP'] != null ? (d['systolicBP'] as num).toDouble() : null,
      diastolicBP: d['diastolicBP'] != null ? (d['diastolicBP'] as num).toDouble() : null,
      phiScore: (d['phiScore'] as num).toDouble(),
      stressLevel: d['stressLevel'] != null ? (d['stressLevel'] as num).toDouble() : null,
      hrv: d['hrv'] != null ? (d['hrv'] as num).toDouble() : null,
      source: d['source'],
      periodPhase: d['periodPhase'],
      daysUntilPeriod: d['daysUntilPeriod'],
      xaiExplanation: d['xaiExplanation'] is Map ? Map<String, dynamic>.from(d['xaiExplanation']) : null,
      isSynced: d['isSynced'] == 1 || d['isSynced'] == true,
    );
  }

  VitalReading copyWith({bool? isSynced}) {
    return VitalReading(
      id: id, userId: userId, timestamp: timestamp,
      heartRate: heartRate, spo2: spo2, temperature: temperature,
      ecgValue: ecgValue, systolicBP: systolicBP, diastolicBP: diastolicBP,
      phiScore: phiScore, stressLevel: stressLevel, hrv: hrv,
      source: source, xaiExplanation: xaiExplanation,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class HealthAlert {
  final String id;
  final String userId;
  final String title;
  final String message;
  final VitalStatus severity;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? vitalSnapshot;

  HealthAlert({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
    this.vitalSnapshot,
  });

  factory HealthAlert.fromMap(Map<String, dynamic> d) {
    return HealthAlert(
      id: d['id'],
      userId: d['userId'],
      title: d['title'],
      message: d['message'],
      severity: VitalStatus.values.firstWhere((e) => e.name == d['severity']),
      timestamp: d['timestamp'] is DateTime
          ? d['timestamp']
          : DateTime.parse(d['timestamp'].toString()),
      isRead: d['isRead'] == 1 || d['isRead'] == true,
      vitalSnapshot: d['vitalSnapshot'] is Map ? Map<String, dynamic>.from(d['vitalSnapshot']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'title': title, 'message': message,
    'severity': severity.name, 'timestamp': timestamp.toIso8601String(),
    'isRead': isRead ? 1 : 0,
  };
}
