import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vital_model.dart';
import 'offline_service.dart';

// TODO: Replace with your actual server IP before demo
// Your backend runs on: python main.py → then get IP with ipconfig
const String _wsBaseUrl = 'ws://192.168.1.100:8000/ws/vitals';
const String _httpBaseUrl = 'http://192.168.1.100:8000';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<VitalReading>? _vitalsController;
  Timer? _reconnectTimer;
  String? _userId;
  bool _isConnected = false;
  final OfflineService _offlineService;

  WebSocketService(this._offlineService);

  Stream<VitalReading> get vitalsStream {
    _vitalsController ??= StreamController<VitalReading>.broadcast();
    return _vitalsController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect(String userId) async {
    _userId = userId;
    _vitalsController ??= StreamController<VitalReading>.broadcast();

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_wsBaseUrl/$userId'),
      );
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            final reading = VitalReading.fromMap(data);
            _vitalsController!.add(reading);
            _offlineService.cacheVitalReading(reading);
          } catch (e) {
            print('WS parse error: $e');
          }
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
          _serveCachedData();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      // Backend not running — serve cached/demo data
      _isConnected = false;
      _serveDemoData();
    }
  }

  /// Serves demo vitals when backend is not connected
  void _serveDemoData() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isConnected) {
        timer.cancel();
        return;
      }
      final demo = VitalReading(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId ?? 'demo',
        timestamp: DateTime.now(),
        heartRate: 72 + (DateTime.now().second % 10).toDouble(),
        spo2: 97 + (DateTime.now().second % 3).toDouble(),
        temperature: 36.6 + (DateTime.now().second % 2) * 0.1,
        ecgValue: 0.5,
        phiScore: 82,
        stressLevel: 25,
        hrv: 58,
        source: 'demo',
        isSynced: false,
      );
      _vitalsController?.add(demo);
    });
  }

  void _serveCachedData() async {
    final cached = await _offlineService.getLastReading();
    if (cached != null) {
      _vitalsController?.add(cached.copyWith(isSynced: false));
    } else {
      _serveDemoData();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_userId != null) connect(_userId!);
    });
  }

  void sendManualReading(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'manual_input', ...data}));
    }
  }

  void sendRPPGReading(double heartRate) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'rppg',
        'heartRate': heartRate,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _vitalsController?.close();
  }
}

final offlineServiceProvider = Provider<OfflineService>((ref) => OfflineService());

final wsServiceProvider = Provider<WebSocketService>((ref) {
  final offline = ref.watch(offlineServiceProvider);
  final service = WebSocketService(offline);
  ref.onDispose(() => service.dispose());
  return service;
});

final vitalsStreamProvider = StreamProvider.family<VitalReading, String>((ref, userId) {
  final wsService = ref.watch(wsServiceProvider);
  wsService.connect(userId);
  return wsService.vitalsStream;
});
