import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hardware_service.dart';

// ── Connection status ─────────────────────────────────────────────────────────
enum HwConnectionStatus {
  disconnected,
  connecting,
  fingerNotDetected,
  connected,
}

// ── History entry from hardware ───────────────────────────────────────────────
class HwReading {
  final double hr;
  final double spo2;
  final double temp;
  final DateTime time;
  final String source; // 'sensor' | 'cache'

  const HwReading({
    required this.hr,
    required this.spo2,
    required this.temp,
    required this.time,
    this.source = 'sensor',
  });
}

// ── State ─────────────────────────────────────────────────────────────────────
class HardwareState {
  final bool isRealTimeMode;
  final String ipAddress;
  final HwConnectionStatus connectionStatus;

  // Latest live or cached values
  final double latestHr;
  final double latestSpo2;
  final double latestTemp;
  final bool fingerDetected;
  final DateTime? lastReadingTime;

  // Ring buffer of the last 30 real-time readings
  final List<HwReading> history;

  const HardwareState({
    this.isRealTimeMode = false,
    this.ipAddress = '',
    this.connectionStatus = HwConnectionStatus.disconnected,
    this.latestHr = 72.0,
    this.latestSpo2 = 98.0,
    this.latestTemp = 36.6,
    this.fingerDetected = false,
    this.lastReadingTime,
    this.history = const [],
  });

  bool get isConnected =>
      connectionStatus == HwConnectionStatus.connected ||
      connectionStatus == HwConnectionStatus.fingerNotDetected;

  /// Source label for UI badges
  String get sourceLabel {
    if (!isRealTimeMode) return 'DEMO';
    if (connectionStatus == HwConnectionStatus.connected && fingerDetected) return 'SENSOR';
    if (isConnected) return 'CACHED';
    return 'CACHED';
  }

  HardwareState copyWith({
    bool? isRealTimeMode,
    String? ipAddress,
    HwConnectionStatus? connectionStatus,
    double? latestHr,
    double? latestSpo2,
    double? latestTemp,
    bool? fingerDetected,
    DateTime? lastReadingTime,
    List<HwReading>? history,
  }) {
    return HardwareState(
      isRealTimeMode: isRealTimeMode ?? this.isRealTimeMode,
      ipAddress: ipAddress ?? this.ipAddress,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      latestHr: latestHr ?? this.latestHr,
      latestSpo2: latestSpo2 ?? this.latestSpo2,
      latestTemp: latestTemp ?? this.latestTemp,
      fingerDetected: fingerDetected ?? this.fingerDetected,
      lastReadingTime: lastReadingTime ?? this.lastReadingTime,
      history: history ?? this.history,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class HardwareNotifier extends StateNotifier<HardwareState> {
  Timer? _timer;
  final HardwareService _service = HardwareService();

  HardwareNotifier() : super(const HardwareState());

  // ── Public API ─────────────────────────────────────────────────────────────
  void setIpAddress(String ip) {
    state = state.copyWith(ipAddress: ip.trim());
  }

  void setRealTimeMode(bool isRealTime) {
    if (isRealTime) {
      state = state.copyWith(
        isRealTimeMode: true,
        connectionStatus: HwConnectionStatus.connecting,
      );
      _startPolling();
    } else {
      _stopPolling();
      state = state.copyWith(
        isRealTimeMode: false,
        connectionStatus: HwConnectionStatus.disconnected,
        fingerDetected: false,
      );
    }
  }

  void _startPolling() {
    _timer?.cancel();
    // Immediately fetch history + current reading
    _fetchHistory();
    _fetchLatest();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchLatest());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Fetch latest vitals from /json ─────────────────────────────────────────
  Future<void> _fetchLatest() async {
    if (!state.isRealTimeMode || state.ipAddress.isEmpty) return;

    final data = await _service.fetchJson(state.ipAddress);

    if (data == null) {
      // Hardware unreachable — keep cached values, mark disconnected
      state = state.copyWith(
        connectionStatus: HwConnectionStatus.disconnected,
        fingerDetected: false,
      );
      return;
    }

    final hr = (data['hr'] as num?)?.toDouble() ?? 0;
    final spo2 = (data['spo2'] as num?)?.toDouble() ?? 0;
    final temp = (data['bodyTemp'] as num?)?.toDouble() ?? 0;
    final fingerDetected =
        data['fingerDetected'] == true || data['fingerDetected'] == 1;

    if (fingerDetected && hr > 0 && spo2 > 0) {
      final newReading = HwReading(
        hr: hr,
        spo2: spo2,
        temp: temp > 0 ? temp : state.latestTemp,
        time: DateTime.now(),
        source: 'sensor',
      );

      // Append to ring buffer (keep last 30)
      final history = [...state.history, newReading];
      if (history.length > 30) history.removeAt(0);

      state = state.copyWith(
        connectionStatus: HwConnectionStatus.connected,
        latestHr: hr,
        latestSpo2: spo2,
        latestTemp: temp > 0 ? temp : state.latestTemp,
        fingerDetected: true,
        lastReadingTime: DateTime.now(),
        history: history,
      );
    } else {
      // Connected but no finger — cache last known values
      state = state.copyWith(
        connectionStatus: HwConnectionStatus.fingerNotDetected,
        fingerDetected: false,
      );
    }
  }

  // ── Backfill history from /history endpoint ────────────────────────────────
  Future<void> _fetchHistory() async {
    if (state.ipAddress.isEmpty) return;
    final readings = await _service.fetchHistory(state.ipAddress);
    if (readings.isEmpty) return;

    final hwReadings = readings.map((r) {
      return HwReading(
        hr: (r['hr'] as num?)?.toDouble() ?? 0,
        spo2: (r['spo2'] as num?)?.toDouble() ?? 0,
        temp: (r['bodyTemp'] as num?)?.toDouble() ?? 0,
        // ts from ESP32 is millis uptime — convert to approximate wall time
        time: DateTime.now().subtract(
          Duration(milliseconds: ((r['ts'] as num?)?.toInt() ?? 0)),
        ),
        source: 'sensor',
      );
    }).where((r) => r.hr > 0 && r.spo2 > 0).toList();

    if (hwReadings.isEmpty) return;

    final combined = [...hwReadings, ...state.history];
    // Dedupe & keep last 30 by time
    combined.sort((a, b) => a.time.compareTo(b.time));
    final trimmed = combined.length > 30
        ? combined.sublist(combined.length - 30)
        : combined;

    state = state.copyWith(history: trimmed);
  }

  @override
  void dispose() {
    _stopPolling();
    _service.dispose();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final hardwareProvider =
    StateNotifierProvider<HardwareNotifier, HardwareState>((ref) {
  return HardwareNotifier();
});

/// Convenience: true when real-time AND connected (finger or cached)
final isHardwareActiveProvider = Provider<bool>((ref) {
  final hw = ref.watch(hardwareProvider);
  return hw.isRealTimeMode && hw.isConnected;
});
