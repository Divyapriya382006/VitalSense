import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vital_model.dart';

class OfflineService {
  static const String _vitalsBox = 'vitals_cache';
  static const String _pendingBox = 'pending_sync';
  static const int _maxCacheSize = 500;

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_vitalsBox);
    await Hive.openBox(_pendingBox);
  }

  Future<void> cacheVitalReading(VitalReading reading) async {
    final box = Hive.box(_vitalsBox);
    final data = jsonEncode(reading.toMap());
    await box.put(reading.id, data);

    // Keep cache size manageable
    if (box.length > _maxCacheSize) {
      final keys = box.keys.toList();
      await box.delete(keys.first);
    }
  }

  Future<VitalReading?> getLastReading() async {
    final box = Hive.box(_vitalsBox);
    if (box.isEmpty) return null;
    final lastKey = box.keys.last;
    final data = box.get(lastKey);
    if (data == null) return null;
    return VitalReading.fromMap(jsonDecode(data));
  }

  Future<List<VitalReading>> getCachedReadings({int limit = 50}) async {
    final box = Hive.box(_vitalsBox);
    final keys = box.keys.toList().reversed.take(limit).toList();
    final readings = <VitalReading>[];
    for (final key in keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          readings.add(VitalReading.fromMap(jsonDecode(data)));
        } catch (_) {}
      }
    }
    return readings;
  }

  Future<void> addToPendingSync(VitalReading reading) async {
    final box = Hive.box(_pendingBox);
    await box.put(reading.id, jsonEncode(reading.toMap()));
  }

  Future<List<VitalReading>> getPendingSync() async {
    final box = Hive.box(_pendingBox);
    return box.values
        .map((v) => VitalReading.fromMap(jsonDecode(v)))
        .toList();
  }

  Future<void> clearPendingSync(String id) async {
    final box = Hive.box(_pendingBox);
    await box.delete(id);
  }

  Future<void> clearAll() async {
    await Hive.box(_vitalsBox).clear();
    await Hive.box(_pendingBox).clear();
  }
}
